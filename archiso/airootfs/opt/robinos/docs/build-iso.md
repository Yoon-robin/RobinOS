# Build RobinOS ISO

Build on Arch Linux or an Arch-based VM.

## Requirements

```bash
sudo pacman -S --needed archiso git
```

Before building, check package names:

```bash
scripts/check-arch-packages.sh
```

## Prepare Profile

From the repository root on Arch Linux:

```bash
scripts/prepare-archiso.sh
```

This copies Arch's official `releng` profile into `build/archiso-profile`, then overlays the RobinOS files.
It also runs `scripts/customize-iso-boot.sh` to rename the live boot menus and stage the RobinOS GRUB theme into the generated profile.

On Windows PowerShell, you can only sync project files into the source overlay:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-archiso-files.ps1
```

The actual ISO build still needs Arch Linux.

The ISO profile sets executable permissions for RobinOS scripts through `archiso/profiledef.sh`.

## Build

```bash
scripts/build-iso.sh
```

The ISO, checksum file, and build logs will be written to:

```text
out/
build/logs/
```

For a faster rebuild after packages are already checked:

```bash
scripts/build-iso.sh --skip-package-check
```

To clean generated build outputs:

```bash
scripts/clean-build.sh --yes
```

## First VM Checks

After booting the ISO:

```bash
robinctl version
robinctl doctor
robinctl profile list
robinctl lab list
ls /opt/robinos/assets/brand
ls /usr/share/grub/themes/robinos
```

The live ISO boot menu customization is applied to `build/archiso-profile`, not directly to the source `archiso/` overlay. Re-run `scripts/prepare-archiso.sh` whenever you want to regenerate the build profile.
