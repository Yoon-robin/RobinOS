#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="false"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="true"
fi

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf 'Would run: %s\n' "$*"
    return
  fi
  "$@"
}

package_file() {
  local file="$1"
  [[ -f "${file}" ]] || die "package file not found: ${file}"
  grep -Ev '^\s*(#|$)' "${file}"
}

if [[ "${DRY_RUN}" != "true" ]]; then
  [[ "${EUID}" -eq 0 ]] || die "run as root"
  command -v pacman >/dev/null 2>&1 || die "pacman is required"
fi

mapfile -t core_packages < <(package_file "${ROOT_DIR}/packages/core.txt")

run pacman -Syu --needed "${core_packages[@]}"
run install -Dm755 "${ROOT_DIR}/bin/robinctl" /usr/local/bin/robinctl
run install -Dm644 "${ROOT_DIR}/config/robinos.toml" /etc/robinos/config.toml

if [[ -x "${ROOT_DIR}/scripts/install-branding.sh" ]]; then
  if [[ "${DRY_RUN}" == "true" ]]; then
    "${ROOT_DIR}/scripts/install-branding.sh" --dry-run
  else
    run "${ROOT_DIR}/scripts/install-branding.sh"
  fi
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Would enable locale ko_KR.UTF-8 in /etc/locale.gen\n'
else
  if grep -q '^#ko_KR.UTF-8 UTF-8' /etc/locale.gen; then
    sed -i 's/^#ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
  fi
  locale-gen
fi

run localectl set-locale LANG=ko_KR.UTF-8

for service in NetworkManager sddm docker; do
  if [[ "${DRY_RUN}" == "true" ]] || systemctl list-unit-files "${service}.service" >/dev/null 2>&1; then
    run systemctl enable "${service}.service"
  fi
done

printf 'RobinOS post-install complete.\n'
