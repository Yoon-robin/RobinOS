#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

command -v pacman >/dev/null 2>&1 || {
  printf 'error: pacman is required; run this on Arch Linux or the RobinOS live environment\n' >&2
  exit 1
}

package_file() {
  local file="$1"
  grep -Ev '^\s*(#|$)' "${file}"
}

check_file() {
  local file="$1"
  local failed="false"

  printf 'Checking packages in %s\n' "${file}"

  while IFS= read -r package; do
    if pacman -Si "${package}" >/dev/null 2>&1; then
      printf '  ok      %s\n' "${package}"
    else
      printf '  missing %s\n' "${package}" >&2
      failed="true"
    fi
  done < <(package_file "${file}")

  [[ "${failed}" == "false" ]]
}

check_file "${ROOT_DIR}/packages/core.txt"
check_file "${ROOT_DIR}/packages/security-baseline.txt"
check_file "${ROOT_DIR}/archiso/packages.x86_64"

printf 'Arch package check passed.\n'

