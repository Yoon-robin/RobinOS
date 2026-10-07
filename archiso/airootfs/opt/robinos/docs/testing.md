# RobinOS Testing

RobinOS has two levels of early validation.

## Static Validation on Windows

Run this from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
```

This checks:

- Required files
- SVG/XML validity
- Duplicate package entries
- Core package coverage in `archiso/packages.x86_64`
- Expected ISO security package coverage
- ISO overlay paths

The same check runs in GitHub Actions through `.github/workflows/validate.yml`.

You can run the local CI wrapper with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
```

## Package Validation on Arch

Run this on Arch Linux or inside the RobinOS live environment:

```bash
scripts/check-arch-packages.sh
```

This uses `pacman -Si` to verify package names against the configured repositories.

The same package check can be run manually in GitHub Actions through `.github/workflows/arch-package-check.yml`.

## ISO Build Smoke Test

On Arch Linux:

```bash
sudo pacman -S --needed archiso git
scripts/doctor-build.sh
scripts/build-iso.sh
```

Expected result:

```text
out/robinos-*.iso
out/SHA256SUMS
build/logs/mkarchiso-*.log
```

## VM Boot Checks

Boot the ISO with QEMU:

```bash
scripts/run-vm.sh
```

After booting the ISO in a VM:

```bash
robinctl version
robinctl doctor
robinctl lab info web
robinctl packages core
robinctl packages security
ls /opt/robinos
ls /usr/share/sddm/themes/robinos
ls /usr/share/grub/themes/robinos
```

## Visual Checks

Confirm:

- Boot menu says RobinOS Security Learning Live
- SDDM uses the RobinOS theme
- The RobinOS desktop starts: top bar, dock, and dot-grid wallpaper
- `Super+Space` opens the launcher and `Super+S` opens quick settings
- foot uses the RobinOS colors and Korean input toggles with Right Alt
- `/opt/robinos` contains docs, scripts, packages, labs, assets, and themes

More detail: `docs/vm-smoke-test.md`.
