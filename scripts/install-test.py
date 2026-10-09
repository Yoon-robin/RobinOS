#!/usr/bin/env python3
"""Drive the RobinOS install test (scripts/install-test.sh) over the serial console.

Usage: install-test.py <live|installed|snapshots|rollback> <out-dir> [speed]

Each phase is one boot in its own QEMU run and ends by powering off (QEMU's
WHPX can't handle a guest that reboots itself).

live       Boots the ISO, installs (archinstall: default Btrfs layout, GRUB,
           EFI on /boot; or robin-install), copies the shared checkout to
           /opt/robinos and prepares a serial console for the next phases.
installed  Boots the installed disk, runs scripts/post-install.sh --yes
           (archinstall only) and checks the snapshot setup.
snapshots  Screenshots the GRUB menu and its snapshot submenu, installs a
           package to get a snap-pac pre/post pair and rolls back to the pre
           snapshot.
rollback   Checks the package is gone after the rollback, then logs in on the
           desktop and takes screenshots.

speed multiplies every timeout (1 with KVM, about 4 with TCG).
"""

import base64
import codecs
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
# "archinstall" (docs/install.md, option A) or "robinos" (installer/robin-install)
INSTALLER = os.environ.get("ROBINOS_INSTALLER", "archinstall")
TEST_LAB = os.environ.get("ROBINOS_TEST_LAB") == "1"
# robin-install next to Windows puts RobinOS on the fourth partition
ROOT_PART = "/dev/vda4" if INSTALLER == "windows" else "/dev/vda2"
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
        # The serial port delivers a few bytes at a time; an incremental decoder
        # keeps a Korean character that is split across reads in one piece.
        self.decoder = codecs.getincrementaldecoder("utf-8")("replace")

    def _receive(self, timeout):
        ready, _, _ = select.select([self.sock], [], [], timeout)
        if not ready:
            return
        data = self.sock.recv(65536)
        if not data:
            raise EOFError("serial console closed")
        text = self.decoder.decode(data)
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
            # PAM's prompt is translated on a Korean system ("비밀번호:")
            self.expect(r"[Pp]assword: ?|비밀번호: ?|암호: ?", 60)
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
        # One line, so the shell prints no prompt ("# ") inside the captured output
        self.send(f"printf '__B%s__\\n' {n}; {command}; printf '__E%s_%s__\\n' {n} \"$?\"\n")
        self.expect(rf"__B{n}__\r?\n", timeout)
        match = self.expect(rf"([\s\S]*?)__E{n}_(\d+)__", timeout)
        return int(match.group(2)), match.group(1).replace("\r", "")

    def run_long(self, command, name, timeout, logs=(), done_text=None, kill=None):
        """Runs a long command in the background of the guest shell, printing the
        tail of its output every 30 s so a hang shows where it stopped. On failure
        or timeout prints the tail of the given log files too. Returns the status.

        done_text: output that means the work is finished even if the process
        lingers afterwards; it is then ended with `kill` and counts as success."""
        out, rc = f"/root/{name}.out", f"/root/{name}.rc"
        self.run(f"rm -f {rc}; ({command} > {out} 2>&1; echo $? > {rc}) &")
        deadline = time.time() + timeout * SPEED
        status = None
        finished_seen = 0
        while time.time() < deadline:
            time.sleep(30)
            _, text = self.capture(f"cat {rc} 2>/dev/null; echo ---; tail -n 2 {out} | cut -c1-200")
            done, _, tail = text.partition("---")
            for line in tail.strip().splitlines():
                log(f"{name}: {line}")
            if done.strip().isdigit():
                status = int(done.strip())
                break
            if done_text and self.run(f"grep -qF '{done_text}' {out}", check=False) == 0:
                finished_seen += 1
                if finished_seen >= 2:  # give it a minute to exit on its own
                    log(f"{name}: finished but still running, ending it")
                    self.run(f"{kill}; sleep 3", check=False)
                    status = 0
                    break
        if status != 0:
            self.run(f"tail -n 60 {out}", check=False)
            for path in logs:
                self.run(f"tail -n 80 {path}", check=False)
        if status is None:
            raise TimeoutError(f"{name} did not finish within {timeout * SPEED:.0f}s")
        return status

    def put_file(self, path, content):
        """Writes a file in the guest (base64 in short lines over the console)."""
        data = base64.b64encode(content.encode()).decode()
        self.run(f"mkdir -p \"$(dirname {path})\" && : > {path}.b64")
        for i in range(0, len(data), 512):
            self.run(f"printf '%s' '{data[i:i + 512]}' >> {path}.b64")
        self.run(f"base64 -d {path}.b64 > {path} && rm {path}.b64")


