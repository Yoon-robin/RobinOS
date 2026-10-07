#!/usr/bin/env python3
"""Drive the RobinOS install test (scripts/install-test.sh) over the serial console.

Usage: install-test.py <live|installed> <out-dir> [speed]

live       Boots the ISO, runs archinstall (default Btrfs layout, GRUB, EFI on
           /boot), copies the shared checkout to /opt/robinos and prepares a
           serial console for the next phase, then powers off.
installed  Boots the installed disk, runs scripts/post-install.sh --yes, checks
           the snapshot setup, installs a package to get a snap-pac pre/post
           pair, rolls back to the pre snapshot, reboots and checks the package
           is gone, then logs in on the desktop and takes screenshots.

speed multiplies every timeout (1 with KVM, about 4 with TCG).
"""

import base64
import json
import os
import re
import select
import socket
import sys
import time
import uuid

PHASE = sys.argv[1]
OUT = sys.argv[2]
SPEED = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
PASSWORD = "robin"  # root and the robin user, like the live ISO
MIRROR = "https://geo.mirror.pkgbuild.com/$repo/os/$arch"


def log(message):
    print(f"\n[install-test] {message}", flush=True)


# ---- Serial console ----

class Console:
    """Line-oriented control of a getty on the VM's serial port."""

    def __init__(self, path):
        self.sock = connect_unix(path)
        self.buf = ""
        self.count = 0

    def _receive(self, timeout):
        ready, _, _ = select.select([self.sock], [], [], timeout)
        if not ready:
            return
        data = self.sock.recv(65536)
        if not data:
            raise EOFError("serial console closed")
        text = data.decode("utf-8", "replace")
        sys.stdout.write(text)
        sys.stdout.flush()
        self.buf = (self.buf + text)[-200000:]

    def expect(self, pattern, timeout):
        """Waits for a regex in the output and consumes everything up to it."""
        regex = re.compile(pattern)
        deadline = time.time() + timeout * SPEED
        while True:
            match = regex.search(self.buf)
            if match:
                self.buf = self.buf[match.end():]
                return match
            remaining = deadline - time.time()
            if remaining <= 0:
                raise TimeoutError(f"no {pattern!r} within {timeout * SPEED:.0f}s")
            self._receive(min(remaining, 1.0))

    def send(self, text):
        self.sock.sendall(text.encode())

    def wait_closed(self, timeout):
        deadline = time.time() + timeout * SPEED
        try:
            while time.time() < deadline:
                self._receive(1.0)
        except (EOFError, OSError):
            return True
        return False

    def login(self, user, password=None, timeout=600):
        log(f"logging in as {user}")
        deadline = time.time() + timeout * SPEED
        while True:
            self.send("\n")
            try:
                self.expect(r"login: ", 15)
                break
            except TimeoutError:
                if time.time() > deadline:
                    raise
        self.send(user + "\n")
        if password is not None:
            self.expect(r"Password: ", 60)
            self.send(password + "\n")
        self.expect(r"[#$] $|[#$] \x1b|[#$] \r", 60)
        # The live ISO's root shell is zsh (grml); use a plain bash without echo,
        # so only command output (and our markers) comes back.
        self.send("exec bash --noprofile --norc\n")
        time.sleep(2)
        self.send("stty -echo; export PS1='# ' TERM=dumb SYSTEMD_PAGER= SYSTEMD_COLORS=0; dmesg -n 1\n")
        time.sleep(1)
        self.buf = ""

    def reboot(self):
        log("reboot")
        self.buf = ""
        self.send("reboot\n")
        # pr_emerg, so it shows despite dmesg -n 1
        self.expect(r"reboot: Restarting system", 300)

    def run(self, command, timeout=120, check=True):
        """Runs a shell command and returns its exit status."""
        self.count += 1
        n = self.count
        log(f"$ {command}")
        # printf splits the marker so a stray echo of the command can't match it
        self.send(f"{command}\nprintf '__RC{n}_%s__\\n' \"$?\"\n")
        status = int(self.expect(rf"__RC{n}_(\d+)__", timeout).group(1))
        if check and status != 0:
            raise RuntimeError(f"command failed with {status}: {command}")
        return status

    def capture(self, command, timeout=120):
        """Runs a shell command and returns (status, output)."""
        self.count += 1
        n = self.count
        log(f"$ {command}")
        self.send(f"printf '__B%s__\\n' {n}\n{command}\nprintf '__E%s_%s__\\n' {n} \"$?\"\n")
        self.expect(rf"__B{n}__\r?\n", timeout)
        match = self.expect(rf"([\s\S]*?)__E{n}_(\d+)__", timeout)
        return int(match.group(2)), match.group(1).replace("\r", "")

    def put_file(self, path, content):
        """Writes a file in the guest (base64 in short lines over the console)."""
        data = base64.b64encode(content.encode()).decode()
        self.run(f": > {path}.b64")
        for i in range(0, len(data), 512):
            self.run(f"printf '%s' '{data[i:i + 512]}' >> {path}.b64")
        self.run(f"base64 -d {path}.b64 > {path} && rm {path}.b64")


