#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="${1:-${ROOT_DIR}/build/archiso-profile}"

[[ -d "${PROFILE_DIR}" ]] || {
  printf 'error: archiso profile not found: %s\n' "${PROFILE_DIR}" >&2
  exit 1
}

replace_text() {
  local file="$1"
  [[ -f "${file}" ]] || return 0

  # The help lines under the menu first, so they read as sentences
  sed -i \
    -e 's/Boot the Arch Linux install medium on BIOS with speakup screen reader\./Start RobinOS Live with the speakup screen reader./' \
    -e 's/Boot the Arch Linux install medium on BIOS\./Start RobinOS Live./' \
    -e 's/Boot the Arch Linux \(install\|live\) medium using/Start RobinOS Live using/' \
    -e 's/It allows you to install Arch Linux or perform system maintenance with speech feedback\./Try RobinOS or install it, with speech feedback./' \
    -e 's/It allows you to install Arch Linux or perform system maintenance\./Try RobinOS without installing, or install it on this PC./' \
    -e 's/Arch Linux install medium/RobinOS Live/g' \
    -e 's/Arch Linux archiso x86_64/RobinOS Live/g' \
    -e 's/Arch Linux/RobinOS/g' \
    "${file}"
}

customize_grub() {
  local grub_dir="${PROFILE_DIR}/grub"
  [[ -d "${grub_dir}" ]] || return 0

  mkdir -p "${grub_dir}/themes/robinos"
  cp -a "${ROOT_DIR}/themes/grub/robinos/." "${grub_dir}/themes/robinos/"

  while IFS= read -r -d '' cfg; do
    replace_text "${cfg}"

    if ! grep -q 'themes/robinos/theme.txt' "${cfg}"; then
      tmp_file="$(mktemp)"
      {
        printf 'set timeout=15\n'
        printf 'set default=0\n'
        printf 'set theme=/grub/themes/robinos/theme.txt\n'
        printf 'set color_normal=light-cyan/black\n'
        printf 'set color_highlight=white/cyan\n'
        cat "${cfg}"
      } >"${tmp_file}"
      cat "${tmp_file}" >"${cfg}"
      rm -f "${tmp_file}"
    fi
  done < <(find "${grub_dir}" -type f \( -name '*.cfg' -o -name '*.inc' \) -print0)
}

customize_syslinux() {
  local syslinux_dir="${PROFILE_DIR}/syslinux"
  [[ -d "${syslinux_dir}" ]] || return 0

  # RobinOS background and colors in place of archiso's Arch logo (themes/syslinux)
  cp "${ROOT_DIR}/themes/syslinux/splash.png" "${syslinux_dir}/splash.png"
  local head="${syslinux_dir}/archiso_head.cfg"
  if [[ -f "${head}" ]]; then
    sed -i '/^MENU COLOR/d' "${head}"
    sed -i "/^MENU BACKGROUND/r ${ROOT_DIR}/themes/syslinux/colors.cfg" "${head}"
  fi

  while IFS= read -r -d '' cfg; do
    replace_text "${cfg}"
    if grep -q '^MENU TITLE' "${cfg}"; then
      sed -i 's/^MENU TITLE.*/MENU TITLE RobinOS Live/' "${cfg}"
    else
      tmp_file="$(mktemp)"
      {
        printf 'MENU TITLE RobinOS Live\n'
        cat "${cfg}"
      } >"${tmp_file}"
      cat "${tmp_file}" >"${cfg}"
      rm -f "${tmp_file}"
    fi
  done < <(find "${syslinux_dir}" -type f -name '*.cfg' -print0)
}

customize_loader_entries() {
  # replace_text names each entry ("RobinOS Live (x86_64, UEFI)", "... with speech");
  # the memory test keeps its own title
  while IFS= read -r -d '' entry; do
    replace_text "${entry}"
  done < <(find "${PROFILE_DIR}" -path '*/loader/entries/*.conf' -type f -print0 2>/dev/null || true)
}

customize_grub
customize_syslinux
customize_loader_entries

printf 'Customized RobinOS ISO boot menus in %s\n' "${PROFILE_DIR}"
