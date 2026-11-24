#!/usr/bin/env bash
# Screenshots of GTK apps with RobinOS's GTK colours (desktop/gtk, made by
# scripts/build-gtk-theme.py), in a headless sway, without a VM: Files and Text
# Editor (libadwaita), Calculator, and Firefox (GTK 3), each dark and light.
#
#   bash scripts/gtk-shot.sh OUT_DIR [--stock]
#
# --stock leaves the RobinOS colours out (GNOME's look, to compare). Run as root in
# WSL: it copies the themes to /usr/share/themes and /usr/share/robinos/gtk the way
# the ISO installs them, then runs the apps as the user "gtkshot" (made if missing;
# Files opens no window for root). Needs sway, grim, nautilus, gnome-text-editor,
# gnome-calculator, firefox, adw-gtk-theme, papirus-icon-theme.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME=gtkshot

# ---- As root: install the themes, then come back as the user ----
if [[ "${1:-}" != --as-user ]]; then
  out="${1:?usage: gtk-shot.sh OUT_DIR [--stock]}"
  stock="${2:-}"
  [[ "$(id -u)" == 0 ]] || { printf 'gtk-shot: run as root (wsl.exe -d archlinux -u root ...)\n' >&2; exit 1; }
  for tool in sway grim swaymsg nautilus gnome-text-editor gnome-calculator firefox dbus-run-session; do
    command -v "${tool}" >/dev/null 2>&1 || {
      printf 'gtk-shot: %s is missing (pacman -S sway grim nautilus gnome-text-editor gnome-calculator firefox adw-gtk-theme papirus-icon-theme)\n' "${tool}" >&2
      exit 1
    }
  done
  # Installed the way desktop/install-map.txt puts them
  cp -r "${ROOT_DIR}/desktop/gtk/themes/." /usr/share/themes/
  mkdir -p /usr/share/robinos/gtk
  cp "${ROOT_DIR}/desktop/gtk/libadwaita.css" /usr/share/robinos/gtk/libadwaita.css
  mkdir -p /usr/share/gtksourceview-5/styles
  cp "${ROOT_DIR}"/desktop/gtk/gtksourceview/*.xml /usr/share/gtksourceview-5/styles/
  # Firefox's admin config registers the kit's sheet; --stock takes it out again
  if [[ "${stock}" == --stock ]]; then
    rm -f /usr/lib/firefox/defaults/pref/autoconfig.js /usr/lib/firefox/robinos.cfg
  else
    cp "${ROOT_DIR}/desktop/firefox/autoconfig.js" /usr/lib/firefox/defaults/pref/autoconfig.js
    cp "${ROOT_DIR}/desktop/firefox/robinos.cfg" /usr/lib/firefox/robinos.cfg
    mkdir -p /usr/share/robinos/firefox
    cp "${ROOT_DIR}/desktop/gtk/firefox.css" /usr/share/robinos/firefox/robinos.css
  fi
  id -u "${USER_NAME}" >/dev/null 2>&1 || useradd -m "${USER_NAME}"
  shots="$(mktemp -d)"
  chown "${USER_NAME}" "${shots}"
  cp "$0" "${shots}/gtk-shot.sh"
  status=0
  runuser -u "${USER_NAME}" -- bash "${shots}/gtk-shot.sh" --as-user "${shots}" "${stock}" || status=$?
  rm -f "${shots}/gtk-shot.sh"
  mkdir -p "${out}"
  cp "${shots}"/*.png "${out}/" 2>/dev/null || true
  [[ -n "${GTK_SHOT_LOGS:-}" ]] && cp "${shots}"/*.log "${GTK_SHOT_LOGS}/" 2>/dev/null
  for png in "${shots}"/*.png; do
    [[ -e "${png}" ]] && printf 'gtk-shot: %s\n' "${out}/${png##*/}"
  done
  rm -rf "${shots}"
  exit "${status}"
fi

