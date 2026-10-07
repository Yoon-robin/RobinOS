#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_PROFILE="${ARCHISO_RELENG:-/usr/share/archiso/configs/releng}"
OUT_PROFILE="${ROOT_DIR}/build/archiso-profile"

[[ -d "${BASE_PROFILE}" ]] || {
  printf 'error: archiso releng profile not found at %s\n' "${BASE_PROFILE}" >&2
  printf 'Install it with: sudo pacman -S --needed archiso\n' >&2
  exit 1
}

rm -rf "${OUT_PROFILE}"
mkdir -p "$(dirname "${OUT_PROFILE}")"
cp -a "${BASE_PROFILE}" "${OUT_PROFILE}"
cp -a "${ROOT_DIR}/archiso/." "${OUT_PROFILE}/"

# RobinOS uses NetworkManager. releng enables systemd-networkd and iwd, which
# would manage the same interfaces, so drop those enablement links.
systemd_dir="${OUT_PROFILE}/airootfs/etc/systemd/system"
rm -f \
  "${systemd_dir}/multi-user.target.wants/systemd-networkd.service" \
  "${systemd_dir}/multi-user.target.wants/iwd.service" \
  "${systemd_dir}/network-online.target.wants/systemd-networkd-wait-online.service" \
  "${systemd_dir}/sockets.target.wants/systemd-networkd.socket" \
  "${systemd_dir}/dbus-org.freedesktop.network1.service"

# The live user's password (robin) is public, so never start an SSH server on
# the live ISO. The ssh client stays available.
rm -f "${systemd_dir}/multi-user.target.wants/sshd.service"

"${ROOT_DIR}/scripts/sync-archiso-files.sh"
cp -a "${ROOT_DIR}/archiso/airootfs/." "${OUT_PROFILE}/airootfs/"
"${ROOT_DIR}/scripts/fetch-fonts.sh" "${OUT_PROFILE}/airootfs/usr/share/fonts/robinos"
"${ROOT_DIR}/scripts/customize-iso-boot.sh" "${OUT_PROFILE}"

printf 'Prepared RobinOS archiso profile at %s\n' "${OUT_PROFILE}"
