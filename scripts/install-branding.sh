#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="false"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="true"
fi

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '실행할 명령: %s\n' "$*"
    return
  fi
  "$@"
}

[[ "${DRY_RUN}" == "true" || "${EUID}" -eq 0 ]] || {
  printf '오류: 관리자 권한이 필요해요. sudo를 붙여 실행하세요\n' >&2
  exit 1
}

run install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-default.svg" /usr/share/wallpapers/RobinOS/robinos-default.svg
run install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/wallpapers/RobinOS/robinos-lock.svg
run install -Dm644 "${ROOT_DIR}/assets/brand/robinos-mark.svg" /usr/share/pixmaps/robinos-mark.svg
run install -Dm644 "${ROOT_DIR}/config/grub/10-robinos-theme.cfg" /etc/default/grub.d/10-robinos-theme.cfg

run mkdir -p /usr/share/sddm/themes/robinos
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'themes/sddm/robinos를 /usr/share/sddm/themes/robinos에 복사해요\n'
  printf '로고와 잠금 화면 배경을 SDDM 테마 폴더에 복사해요\n'
else
  cp -a "${ROOT_DIR}/themes/sddm/robinos/." /usr/share/sddm/themes/robinos/
  cp "${ROOT_DIR}/assets/brand/robinos-mark.svg" /usr/share/sddm/themes/robinos/logo.svg
  cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/sddm/themes/robinos/background.svg
  cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/sddm/themes/robinos/preview.svg
fi

run mkdir -p /usr/share/grub/themes/robinos
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'themes/grub/robinos를 /usr/share/grub/themes/robinos에 복사해요\n'
else
  cp -a "${ROOT_DIR}/themes/grub/robinos/." /usr/share/grub/themes/robinos/
fi

run mkdir -p /etc/sddm.conf.d
if [[ "${DRY_RUN}" == "true" ]]; then
  printf '/etc/sddm.conf.d/10-robinos-theme.conf를 써요\n'
else
  cat >/etc/sddm.conf.d/10-robinos-theme.conf <<'EOF'
[Theme]
Current=robinos
EOF
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'grub-mkconfig가 있으면 GRUB 설정을 다시 만들어요\n'
elif command -v grub-mkconfig >/dev/null 2>&1; then
  # grub.cfg is in /efi/grub when the EFI partition is mounted on /efi
  grub_dir=""
  for dir in /boot/grub /efi/grub /boot/efi/grub; do
    if [[ -f "${dir}/grub.cfg" ]]; then
      grub_dir="${dir}"
      break
    fi
  done
  if [[ -n "${grub_dir}" ]]; then
    grub-mkconfig -o "${grub_dir}/grub.cfg"
  else
    printf '알림: /boot/grub와 /efi/grub에 grub.cfg가 없어서 grub-mkconfig를 건너뛰었어요\n' >&2
  fi
fi

printf 'RobinOS 테마 설치가 끝났어요.\n'
