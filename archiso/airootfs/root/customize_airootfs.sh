#!/usr/bin/env bash
set -euo pipefail

# Locales: Korean desktop with an English fallback
sed -i -e 's/^#\(ko_KR.UTF-8 UTF-8\)/\1/' -e 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Korean time in the live session too (releng's default is UTC, so the bar's
# clock was 9 hours behind once systemd-timesyncd set the time); the installer
# asks for the installed system's time zone itself
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# Live session user. Credentials are shown in /etc/motd and docs/desktop.md.
if ! id robin >/dev/null 2>&1; then
  groups="wheel"
  for group in video audio input docker wireshark; do
    if getent group "${group}" >/dev/null; then
      groups="${groups},${group}"
    fi
  done
  useradd -m -G "${groups}" -s /bin/bash robin
  printf 'robin:robin\n' | chpasswd
fi

# Passwordless sudo exists only on the live ISO
install -m440 /dev/stdin /etc/sudoers.d/10-robinos-live <<'EOF'
robin ALL=(ALL:ALL) NOPASSWD: ALL
EOF

# fastfetch and hostnamectl say RobinOS (a pacman hook keeps it after upgrades)
/usr/share/robinos/bin/robinos-os-release

# GTK/libadwaita defaults and the fonts fetched by scripts/fetch-fonts.sh
dconf update
fc-cache -f

systemctl enable NetworkManager.service
systemctl enable sddm.service
systemctl enable bluetooth.service
# Power mode in quick settings (desktop/shell/QuickSettings.qml)
systemctl enable power-profiles-daemon.service
systemctl set-default graphical.target

# releng enables units of packages RobinOS leaves out (ModemManager, Hyper-V's
# hv_fcopy_daemon). Their dangling links made systemd's first-boot preset-all fail
# on every live boot ("unresolvable alias"), so drop them.
while IFS= read -r link; do
  [[ "$(readlink "${link}")" == /dev/null || -e "${link}" ]] || rm -f "${link}"
done < <(find /etc/systemd/system -type l)

# Docker starts on first use (robinctl lab start, or the socket), not at boot:
# docker.service at boot held the login screen back by about 5 s
if systemctl list-unit-files docker.socket >/dev/null 2>&1; then
  systemctl enable docker.socket
fi

# systemd's boot-time update jobs (ldconfig, the journal catalog) run when /usr
# is newer than /etc/.updated and /var/.updated. A fresh live ISO has neither,
# so every live boot spent about 14 s rebuilding the linker cache. Do them now.
ldconfig
journalctl --update-catalog
touch /etc/.updated /var/.updated
