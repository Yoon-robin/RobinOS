#!/usr/bin/env bash
set -uo pipefail

# Boots a RobinOS ISO in QEMU without a window, drives the desktop over QMP
# (scripts/boot-test-qmp.py) and saves screenshots plus the serial console log
# to build/boot-test/. Used by .github/workflows/boot-test.yml; works on any
# Linux host with QEMU.
#
# The kernel and initramfs are taken out of the ISO and booted directly, which
# skips the boot menu and sends the whole boot to the serial log. The display is
# a plain VGA device (no 3D), like Hyper-V, so the session starts in software
# rendering.
#
# Usage:
#   scripts/boot-test.sh [path/to/robinos.iso]
#
# Needs: qemu-system-x86_64, bsdtar (libarchive-tools), python3.
# Uses KVM when /dev/kvm is writable, otherwise TCG (much slower).

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/boot-test"
ISO="${1:-$(ls -t "${ROOT_DIR}"/out/robinos-*.iso 2>/dev/null | head -n1)}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ -n "${ISO}" && -f "${ISO}" ]] || die "ISO not found: '${ISO}' (build one with scripts/build-iso.sh)"
for cmd in qemu-system-x86_64 bsdtar python3; do
  command -v "${cmd}" >/dev/null 2>&1 || die "${cmd} is required"
done

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"
printf 'ISO: %s (%s)\n' "${ISO}" "$(du -h "${ISO}" | cut -f1)"

# archiso keeps the kernel in /<install_dir>/boot/x86_64/
kernel_path="$(bsdtar -tf "${ISO}" | sed 's#^\./##' | grep -E '^[^/]+/boot/x86_64/vmlinuz-linux$' | head -n1)"
[[ -n "${kernel_path}" ]] || die "no archiso kernel found in the ISO"
base_dir="${kernel_path%%/*}"
bsdtar -xf "${ISO}" -C "${OUT_DIR}" "${base_dir}/boot/x86_64/vmlinuz-linux" "${base_dir}/boot/x86_64/initramfs-linux.img"

# ISO 9660 volume label: 32 bytes at offset 32808 (sector 16, byte 40)
label="$(dd if="${ISO}" bs=1 skip=32808 count=32 2>/dev/null | tr -d ' \0')"
[[ -n "${label}" ]] || die "could not read the ISO label"
printf 'archisobasedir=%s archisolabel=%s\n' "${base_dir}" "${label}"

accel=(-accel tcg)
speed=4
if [[ -w /dev/kvm ]]; then
  accel=(-accel kvm -cpu host)
  speed=1
fi
printf 'Acceleration: %s\n' "${accel[1]}"

# A blank disk, so the installer's disk step has something to show
qemu-img create -q -f qcow2 "${OUT_DIR}/disk.qcow2" 64G

qemu-system-x86_64 \
  -machine q35 "${accel[@]}" -m 6144 -smp 4 \
  -kernel "${OUT_DIR}/${base_dir}/boot/x86_64/vmlinuz-linux" \
  -initrd "${OUT_DIR}/${base_dir}/boot/x86_64/initramfs-linux.img" \
  -append "archisobasedir=${base_dir} archisolabel=${label} console=tty0 console=ttyS0,115200 systemd.journald.forward_to_console=1 robinos.debug" \
  -cdrom "${ISO}" \
  -drive "file=${OUT_DIR}/disk.qcow2,format=qcow2,if=virtio" \
  -vga none -device VGA,edid=on,xres=1600,yres=900 \
  -display none \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -qmp "unix:${OUT_DIR}/qmp.sock,server,nowait" \
  -serial "file:${OUT_DIR}/serial.log" &
qemu_pid=$!

python3 "${ROOT_DIR}/scripts/boot-test-qmp.py" "${OUT_DIR}/qmp.sock" "${OUT_DIR}" "${speed}"
kill "${qemu_pid}" 2>/dev/null
wait "${qemu_pid}" 2>/dev/null

# Older QEMU writes PPM screenshots; convert them when ImageMagick is around
for ppm in "${OUT_DIR}"/*.ppm; do
  [[ -f "${ppm}" ]] || continue
  if command -v convert >/dev/null 2>&1; then
    convert "${ppm}" "${ppm%.ppm}.png" && rm -f "${ppm}"
  fi
done

summary() {
  printf '## Boot test\n\n'
  printf -- '- ISO: `%s`\n' "$(basename "${ISO}")"
  printf -- '- Acceleration: `%s`\n\n' "${accel[1]}"
  printf 'Key lines from the serial log:\n\n```text\n'
  grep -a -E 'robinos-session|Reached target .*Graphical|Started .*(SDDM|Simple Desktop)|Failed to start|hyprland.*(ERR|error|CRIT)' \
    "${OUT_DIR}/serial.log" | sed 's/\x1b\[[0-9;]*m//g' | tail -n 40
  printf '```\n'
}

summary
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  summary >>"${GITHUB_STEP_SUMMARY}"
fi

printf '\nScreenshots:\n'
ls -1 "${OUT_DIR}"/*.png 2>/dev/null || printf '  (none)\n'
