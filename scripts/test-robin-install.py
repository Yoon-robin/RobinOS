#!/usr/bin/env python3
"""Fast checks for installer/robin-install, no VM or root needed: the graphics
driver choice on a stand-in /sys/bus/pci/devices, the initramfs hooks, the
fstab rewrite and the guest tools for the VM. wsl-build.ps1 check runs it; the
install tests cover the rest.

    python3 scripts/test-robin-install.py
"""
import importlib.machinery
import importlib.util
import os
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("robin_install", os.path.join(ROOT, "installer", "robin-install"))
spec = importlib.util.spec_from_loader("robin_install", loader)
robin = importlib.util.module_from_spec(spec)
loader.exec_module(robin)
robin.say = lambda text: None

failures = 0


def check(what, got, want):
    global failures
    if got == want:
        print(f"  ok      {what}")
    else:
        print(f"  FAILED  {what}: got {got!r}, want {want!r}")
        failures += 1


def pci(root, *devices):
    """A stand-in /sys/bus/pci/devices with (vendor, device, class) entries."""
    path = tempfile.mkdtemp(dir=root)
    for number, (vendor, device, pci_class) in enumerate(devices):
        slot = os.path.join(path, f"0000:0{number}:00.0")
        os.makedirs(slot)
        for name, value in (("vendor", vendor), ("device", device), ("class", pci_class)):
            with open(os.path.join(slot, name), "w") as f:
                f.write(f"0x{value:04x}\n" if name != "class" else f"0x{value:06x}\n")
    return path


INTEL_GPU = (0x8086, 0x9BC4, 0x030000)
RTX_3060 = (0x10DE, 0x2504, 0x030000)
RTX_3060_AUDIO = (0x10DE, 0x228E, 0x040300)
GTX_1650 = (0x10DE, 0x1F82, 0x030000)
GTX_1060 = (0x10DE, 0x1C03, 0x030000)
LAPTOP_RTX_3050 = (0x10DE, 0x25A2, 0x030200)

print("Graphics drivers")
with tempfile.TemporaryDirectory() as root:
    check("only NVIDIA display controllers count", robin.nvidia_gpus(pci(root, INTEL_GPU, RTX_3060, RTX_3060_AUDIO)), [0x2504])
    check("no NVIDIA card: nothing extra", robin.gpu_drivers(pci(root, INTEL_GPU)), [])
    check("RTX 30: nvidia-open", robin.gpu_drivers(pci(root, RTX_3060, RTX_3060_AUDIO)), ["nvidia-open"])
    check("GTX 16 (Turing): nvidia-open", robin.gpu_drivers(pci(root, GTX_1650)), ["nvidia-open"])
    check("GTX 10 (Pascal): keeps nouveau", robin.gpu_drivers(pci(root, GTX_1060)), [])
    check("laptop with a 3D controller next to Intel: nvidia-open",
          robin.gpu_drivers(pci(root, INTEL_GPU, LAPTOP_RTX_3050)), ["nvidia-open"])
    check("no PCI directory: nothing extra", robin.gpu_drivers(os.path.join(root, "missing")), [])

print("Initramfs hooks")
check("without NVIDIA: the udev hooks as they are", robin.initramfs_hooks(False), robin.UDEV_HOOKS)
check("with nvidia-open: no kms hook", "kms" in robin.initramfs_hooks(True).split(), False)
check("with nvidia-open: the rest stays in order",
      robin.initramfs_hooks(True), robin.UDEV_HOOKS.replace(" kms", ""))

print("fstab")
fstab = ("UUID=1 / btrfs rw,noatime,compress=zstd:1,subvolid=256,subvol=/@ 0 0\n"
         "UUID=2 /efi vfat rw,relatime 0 2\n")
check("subvolid= goes, subvol= stays", robin.without_subvolid(fstab),
      "UUID=1 / btrfs rw,noatime,compress=zstd:1,subvol=/@ 0 0\nUUID=2 /efi vfat rw,relatime 0 2\n")

print("Guest tools")
for virt, vmware, want in (("vmware", True, (["open-vm-tools"], ["vmtoolsd.service"])),
                           ("vmware", False, ([], [])),  # QEMU on Windows (WHPX), T-137
                           ("kvm", False, (["qemu-guest-agent"], [])),
                           ("none", False, ([], []))):
    robin.output = lambda *args, virt=virt: virt + "\n"
    robin.is_vmware = lambda vmware=vmware: vmware
    check(f"{virt}, VMware answers: {vmware}", robin.guest_tools(), want)

