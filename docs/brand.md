# RobinOS Brand

RobinOS uses a calm security-workstation identity: technical, trustworthy, and learning-first.

## Logo Files

- `assets/brand/robinos-mark.svg`: square app/icon mark
- `assets/brand/robinos-logo.svg`: full logo lockup
- `assets/brand/robinos-logo-horizontal.svg`: header-friendly horizontal logo

## Concept

The mark combines:

- Shield: safe lab boundaries and defensive learning
- Wing shape: RobinOS identity and forward motion
- Terminal prompt: hands-on Linux and security practice
- Red accent: the RobinOS signature color

## Palette

RobinOS follows the shadcn/ui zinc palette with Robin red as the only accent. The source of truth is `desktop/shell/Theme.qml`.

| Token | Dark (default) | Light |
|---|---|---|
| background | `#09090b` | `#ffffff` |
| surface | `#121214` | `#ffffff` |
| secondary | `#27272a` | `#f4f4f5` |
| foreground | `#fafafa` | `#09090b` |
| muted foreground | `#a1a1aa` | `#71717a` |
| border | white 10% | `#e4e4e7` |
| primary | `#fafafa` | `#18181b` |
| accent (Robin red) | `#e5484d` | `#e5484d` |
| destructive | `#f87171` | `#dc2626` |
| success | `#4ade80` | `#16a34a` |

Other accents the user can pick: orange `#f76b15`, green `#30a46c`, blue `#3e63dd`, violet `#8e4ec6`, neutral `#a1a1aa`.

## Type and Shape

- Interface: Geist, with Pretendard for Hangul
- Code and terminal: Geist Mono / GeistMono Nerd Font
- Radius: 6 (small), 8 (inputs, buttons), 10 (cards), 14 (windows, popovers), 18 (dock)
- Icons: Lucide stroke icons, 2px stroke on a 24px grid

The cyan palette of the first logo files (`assets/brand/*.svg`) predates this palette and still needs a refresh.

## Usage

Use the square mark for:

- App icon
- Boot splash
- SDDM avatar or badge
- Favicon

Use the horizontal logo for:

- Documentation headers
- Website navigation
- Installer header

Use the full lockup for:

- README hero image
- Release notes
- ISO splash screens

## Boot Branding

The first boot branding pass includes:

- `themes/grub/robinos`: GRUB boot menu theme
- `themes/sddm/robinos`: SDDM login theme
- `assets/wallpapers/robinos-default.svg`: desktop wallpaper
- `assets/wallpapers/robinos-lock.svg`: login and lock wallpaper
