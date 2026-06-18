# RobinOS Desktop Defaults

RobinOS starts with KDE Plasma because it is easier to brand, easier for new users to understand, and flexible enough for security workflows.

## Defaults

- Desktop: KDE Plasma
- Terminal: Konsole
- File manager: Dolphin
- Login manager: SDDM
- Input method: Fcitx5 Hangul
- Fonts: Noto Sans, Noto Sans CJK, Noto Emoji
- Shell editor: Vim

## First Branding Targets

- SDDM theme using `assets/brand/robinos-mark.svg`
- Wallpaper using `assets/brand/robinos-logo-horizontal.svg`
- Konsole color profile
- Shell prompt
- About text and MOTD
- Application launcher categories for RobinOS labs

## Security Learning Layout

The default desktop should avoid looking like a cluttered tool dump. Tools should be grouped by task:

- Recon and network
- Web security
- Password and crypto
- Reverse engineering
- Forensics
- Local labs

## Prototype Install

Install the current visual identity files with:

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

This includes wallpaper, SDDM, Konsole, and installed-system GRUB branding.
