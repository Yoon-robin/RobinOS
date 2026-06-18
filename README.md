# RobinOS

![RobinOS logo](assets/brand/robinos-logo-horizontal.svg)

RobinOS is an Arch-based security learning operating system focused on ethical hacking, CTF practice, malware-safe analysis labs, network fundamentals, and developer-friendly workflows.

The goal is not to clone Kali Linux. RobinOS should feel like its own learning workstation: safer defaults, Korean-friendly setup, guided tooling, reproducible labs, and a clean security-focused desktop experience.

## Positioning

RobinOS is for:

- Students learning Linux, networking, web security, reversing, and forensics
- CTF players who want a ready-to-practice workstation
- Developers who want a security lab without turning their daily system into a risky toolkit dump
- Korean users who want fonts, input, locale, and documentation to work naturally from first boot

RobinOS is not for:

- Attacking real systems without permission
- Hiding activity, persistence, evasion, or credential theft
- Shipping offensive automation without a legal lab context

## Core Ideas

- Arch base with curated security profiles
- Btrfs snapshots before risky updates
- Korean input, fonts, locale, and docs by default
- `robinctl` command for setup, profiles, snapshots, diagnostics, and lab tools
- Learning-first tool organization instead of dumping every pentest package into the system
- Isolated practice labs through containers and virtual machines

## Planned Editions

### RobinOS Core

Minimal desktop, Korean-friendly defaults, safe update layer, and the `robinctl` foundation.

### RobinOS Security Lab

Core plus curated tools for web security, network analysis, CTF, reversing, forensics, and wireless learning.

### RobinOS Live

Bootable live ISO for workshops, classes, quick practice, and recovery-style workflows.

## First Milestone

The first milestone is a bootable Arch ISO with:

- Branded boot, login, wallpaper, and terminal prompt
- KDE Plasma or Xfce desktop profile
- Korean input and font defaults
- `robinctl doctor`
- `robinctl profile security`
- Curated package lists
- Btrfs + Snapper design
- VM-tested installation path

## Early Commands

RobinOS now has an early `robinctl` prototype:

```bash
bin/robinctl version
bin/robinctl doctor
bin/robinctl profile list
bin/robinctl profile security --dry-run
bin/robinctl packages core
bin/robinctl packages security
bin/robinctl packages optional
bin/robinctl lab list
bin/robinctl lab info web
bin/robinctl lab status web
```

`robinctl doctor` also checks the early RobinOS branding layer: wallpaper, SDDM theme, and installed-system GRUB theme.

On a future RobinOS install, it can be installed with:

```bash
sudo scripts/install-robinctl.sh
```

For a prototype post-install setup on Arch:

```bash
sudo scripts/post-install.sh --dry-run
sudo scripts/post-install.sh
```

## Validation

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
```

On Arch Linux:

```bash
scripts/check-arch-packages.sh
scripts/build-iso.sh
```
