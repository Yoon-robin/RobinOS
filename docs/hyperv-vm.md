# Hyper-V Arch VM for RobinOS

Use this when building RobinOS from Windows.

## Requirements

- Windows 10/11 Pro, Enterprise, or Education
- Administrator PowerShell
- Virtualization enabled in firmware
- Network access

## Create the VM

Open PowerShell as Administrator:

```powershell
cd "C:\Users\robin\바탕화면\RobinOS"
powershell -ExecutionPolicy Bypass -File scripts/setup-hyperv-arch-vm.ps1
```

If the script enables Hyper-V, reboot Windows and run the same command again.

The script creates:

```text
VM name: RobinOS-Builder
Memory: 8 GB
CPUs: 4
Disk: 60 GB
ISO: %USERPROFILE%\Downloads\RobinOS-Builder\archlinux-x86_64.iso
```

## Start the VM

```powershell
Start-VM -Name "RobinOS-Builder"
vmconnect.exe localhost "RobinOS-Builder"
```

## Build RobinOS Inside Arch

Inside the Arch environment:

```bash
sudo pacman -Syu
sudo pacman -S --needed git archiso qemu-full edk2-ovmf
git clone https://github.com/Yoon-robin/RobinOS-Security-Lab.git
cd RobinOS-Security-Lab
scripts/doctor-build.sh
scripts/build-iso.sh
```

The built ISO will be in:

```text
out/
```

