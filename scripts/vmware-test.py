"""RobinOS in VMware Workstation (T-025), driven with vmrun.

  python scripts/vmware-test.py create      new VM: EFI, 8 GB, NVMe 64 GB, 3D on, live ISO
  python scripts/vmware-test.py install     boot the live ISO, run robin-install on the whole disk
  python scripts/vmware-test.py installed   boot the disk, log in automatically, screenshots + checks
  python scripts/vmware-test.py stop

Needs VMware Workstation on this PC and the ISO at build/vmware/robinos.iso (copy one
from WSL's /root/RobinOS/out/). Screenshots and guest output land in build/vmware/,
which git ignores. Moved here from build/ on 2026-11-24 so every PC has it.

Guest commands go through VMware Tools (vmtoolsd runs on the live ISO, and
robin-install installs open-vm-tools when it sees VMware), as the user robin.
The password is the test one from scripts/install-test.py.
"""
import json
import os
import subprocess
import sys
import time

VMWARE = r"C:\Program Files\VMware\VMware Workstation"
VMRUN = os.path.join(VMWARE, "vmrun.exe")
VDISK = os.path.join(VMWARE, "vmware-vdiskmanager.exe")
VM_DIR = os.path.join(os.path.expanduser("~"), "Documents", "Virtual Machines", "RobinOS")
VMX = os.path.join(VM_DIR, "RobinOS.vmx")
# Work files (ISO, screenshots, guest output) stay out of git, under build/vmware
HERE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "build", "vmware")
os.makedirs(HERE, exist_ok=True)
ISO = os.path.join(HERE, "robinos.iso")
USER, PASSWORD = "robin", "robin"


def log(message):
    print(f"[vmware] {message}", flush=True)


def vmrun(*args, guest=False, check=True, timeout=None):
    cmd = [VMRUN, "-T", "ws"]
    if guest:
        cmd += ["-gu", USER, "-gp", PASSWORD]
    cmd += list(args)
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                            encoding="utf-8", errors="replace")
    out = (result.stdout + result.stderr).strip()
    if check and result.returncode != 0:
        raise RuntimeError(f"vmrun {args[0]} failed ({result.returncode}): {out}")
    return result.returncode, out


def guest_sh(script, timeout=600, check=True):
    """Runs a shell snippet in the guest; its output comes back through a file."""
    marker = f"/tmp/vmware-test-{int(time.time() * 1000)}"
    wrapped = f"( {script} ) > {marker}.out 2>&1; echo $? > {marker}.rc"
    vmrun("runProgramInGuest", VMX, "/bin/bash", "-c", wrapped, guest=True, timeout=timeout)
    local = os.path.join(HERE, "guest.out")
    vmrun("copyFileFromGuestToHost", VMX, marker + ".out", local, guest=True)
    out = open(local, encoding="utf-8", errors="replace").read()
    vmrun("copyFileFromGuestToHost", VMX, marker + ".rc", local, guest=True)
    rc = int(open(local).read().strip() or "1")
    print(out, flush=True)
    if check and rc != 0:
        raise RuntimeError(f"guest command failed ({rc}): {script[:80]}")
    return rc, out


def wait_tools(timeout=600):
    log("waiting for VMware Tools in the guest")
    end = time.time() + timeout
    while time.time() < end:
        _, out = vmrun("checkToolsState", VMX, check=False)
        if "running" in out:
            # The user session has to be up too before guest commands work
            rc, _ = vmrun("runProgramInGuest", VMX, "/bin/true", guest=True, check=False, timeout=60)
            if rc == 0:
                return
        time.sleep(10)
    raise RuntimeError("VMware Tools did not come up")


def shot(name):
    path = os.path.join(HERE, f"{name}.png")
    vmrun("captureScreen", VMX, path, guest=True)
    log(f"screenshot {path}")


