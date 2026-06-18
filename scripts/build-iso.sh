#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/build/work"
OUT_DIR="${ROOT_DIR}/out"
LOG_DIR="${ROOT_DIR}/build/logs"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/mkarchiso-${STAMP}.log"
SKIP_PACKAGE_CHECK="false"
SKIP_DOCTOR="false"

for arg in "$@"; do
  case "${arg}" in
    --skip-doctor)
      SKIP_DOCTOR="true"
      ;;
    --skip-package-check)
      SKIP_PACKAGE_CHECK="true"
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  scripts/build-iso.sh [--skip-doctor] [--skip-package-check]

Builds the RobinOS ISO on Arch Linux.

Steps:
  1. Checks the build environment
  2. Optionally validates package names with pacman -Si
  3. Prepares build/archiso-profile from Arch releng
  4. Runs mkarchiso
  5. Writes SHA256SUMS for generated ISO files
EOF
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "${arg}" >&2
      exit 1
      ;;
  esac
done

command -v pacman >/dev/null 2>&1 || {
  printf 'error: pacman is required; run this on Arch Linux\n' >&2
  exit 1
}

command -v mkarchiso >/dev/null 2>&1 || {
  printf 'error: mkarchiso is required; install it with: sudo pacman -S --needed archiso\n' >&2
  exit 1
}

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

if [[ "${SKIP_DOCTOR}" != "true" ]]; then
  "${ROOT_DIR}/scripts/doctor-build.sh"
fi

if [[ "${SKIP_PACKAGE_CHECK}" != "true" ]]; then
  "${ROOT_DIR}/scripts/check-arch-packages.sh"
fi

"${ROOT_DIR}/scripts/prepare-archiso.sh"

printf 'Building RobinOS ISO...\n'
sudo mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${ROOT_DIR}/build/archiso-profile" 2>&1 | tee "${LOG_FILE}"

mapfile -t iso_files < <(find "${OUT_DIR}" -maxdepth 1 -type f -name 'robinos-*.iso' -print | sort)

if [[ "${#iso_files[@]}" -eq 0 ]]; then
  printf 'error: no RobinOS ISO found in %s\n' "${OUT_DIR}" >&2
  exit 1
fi

(
  cd "${OUT_DIR}"
  sha256sum ./*.iso > SHA256SUMS
)

printf '\nBuild complete.\n'
printf 'Log: %s\n' "${LOG_FILE}"
printf 'Output:\n'
for iso in "${iso_files[@]}"; do
  printf '  %s\n' "${iso}"
done
printf 'Checksums: %s\n' "${OUT_DIR}/SHA256SUMS"
