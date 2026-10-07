#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY="4096"
CPUS="2"
ISO_PATH=""
UEFI="false"
ENABLE_KVM="auto"
GL="false"

usage() {
  cat <<'EOF'
Usage:
  scripts/run-vm.sh [--iso path] [--memory mib] [--cpus n] [--uefi] [--no-kvm] [--gl]

Boots a RobinOS ISO in QEMU for smoke testing.

--gl uses a virtio GPU with OpenGL (virgl) so Hyprland runs with GPU
acceleration. Without it the desktop starts in software rendering.

Examples:
  scripts/run-vm.sh
  scripts/run-vm.sh --memory 8192 --cpus 4
  scripts/run-vm.sh --iso out/robinos-2026.06.18-x86_64.iso
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --iso)
      ISO_PATH="${2:-}"
      shift 2
      ;;
    --memory)
      MEMORY="${2:-}"
      shift 2
      ;;
    --cpus)
      CPUS="${2:-}"
      shift 2
      ;;
    --uefi)
      UEFI="true"
      shift
      ;;
    --no-kvm)
      ENABLE_KVM="false"
      shift
      ;;
    --gl)
      GL="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  printf 'error: qemu-system-x86_64 is required\n' >&2
  printf 'Install on Arch with: sudo pacman -S --needed qemu-full\n' >&2
  exit 1
}

if [[ -z "${ISO_PATH}" ]]; then
  ISO_PATH="$(find "${ROOT_DIR}/out" -maxdepth 1 -type f -name 'robinos-*.iso' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {print $2}')"
fi

[[ -n "${ISO_PATH}" ]] || {
  printf 'error: no ISO found in %s/out\n' "${ROOT_DIR}" >&2
  printf 'Build one first with: scripts/build-iso.sh\n' >&2
  exit 1
}

[[ -f "${ISO_PATH}" ]] || {
  printf 'error: ISO not found: %s\n' "${ISO_PATH}" >&2
  exit 1
}

qemu_args=(
  -name "RobinOS Smoke Test"
  -m "${MEMORY}"
  -smp "${CPUS}"
  -cdrom "${ISO_PATH}"
  -boot d
  -netdev user,id=net0
  -device virtio-net-pci,netdev=net0
)

if [[ "${GL}" == "true" ]]; then
  qemu_args+=(-device virtio-vga-gl -display gtk,gl=on)
else
  qemu_args+=(-display gtk)
fi

if [[ "${ENABLE_KVM}" == "auto" && -e /dev/kvm ]]; then
  qemu_args+=(-enable-kvm -cpu host)
fi

if [[ "${UEFI}" == "true" ]]; then
  if [[ -r /usr/share/edk2-ovmf/x64/OVMF_CODE.fd ]]; then
    qemu_args+=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd)
  elif [[ -r /usr/share/ovmf/x64/OVMF_CODE.fd ]]; then
    qemu_args+=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/ovmf/x64/OVMF_CODE.fd)
  else
    printf 'error: OVMF firmware not found; install edk2-ovmf or run without --uefi\n' >&2
    exit 1
  fi
fi

printf 'Booting ISO: %s\n' "${ISO_PATH}"
printf 'Memory: %s MiB, CPUs: %s\n' "${MEMORY}" "${CPUS}"
qemu-system-x86_64 "${qemu_args[@]}"

