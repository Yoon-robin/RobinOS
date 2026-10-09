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

# releng also ships cloud-init, which sets up users and SSH from cloud metadata
# or a "cidata" disk. A desktop live ISO has no use for it.
rm -rf "${systemd_dir}/cloud-init.target.wants"

# releng holds the boot until the clock is synced over NTP (time-sync.target), and
# pacman-init and multi-user.target wait for it. Where IPv6 doesn't reach out (the
# test VM's NAT, many home networks) timesyncd spends 10 s on each IPv6 server
# first: the boot finished at 84 s instead of 14 s, with the power mode daemon and
# pacman's keyring waiting (boot test, 2026-10-10). The clock still syncs; the boot
# just doesn't wait, and the PC's own clock is close enough for the keyring.
rm -f "${systemd_dir}/sysinit.target.wants/systemd-time-wait-sync.service"

"${ROOT_DIR}/scripts/sync-archiso-files.sh"
cp -a "${ROOT_DIR}/archiso/airootfs/." "${OUT_PROFILE}/airootfs/"
"${ROOT_DIR}/scripts/fetch-fonts.sh" "${OUT_PROFILE}/airootfs/usr/share/fonts/robinos"
"${ROOT_DIR}/scripts/customize-iso-boot.sh" "${OUT_PROFILE}"

printf 'Prepared RobinOS archiso profile at %s\n' "${OUT_PROFILE}"