def set_vmx(**values):
    lines = open(VMX, encoding="utf-8").read().splitlines()
    keys = {k.replace("__", ":").replace("_", "."): v for k, v in values.items()}
    out = [line for line in lines if line.split("=")[0].strip() not in keys]
    out += [f'{k} = "{v}"' for k, v in keys.items()]
    open(VMX, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")


def create():
    if os.path.exists(VMX):
        raise SystemExit(f"{VMX} exists already")
    os.makedirs(VM_DIR, exist_ok=True)
    subprocess.run([VDISK, "-c", "-s", "64GB", "-a", "lsilogic", "-t", "0",
                    os.path.join(VM_DIR, "RobinOS.vmdk")], check=True)
    vmx = {
        ".encoding": "UTF-8",
        "config.version": "8",
        "virtualHW.version": "21",
        "displayName": "RobinOS",
        "guestOS": "other6xlinux-64",
        "firmware": "efi",
        "memsize": "8192",
        "numvcpus": "4",
        "nvme0.present": "TRUE",
        "nvme0:0.present": "TRUE",
        "nvme0:0.fileName": "RobinOS.vmdk",
        "sata0.present": "TRUE",
        "sata0:1.present": "TRUE",
        "sata0:1.deviceType": "cdrom-image",
        "sata0:1.fileName": ISO,
        "sata0:1.startConnected": "TRUE",
        "ethernet0.present": "TRUE",
        "ethernet0.connectionType": "nat",
        "ethernet0.virtualDev": "vmxnet3",
        "ethernet0.addressType": "generated",
        "usb.present": "TRUE",
        "usb_xhci.present": "TRUE",
        "svga.present": "TRUE",
        "mks.enable3d": "TRUE",
        "svga.graphicsMemoryKB": "8388608",
        "tools.syncTime": "TRUE",
        "sound.present": "FALSE",
        # Without the PCIe root ports VMware refuses to power on: "No PCIe slot
        # available for Ethernet0"
        "pciBridge0.present": "TRUE",
        # On a Hyper-V host VMware asks about side channel mitigations in a dialog
        # and powers on only after a click (2026-10-13); answer dialogs by themselves
        "msg.autoAnswer": "TRUE",
        "ulm.disableMitigations": "TRUE",
        # The guest's console goes to a file, to see why a boot hangs
        "serial0.present": "TRUE",
        "serial0.fileType": "file",
        "serial0.fileName": os.path.join(VM_DIR, "serial.log"),
    }
    for n in range(4, 8):
        vmx[f"pciBridge{n}.present"] = "TRUE"
        vmx[f"pciBridge{n}.virtualDev"] = "pcieRootPort"
        vmx[f"pciBridge{n}.functions"] = "8"
    with open(VMX, "w", encoding="utf-8", newline="\n") as f:
        for key, value in vmx.items():
            f.write(f'{key} = "{value}"\n')
    log(f"created {VMX}")


def install():
    set_vmx(**{"sata0__1_startConnected": "TRUE", "msg_autoAnswer": "TRUE", "ulm_disableMitigations": "TRUE"})
    vmrun("start", VMX, "gui")
    wait_tools()
    shot("live-desktop")
    plan = {"disk": "/dev/nvme0n1", "mode": "whole", "user": USER, "password": PASSWORD,
            "hostname": "robinos", "timezone": "Asia/Seoul"}
    local = os.path.join(HERE, "plan.json")
    json.dump(plan, open(local, "w"))
    vmrun("copyFileFromHostToGuest", VMX, local, "/tmp/plan.json", guest=True)
    os.remove(local)
    log("robin-install (10-20 minutes)")
    guest_sh("sudo robin-install run /tmp/plan.json > /tmp/robin-install.out 2>&1; s=$?;"
             " grep '^@@' /tmp/robin-install.out; tail -n 5 /tmp/robin-install.out; exit $s", timeout=3600)
    shot("live-after-install")
    guest_sh("sudo poweroff", check=False, timeout=60)
    time.sleep(20)
    vmrun("stop", VMX, "hard", check=False)
    log("installed; the next boot is from the disk")


def installed():
    set_vmx(**{"sata0__1_startConnected": "FALSE"})
    vmrun("start", VMX, "gui")
    wait_tools(900)
    time.sleep(10)
    shot("installed-sddm")
    # Log in without a keyboard: SDDM autologin for this test VM, then restart SDDM
    guest_sh(f"echo {PASSWORD} | sudo -S sh -c 'mkdir -p /etc/sddm.conf.d &&"
             " printf \"[Autologin]\\nUser={USER}\\nSession=robinos.desktop\\n\" > /etc/sddm.conf.d/99-vmware-test.conf"
             " && systemctl restart sddm'", check=False)
    time.sleep(45)
    shot("installed-desktop")
    guest_sh("export XDG_RUNTIME_DIR=/run/user/$(id -u); sig=$(ls $XDG_RUNTIME_DIR/hypr | head -n1);"
             " HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl monitors | head -n 12;"
             " systemctl is-active vmtoolsd; pacman -Q open-vm-tools;"
             " journalctl -b --no-pager -o cat -t robinos-session -t robinos-shell | tail -n 20", check=False)


def stop():
    vmrun("stop", VMX, "soft", check=False)


if __name__ == "__main__":
    {"create": create, "install": install, "installed": installed, "stop": stop}[sys.argv[1]]()