print("BitLocker (T-147)")
GIB = 1024**3


def lsblk_disk(windows_fstype):
    """lsblk -J for a GPT disk with an ESP, a Windows partition and 100 GB free."""
    return {"blockdevices": [{
        "name": "nvme0n1", "path": "/dev/nvme0n1", "size": 512 * GIB, "type": "disk",
        "model": "Test", "tran": "nvme", "rm": False, "ro": False, "pttype": "gpt",
        "children": [
            {"path": "/dev/nvme0n1p1", "parttype": robin.ESP_TYPE, "fstype": "vfat"},
            {"path": "/dev/nvme0n1p2", "parttype": "ebd0a0a2-b9e5-4433-87c0-68b6b72699c7",
             "fstype": windows_fstype},
        ]}]}


def fake_output(listing):
    def output(*args):
        if args[0] == "lsblk":
            return robin.json.dumps(listing)
        # parted -m: the largest free block
        return f"BYT;\n1:1048576B:{101 * GIB}B:{100 * GIB}B:free;\n"
    return output


robin.live_disk = lambda: None
for fstype, want in (("ntfs", False), ("BitLocker", True)):
    robin.output = fake_output(lsblk_disk(fstype))
    disk = robin.list_disks()[0]
    check(f"Windows partition {fstype}: windows", disk["windows"], True)
    check(f"Windows partition {fstype}: bitlocker", disk["bitlocker"], want)
    check(f"Windows partition {fstype}: can install alongside", disk["can_alongside"], True)

robin.output = fake_output(lsblk_disk("BitLocker"))
disk = robin.list_disks()[0]
ran = []
robin.run = lambda *args, **kwargs: ran.append(args)
try:
    robin.prepare_disk({"mode": "alongside"}, disk)
    refused = False
except robin.InstallError:
    refused = True
check("BitLocker without the recovery key confirmed: refused", refused, True)
check("refused before touching the disk", ran, [])

print("pacman progress (piped, pacman prints \"installing name...\" without counters)")
pacman = robin.PacmanProgress()
check("database downloads before the package list don't count", pacman.feed(" core downloading..."), None)
check("the package list starts the download step", pacman.feed("Packages (40) a-1-1 b-1-1"), (12, "패키지 내려받기 (0/40)"))
shown = [pacman.feed(f" pkg{n}-1-1-x86_64 downloading...") for n in range(40)]
check("downloads report every tenth package", [s for s in shown if s],
      [(19, "패키지 내려받기 (10/40)"), (27, "패키지 내려받기 (20/40)"),
       (34, "패키지 내려받기 (30/40)"), (42, "패키지 내려받기 (40/40)")])
check("other lines show nothing", pacman.feed(":: Processing package changes..."), None)
check("checking steps with a counter show nothing", pacman.feed("(40/40) checking keys in keyring..."), None)
shown = [pacman.feed(f"installing pkg{n}...") for n in range(40)]
check("installing takes 42-70%, a tenth at a time", [s for s in shown if s],
      [(49, "패키지 설치 (10/40)"), (56, "패키지 설치 (20/40)"),
       (63, "패키지 설치 (30/40)"), (70, "패키지 설치 (40/40)")])
check("a terminal's counter is taken as it is", robin.PacmanProgress().feed("( 20/40) installing glibc"),
      (56, "패키지 설치 (20/40)"))

print("Disk picture and an earlier RobinOS partition")
MIB = 1024**2
windows_disk = {"blockdevices": [{
    "name": "nvme0n1", "path": "/dev/nvme0n1", "size": 512 * GIB, "type": "disk",
    "model": "Test", "tran": "nvme", "rm": False, "ro": False, "pttype": "gpt",
    "children": [
        {"path": "/dev/nvme0n1p1", "partn": 1, "size": 100 * MIB, "parttype": robin.ESP_TYPE, "fstype": "vfat"},
        {"path": "/dev/nvme0n1p2", "partn": 2, "size": 16 * MIB, "parttype": robin.WINDOWS_RESERVED_TYPE},
        {"path": "/dev/nvme0n1p3", "partn": 3, "size": 300 * GIB, "parttype": robin.WINDOWS_DATA_TYPE,
         "fstype": "ntfs", "label": "OS"},
        {"path": "/dev/nvme0n1p4", "partn": 4, "size": 150 * GIB, "parttype": robin.LINUX_TYPE,
         "partlabel": "RobinOS", "fstype": "btrfs"},
        {"path": "/dev/nvme0n1p5", "partn": 5, "size": 1 * GIB, "parttype": robin.WINDOWS_RECOVERY_TYPE,
         "fstype": "ntfs"},
    ]}]}
