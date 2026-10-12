#!/usr/bin/env bash
# Checks one boot test scene inside the guest and logs the verdict to the journal,
# which reaches the serial log (scripts/boot-test-qmp.py waits for it there):
#
#   robinos-e2e: scenario=<name> status=PASS|FAIL <detail>
#
# The boot test types `bash /opt/robinos/scripts/e2e-check.sh <name>` into the
# terminal right after the scene, so a scene is judged by the state it left behind,
# not by a screenshot that also "passes" when the screen is wrong (T-155).
#
#   terminal        the focused window is Ptyxis
#   count-save      remember how many Ptyxis windows there are
#   one-more        exactly one Ptyxis window more than at count-save
#   maximized       the focused window is maximized between the bar and the dock
#   restored        the focused window is not maximized any more
#   mission-1       learning mission 1 counts as solved
#   light           light mode saved by the shell and given to GTK apps
#   dark            dark mode, the same way
#   recorded        a screen recording (Win+Alt+R twice) left a playable video
#   shell-restarted a new shell (qs) runs and answers over IPC

set -uo pipefail

name="${1:-}"
STATE="${XDG_RUNTIME_DIR:-/tmp}/robinos-e2e"
SHELL_IPC=(qs ipc -p /usr/share/robinos/shell)

verdict() {
  local status="$1"
  shift
  logger -t robinos-e2e "scenario=${name} status=${status} $*"
  printf 'scenario=%s status=%s %s\n' "${name}" "${status}" "$*"
}

check() {
  # check DETAIL COMMAND...: PASS when the command succeeds
  local detail="$1"
  shift
  if "$@"; then
    verdict PASS "${detail}"
  else
    verdict FAIL "${detail}"
  fi
}

ptyxis_count() {
  hyprctl clients -j | python3 -c 'import json, sys
print(sum(1 for c in json.load(sys.stdin) if c.get("class") == "org.gnome.Ptyxis"))'
}

# Prints "fullscreen y height monitor_height" for the focused window
active_geometry() {
  local window monitors
  window="$(hyprctl activewindow -j)"
  monitors="$(hyprctl monitors -j)"
  python3 -c 'import json, sys
w = json.loads(sys.argv[1])
m = next(m for m in json.loads(sys.argv[2]) if m["id"] == w["monitor"])
height = round(m["height"] / m["scale"])
print(w["fullscreen"], w["at"][1] - m["y"], w["size"][1], height)' "${window}" "${monitors}"
}

case "${name}" in
  terminal)
    check "$(hyprctl activewindow -j | grep -o '"class": "[^"]*"')" \
      bash -c 'hyprctl activewindow -j | grep -q "\"class\": \"org.gnome.Ptyxis\""'
    ;;
  count-save)
    mkdir -p "${STATE}"
    ptyxis_count >"${STATE}/ptyxis"
    verdict PASS "ptyxis=$(cat "${STATE}/ptyxis")"
    ;;
  one-more)
    before="$(cat "${STATE}/ptyxis" 2>/dev/null || printf 'none')"
    now="$(ptyxis_count)"
    check "before=${before} now=${now}" test "${now}" = "$((before + 1))"
    ;;
  maximized)
    read -r fullscreen y height screen < <(active_geometry)
    # Maximized (fullscreen state 1), below the bar and above the dock: not the
    # whole screen, and most of it
    check "fullscreen=${fullscreen} y=${y} height=${height} screen=${screen}" \
      bash -c "[ ${fullscreen} = 1 ] && [ ${y} -gt 0 ] && [ $((y + height)) -lt ${screen} ] && [ $((height * 10)) -gt $((screen * 7)) ]"
    ;;
  restored)
    read -r fullscreen y height screen < <(active_geometry)
    check "fullscreen=${fullscreen} height=${height} screen=${screen}" test "${fullscreen}" = 0
    ;;
  mission-1)
    check "robinctl learn check 1" bash -c 'robinctl learn check 1 >/dev/null 2>&1'
    ;;
  light | dark)
    want_saved=false want_scheme=default
    if [[ "${name}" == dark ]]; then
      want_saved=true want_scheme=prefer-dark
    fi
    saved="$(find "${HOME}/.local/state/quickshell" -name appearance.json -exec grep -ho '"dark": *[a-z]*' {} + 2>/dev/null | head -n1)"
    scheme="$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")"
    check "saved=${saved:-none} gtk=${scheme}" \
      bash -c "[[ '${saved}' =~ ${want_saved}\$ ]] && [ '${scheme}' = '${want_scheme}' ]"
    ;;
  recorded)
    # Win+Alt+R twice: a video of a second or more in ~/Videos/Screencasts
    dir="$(xdg-user-dir VIDEOS 2>/dev/null || printf '%s/Videos' "${HOME}")/Screencasts"
    file="$(ls -t "${dir}"/*.mp4 2>/dev/null | head -n1)"
    seconds="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "${file:-/nonexistent}" 2>/dev/null | cut -d. -f1)"
    check "file=${file:-none} seconds=${seconds:-none} recording=$(pgrep -x wf-recorder >/dev/null && echo still || echo stopped)" \
      bash -c "[ -n '${file}' ] && [ '${seconds:-0}' -ge 1 ] && ! pgrep -x wf-recorder >/dev/null"
    ;;
  shell-restarted)
    pids="$(pgrep -x qs | tr '\n' ' ')"
    check "qs=${pids:-none}" bash -c "[ -n '${pids}' ] && timeout 10 ${SHELL_IPC[*]} show >/dev/null"
    ;;
  *)
    printf 'usage: %s <scene>  (see the top of this file)\n' "$0" >&2
    exit 2
    ;;
esac