def connect_unix(path):
    """path: a unix socket, or tcp:HOST:PORT (QEMU for Windows, see wsl-build.ps1)."""
    for _ in range(120):
        try:
            if path.startswith("tcp:"):
                host, port = path[4:].rsplit(":", 1)
                return socket.create_connection((host, int(port)))
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
    # kb_layout stays empty: setting it makes archinstall boot the target in
    # systemd-nspawn and run `systemd-run --pty localectl`, which hangs without
    # a terminal. post-install.sh sets up the keyboard and input method anyway.
    "locale_config": {"kb_layout": "", "sys_enc": "UTF-8", "sys_lang": "ko_KR"},
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


# ---- "windows": a disk that looks like a Windows install (T-006) ----
#
# GPT with Windows' usual layout: a 100 MB EFI partition holding a stand-in
# Microsoft boot manager, the Microsoft reserved partition and an NTFS "C:"
# with a marker file. The rest of the 64 GB disk is free, as after shrinking
# C: in Disk Management. robin-install then installs next to it.

WINDOWS_PARTITIONS = (1, 2, 3)


def make_windows_disk(con):
    con.run("sgdisk --zap-all /dev/vda > /dev/null"
            " && sgdisk -n 1:0:+100M -t 1:ef00 -c '1:EFI system partition'"
            " -n 2:0:+16M -t 2:0c01 -c '2:Microsoft reserved partition'"
            " -n 3:0:+20G -t 3:0700 -c '3:Basic data partition' /dev/vda"
            " && partprobe /dev/vda && udevadm settle")
    con.run("mkfs.fat -F 32 -n SYSTEM /dev/vda1 > /dev/null && mkfs.ntfs -Q -L Windows /dev/vda3 > /dev/null")
    con.run("mkdir -p /tmp/esp /tmp/win"
            " && mount /dev/vda1 /tmp/esp && mkdir -p /tmp/esp/EFI/Microsoft/Boot"
            " && echo 'stand-in for the Windows boot manager' > /tmp/esp/EFI/Microsoft/Boot/bootmgfw.efi"
            # os-prober's efi/20microsoft wants the boot configuration store next to it
            " && echo 'stand-in for the boot configuration data' > /tmp/esp/EFI/Microsoft/Boot/BCD"
            " && umount /tmp/esp"
            " && mount -t ntfs-3g /dev/vda3 /tmp/win && mkdir -p /tmp/win/Windows/System32"
            " && echo robinos-install-test > /tmp/win/marker.txt && umount /tmp/win")


def windows_state(con):
    """What must not change: the Windows partitions' table entries and the start of C:."""
    parts = " ; ".join(f"sgdisk -i {n} /dev/vda" for n in WINDOWS_PARTITIONS)
    _, table = con.capture(parts)
    _, head = con.capture("head -c 64M /dev/vda3 | sha256sum")
    return table.strip() + "\n" + head.strip()


def check_windows_kept(con, before):
    after = windows_state(con)
    if after != before:
        print(f"before:\n{before}\nafter:\n{after}", flush=True)
        raise RuntimeError("the Windows partitions changed")
    # A subshell: a bare "exit" would end the test's login shell
    con.run("(mount -o ro -t ntfs-3g /dev/vda3 /tmp/win && grep -qx robinos-install-test /tmp/win/marker.txt;"
            " s=$?; umount /tmp/win; exit $s)")
    con.run("test -f /mnt/efi/EFI/Microsoft/Boot/bootmgfw.efi && test -f /mnt/efi/EFI/RobinOS/grubx64.efi")
    # The firmware's fallback path belongs to Windows here; robin-install only adds EFI/RobinOS
    con.run("! test -e /mnt/efi/EFI/BOOT/BOOTX64.EFI")
    # Windows keeps the hardware clock in local time
    con.run("grep -qx LOCAL /mnt/etc/adjtime")
    # robin-install writes the last grub.cfg where os-prober can ask udev about
    # the EFI partition, so Windows is in the boot menu
    con.run("grep -q 'Windows Boot Manager' /mnt/boot/grub/grub.cfg")
    log("GRUB menu has Windows Boot Manager")
    log("Windows partitions, its EFI files and C: are unchanged")


