# RobinOS VM Smoke Test

After building an ISO, boot it in a VM and check the live environment.

## QEMU

On Arch Linux:

```bash
sudo pacman -S --needed qemu-full
scripts/run-vm.sh
```

Use more memory and CPUs:

```bash
scripts/run-vm.sh --memory 8192 --cpus 4
```

Boot a specific ISO:

```bash
scripts/run-vm.sh --iso out/robinos-YYYY.MM.DD-x86_64.iso
```

Try UEFI boot:

```bash
sudo pacman -S --needed edk2-ovmf
scripts/run-vm.sh --uefi
```

## Live Checks

In the booted live environment:

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

- Boot menu says RobinOS Security Learning Live
- SDDM uses the RobinOS theme
- The RobinOS desktop starts: top bar, dock, and dot-grid wallpaper
- `Super+Space` opens the launcher and `Super+S` opens quick settings
- foot uses the RobinOS colors and Korean input toggles with Right Alt
- `~/.local/state/robinos/session.log` shows the rendering mode (software in most VMs)
- Ethics notice appears in `/etc/motd`