def connect_unix(path):
    for _ in range(120):
        try:
            sock = socket.socket(socket.AF_UNIX)
            sock.connect(path)
            return sock
        except OSError:
            time.sleep(1)
    raise RuntimeError(f"could not connect to {path} (did QEMU start?)")


# ---- QMP: screenshots and keys ----

class Qmp:
    def __init__(self, path):
        self.sock = connect_unix(path)
        self.file = self.sock.makefile("rwb")
        self._read()  # greeting
        self.execute("qmp_capabilities")

    def _read(self):
        line = self.file.readline()
        if not line:
            raise RuntimeError("QMP connection closed")
        return json.loads(line)

    def execute(self, command, **arguments):
        message = {"execute": command}
        if arguments:
            message["arguments"] = arguments
        self.file.write((json.dumps(message) + "\n").encode())
        self.file.flush()
        while True:
            reply = self._read()
            if "event" not in reply:
                return reply

    def keys(self, *names):
        self.execute("send-key", keys=[{"type": "qcode", "data": n} for n in names], **{"hold-time": 80})
        time.sleep(0.2)

    def type_text(self, text):
        special = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash"}
        for ch in text:
            if ch.isupper():
                self.keys("shift", ch.lower())
            else:
                self.keys(special.get(ch, ch))


shot_number = 0


def shot(qmp, name):
    global shot_number
    shot_number += 1
    path = os.path.join(OUT, f"{PHASE}-{shot_number:02d}-{name}.png")
    try:
        reply = qmp.execute("screendump", filename=path, format="png")
        log(f"screenshot {os.path.basename(path)}: {'ok' if 'return' in reply else reply}")
    except Exception as error:  # a missing screenshot shouldn't fail the test
        log(f"screenshot {name} failed: {error}")


def sleep(seconds):
    time.sleep(seconds * SPEED)


# ---- archinstall configuration (archinstall 4.5, like its guided default layout) ----

def size(value, unit):
    return {"sector_size": {"unit": "B", "value": 512}, "unit": unit, "value": value}


