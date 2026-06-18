# RobinOS Themes

This directory contains first-pass RobinOS visual identity assets for the live ISO and installed system.

## Included

- `themes/sddm/robinos`: SDDM login theme prototype
- `themes/grub/robinos`: GRUB boot menu theme prototype
- `themes/konsole/RobinOS.colorscheme`: Konsole terminal color scheme
- `assets/wallpapers/robinos-default.svg`: default desktop wallpaper
- `assets/wallpapers/robinos-lock.svg`: lock/login wallpaper

## Install Targets

Future packaging should install:

```text
assets/wallpapers/*.svg -> /usr/share/wallpapers/RobinOS/
themes/sddm/robinos -> /usr/share/sddm/themes/robinos
themes/grub/robinos -> /usr/share/grub/themes/robinos
themes/konsole/RobinOS.colorscheme -> /usr/share/konsole/RobinOS.colorscheme
```

For the current prototype:

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

For live ISO boot menu branding:

```bash
scripts/prepare-archiso.sh
```

That command runs `scripts/customize-iso-boot.sh` against the generated `build/archiso-profile`.