# ---- Phases ----

def phase_live(con, qmp):
    con.login("root")
    wait_network(con)
    shot(qmp, "live-session")

    con.run("mkdir -p /share && (mount -o ro /dev/vdb1 /share 2>/dev/null || mount -o ro /dev/vdb /share)"
            " && test -f /share/robinos/bin/robinctl")
    if INSTALLER == "windows":
        make_windows_disk(con)
        before = windows_state(con)
        install_with_robin_install(con, mode="alongside")
        check_windows_kept(con, before)
    elif INSTALLER == "robinos":
        install_with_robin_install(con)
    else:
        install_with_archinstall(con)

    # Serial console and a GRUB menu the test can see on the installed system
    con.put_file("/mnt/etc/default/grub.d/99-install-test.cfg", GRUB_TEST_CFG)
    con.run("arch-chroot /mnt systemctl enable serial-getty@ttyS0.service")
    if INSTALLER == "windows":
        # Like robin-install: os-prober needs the live system's /run (udev), which
        # arch-chroot hides, or Windows drops out of the menu again
        con.run("(for d in proc sys dev run; do mount --rbind /$d /mnt/$d && mount --make-rslave /mnt/$d; done;"
                " chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1; s=$?;"
                " for d in run dev sys proc; do umount -R /mnt/$d; done; exit $s)")
    else:
        con.run("arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1")
    con.run("cat /mnt/etc/fstab; ls /mnt/boot", check=False)
    con.run("sync; umount -R /mnt")
    log("powering off the live system")
    con.send("poweroff\n")
    con.wait_closed(180)


def install_with_robin_install(con, mode="whole"):
    """installer/robin-install from this checkout; leaves the target on /mnt."""
    con.run("cp -r /share/robinos/. /opt/robinos/"
            " && chmod +x /opt/robinos/bin/* /opt/robinos/installer/* /opt/robinos/scripts/*.sh"
            " /opt/robinos/scripts/*.py /opt/robinos/desktop/bin/*"
            " && install -m755 /opt/robinos/installer/robin-install /usr/local/bin/robin-install")
    con.run("robin-install disks", check=False)
    plan = {"disk": "/dev/vda", "mode": mode, "user": "robin", "password": PASSWORD,
            "hostname": "robinos", "timezone": "Asia/Seoul"}
    con.put_file("/root/plan.json", json.dumps(plan))
    con.run("chmod 600 /root/plan.json")

    log("robin-install")
    status = con.run_long("robin-install run /root/plan.json", "robin-install", timeout=5400,
                          logs=("/var/log/robin-install.log",))
    con.run("grep '^@@' /root/robin-install.out", check=False)
    if status != 0:
        raise RuntimeError(f"robin-install failed with {status}")

    con.run(f"mount -o subvol=@ {ROOT_PART} /mnt && mount /dev/vda1 /mnt/efi")
    # robin-install locks root; the test logs in on the serial console as root
    con.run("arch-chroot /mnt sh -c 'echo root:robin | chpasswd'")


