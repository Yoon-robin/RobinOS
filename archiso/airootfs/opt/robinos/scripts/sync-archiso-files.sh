#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

install -Dm755 "${ROOT_DIR}/bin/robinctl" "${ROOT_DIR}/archiso/airootfs/usr/local/bin/robinctl"
install -Dm755 "${ROOT_DIR}/installer/robin-install" "${ROOT_DIR}/archiso/airootfs/usr/local/bin/robin-install"
mkdir -p "${ROOT_DIR}/archiso/airootfs/opt/robinos/assets"
cp -a "${ROOT_DIR}/assets/." "${ROOT_DIR}/archiso/airootfs/opt/robinos/assets/"
mkdir -p "${ROOT_DIR}/archiso/airootfs/opt/robinos/themes"
cp -a "${ROOT_DIR}/themes/." "${ROOT_DIR}/archiso/airootfs/opt/robinos/themes/"
install -Dm755 "${ROOT_DIR}/bin/robinctl" "${ROOT_DIR}/archiso/airootfs/opt/robinos/bin/robinctl"
mkdir -p "${ROOT_DIR}/archiso/airootfs/opt/robinos/config"
cp -a "${ROOT_DIR}/config/." "${ROOT_DIR}/archiso/airootfs/opt/robinos/config/"
# Only the Markdown: docs/screenshots (README pictures) stays out of the ISO
install -Dm644 "${ROOT_DIR}"/docs/*.md -t "${ROOT_DIR}/archiso/airootfs/opt/robinos/docs"
install -Dm644 "${ROOT_DIR}"/packages/*.txt -t "${ROOT_DIR}/archiso/airootfs/opt/robinos/packages"
install -Dm755 "${ROOT_DIR}"/scripts/*.sh -t "${ROOT_DIR}/archiso/airootfs/opt/robinos/scripts"
install -Dm644 "${ROOT_DIR}"/scripts/*.ps1 -t "${ROOT_DIR}/archiso/airootfs/opt/robinos/scripts"
mkdir -p "${ROOT_DIR}/archiso/airootfs/opt/robinos"
rm -rf "${ROOT_DIR}/archiso/airootfs/opt/robinos/labs"
cp -a "${ROOT_DIR}/labs" "${ROOT_DIR}/archiso/airootfs/opt/robinos/labs"
rm -rf "${ROOT_DIR}/archiso/airootfs/opt/robinos/desktop"
cp -a "${ROOT_DIR}/desktop" "${ROOT_DIR}/archiso/airootfs/opt/robinos/desktop"

"${ROOT_DIR}/scripts/install-desktop.sh" --root "${ROOT_DIR}/archiso/airootfs"

install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-default.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/wallpapers/RobinOS/robinos-default.svg"
install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/wallpapers/RobinOS/robinos-lock.svg"
install -Dm644 "${ROOT_DIR}/assets/brand/robinos-mark.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/pixmaps/robinos-mark.svg"
mkdir -p "${ROOT_DIR}/archiso/airootfs/usr/share/grub/themes/robinos"
cp -a "${ROOT_DIR}/themes/grub/robinos/." "${ROOT_DIR}/archiso/airootfs/usr/share/grub/themes/robinos/"
install -Dm644 "${ROOT_DIR}/config/grub/10-robinos-theme.cfg" "${ROOT_DIR}/archiso/airootfs/etc/default/grub.d/10-robinos-theme.cfg"
mkdir -p "${ROOT_DIR}/archiso/airootfs/usr/share/sddm/themes/robinos"
cp -a "${ROOT_DIR}/themes/sddm/robinos/." "${ROOT_DIR}/archiso/airootfs/usr/share/sddm/themes/robinos/"
cp "${ROOT_DIR}/assets/brand/robinos-mark.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/sddm/themes/robinos/logo.svg"
cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/sddm/themes/robinos/background.svg"
cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${ROOT_DIR}/archiso/airootfs/usr/share/sddm/themes/robinos/preview.svg"
mkdir -p "${ROOT_DIR}/archiso/airootfs/etc/sddm.conf.d"
cat >"${ROOT_DIR}/archiso/airootfs/etc/sddm.conf.d/10-robinos-theme.conf" <<'EOF'
[Theme]
Current=robinos
EOF

printf 'Synced RobinOS files into archiso/airootfs\n'
