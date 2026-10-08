#!/usr/bin/env bash
set -euo pipefail

# Locales: Korean desktop with an English fallback
sed -i -e 's/^#\(ko_KR.UTF-8 UTF-8\)/\1/' -e 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

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

# GTK/libadwaita defaults and the fonts fetched by scripts/fetch-fonts.sh
dconf update
fc-cache -f

systemctl enable NetworkManager.service
systemctl enable sddm.service
systemctl enable bluetooth.service
# Power mode in quick settings (desktop/shell/QuickSettings.qml)
systemctl enable power-profiles-daemon.service
systemctl set-default graphical.target

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
