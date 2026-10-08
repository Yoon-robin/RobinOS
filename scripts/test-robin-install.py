#!/usr/bin/env python3
"""Fast checks for installer/robin-install, no VM or root needed: the graphics
driver choice on a stand-in /sys/bus/pci/devices, the initramfs hooks and the
fstab rewrite. wsl-build.ps1 check runs it; the install tests cover the rest.

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

if failures:
    print(f"{failures} robin-install check(s) failed.")
    sys.exit(1)
print("robin-install checks passed.")
