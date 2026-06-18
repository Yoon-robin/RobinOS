#!/usr/bin/env bash
set -euo pipefail

systemctl enable NetworkManager.service
systemctl enable sddm.service

if systemctl list-unit-files docker.service >/dev/null 2>&1; then
  systemctl enable docker.service
fi

