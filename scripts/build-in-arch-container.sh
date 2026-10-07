#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

command -v docker >/dev/null 2>&1 || {
  printf 'error: docker is required for this container build path\n' >&2
  exit 1
}

cat <<'EOF'
RobinOS container build path

This path requires a Linux host with Docker, loop devices, and enough privileges
for archiso. It usually does not work inside ordinary Windows containers.
EOF

docker run --rm -it \
  --privileged \
  -v "${ROOT_DIR}:/repo" \
  -w /repo \
  archlinux:latest \
  bash -lc '
    pacman -Sy --noconfirm archiso git qemu-full edk2-ovmf
    scripts/doctor-build.sh
    scripts/build-iso.sh
  '

