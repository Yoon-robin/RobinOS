#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="false"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="true"
fi

run() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf 'Would run: %s\n' "$*"
    return
  fi
  "$@"
}

[[ "${DRY_RUN}" == "true" || "${EUID}" -eq 0 ]] || {
  printf 'error: run as root\n' >&2
  exit 1
}

run install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-default.svg" /usr/share/wallpapers/RobinOS/robinos-default.svg
run install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/wallpapers/RobinOS/robinos-lock.svg
run install -Dm644 "${ROOT_DIR}/assets/brand/robinos-mark.svg" /usr/share/pixmaps/robinos-mark.svg
run install -Dm644 "${ROOT_DIR}/config/grub/10-robinos-theme.cfg" /etc/default/grub.d/10-robinos-theme.cfg

run mkdir -p /usr/share/sddm/themes/robinos
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Would copy themes/sddm/robinos to /usr/share/sddm/themes/robinos\n'
  printf 'Would copy brand mark and lock wallpaper into the SDDM theme directory\n'
else
  cp -a "${ROOT_DIR}/themes/sddm/robinos/." /usr/share/sddm/themes/robinos/
  cp "${ROOT_DIR}/assets/brand/robinos-mark.svg" /usr/share/sddm/themes/robinos/logo.svg
  cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/sddm/themes/robinos/background.svg
  cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" /usr/share/sddm/themes/robinos/preview.svg
fi

run mkdir -p /usr/share/grub/themes/robinos
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Would copy themes/grub/robinos to /usr/share/grub/themes/robinos\n'
else
  cp -a "${ROOT_DIR}/themes/grub/robinos/." /usr/share/grub/themes/robinos/
fi

run mkdir -p /etc/sddm.conf.d
if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Would write /etc/sddm.conf.d/10-robinos-theme.conf\n'
else
  cat >/etc/sddm.conf.d/10-robinos-theme.conf <<'EOF'
[Theme]
Current=robinos
EOF
fi

if [[ "${DRY_RUN}" == "true" ]]; then
  printf 'Would regenerate GRUB config if grub-mkconfig is available\n'
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
    printf 'warning: no grub.cfg in /boot/grub or /efi/grub; skipped grub-mkconfig\n' >&2
  fi
fi

printf 'RobinOS branding install complete.\n'
