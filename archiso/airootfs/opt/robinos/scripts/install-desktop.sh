#!/usr/bin/env bash
set -euo pipefail

# Installs the RobinOS desktop files listed in desktop/install-map.txt.
#
# Usage:
#   sudo scripts/install-desktop.sh                 # into the running system
#   scripts/install-desktop.sh --root archiso/airootfs
#   scripts/install-desktop.sh --dry-run

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MAP_FILE="${ROOT_DIR}/desktop/install-map.txt"
TARGET_ROOT="/"
DRY_RUN="false"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      TARGET_ROOT="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      sed -n '4,10p' "$0"
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf 'Would run: %s\n' "$*"
    return
  fi
  "$@"
}

[[ -f "${MAP_FILE}" ]] || {
  printf 'error: missing %s\n' "${MAP_FILE}" >&2
  exit 1
}

if [[ "${TARGET_ROOT}" == "/" && "${DRY_RUN}" != "true" && "${EUID}" -ne 0 ]]; then
  printf 'error: run as root to install into /\n' >&2
  exit 1
fi

while read -r src dest mode; do
  [[ -z "${src}" || "${src}" == \#* ]] && continue

  target="${TARGET_ROOT%/}${dest}"

  if [[ "${mode}" == "dir" ]]; then
    run rm -rf "${target}"
    run mkdir -p "${target}"
    run cp -a "${ROOT_DIR}/${src}." "${target}"
  else
    run install -Dm"${mode}" "${ROOT_DIR}/${src}" "${target}"
  fi
done <"${MAP_FILE}"

printf 'Installed RobinOS desktop files into %s\n' "${TARGET_ROOT}"