# ---- As the user ----
out="$2"
stock="${3:-}"
work="$(mktemp -d)"
sway_pid=""
cleanup() {
  [[ -n "${sway_pid}" ]] && kill "${sway_pid}" 2>/dev/null
  wait 2>/dev/null || true
  cp "${work}"/*.log "${out}/" 2>/dev/null || true
  rm -rf "${work}"
}
trap cleanup EXIT

export XDG_RUNTIME_DIR="${work}/run" XDG_CONFIG_HOME="${work}/config" XDG_CACHE_HOME="${work}/cache" HOME="${work}/home"
mkdir -m 700 "${XDG_RUNTIME_DIR}"
mkdir -p "${XDG_CONFIG_HOME}" "${HOME}/Documents" "${HOME}/Pictures" "${HOME}/Downloads" "${HOME}/Music"
unset WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE
# No dconf here: GTK reads settings.ini, and gsettings a key file with what
# desktop/dconf/00-robinos sets. GSK_RENDERER=cairo: sway's pixman renderer gives
# GTK 4 no GL, and its windows would stay blank
export GSETTINGS_BACKEND=keyfile GTK_A11Y=none NO_AT_BRIDGE=1 MOZ_ENABLE_WAYLAND=1 GSK_RENDERER=cairo

printf 'output HEADLESS-1 resolution 1600x900\nxwayland disable\ndefault_border none\ngaps outer 60\n' >"${work}/sway.conf"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  sway -c "${work}/sway.conf" >"${work}/sway.log" 2>&1 </dev/null &
sway_pid=$!
socket=""
for _ in $(seq 50); do
  socket="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -n 1)"
  [[ -n "${socket}" ]] && break
  sleep 0.2
done
[[ -n "${socket}" ]] || { sed 's/^/  /' "${work}/sway.log" >&2; exit 1; }
export WAYLAND_DISPLAY="${socket}"
SWAYSOCK="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'sway-ipc.*.sock' | head -n 1)"
export SWAYSOCK

scheme_files() {
  local dark="$1" theme icons
  if [[ "${stock}" == --stock ]]; then
    theme="$([[ "${dark}" == 1 ]] && echo adw-gtk3-dark || echo adw-gtk3)"
  else
    theme="$([[ "${dark}" == 1 ]] && echo RobinOS-dark || echo RobinOS)"
  fi
  icons="$([[ "${dark}" == 1 ]] && echo Papirus-Dark || echo Papirus)"
  for v in 3.0 4.0; do
    mkdir -p "${XDG_CONFIG_HOME}/gtk-${v}"
    printf '[Settings]\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-font-name=Pretendard Variable 11\ngtk-application-prefer-dark-theme=%s\n' \
      "${theme}" "${icons}" "$([[ "${dark}" == 1 ]] && echo true || echo false)" >"${XDG_CONFIG_HOME}/gtk-${v}/settings.ini"
  done
  mkdir -p "${XDG_CONFIG_HOME}/glib-2.0/settings"
  # What Theme.qml writes for every user
  if [[ "${stock}" == --stock ]]; then
    rm -f "${XDG_CONFIG_HOME}/gtk-4.0/gtk.css" "${XDG_CONFIG_HOME}/glib-2.0/settings/keyfile"
  else
    printf '[org/gnome/TextEditor]\nstyle-scheme=%s\n' "'robinos'" >"${XDG_CONFIG_HOME}/glib-2.0/settings/keyfile"
    printf '/* robinos-managed */\n@import url("file:///usr/share/robinos/gtk/libadwaita.css");\n' >"${XDG_CONFIG_HOME}/gtk-4.0/gtk.css"
  fi
  export ADW_DEBUG_COLOR_SCHEME="$([[ "${dark}" == 1 ]] && echo prefer-dark || echo prefer-light)"
}

shoot() {
  local name="$1" wait="$2"
  shift 2
  dbus-run-session -- "$@" >"${work}/${name}.log" 2>&1 </dev/null &
  local pid=$!
  sleep "${wait}"
  grim "${out}/${name}.png"
  swaymsg -q '[app_id=".*"] kill' >/dev/null 2>&1 || true
  sleep 1
  kill "${pid}" 2>/dev/null || true
  wait "${pid}" 2>/dev/null || true
}

for dark in 1 0; do
  scheme_files "${dark}"
  tag="$([[ "${dark}" == 1 ]] && echo dark || echo light)"
  printf 'hello RobinOS\n안녕하세요\n' >"${HOME}/Documents/note.txt"
  shoot "files-${tag}" 7 nautilus --new-window "${HOME}"
  shoot "text-editor-${tag}" 6 gnome-text-editor --new-window "${HOME}/Documents/note.txt"
  shoot "calculator-${tag}" 5 gnome-calculator
  mkdir -p "${work}/ff-${tag}"
  # ui.systemUsesDarkTheme stands in for the colour-scheme portal this sway lacks
  printf 'user_pref("ui.systemUsesDarkTheme", %s);\n' "${dark}" >"${work}/ff-${tag}/user.js"
  shoot "firefox-${tag}" 14 firefox --new-instance --profile "${work}/ff-${tag}" about:home
done
