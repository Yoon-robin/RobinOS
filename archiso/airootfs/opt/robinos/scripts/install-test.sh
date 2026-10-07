#!/usr/bin/env bash
set -euo pipefail

# Installs RobinOS from the live ISO onto a blank disk in QEMU (UEFI) and checks
# the installed system, the way docs/install.md describes it:
#
#   1. Live ISO: archinstall with the default Btrfs layout and GRUB
#   2. Installed system: scripts/post-install.sh --yes (desktop, branding, snapshots)
#   3. Reboot: GRUB menu with the snapshot submenu, snap-pac snapshots around a
#      pacman install, robinctl snapshot rollback, then the desktop login
#
# The repository checkout is shared with the VM as a read-only FAT disk, so the
# installed system gets this checkout's bin/, scripts/, desktop/, ... (not the
# copy inside the ISO). scripts/install-test.py drives everything over the
# serial console and takes screenshots over QMP.
#
# Usage: scripts/install-test.sh [--installer=archinstall|robinos] [path/to/robinos.iso]
#   archinstall  docs/install.md option A: archinstall, then post-install.sh (default)
#   robinos      installer/robin-install, erasing the disk (EFI on /efi)
# Needs: qemu-system-x86_64, qemu-img, OVMF, bsdtar, python3.
# Results: build/install-test/ (screenshots, serial logs)

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/install-test"
export ROBINOS_INSTALLER="archinstall"
if [[ "${1:-}" == --installer=* ]]; then
  ROBINOS_INSTALLER="${1#--installer=}"
  shift
fi
[[ "${ROBINOS_INSTALLER}" == "archinstall" || "${ROBINOS_INSTALLER}" == "robinos" ]] ||
  { printf 'error: unknown installer: %s\n' "${ROBINOS_INSTALLER}" >&2; exit 1; }
ISO="${1:-$(ls -t "${ROOT_DIR}"/out/robinos-*.iso 2>/dev/null | head -n1)}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ -n "${ISO}" && -f "${ISO}" ]] || die "ISO not found: '${ISO}' (build one with scripts/build-iso.sh)"
for cmd in qemu-system-x86_64 qemu-img bsdtar python3; do
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
[[ -n "${ovmf_code}" ]] || die "OVMF firmware not found (apt install ovmf / pacman -S edk2-ovmf)"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"
printf 'ISO: %s\nOVMF: %s\nInstaller: %s\n' "${ISO}" "${ovmf_code}" "${ROBINOS_INSTALLER}"

# Live kernel and initramfs for direct boot, as in scripts/boot-test.sh
kernel_path="$(bsdtar -tf "${ISO}" | sed 's#^\./##' | grep -E '^[^/]+/boot/x86_64/vmlinuz-linux$' | head -n1)"
[[ -n "${kernel_path}" ]] || die "no archiso kernel found in the ISO"
base_dir="${kernel_path%%/*}"
bsdtar -xf "${ISO}" -C "${OUT_DIR}" "${base_dir}/boot/x86_64/vmlinuz-linux" "${base_dir}/boot/x86_64/initramfs-linux.img"
label="$(dd if="${ISO}" bs=1 skip=32808 count=32 2>/dev/null | tr -d ' \0')"
[[ -n "${label}" ]] || die "could not read the ISO label"

# The files the installed system needs from this checkout
share="${OUT_DIR}/share/robinos"
mkdir -p "${share}"
for dir in assets bin config desktop docs installer labs packages scripts themes; do
  cp -a "${ROOT_DIR}/${dir}" "${share}/"
done

qemu-img create -q -f qcow2 "${OUT_DIR}/disk.qcow2" 40G
cp "${ovmf_vars}" "${OUT_DIR}/OVMF_VARS.fd"

accel=(-accel tcg)
speed=4
if [[ -w /dev/kvm ]]; then
  accel=(-accel kvm -cpu host)
  speed=1
fi
printf 'Acceleration: %s\n' "${accel[1]}"

# run_qemu <phase> [extra qemu args...]: one QEMU process per phase, driven by
# install-test.py over the serial console until the VM powers off.
run_qemu() {
  local phase="$1"
  shift
  rm -f "${OUT_DIR}/serial.sock" "${OUT_DIR}/qmp.sock"
  qemu-system-x86_64 \
    -machine q35 "${accel[@]}" -m 6144 -smp 4 \
    -drive "if=pflash,format=raw,readonly=on,file=${ovmf_code}" \
    -drive "if=pflash,format=raw,file=${OUT_DIR}/OVMF_VARS.fd" \
    -drive "file=${OUT_DIR}/disk.qcow2,format=qcow2,if=virtio" \
    -drive "file=fat:${OUT_DIR}/share,format=raw,if=virtio,readonly=on" \
    -vga none -device VGA,edid=on,xres=1600,yres=900 \
    -display none \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -chardev "socket,id=ser0,path=${OUT_DIR}/serial.sock,server=on,wait=off,logfile=${OUT_DIR}/serial-${phase}.log" \
    -serial chardev:ser0 \
    -qmp "unix:${OUT_DIR}/qmp.sock,server,nowait" \
    "$@" &
  local qemu_pid=$!

  local status=0
  python3 "${ROOT_DIR}/scripts/install-test.py" "${phase}" "${OUT_DIR}" "${speed}" || status=$?

  # The driver powers the VM off; don't leave QEMU behind if it failed first
  if kill -0 "${qemu_pid}" 2>/dev/null; then
    sleep 5
    kill "${qemu_pid}" 2>/dev/null || true
  fi
  wait "${qemu_pid}" 2>/dev/null || true
  return "${status}"
}

printf '\n== Phase 1: install from the live ISO\n'
run_qemu live \
  -kernel "${OUT_DIR}/${base_dir}/boot/x86_64/vmlinuz-linux" \
  -initrd "${OUT_DIR}/${base_dir}/boot/x86_64/initramfs-linux.img" \
  -append "archisobasedir=${base_dir} archisolabel=${label} console=tty0 console=ttyS0,115200" \
  -cdrom "${ISO}"

printf '\n== Phase 2: post-install, snapshots and rollback on the installed system\n'
run_qemu installed

printf '\nScreenshots:\n'
ls -1 "${OUT_DIR}"/*.png 2>/dev/null || printf '  (none)\n'
