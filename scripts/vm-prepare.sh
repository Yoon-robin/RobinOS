#!/usr/bin/env bash
set -euo pipefail

# Prepares the newest built ISO for a VM that runs outside this Linux system
# (QEMU for Windows with WHPX, see scripts/wsl-build.ps1): copies the ISO to a
# directory and extracts the live kernel and initramfs for direct boot.
#
# Usage: scripts/vm-prepare.sh <dest-dir> [iso]
# Prints one line: <archiso base dir> <ISO label> <ISO file name>

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:?usage: scripts/vm-prepare.sh <dest-dir> [iso]}"
# Builds land in this checkout's out/, or in the WSL clone's when this copy is on /mnt/c
ISO="${2:-$(ls -t "${ROOT_DIR}"/out/robinos-*.iso /root/RobinOS/out/robinos-*.iso 2>/dev/null | head -n1)}"

[[ -n "${ISO}" && -f "${ISO}" ]] || { printf 'error: no ISO in %s/out (build one first)\n' "${ROOT_DIR}" >&2; exit 1; }
mkdir -p "${DEST}"

# Copy only when the ISO changed; it is 2.5 GB
if [[ ! -f "${DEST}/robinos.iso" ]] || ! cmp -s <(stat -c '%s %Y' "${ISO}") "${DEST}/robinos.iso.stamp"; then
  cp "${ISO}" "${DEST}/robinos.iso"
  stat -c '%s %Y' "${ISO}" >"${DEST}/robinos.iso.stamp"
fi

# Same lookups as scripts/boot-test.sh
kernel_path="$(bsdtar -tf "${ISO}" | sed 's#^\./##' | grep -E '^[^/]+/boot/x86_64/vmlinuz-linux$' | head -n1)"
[[ -n "${kernel_path}" ]] || { printf 'error: no archiso kernel in %s\n' "${ISO}" >&2; exit 1; }
base_dir="${kernel_path%%/*}"
rm -rf "${DEST:?}/${base_dir}"
bsdtar -xf "${ISO}" -C "${DEST}" "${base_dir}/boot/x86_64/vmlinuz-linux" "${base_dir}/boot/x86_64/initramfs-linux.img"
label="$(dd if="${ISO}" bs=1 skip=32808 count=32 2>/dev/null | tr -d ' \0')"

printf '%s %s %s\n' "${base_dir}" "${label}" "$(basename "${ISO}")"
