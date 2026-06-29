#!/usr/bin/env bash
#
# 빌드한 ISO를 QEMU로 부팅 테스트한다 (UEFI). qemu + edk2-ovmf 필요.
#   bash scripts/test-qemu.sh [경로/robinos.iso]
#
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO="${1:-$(ls -t "${REPO_ROOT}"/out/*.iso 2>/dev/null | head -1 || true)}"
[[ -n "${ISO}" && -f "${ISO}" ]] || { echo "ISO를 찾을 수 없다. 먼저 빌드하거나 경로를 넘겨라."; exit 1; }

OVMF="/usr/share/edk2/x64/OVMF_CODE.4m.fd"
[[ -f "$OVMF" ]] || OVMF="/usr/share/OVMF/OVMF_CODE.fd"

echo "부팅: ${ISO}"
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -cpu host \
    -vga virtio -display gtk,gl=on \
    -drive if=pflash,format=raw,readonly=on,file="${OVMF}" \
    -cdrom "${ISO}" \
    -boot d