def install_with_archinstall(con):
    """archinstall with the default Btrfs layout; leaves the target on /mnt with /opt/robinos."""
    con.put_file("/root/config.json", json.dumps(ARCHINSTALL_CONFIG, indent=2))
    con.put_file("/root/creds.json", json.dumps(ARCHINSTALL_CREDS))

    log("archinstall")
    status = con.run_long("archinstall --config /root/config.json --creds /root/creds.json --silent"
                          " --skip-ntp --skip-wkd --skip-version-check", "archinstall",
                          timeout=2400, logs=("/var/log/archinstall/install.log",),
                          # archinstall 4.5 prints this when done, then does not exit (seen 2026-10-08)
                          done_text="You may reboot when ready",
                          kill="pkill -TERM -f bin/archinstall; sleep 5; pkill -KILL -f bin/archinstall")
    if status != 0:
        raise RuntimeError(f"archinstall failed with {status}")

    # archinstall may leave the target mounted; mount it the way we want it
    con.run("umount -R /mnt 2>/dev/null; mount -o subvol=@ /dev/vda2 /mnt && mount /dev/vda1 /mnt/boot")
    con.run("rm -rf /mnt/opt/robinos && mkdir -p /mnt/opt && cp -r /share/robinos /mnt/opt/robinos"
            " && chmod +x /mnt/opt/robinos/bin/* /mnt/opt/robinos/installer/* /mnt/opt/robinos/scripts/*.sh"
            " /mnt/opt/robinos/scripts/*.py /mnt/opt/robinos/desktop/bin/*")


GRUB_BTRFS_CFG = "/boot/grub/grub-btrfs.cfg"
# The first boot after archinstall still has its "Arch Linux" menu;
# post-install.sh renames it (config/grub/10-robinos-theme.cfg)
MENU_ENTRY = r"(RobinOS|Arch) Linux"


def boot_from_grub(con, qmp, name, show_snapshots=False):
    """Waits for the GRUB menu on the serial port, screenshots it, boots the default entry."""
    try:
        con.expect(MENU_ENTRY, 300)
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
    boot_from_grub(con, qmp, "grub-first-boot")
    con.login("root", PASSWORD)
    wait_network(con)

    # robin-install already ran post-install.sh in its chroot
    if INSTALLER == "archinstall":
        log("post-install")
        status = con.run_long("cd /opt/robinos && SUDO_USER=robin scripts/post-install.sh --yes",
                              "post-install", timeout=5400)
        con.run("tail -n 30 /root/post-install.out", check=False)
        if status != 0:
            raise RuntimeError(f"post-install.sh failed with {status}")

    con.run("robinctl doctor", check=False)
    con.run("robinctl snapshot list")
    con.run("grep -E 'snapshots|^UUID' /etc/fstab; ls /etc/pacman.d/hooks; ls /.bootbackup", check=False)
    con.run("grep -q '^HOOKS=.*grub-btrfs-overlayfs' /etc/mkinitcpio.conf", check=False)
    con.run("test -s /boot/grub/grub-btrfs.cfg && grep -c 'menuentry' /boot/grub/grub-btrfs.cfg")
    # The boot menu says RobinOS, not Arch Linux, and has no firmware BootNext entries
    con.run("grep -q \"menuentry 'RobinOS Linux\" /boot/grub/grub.cfg"
            " && grep -q \"submenu 'RobinOS snapshots'\" /boot/grub/grub.cfg"
            " && ! grep -q 'EFI BootNext' /boot/grub/grub.cfg")
    # Security learning profiles (T-010): listed, and a dry run names the packages
    con.run("robinctl profile list")
    con.run("robinctl profile network --dry-run | grep -qx '  nmap'"
            " && robinctl packages web | grep -qx docker")
    # Printing (packages/apps.txt): CUPS starts through its socket, name.local resolves
    con.run("systemctl is-enabled cups.socket avahi-daemon.service"
            " && grep -q '^hosts:.*mdns_minimal' /etc/nsswitch.conf && lpstat -r")
    # Office (packages/apps.txt): the launcher's Word, Excel and PowerPoint names
    con.run("ls /usr/share/applications/libreoffice-writer.desktop /usr/share/applications/libreoffice-calc.desktop"
            " /usr/share/applications/libreoffice-impress.desktop && pacman -Q libreoffice-still-ko")
    # Video and music (packages/apps.txt), and the default apps that open them
    # (desktop/mime/mimeapps.list): double-clicking an MP4 or MP3 in Files plays it
    # "배경으로 설정": the Wallpaper portal backend, its Python bindings and the portal choice
    con.run("test -x /usr/share/robinos/bin/robinos-wallpaper-portal"
            " && test -f /usr/share/xdg-desktop-portal/portals/robinos.portal"
            " && grep -q 'Wallpaper=robinos' /etc/xdg/xdg-desktop-portal/hyprland-portals.conf"
            " && python3 -c 'from gi.repository import Gio'")
    # (gio's first line names the default; the registered apps below are indented)
    con.run("pacman -Q showtime decibels gst-libav"
            " && gio mime video/mp4 | grep -q '^[^[:space:]].*org.gnome.Showtime.desktop'"
            " && gio mime audio/mpeg | grep -q '^[^[:space:]].*org.gnome.Decibels.desktop'"
            " && gio mime application/pdf | grep -q '^[^[:space:]].*org.gnome.Evince.desktop'")
    # App store (packages/apps.txt): GNOME Software with Flathub, without PackageKit
    con.run("test -f /usr/share/applications/org.gnome.Software.desktop && ! pacman -Q packagekit && command -v gnome-disks"
            " && grep -q DisableTelemetry /etc/firefox/policies/policies.json")
    # The shell's update dot asks checkupdates: 0 = updates, 2 = none, 1 = it failed
    con.run("checkupdates | tail -n 3; rc=${PIPESTATUS[0]}; echo checkupdates=$rc; [ $rc -ne 1 ]")
    con.run("flatpak remotes --system", check=False)
    # What the default install opens to the network (docs/ethics.md): CUPS only on
    # localhost, no sshd; Avahi's 5353/udp is the one service the LAN can reach
    con.run("ss -Htuln", check=False)
    con.run(r"! ss -Htln | awk '{print $4}' | grep -Eq '^(0\.0\.0\.0|\*|\[::\]):631$'"
            " && ! systemctl is-enabled --quiet sshd.service")
    # The system is named RobinOS, and stays so when the filesystem package puts
    # Arch's os-release back (pacman hook; SNAP_PAC_SKIP keeps the snapshot list
    # as the later phases expect). The user's ~/.bashrc loads the RobinOS prompt.
    con.run("SNAP_PAC_SKIP=y pacman -S --noconfirm filesystem > /dev/null"
            " && (. /etc/os-release && [ \"$ID\" = robinos ] && [ \"$ID_LIKE\" = arch ] && echo \"$PRETTY_NAME\")",
            timeout=600)
    con.run("grep -q robinos-bashrc.sh /etc/skel/.bashrc && grep -l robinos-bashrc.sh /home/*/.bashrc")
    # which isn't in Arch's base; the where hint and learning mission 27 need it.
    # ssh-keygen (mission 38) and gpg (mission 40, CTF 8) for the security missions,
    # wtype for the Win+. emoji picker
    con.run("command -v which && command -v ssh-keygen && command -v gpg && command -v wtype")

    # QEMU's WHPX can't reset a VM that reboots itself ("Unexpected VP exit code 4"),
    # so every boot is its own QEMU run: power off here, the next phase boots again.
    con.send("poweroff\n")
    con.wait_closed(180)


