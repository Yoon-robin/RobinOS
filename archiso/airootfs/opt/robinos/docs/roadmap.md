# RobinOS Roadmap

The v0.1 scope and its status are tracked in `docs/design.md`.

## Phase 0: Identity

- Define name, logo direction, color system, and desktop tone
- Decide default desktop: Hyprland + Quickshell shell (decided, see `docs/design.md`)
- Write Korean and English one-line descriptions
- Define ethical-use policy

## Phase 1: Reproducible Arch Workstation

- Create package lists
- Create post-install setup script
- Configure Korean fonts, input, locale, and timezone
- Add terminal prompt branding
- Add wallpaper and login theme placeholders - done (shell-drawn wallpaper, new SDDM theme)

## Phase 2: `robinctl`

- Implement `robinctl doctor` - initial prototype done
- Implement `robinctl profile security` - initial prototype done
- Implement `robinctl update` - initial prototype done
- Implement `robinctl snapshot create` - initial prototype done
- Add simple config file at `/etc/robinos/config.toml`

## Phase 3: Security Profiles

- Add baseline CTF tools
- Add web security tools
- Add network analysis tools
- Add reversing tools
- Add forensics tools
- Add containerized vulnerable labs

## Phase 4: ISO Build

- Create `archiso` profile - initial prototype done
- Add RobinOS branding - initial prototype done
- Add live ISO boot menu branding - initial prototype done
- Add static project validation - initial prototype done
- Add scripted ISO build and checksum flow - initial prototype done
- Add installer or guided post-install script
- Test in VM
- Document build steps

## Phase 5: Safety and Recovery

- Btrfs layout
- Snapper integration
- Bootloader snapshot entries
- `robinctl update` pre-update snapshot
- Recovery documentation

## Phase 6: Public Preview

- Build signed ISO
- Publish checksums
- Write install guide
- Write first CTF lab guide
- Create GitHub releases
