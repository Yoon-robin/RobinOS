# RobinOS Vision

RobinOS should be a security learning OS, not just a Kali Linux reskin.

Kali is excellent as a professional penetration testing toolkit. RobinOS should be different by focusing on guided learning, safe lab boundaries, Korean-first usability, and a clean workstation experience.

## Brand Promise

RobinOS turns Arch into a focused security learning workstation.

## Differentiators

### 1. Learning-First Structure

Security tools should be grouped by learning path:

- Linux and networking basics
- Web security
- CTF essentials
- Reverse engineering
- Digital forensics
- Wireless security
- Cloud and container security

Instead of installing every possible tool, RobinOS should install a curated baseline and allow users to add profiles as they grow.

### 2. Safer Defaults

RobinOS should encourage ethical and controlled practice:

- Lab-only targets by default
- Local vulnerable apps in containers
- Clear separation between learning tools and daily apps
- No stealth, persistence, or credential abuse tooling in the default profile
- Snapshots before major updates

### 3. Korean-Friendly Experience

RobinOS should feel natural for Korean users from first boot:

- Korean locale options
- Korean input method setup
- Korean-friendly fonts
- Korean quickstart documentation
- Timezone and keyboard setup support

### 4. Own System Layer

RobinOS needs its own commands and system glue:

```bash
robinctl doctor
robinctl update
robinctl snapshot create
robinctl profile security
robinctl lab start web
robinctl lab stop web
```

This makes RobinOS feel like a real OS experience, not a theme pack.

## Recommended Base

Use Arch Linux as the base.

Reasons:

- Latest security and development packages
- Strong customization path through `archiso`
- `pacman`, AUR, and optional BlackArch integration
- Good fit for building a custom identity

Kali Linux should be treated as inspiration, not the base. If Kali becomes the base, RobinOS will likely be perceived as a Kali remix. Arch gives RobinOS more room to become its own thing.