def cowsay_pre_snapshot(con):
    """Number of the snapshot snap-pac took before `pacman -S cowsay`."""
    _, listing = con.capture("snapper --no-dbus --csvout -c root list --columns number,type,description")
    print(listing, flush=True)
    pre = None
    for line in listing.splitlines():
        fields = line.split(",")
        if len(fields) >= 3 and fields[1] == "pre" and "cowsay" in line:
            pre = fields[0]
    if pre is None:
        raise RuntimeError("snap-pac made no pre snapshot for 'pacman -S cowsay'")
    return pre


def phase_snapshots(con, qmp):
    """Second boot: the snapshot submenu in GRUB and a snap-pac pair."""
    boot_from_grub(con, qmp, "grub-menu", show_snapshots=True)
    con.login("root", PASSWORD)

    # snap-pac: a pacman transaction leaves a pre/post pair behind
    con.run("pacman -S --noconfirm cowsay > /dev/null && command -v cowsay", timeout=600)
    pre = cowsay_pre_snapshot(con)

    # Where that snapshot sits in GRUB's snapshot submenu, for the next boot.
    # grub-btrfsd rebuilds the menu when snapshots appear; give it a moment.
    entry = f"@snapshots/{pre}/snapshot"
    con.run(f"for i in $(seq 30); do grep -q '{entry}' {GRUB_BTRFS_CFG} && break; sleep 2; done", timeout=120)
    # grub-btrfs.cfg: a header line "menuentry '| Date | Snapshot ...' { echo }",
    # then one unindented "submenu '| date | @snapshots/N/snapshot | ...'" per snapshot
    _, menu = con.capture(f"grep -E \"^(menuentry|submenu) '\" {GRUB_BTRFS_CFG}")
    print(menu, flush=True)
    items = [line for line in menu.splitlines() if line.startswith(("menuentry '", "submenu '"))]
    position = next((i for i, item in enumerate(items) if entry in item), None)
    if position is None:
        raise RuntimeError(f"{entry} is not in GRUB's snapshot menu")
    with open(os.path.join(OUT, "snapshot-entry.txt"), "w") as f:
        f.write(f"{position} {pre}\n")
    log(f"snapshot {pre} is item {position} of the GRUB snapshot menu")

    con.send("poweroff\n")
    con.wait_closed(180)


