# RobinOS Desktop

RobinOS uses Hyprland with its own Quickshell shell. The look follows the shadcn/ui zinc palette, and the defaults are tuned for people coming from Windows. The product reasoning is in `docs/design.md`.

## Components

| Part | Program | Source in this repo |
|---|---|---|
| Compositor | Hyprland 0.56+ (Lua config) | `desktop/hypr/robinos.lua` |
| Shell: top bar, dock, launcher, quick settings, notifications, volume indicator, wallpaper | Quickshell 0.3 | `desktop/shell/` |
| Session start and rendering fallback | `robinos-session` | `desktop/bin/robinos-session` |
| Login screen | SDDM (Qt 6 theme) | `themes/sddm/robinos/` |
| Lock screen and idle | hyprlock, hypridle | `desktop/hypr/hyprlock.conf`, `hypridle.conf` |
| Terminal | foot | `desktop/foot/foot.ini` |
| Files, browser | Nautilus, Firefox | - |
| GTK and libadwaita apps | adw-gtk3, dconf defaults | `desktop/dconf/` |
| Qt apps | qt6ct palettes | `desktop/qt6ct/` |
| Korean input | fcitx5-hangul | `desktop/fcitx5/` |
| Fonts | Geist, Geist Mono, Pretendard | `desktop/fontconfig/`, `scripts/fetch-fonts.sh` |

Design tokens live in `desktop/shell/Theme.qml`. foot, hyprlock, the qt6ct palettes and the SDDM theme use the same values.

## Install Targets

`desktop/install-map.txt` lists every file and where it goes. It is the single source for:

- `scripts/install-desktop.sh` (installed systems, `--root` for other trees)
- `scripts/sync-archiso-files.sh` and `scripts/sync-archiso-files.ps1` (live ISO overlay)

Main locations:

```text
/usr/share/robinos/shell/                Quickshell config (qs -p /usr/share/robinos/shell)
/usr/share/robinos/hypr/robinos.lua      Hyprland defaults
/etc/xdg/hypr/hyprland.lua               System entry point, used when ~/.config/hypr/hyprland.lua is missing
/usr/share/wayland-sessions/robinos.desktop
/usr/share/robinos/bin/robinos-session
```

Geist and Pretendard are not in the Arch repositories. `scripts/fetch-fonts.sh` downloads pinned releases, checks their SHA-256 sums, and installs them into `/usr/share/fonts/robinos`. `scripts/prepare-archiso.sh` runs it for the ISO; `scripts/post-install.sh` runs it on installed systems.

## Rendering in VMs

`robinos-session` decides how to start Hyprland:

1. Graphics drivers without 3D acceleration (`hyperv_drm`, `bochs`, `simpledrm`, `qxl`, ...) or a missing DRM render node start in software rendering.
2. Otherwise Hyprland starts with GPU acceleration. If it exits within 8 seconds, the session restarts it with software rendering.
3. `ROBINOS_RENDER=software` turns off Hyprland blur and shadows, and the shell skips its shadow effects.

The log is in `~/.local/state/robinos/session.log`. To force a mode, export `ROBINOS_RENDER=software` or `ROBINOS_RENDER=hardware` in `~/.bash_profile`.

For GPU-accelerated testing in QEMU, run `scripts/run-vm.sh --gl`.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Super+Space` or `Super+A` | Launcher (apps, labs, system commands) |
| `Super+S` | Quick settings |
| `Super+N` | Clear notifications |
| `Super+Return` | Terminal |
| `Super+E` | Files |
| `Super+B` | Browser |
| `Super+L` | Lock screen |
| `Alt+Tab`, `Alt+Shift+Tab` | Next / previous window |
| `Alt+F4` or `Super+Q` | Close window |
| `Super+T` | Toggle the window between floating and tiled |
| `Super+F`, `Super+M` | Fullscreen, maximize |
| `Super+1`...`Super+9` | Switch workspace (`Shift` moves the window) |
| `Super+drag` | Move (left button) or resize (right button) a window |
| `Print`, `Shift+Print` | Region or full screenshot to `~/Pictures/Screenshots` and the clipboard |
| `Right Alt` | 한/영 toggle (`Right Ctrl` is 한자) |
| `Super+Shift+Escape` | Log out |

New windows float like on Windows. Quick settings has a "창 자동 정렬" switch that makes new windows tile instead.

## Windows Command Hints

`desktop/bash/robinos-hints.sh` is sourced from `~/.bashrc`. Typing a Windows command in the terminal prints the Linux equivalent:

```text
$ ipconfig
ipconfig은(는) 윈도우 명령이에요. 리눅스에서는
  ip a  IP 주소와 네트워크 장치를 보여 줘요
```

It covers about 30 commands (`dir`, `cls`, `cd..`, `copy`, `del`, `tasklist`, `tracert`, `netstat`, `findstr`, `notepad`, ...). New users get it through `/etc/skel/.bashrc`; `scripts/post-install.sh` adds it to the installing user's `~/.bashrc`.

## Live Session

The live ISO logs in automatically as `robin` (password `robin`) into the RobinOS session. Passwordless sudo is configured only on the live ISO (`/etc/sudoers.d/10-robinos-live`).

## Customizing

Create `~/.config/hypr/hyprland.lua`, load the RobinOS defaults, then override:

```lua
require("/usr/share/robinos/hypr/robinos")

hl.config({ general = { gaps_out = 16 } })
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"))
```

Theme and accent color are changed in quick settings. The choice is stored in `~/.local/state/quickshell/` and applied to GTK, libadwaita, foot, qt6ct and Hyprland borders.

Shell IPC for scripts:

```bash
qs ipc -p /usr/share/robinos/shell call shell launcher
qs ipc -p /usr/share/robinos/shell call shell setDark false
```

## Checks

```bash
scripts/check-desktop.sh
```

It checks Lua syntax, runs `Hyprland --verify-config`, parses every QML file with `qmlformat`, and checks the desktop scripts with `bash -n`. The `Validate` workflow runs it in an Arch Linux container.
