#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="false"
PACMAN_ARGS=(-Syu --needed)

# --dry-run: print what would happen. --yes: answer pacman's questions (unattended installs).
for arg in "$@"; do
  case "${arg}" in
    --dry-run) DRY_RUN="true" ;;
    --yes)
      PACMAN_ARGS+=(--noconfirm)
      export ROBINOS_ASSUME_YES="true"
      ;;
    *)
      printf '사용법: %s [--dry-run] [--yes]\n' "$0" >&2
      exit 2
      ;;
  esac
done

die() {
  printf '오류: %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '실행할 명령: %s\n' "$*"
    return
  fi
  "$@"
}

package_file() {
  local file="$1"
  [[ -f "${file}" ]] || die "패키지 목록이 없어요: ${file}"
  grep -Ev '^\s*(#|$)' "${file}"
}

if [[ "${DRY_RUN}" != "true" ]]; then
  [[ "${EUID}" -eq 0 ]] || die "관리자 권한이 필요해요. sudo를 붙여 실행하세요"
  command -v pacman >/dev/null 2>&1 || die "pacman이 필요해요"
fi

mapfile -t core_packages < <(package_file "${ROOT_DIR}/packages/core.txt")
mapfile -t desktop_packages < <(package_file "${ROOT_DIR}/packages/desktop.txt")

run pacman "${PACMAN_ARGS[@]}" "${core_packages[@]}" "${desktop_packages[@]}"
run install -Dm755 "${ROOT_DIR}/bin/robinctl" /usr/local/bin/robinctl
run install -Dm644 "${ROOT_DIR}/config/robinos.toml" /etc/robinos/config.toml

# Desktop: Hyprland + Quickshell shell, themes, input method and font defaults
if [[ "${DRY_RUN}" == "true" ]]; then
  "${ROOT_DIR}/scripts/install-desktop.sh" --dry-run
  printf 'Geist와 Pretendard 글꼴을 /usr/share/fonts/robinos에 내려받아요\n'
else
  run "${ROOT_DIR}/scripts/install-desktop.sh"
  # robin-install copies the fonts from the live ISO, so there is nothing to download
  if [[ -f "/usr/share/fonts/robinos/Geist[wght].ttf" && -f /usr/share/fonts/robinos/PretendardVariable.ttf ]]; then
    printf 'RobinOS 글꼴이 이미 있어요\n'
  else
    run "${ROOT_DIR}/scripts/fetch-fonts.sh" /usr/share/fonts/robinos
  fi
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
      printf '%s/.bashrc에 윈도우 명령 안내를 넣어요\n' "${user_home}"
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
  printf '/etc/locale.gen에서 ko_KR.UTF-8을 켜요\n'
else
  if grep -q '^#ko_KR.UTF-8 UTF-8' /etc/locale.gen; then
    sed -i 's/^#ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
  fi
  locale-gen
fi

# localectl needs a running systemd; robin-install runs this script in a chroot
if [[ "${DRY_RUN}" != "true" ]] && systemd-detect-virt --quiet --chroot; then
  printf 'LANG=ko_KR.UTF-8\n' >/etc/locale.conf
else
  run localectl set-locale LANG=ko_KR.UTF-8
fi

# Docker (web profile) starts on first use through its socket, not at boot
for unit in NetworkManager.service sddm.service bluetooth.service docker.socket; do
  if [[ "${DRY_RUN}" == "true" ]] || systemctl list-unit-files "${unit}" >/dev/null 2>&1; then
    run systemctl enable "${unit}"
  fi
done

run systemctl set-default graphical.target

# Snapshots around every pacman transaction and in the GRUB menu (Btrfs root only).
# Runs after install-branding.sh so its grub-mkconfig keeps the theme.
root_fs="$(findmnt -no FSTYPE / 2>/dev/null || true)"
if [[ "${root_fs}" == "btrfs" ]]; then
  if [[ "${DRY_RUN}" == "true" ]]; then
    "${ROOT_DIR}/bin/robinctl" snapshot setup --dry-run
  else
    run /usr/local/bin/robinctl snapshot setup
  fi
else
  printf '루트 파일 시스템이 Btrfs가 아니라서(%s) 스냅샷 설정은 건너뛰어요\n' "${root_fs:-알 수 없음}"
fi

printf 'RobinOS 설치 후 설정이 끝났어요.\n'