ARCHINSTALL_CONFIG = {
    "audio_config": {"audio": "pipewire"},
    "bootloader_config": {"bootloader": "Grub", "uki": False, "removable": True},
    "disk_config": {
        "config_type": "default_layout",
        "device_modifications": [{
            "device": "/dev/vda",
            "wipe": True,
            "partitions": [
                {
                    "btrfs": [],
                    "dev_path": None,
                    "flags": ["boot", "esp"],
                    "fs_type": "fat32",
                    "mount_options": [],
                    "mountpoint": "/boot",
                    "obj_id": str(uuid.uuid4()),
                    "size": size(1024, "MiB"),
                    "start": size(1, "MiB"),
                    "status": "create",
                    "type": "primary",
                },
                {
                    "btrfs": [
                        {"name": "@", "mountpoint": "/"},
                        {"name": "@home", "mountpoint": "/home"},
                        {"name": "@log", "mountpoint": "/var/log"},
                        {"name": "@pkg", "mountpoint": "/var/cache/pacman/pkg"},
                    ],
                    "dev_path": None,
                    "flags": [],
                    "fs_type": "btrfs",
                    "mount_options": ["compress=zstd"],
                    "mountpoint": None,
                    "obj_id": str(uuid.uuid4()),
                    "size": size(38, "GiB"),
                    "start": size(1025, "MiB"),
                    "status": "create",
                    "type": "primary",
                },
            ],
        }],
    },
    "hostname": "robinos",
    "kernels": ["linux"],
    "locale_config": {"kb_layout": "us", "sys_enc": "UTF-8", "sys_lang": "ko_KR"},
    "mirror_config": {
        "custom_servers": [{"url": MIRROR}],
        "mirror_regions": {},
        "optional_repositories": [],
        "custom_repositories": [],
    },
    "network_config": {"type": "nm"},
    "ntp": True,
    "packages": ["git"],
    "profile_config": {"profile": {"main": "Minimal"}},
    "swap": {"enabled": True, "algorithm": "zstd"},
    "timezone": "Asia/Seoul",
}

ARCHINSTALL_CREDS = {
    "!root-password": PASSWORD,
    "users": [{"username": "robin", "!password": PASSWORD, "sudo": True, "groups": []}],
}

# GRUB on the serial port too, so the test sees the menu; kernel and getty on ttyS0.
# A grub.d drop-in sorts after RobinOS's 10-robinos-theme.cfg.
GRUB_TEST_CFG = """\
GRUB_TIMEOUT=60
GRUB_TERMINAL_INPUT="console serial"
GRUB_TERMINAL_OUTPUT="gfxterm serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} console=tty0 console=ttyS0,115200"
"""


def wait_network(con):
    con.run("for i in $(seq 90); do curl -sfo /dev/null --max-time 5 https://geo.mirror.pkgbuild.com/ && break; sleep 2; done; "
            "curl -sfo /dev/null --max-time 10 https://geo.mirror.pkgbuild.com/", timeout=300)


# ---- Phases ----

def phase_live(con, qmp):
    con.login("root")
    wait_network(con)
    shot(qmp, "live-session")

    con.run("mkdir -p /share && (mount -o ro /dev/vdb1 /share 2>/dev/null || mount -o ro /dev/vdb /share)"
            " && test -f /share/robinos/bin/robinctl")
    con.put_file("/root/config.json", json.dumps(ARCHINSTALL_CONFIG, indent=2))
    con.put_file("/root/creds.json", json.dumps(ARCHINSTALL_CREDS))

    log("archinstall")
    status = con.run("archinstall --config /root/config.json --creds /root/creds.json --silent"
                     " --skip-ntp --skip-wkd --skip-version-check > /root/archinstall.out 2>&1",
                     timeout=3600, check=False)
    con.run("tail -n 40 /root/archinstall.out", check=False)
    if status != 0:
        con.run("tail -n 120 /var/log/archinstall/install.log", check=False)
        raise RuntimeError(f"archinstall failed with {status}")

    # archinstall may leave the target mounted; mount it the way we want it
    con.run("umount -R /mnt 2>/dev/null; mount -o subvol=@ /dev/vda2 /mnt && mount /dev/vda1 /mnt/boot")
    con.run("rm -rf /mnt/opt/robinos && mkdir -p /mnt/opt && cp -r /share/robinos /mnt/opt/robinos"
            " && chmod +x /mnt/opt/robinos/bin/* /mnt/opt/robinos/installer/* /mnt/opt/robinos/scripts/*.sh"
            " /mnt/opt/robinos/scripts/*.py /mnt/opt/robinos/desktop/bin/*")
    con.put_file("/mnt/etc/default/grub.d/99-install-test.cfg", GRUB_TEST_CFG)
    con.run("arch-chroot /mnt systemctl enable serial-getty@ttyS0.service")
    con.run("arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1")
    con.run("cat /mnt/etc/fstab; ls /mnt/boot", check=False)
    con.run("sync; umount -R /mnt")
    log("powering off the live system")
    con.send("poweroff\n")
    con.wait_closed(180)