def phase_snapshot_boot(con, qmp):
    """Third boot: the snapshot from before cowsay, picked in the GRUB menu like
    docs/recovery.md says, and the rollback done from inside it."""
    position, pre = open(os.path.join(OUT, "snapshot-entry.txt")).read().split()
    con.expect(MENU_ENTRY, 300)
    time.sleep(3)
    qmp.keys("end")  # "RobinOS snapshots" is the last entry
    time.sleep(1)
    qmp.keys("ret")
    time.sleep(3)
    for _ in range(int(position)):  # from the header line down to the snapshot
        qmp.keys("down")
        time.sleep(0.5)
    shot(qmp, "grub-snapshot-pick")
    # The snapshot's own submenu: its title as a dummy entry, then one entry per kernel
    qmp.keys("ret")
    time.sleep(3)
    qmp.keys("down")
    time.sleep(1)
    shot(qmp, "grub-snapshot-kernel")
    qmp.keys("ret")
    con.login("root", PASSWORD)

    _, fstype = con.capture("findmnt -no FSTYPE /")
    fstype = fstype.strip()
    log(f"booted snapshot {pre}; / is {fstype}")
    if con.run("command -v cowsay", check=False) == 0:
        raise RuntimeError(f"cowsay is installed, so this is not snapshot {pre} from before it")
    # With the grub-btrfs-overlayfs hook (udev initramfs) / is an overlay in memory
    if con.run("grep -q '^HOOKS=.*grub-btrfs-overlayfs' /etc/mkinitcpio.conf", check=False) == 0 \
            and fstype != "overlay":
        raise RuntimeError(f"/ is {fstype}, not the overlay grub-btrfs-overlayfs should give")
    con.run("robinctl doctor | tail -n 3", check=False)

    log(f"rolling back to snapshot {pre} from inside it")
    con.run(f"robinctl snapshot rollback {pre} --yes")
    con.send("poweroff\n")
    con.wait_closed(180)


def phase_rollback(con, qmp):
    """Third boot: the rolled-back system, then the desktop."""
    boot_from_grub(con, qmp, "grub-after-rollback")
    con.login("root", PASSWORD)
    if con.run("command -v cowsay", check=False) == 0:
        raise RuntimeError("cowsay is still installed after the rollback")
    log("rollback ok: cowsay is gone")
    # The pre snapshot was taken mid-transaction; pacman must still work afterwards
    con.run("test ! -e /var/lib/pacman/db.lck && pacman -Q pacman")
    con.run(f"findmnt -no FSROOT /; mount -o subvolid=5 {ROOT_PART} /mnt && ls /mnt && umount /mnt", check=False)
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
    # Windows names for apps only the installed system has (packages/apps.txt):
    # "word" finds LibreOffice Writer, "store" GNOME Software, "printer" the printer
    # settings, "steam" offers Steam from the app store (Flathub), "video" the video player
    for query in ("word", "store", "printer", "steam", "video"):
        qmp.keys("meta_l", "spc")
        sleep(3)
        qmp.type_text(query)
        sleep(2)
        shot(qmp, f"launcher-{query}")
        qmp.keys("esc")
        sleep(2)
    con.run("journalctl -b --no-pager -o cat -t robinos-session | tail -n 20", check=False)

    if TEST_LAB:
        check_web_lab(con)
        check_net_lab(con)

    con.send("poweroff\n")
    con.wait_closed(180)


# ---- The web lab for real (opt-in: ROBINOS_TEST_LAB=1, wsl-build.ps1 install-test -Lab) ----

