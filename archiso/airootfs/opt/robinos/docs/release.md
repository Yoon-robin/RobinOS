# RobinOS Release Checklist

This is the early release checklist for RobinOS preview ISOs.

## Build

On Arch Linux:

```bash
sudo pacman -S --needed archiso git
scripts/doctor-build.sh
scripts/build-iso.sh
```

For a faster rebuild when package names are already checked:

```bash
scripts/build-iso.sh --skip-package-check
```

## Artifacts

Expected files:

```text
out/robinos-*.iso
out/SHA256SUMS
build/logs/mkarchiso-*.log
```

## Smoke Test

Boot the ISO in a VM and check:

```bash
robinctl doctor
robinctl lab info web
ls /opt/robinos
ls /usr/share/sddm/themes/robinos
ls /usr/share/grub/themes/robinos
```

## Manual Visual Checks

- Live boot menu says RobinOS Security Learning Live
- SDDM shows the RobinOS theme
- Desktop wallpaper is available in `/usr/share/wallpapers/RobinOS`
- Konsole color scheme is installed

## Publish

Do not publish until:

- Static validation passes
- Arch package validation passes
- ISO build succeeds
- VM boot succeeds
- SHA256SUMS is generated
- Ethics notice is visible in docs and MOTD
