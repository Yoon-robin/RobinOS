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
systemctl set-default graphical.target

if systemctl list-unit-files docker.service >/dev/null 2>&1; then
  systemctl enable docker.service
fi
