# RobinOS Build Environment

RobinOS ISO builds require Arch Linux because `mkarchiso` depends on Linux tooling, pacman repositories, loop devices, squashfs, and ISO creation tools.

## Current Windows Limitation

The repository can be edited and statically validated on Windows, but ISO creation needs one of:

- Arch Linux VM
- Arch Linux physical machine
- Linux host with Docker and privileged container support
- WSL/VM setup that can run Arch tooling correctly

## Recommended Path

Use an Arch Linux VM.

On Windows Pro, the project includes a Hyper-V helper:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-hyperv-arch-vm.ps1
```

See `docs/hyperv-vm.md`.

```bash
sudo pacman -Syu
sudo pacman -S --needed git archiso qemu-full edk2-ovmf
git clone https://github.com/Yoon-robin/RobinOS-Security-Lab.git
cd RobinOS-Security-Lab
scripts/doctor-build.sh
scripts/build-iso.sh
scripts/run-vm.sh
```

## Windows Helper

From an Administrator PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-windows-build-env.ps1
```

This enables WSL base features, but a reboot may be required. You still need an Arch-capable Linux environment to run `mkarchiso`.

## Docker Path

On a Linux host with Docker:

```bash
scripts/build-in-arch-container.sh
```

This requires privileged Docker and may not work on ordinary Windows Docker setups.
