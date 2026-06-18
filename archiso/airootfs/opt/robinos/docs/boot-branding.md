# RobinOS Boot Branding

RobinOS has a first-pass boot branding stack.

## Included

- GRUB theme: `themes/grub/robinos`
- GRUB default snippet: `config/grub/10-robinos-theme.cfg`
- SDDM theme: `themes/sddm/robinos`
- Lock wallpaper: `assets/wallpapers/robinos-lock.svg`
- Desktop wallpaper: `assets/wallpapers/robinos-default.svg`

## Installed System

On an installed Arch or RobinOS system:

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

The script installs:

```text
/usr/share/grub/themes/robinos
/etc/default/grub.d/10-robinos-theme.cfg
/usr/share/sddm/themes/robinos
/etc/sddm.conf.d/10-robinos-theme.conf
```

If `grub-mkconfig` is available and `/boot/grub` exists, the script regenerates:

```text
/boot/grub/grub.cfg
```

## Live ISO

The theme files are included inside the live filesystem at:

```text
/usr/share/grub/themes/robinos
/opt/robinos/themes/grub/robinos
```

The live ISO boot menu is customized by:

```bash
scripts/customize-iso-boot.sh build/archiso-profile
```

This is run automatically by:

```bash
scripts/prepare-archiso.sh
```

The customizer:

- Copies the RobinOS GRUB theme into the generated profile's `grub/themes/robinos`
- Adds `set theme=/grub/themes/robinos/theme.txt` to GRUB config files when present
- Renames GRUB menu text to RobinOS
- Renames Syslinux menu titles to RobinOS when present
- Renames systemd-boot loader entries when present

The customizer avoids changing low-level boot parameters such as archiso labels and boot paths.
