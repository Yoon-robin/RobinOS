#!/usr/bin/env bash
set -euo pipefail

# Boots the live ISO from a plain FAT32 data partition instead of a CD or USB stick
# (T-168, docs/install.md "USB 없이 켜 보기"): the ISO's files are copied onto a
# "Microsoft basic data" partition, the way a Windows user would after shrinking C:,
# and UEFI starts the copied \EFI\BOOT\BOOTx64.EFI. archiso then has to find its
# root image on that partition by the ISO's .uuid file, not by the CD's label.
#
# Usage (WSL, root): scripts/partition-boot-test.sh [ISO]
# Passes when the live system reaches its login prompt on the serial console.
# Results: build/partition-boot/ (serial.log)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$(ls -t "${ROOT_DIR}"/out/*.iso 2>/dev/null | head -n1)}"
# A Linux file system for the loop device (not WSL's /mnt/c)
OUT_DIR="${PARTITION_BOOT_OUT:-${ROOT_DIR}/build/partition-boot}"
TIMEOUT="${PARTITION_BOOT_TIMEOUT:-900}"

die() {
  printf 'partition-boot-test: %s\n' "$*" >&2
  exit 1
}

[[ -n "${ISO}" && -f "${ISO}" ]] || die "ISO not found: '${ISO}'"
for cmd in qemu-system-x86_64 bsdtar mkfs.fat sfdisk losetup; do
  command -v "${cmd}" >/dev/null 2>&1 || die "${cmd} is required"
done

ovmf_code=""
ovmf_vars=""
for pair in \
  /usr/share/OVMF/OVMF_CODE_4M.fd:/usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/edk2/x64/OVMF_CODE.4m.fd:/usr/share/edk2/x64/OVMF_VARS.4m.fd \
  /usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd; do
  if [[ -f "${pair%%:*}" && -f "${pair##*:}" ]]; then
    ovmf_code="${pair%%:*}"
    ovmf_vars="${pair##*:}"
    break
  fi
done
[[ -n "${ovmf_code}" ]] || die "OVMF firmware not found"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/mnt"
disk="${OUT_DIR}/disk.img"
cp "${ovmf_vars}" "${OUT_DIR}/OVMF_VARS.fd"

# One 4 GiB partition of type "Microsoft basic data" (not an EFI system partition),
# like a new volume made in Windows' Disk Management
iso_size="$(stat -c %s "${ISO}")"
part_mib=$((iso_size / 1048576 + 512))
truncate -s "$((part_mib + 2))M" "${disk}"
printf 'label: gpt\nstart=2048, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7\n' | sfdisk -q "${disk}"

loop="$(losetup --find --show --partscan "${disk}")"
cleanup() {
  umount "${OUT_DIR}/mnt" 2>/dev/null || true
  losetup -d "${loop}" 2>/dev/null || true
}
trap cleanup EXIT
mkfs.fat -F 32 -n ROBINOS "${loop}p1" >/dev/null
mount "${loop}p1" "${OUT_DIR}/mnt"
bsdtar -xf "${ISO}" -C "${OUT_DIR}/mnt"
[[ -f "${OUT_DIR}/mnt/EFI/BOOT/BOOTx64.EFI" ]] || die "the ISO has no \\EFI\\BOOT\\BOOTx64.EFI to start from a partition"
ls "${OUT_DIR}"/mnt/boot/*.uuid >/dev/null 2>&1 || die "the ISO has no /boot/*.uuid for archiso to find the partition by"
# Test only: also send the kernel's console to the serial port, so this script can
# watch for the login prompt (the copied files stay as they are otherwise)
sed -i 's#^\(\s*linux\s.*\)$#\1 console=tty0 console=ttyS0,115200#' "${OUT_DIR}/mnt/boot/grub/grub.cfg"
grep -q 'console=ttyS0' "${OUT_DIR}/mnt/boot/grub/grub.cfg" || die "no linux line in boot/grub/grub.cfg"
largest="$(find "${OUT_DIR}/mnt" -type f -printf '%s %P\n' | sort -n | tail -n1)"
printf 'Largest file on the partition: %s MiB %s (FAT32 limit 4096 MiB)\n' "$(( ${largest%% *} / 1048576 ))" "${largest#* }"
umount "${OUT_DIR}/mnt"
losetup -d "${loop}"
trap - EXIT

accel=(-accel tcg)
[[ -w /dev/kvm ]] && accel=(-accel kvm -cpu host)
printf 'Booting %s from a data partition (no CD, no USB)...\n' "$(basename "${ISO}")"
qemu-system-x86_64 "${accel[@]}" -m 4096 -smp 2 \
  -drive "if=pflash,format=raw,readonly=on,file=${ovmf_code}" \
  -drive "if=pflash,format=raw,file=${OUT_DIR}/OVMF_VARS.fd" \
  -drive "file=${disk},format=raw,if=virtio" \
  -display none -serial "file:${OUT_DIR}/serial.log" -no-reboot &
qemu=$!

deadline=$((SECONDS + TIMEOUT))
result=""
while ((SECONDS < deadline)); do
  if ! kill -0 "${qemu}" 2>/dev/null; then
    result="QEMU stopped"
    break
  fi
  if grep -aq 'login:' "${OUT_DIR}/serial.log" 2>/dev/null; then
    result="pass"
    break
  fi
  if grep -aqE "device did not show up|Falling back to interactive prompt|emergency shell" "${OUT_DIR}/serial.log" 2>/dev/null; then
    result="archiso did not find its files on the partition"
    break
  fi
  sleep 5
done
kill "${qemu}" 2>/dev/null || true
wait "${qemu}" 2>/dev/null || true

grep -a -m3 'archisosearch\|Mounting\|ROBINOS' "${OUT_DIR}/serial.log" || true
if [[ "${result}" == pass ]]; then
  printf 'Partition boot: passed (login prompt after %s s)\n' "${SECONDS}"
  exit 0
fi
tail -n 30 "${OUT_DIR}/serial.log" 2>/dev/null || true
die "${result:-no login prompt after ${TIMEOUT} s}"