def check_web_lab(con):
    """robinctl lab start web on the installed system (T-014): the web profile
    brings Docker, the pinned images start, both apps answer on 127.0.0.1 only
    and the shell's lab status check (docker-proxy) sees them."""
    log("web lab")
    wait_network(con)
    status = con.run_long("ROBINOS_ASSUME_YES=true robinctl profile web", "profile-web", timeout=1800)
    if status != 0:
        raise RuntimeError(f"robinctl profile web failed with {status}")
    status = con.run_long("robinctl lab start web", "lab-start", timeout=2400)
    if status != 0:
        raise RuntimeError(f"robinctl lab start web failed with {status}")
    # Juice Shop answers 200; DVWA answers before its database is set up too
    con.run("for i in $(seq 90); do curl -sf -o /dev/null http://127.0.0.1:3000/"
            " && curl -s -o /dev/null http://127.0.0.1:8080/ && break; sleep 5; done;"
            " curl -sf -o /dev/null http://127.0.0.1:3000/ && curl -s -o /dev/null http://127.0.0.1:8080/", timeout=600)
    con.run("curl -s -o /dev/null -w 'DVWA %{http_code} %{redirect_url}\\n' http://127.0.0.1:8080/", check=False)
    con.run("ss -tln | grep -E ':(3000|8080) '")
    con.run("! ss -tln | grep -E ':(3000|8080) ' | grep -v '127\\.0\\.0\\.1:'")
    # desktop/shell/ShellState.qml shows the lab as running with this check
    con.run("pgrep -f 'docker-proxy .*-host-port (3000|8080)( |$)' > /dev/null")
    con.run("robinctl lab stop web", timeout=300)
    con.run("! pgrep -f 'docker-proxy .*-host-port (3000|8080)( |$)' > /dev/null")
    log("web lab ok: Juice Shop and DVWA answered on 127.0.0.1 and stopped")


def check_net_lab(con):
    """robinctl lab start net (T-057): the four lab hosts answer from this computer
    on 172.30.66.0/24, none of them listens on the host's own ports, and the lab
    stops cleanly. Docker is there from check_web_lab (web profile)."""
    log("net lab")
    status = con.run_long("robinctl lab start net", "lab-net-start", timeout=1800)
    if status != 0:
        raise RuntimeError(f"robinctl lab start net failed with {status}")
    # nmap and nc come with the network profile; plain bash and curl check the same here
    con.run("for i in $(seq 30); do curl -sf http://172.30.66.10/ | grep -q ROBIN-NET-WEB && break; sleep 2; done;"
            " curl -sf http://172.30.66.10/ | grep -q ROBIN-NET-WEB", timeout=120)
    con.run("timeout 5 bash -c 'exec 3<>/dev/tcp/172.30.66.30/31337; head -n 1 <&3' | grep -q ROBIN-NET-BANNER")
    con.run("timeout 5 bash -c 'exec 3<>/dev/tcp/172.30.66.20/6379'")
    con.run("ping -c 1 -W 2 172.30.66.40 > /dev/null")
    con.run("! ss -tln | grep -E ':(80|6379|31337) '")
    con.run("robinctl lab stop net", timeout=300)
    con.run("! docker network inspect robinos-scan > /dev/null 2>&1")
    log("net lab ok: four hosts on 172.30.66.0/24, nothing on the host's ports, stopped")


def main():
    # On Windows stdout is the ANSI code page; console output can hold anything
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    # install-test.sh uses unix sockets in OUT; wsl-build.ps1 (WHPX) passes TCP addresses
    con = Console(os.environ.get("ROBINOS_SERIAL", os.path.join(OUT, "serial.sock")))
    qmp = Qmp(os.environ.get("ROBINOS_QMP", os.path.join(OUT, "qmp.sock")))
    try:
        if PHASE == "live":
            phase_live(con, qmp)
        elif PHASE == "installed":
            phase_installed(con, qmp)
        elif PHASE == "snapshots":
            phase_snapshots(con, qmp)
        elif PHASE == "snapshot-boot":
            phase_snapshot_boot(con, qmp)
        elif PHASE == "rollback":
            phase_rollback(con, qmp)
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
