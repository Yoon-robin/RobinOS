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
mapfile -t desktop_packages < <(package_file "${ROOT_DIR}/packages/desktop.txt")

run pacman -Syu --needed "${core_packages[@]}" "${desktop_packages[@]}"
run install -Dm755 "${ROOT_DIR}/bin/robinctl" /usr/local/bin/robinctl
run install -Dm644 "${ROOT_DIR}/config/robinos.toml" /etc/robinos/config.toml

# Desktop: Hyprland + Quickshell shell, themes, input method and font defaults
if [[ "${DRY_RUN}" == "true" ]]; then
  "${ROOT_DIR}/scripts/install-desktop.sh" --dry-run
  printf 'Would download Geist and Pretendard into /usr/share/fonts/robinos\n'
else
  run "${ROOT_DIR}/scripts/install-desktop.sh"
  run "${ROOT_DIR}/scripts/fetch-fonts.sh" /usr/share/fonts/robinos
fi
run dconf update
run fc-cache -f

# New users get the defaults from /etc/skel; copy them for the user running sudo too.
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  user_home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
  for config in qt6ct/qt6ct.conf fcitx5/profile fcitx5/config; do
    if [[ -n "${user_home}" && ! -e "${user_home}/.config/${config}" ]]; then
      run install -Dm644 -o "${SUDO_USER}" -g "$(id -gn "${SUDO_USER}")" \
        "/etc/skel/.config/${config}" "${user_home}/.config/${config}"
    fi
  done

  hints_line='[[ -r /usr/share/robinos/bash/robinos-hints.sh ]] && . /usr/share/robinos/bash/robinos-hints.sh'
  if [[ -n "${user_home}" ]] && ! grep -qF "robinos-hints.sh" "${user_home}/.bashrc" 2>/dev/null; then
    if [[ "${DRY_RUN}" == "true" ]]; then
      printf 'Would add Windows command hints to %s/.bashrc\n' "${user_home}"
    else
      printf '\n# Windows command hints (RobinOS)\n%s\n' "${hints_line}" >>"${user_home}/.bashrc"
      chown "${SUDO_USER}:$(id -gn "${SUDO_USER}")" "${user_home}/.bashrc"
    fi
  fi
fi

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

for service in NetworkManager sddm bluetooth docker; do
  if [[ "${DRY_RUN}" == "true" ]] || systemctl list-unit-files "${service}.service" >/dev/null 2>&1; then
    run systemctl enable "${service}.service"
  fi
done

run systemctl set-default graphical.target

printf 'RobinOS post-install complete.\n'
