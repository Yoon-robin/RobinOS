#!/usr/bin/env bash
set -uo pipefail

# Loads the RobinOS shell (desktop/shell) for real, in a headless sway, and fails
# when Quickshell can't load it. qmllint (scripts/qmllint.sh) checks names and
# types, but some mistakes only show when the engine builds the objects: a
# `font.pixelSize: 13.5` ("Invalid property assignment: int expected") passed
# qmllint and every quick check, and the shell crashed five times at login in the
# boot test (2026-11-24). This catches that in seconds instead of a VM run.
#
# Usage: scripts/shell-load.sh [-s FILE.png]
#   -s FILE.png  also save a screenshot of the loaded shell (needs grim)
# Needs: sway (wlroots' headless backend gives the layer shell PanelWindow uses),
# quickshell. Without sway it says so and passes, so a PC without it still runs
# the other checks (wsl-build.ps1 setup installs it).

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
shot=""
if [[ "${1:-}" == "-s" ]]; then
  shot="${2:?usage: shell-load.sh [-s FILE.png]}"
fi

if ! command -v sway >/dev/null 2>&1 || ! command -v qs >/dev/null 2>&1; then
  printf 'shell-load: skipped (sway or quickshell is missing: pacman -S sway quickshell)\n'
  exit 0
fi

work="$(mktemp -d)"
sway_pid=""
qs_pid=""
cleanup() {
  [[ -n "${qs_pid}" ]] && kill "${qs_pid}" 2>/dev/null
  [[ -n "${sway_pid}" ]] && kill "${sway_pid}" 2>/dev/null
  wait 2>/dev/null
  rm -rf "${work}"
}
trap cleanup EXIT

export XDG_RUNTIME_DIR="${work}/run"
mkdir -m 700 "${XDG_RUNTIME_DIR}"
unset WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE
printf 'output HEADLESS-1 resolution 1600x900\n' >"${work}/sway.conf"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  sway -c "${work}/sway.conf" >"${work}/sway.log" 2>&1 </dev/null &
sway_pid=$!

socket=""
for _ in $(seq 50); do
  socket="$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' -printf '%f\n' 2>/dev/null | head -n 1)"
  [[ -n "${socket}" ]] && break
  sleep 0.2
done
if [[ -z "${socket}" ]]; then
  printf 'shell-load: FAILED, sway did not start:\n' >&2
  sed 's/^/  /' "${work}/sway.log" >&2
  exit 1
fi
export WAYLAND_DISPLAY="${socket}"

# A copy, so Quickshell's state files stay out of the checkout
cp -r "${ROOT_DIR}/desktop/shell" "${work}/shell"
QT_QPA_PLATFORM=wayland HOME="${work}/home" XDG_STATE_HOME="${work}/state" \
  qs -p "${work}/shell" >"${work}/qs.log" 2>&1 </dev/null &
qs_pid=$!

result=""
for _ in $(seq 150); do
  if grep -q 'Configuration Loaded' "${work}/qs.log"; then
    result="loaded"
    break
  fi
  if grep -q 'Failed to load configuration' "${work}/qs.log" || ! kill -0 "${qs_pid}" 2>/dev/null; then
    result="failed"
    break
  fi
  sleep 0.2
done

if [[ "${result}" != "loaded" ]]; then
  printf 'shell-load: FAILED, the shell did not load%s:\n' "$([[ -z "${result}" ]] && printf ' in 30 seconds')" >&2
  grep -E 'ERROR|caused by' "${work}/qs.log" | sed 's/\x1b\[[0-9;]*m//g; s/^/  /' >&2
  exit 1
fi

if [[ -n "${shot}" ]]; then
  sleep 2
  if command -v grim >/dev/null 2>&1; then
    grim "${shot}" && printf 'shell-load: screenshot %s\n' "${shot}"
  else
    printf 'shell-load: no screenshot (pacman -S grim)\n'
  fi
fi
printf 'shell-load: ok, the shell loads\n'