parted = ("BYT;\n/dev/nvme0n1:549755813888B:nvme:512:512:gpt:Test:;\n"
          "1:17408B:1048575B:1031168B:free;\n"
          f"1:1048576B:1B:{100 * MIB}B:fat32:EFI system partition:boot, esp;\n"
          f"2:1B:1B:{16 * MIB}B::Microsoft reserved partition:msftres;\n"
          f"3:1B:1B:{300 * GIB}B:ntfs:Basic data partition:msftdata;\n"
          f"4:1B:1B:{150 * GIB}B:btrfs:RobinOS:;\n"
          f"5:1B:1B:{1 * GIB}B:ntfs::hidden, diag;\n"
          f"1:1B:1B:{20 * GIB}B:free;\n")


def output_with(listing, table):
    return lambda *args: robin.json.dumps(listing) if args[0] == "lsblk" else table


robin.output = output_with(windows_disk, parted)
disk = robin.list_disks()[0]
check("the picture follows the disk, without the 1 MB alignment gap",
      [(s["kind"], s["name"]) for s in disk["layout"]],
      [("efi", "EFI"), ("system", "윈도우 예약"), ("windows", "OS"), ("robinos", "RobinOS"),
       ("system", "윈도우 복구"), ("free", "빈 공간")])
check("the earlier RobinOS partition is found", disk["robinos"], {"path": "/dev/nvme0n1p4", "size": 150 * GIB})
check("free space is only 20 GB", disk["free"], 20 * GIB)
check("alongside still possible: into the earlier partition", disk["can_alongside"], True)

ran = []
robin.run = lambda *args, **kwargs: ran.append(args)
robin.settle = lambda path: None
esp, root = robin.prepare_disk({"mode": "alongside", "replace": "/dev/nvme0n1p4"}, disk)
check("replace: installs into the earlier partition", (esp, root), ("/dev/nvme0n1p1", "/dev/nvme0n1p4"))
check("replace: no new partition", [a for a in ran if a[0] == "sgdisk"], [])
check("replace: formats only that partition", ran, [("mkfs.btrfs", "-f", "-L", "RobinOS", "/dev/nvme0n1p4")])
for plan, what in (({"mode": "alongside", "replace": "/dev/nvme0n1p3"}, "Windows' C: as the partition to replace"),
                   ({"mode": "alongside"}, "no replace and only 20 GB free")):
    ran = []
    try:
        robin.prepare_disk(plan, disk)
        refused = False
    except robin.InstallError:
        refused = True
    check(f"{what}: refused before touching the disk", (refused, ran), (True, []))

print("Windows on another disk")
data_disk = {"path": "/dev/sdb", "windows": True, "esp": None, "removable": False}
windows_ssd = {"path": "/dev/sda", "windows": True, "esp": "/dev/sda1", "removable": False}
usb_windows = {"path": "/dev/sdc", "windows": True, "esp": "/dev/sdc1", "removable": True}
target = {"path": "/dev/nvme0n1", "windows": False, "esp": None, "removable": False}
check("Windows on another SSD: in the boot menu", robin.windows_elsewhere([target, windows_ssd], "/dev/nvme0n1"), True)
check("an NTFS data disk isn't Windows", robin.windows_elsewhere([target, data_disk], "/dev/nvme0n1"), False)
check("a removable drive doesn't count", robin.windows_elsewhere([target, usb_windows], "/dev/nvme0n1"), False)
check("the target disk itself doesn't count", robin.windows_elsewhere([windows_ssd], "/dev/sda"), False)

print("Plan checks")


def plan_refused(**changes):
    plan = {"disk": "/dev/vda", "mode": "whole", "user": "robin", "password": "x",
            "hostname": "robinos", "timezone": "Asia/Seoul", **changes}
    fd, path = tempfile.mkstemp()
    with os.fdopen(fd, "w") as f:
        robin.json.dump(plan, f)
    try:
        robin.read_plan(path)
        return False
    except robin.InstallError:
        return True


if os.path.isfile("/usr/share/zoneinfo/Asia/Seoul"):
    check("Asia/Seoul is fine", plan_refused(), False)
check("a time zone outside zoneinfo is refused", plan_refused(timezone="../../../etc/passwd"), True)
check("replace with the whole disk is refused", plan_refused(replace="/dev/vda2"), True)

if failures:
    print(f"{failures} robin-install check(s) failed.")
    sys.exit(1)
print("robin-install checks passed.")
