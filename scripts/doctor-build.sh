#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED="false"

ok() {
  printf '  ok      %s\n' "$1"
}

warn() {
  printf '  warning %s\n' "$1" >&2
}

fail() {
  printf '  missing %s\n' "$1" >&2
  FAILED="true"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_path() {
  local path="$1"
  if [[ -e "${ROOT_DIR}/${path}" ]]; then
    ok "${path}"
  else
    fail "${path}"
  fi
}

printf 'RobinOS build doctor\n'
printf 'Repository: %s\n\n' "${ROOT_DIR}"

printf 'Host tools:\n'
if have_cmd pacman; then
  ok "pacman"
else
  fail "pacman (run on Arch Linux)"
fi

if have_cmd mkarchiso; then
  ok "mkarchiso"
else
  fail "mkarchiso (install archiso)"
fi

if have_cmd sudo; then
  ok "sudo"
else
  fail "sudo"
fi

if have_cmd sha256sum; then
  ok "sha256sum"
else
  fail "sha256sum"
fi

if have_cmd git; then
  ok "git"
else
  warn "git is not required for local builds, but useful for versioning"
fi

if have_cmd qemu-system-x86_64; then
  ok "qemu-system-x86_64"
else
  warn "qemu-system-x86_64 missing; install qemu-full for scripts/run-vm.sh"
fi

printf '\nArchiso profile:\n'
if [[ -d /usr/share/archiso/configs/releng ]]; then
  ok "/usr/share/archiso/configs/releng"
else
  fail "/usr/share/archiso/configs/releng"
fi

printf '\nProject files:\n'
for path in \
  archiso/profiledef.sh \
  archiso/packages.x86_64 \
  archiso/pacman.conf \
  archiso/airootfs/root/customize_airootfs.sh \
  bin/robinctl \
  installer/robin-install \
  scripts/prepare-archiso.sh \
  scripts/customize-iso-boot.sh \
  packages/core.txt \
  packages/security-baseline.txt \
  assets/brand/robinos-mark.svg \
  themes/sddm/robinos/Main.qml \
  themes/grub/robinos/theme.txt
do
  require_path "${path}"
done

printf '\nDisk space:\n'
if have_cmd df; then
  df -h "${ROOT_DIR}" | tail -n +2
else
  warn "df unavailable; skipped disk space check"
fi

printf '\nNetwork quick check:\n'
if have_cmd pacman; then
  if pacman -Sy --print-format '%n' --needed archiso >/dev/null 2>&1; then
    ok "pacman repository metadata reachable"
  else
    warn "pacman repository metadata check failed; run sudo pacman -Syu or check mirrors"
  fi
else
  warn "pacman unavailable; skipped network check"
fi

if [[ "${FAILED}" == "true" ]]; then
  printf '\nBuild doctor failed. Fix missing items before running scripts/build-iso.sh.\n' >&2
  exit 1
fi

printf '\nBuild doctor passed.\n'