def boot_from_grub(con, qmp, name, show_snapshots=False):
    """Waits for the GRUB menu on the serial port, screenshots it, boots the default entry."""
    try:
        con.expect(r"Arch Linux", 300)
    except TimeoutError:
        log("GRUB menu not seen on the serial port; continuing")
        return
    time.sleep(3)
    shot(qmp, name)
    if show_snapshots:
        qmp.keys("end")
        time.sleep(1)
        qmp.keys("ret")
        time.sleep(3)
        shot(qmp, name + "-snapshots")
        qmp.keys("esc")
        time.sleep(2)
        qmp.keys("home")
        time.sleep(1)
    qmp.keys("ret")


def phase_installed(con, qmp):
    boot_from_grub(con, qmp, "grub-before-post-install")
    con.login("root", PASSWORD)
    wait_network(con)

    log("post-install")
    status = con.run("cd /opt/robinos && SUDO_USER=robin scripts/post-install.sh --yes > /root/post-install.out 2>&1",
                     timeout=5400, check=False)
    con.run("tail -n 60 /root/post-install.out", check=False)
    if status != 0:
        raise RuntimeError(f"post-install.sh failed with {status}")

    con.run("robinctl doctor", check=False)
    con.run("robinctl snapshot list")
    con.run("grep -E 'snapshots|^UUID' /etc/fstab; ls /etc/pacman.d/hooks; ls /.bootbackup", check=False)
    con.run("grep -q '^HOOKS=.*grub-btrfs-overlayfs' /etc/mkinitcpio.conf", check=False)
    con.run("test -s /boot/grub/grub-btrfs.cfg && grep -c 'menuentry' /boot/grub/grub-btrfs.cfg")

    con.reboot()
    boot_from_grub(con, qmp, "grub-menu", show_snapshots=True)
    con.login("root", PASSWORD)

    # snap-pac: a pacman transaction leaves a pre/post pair behind
    con.run("pacman -S --noconfirm cowsay > /dev/null && command -v cowsay", timeout=600)
    _, listing = con.capture("snapper --no-dbus --csvout -c root list --columns number,type,description")
    print(listing, flush=True)
    pre = None
    for line in listing.splitlines():
        fields = line.split(",")
        if len(fields) >= 3 and fields[1] == "pre" and "cowsay" in line:
            pre = fields[0]
    if pre is None:
        raise RuntimeError("snap-pac made no pre snapshot for 'pacman -S cowsay'")

    log(f"rolling back to snapshot {pre}")
    con.run(f"robinctl snapshot rollback {pre} --yes")
    con.reboot()
    boot_from_grub(con, qmp, "grub-after-rollback")
    con.login("root", PASSWORD)
    if con.run("command -v cowsay", check=False) == 0:
        raise RuntimeError("cowsay is still installed after the rollback")
    log("rollback ok: cowsay is gone")
    con.run("findmnt -no FSROOT /; mount -o subvolid=5 /dev/vda2 /mnt && ls /mnt && umount /mnt", check=False)
    con.run("robinctl snapshot list", check=False)

    # Desktop: SDDM on the screen, log in as robin
    log("desktop login")
    sleep(10)
    shot(qmp, "sddm")
    qmp.type_text(PASSWORD + "\n")
    sleep(40)
    shot(qmp, "desktop")
    qmp.keys("esc")  # welcome wizard
    sleep(5)
    shot(qmp, "desktop-after-wizard")
    con.run("journalctl -b --no-pager -o cat -t robinos-session | tail -n 20", check=False)

    con.send("poweroff\n")
    con.wait_closed(180)


def main():
    con = Console(os.path.join(OUT, "serial.sock"))
    qmp = Qmp(os.path.join(OUT, "qmp.sock"))
    try:
        if PHASE == "live":
            phase_live(con, qmp)
        elif PHASE == "installed":
            phase_installed(con, qmp)
        else:
            raise SystemExit(f"unknown phase: {PHASE}")
    except Exception as error:
        shot(qmp, "failure")
        log(f"FAILED: {error}")
        return 1
    log(f"phase {PHASE} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
