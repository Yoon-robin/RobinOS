# Install RobinOS Prototype

RobinOS does not have a full disk installer yet.

Use this prototype flow while the ISO and installer mature.

## Option A: Existing Arch Install

On an installed Arch system:

```bash
sudo scripts/post-install.sh --dry-run
sudo scripts/post-install.sh
robinctl doctor
```

Then install the security learning profile:

```bash
sudo robinctl profile security --dry-run
sudo robinctl profile security
```

## Option B: Live ISO Prototype

Boot the RobinOS ISO, then inspect:

```bash
robinctl doctor
robinctl lab info web
robinctl lab list
robin-install
```

The current `robin-install` command is a guide, not a partitioning installer.

The live ISO stages RobinOS files at:

```bash
/opt/robinos
```

After installing Arch, copy that directory into the installed system and run:

```bash
sudo /opt/robinos/scripts/post-install.sh
```

## Future Installer Goals

- Guided disk partitioning
- Btrfs layout
- Snapper setup
- Bootloader setup
- User creation
- Korean input and locale setup
- KDE Plasma branding
- Security Lab profile selection
