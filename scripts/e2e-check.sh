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
#   windows-app     opening an .exe shows the "윈도우 프로그램" window
#   zoomed          Win+Plus twice: the screen is zoomed to 2x around the pointer
#   unzoomed        Win+Esc: back to 1x
#   shell-restarted a new shell (qs) runs and answers over IPC
#   input-changed   pointer and keyboard settings changed from the shell reached Hyprland and the saved file
#   input-default   the same after setting them back
#   report          robinctl report makes a file with all its sections and the drivers
#   power-changed   idle times set from the shell reached hypridle and the saved file
#   power-default   the same after setting the defaults
#   default-apps    settings' 기본 앱: Firefox is the default browser, a choice is saved, a wrong one refused

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
  zoomed | unzoomed)
    # Win+Plus twice zooms to 2x, Win+Esc back to 1x (T-161)
    factor="$(hyprctl getoption cursor:zoom_factor 2>/dev/null | awk '/^float/ { print $2 }')"
    if [[ "${name}" == zoomed ]]; then
      check "zoom_factor=${factor:-none}" awk -v f="${factor:-0}" 'BEGIN { exit !(f >= 1.9) }'
    else
      check "zoom_factor=${factor:-none}" awk -v f="${factor:-0}" 'BEGIN { exit !(f > 0.99 && f < 1.01) }'
    fi
    ;;
  windows-app)
    # Opening an .exe brought up the shell's WindowsApp window (T-159)
    title="$(hyprctl clients -j | grep -o '"title": "윈도우 프로그램"' | head -n1)"
    check "window=${title:-none} default=$(xdg-mime query default application/x-ms-dos-executable)" test -n "${title}"
    ;;
  shell-restarted)
    pids="$(pgrep -x qs | tr '\n' ' ')"
    check "qs=${pids:-none}" bash -c "[ -n '${pids}' ] && timeout 10 ${SHELL_IPC[*]} show >/dev/null"
    ;;
  default-apps)
    # Settings' 기본 앱 (robinos-default-apps): the list names the installed browser as the
    # default one, a choice lands in ~/.config/mimeapps.list, and an app that can't open
    # the kind is refused
    tool=/usr/share/robinos/bin/robinos-default-apps
    summary="$("${tool}" list | python3 -c 'import json, sys
kinds = {k["key"]: k for k in json.load(sys.stdin)}
b = kinds["browser"]
print(len(kinds), b["current"], b["currentName"], len(b["apps"]))')"
    "${tool}" set text org.gnome.TextEditor.desktop
    set_status=$?
    "${tool}" set text firefox.desktop 2>/dev/null
    refused=$?
    check "kinds/browser/name/apps=${summary:-none} set=${set_status} refused=${refused} file=$(grep -c '^text/plain=org.gnome.TextEditor.desktop' "${XDG_CONFIG_HOME:-${HOME}/.config}/mimeapps.list" 2>/dev/null)" \
      bash -c "[[ '${summary}' == '7 firefox.desktop Firefox '* ]] && [ ${set_status} = 0 ] && [ ${refused} = 1 ] \
        && grep -q '^text/plain=org.gnome.TextEditor.desktop' '${XDG_CONFIG_HOME:-${HOME}/.config}/mimeapps.list'"
    ;;
  report)
    # robinctl report (settings' 정보): all the sections, the graphics driver, and the
    # name of the computer is masked when it isn't the default one
    file="${XDG_RUNTIME_DIR:-/tmp}/robinos-report-test.txt"
    robinctl report "${file}" >/dev/null 2>&1
    sections="$(grep -c '^## ' "${file}" 2>/dev/null)"
    check "sections=${sections} drivers=$(grep -c 'Kernel driver in use' "${file}" 2>/dev/null) lines=$(wc -l <"${file}")" \
      bash -c "[ '${sections}' = 8 ] && grep -q 'Kernel driver in use' '${file}' && grep -q '^커널: ' '${file}'"
    ;;
  power-changed | power-default)
    # Settings' 전원 (ShellState.setPower): robinos-idle-config wrote hypridle's policy from
    # the minutes, hypridle runs with that file, and the choices are saved for the next
    # login. The boot test sets lock 1, screen off 2 and sleep 5 first (no dimming for a
    # one minute lock), then the defaults
    state="${XDG_STATE_HOME:-${HOME}/.local/state}/robinos"
    timeouts="$(sed -n 's/^ *timeout = //p' "${state}/hypridle.conf" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')"
    running="$(pgrep -a -x hypridle | grep -c 'robinos/hypridle.conf')"
    saved="$(tr '\n' ',' <"${state}/power" 2>/dev/null)"
    if [[ "${name}" == power-changed ]]; then
      want_timeouts="60 120 300" want_saved="lock 1,screen_off 2,suspend 5,"
    else
      want_timeouts="240 300 600 900" want_saved="lock 5,screen_off 10,suspend 15,"
    fi
    check "timeouts=${timeouts:-none} hypridle=${running} saved=${saved:-none}" \
      bash -c "[ '${timeouts}' = '${want_timeouts}' ] && [ '${running}' = 1 ] && [ '${saved}' = '${want_saved}' ]"
    ;;
  input-changed | input-default)
    # Settings' 마우스와 터치패드 and 키보드 (ShellState.setInput): Hyprland runs with the
    # new values, and the file robinos.lua reads at the next login has them too.
    # The boot test sets tap off, natural scroll off, speed 0.4, key repeat 40 first
    opt() {
      hyprctl getoption "$1" -j 2>/dev/null | python3 -c 'import json, sys
d = json.load(sys.stdin)
print(d.get("int", d.get("float", "none")))'
    }
    tap="$(opt input:touchpad:tap_to_click)"
    natural="$(opt input:touchpad:natural_scroll)"
    speed="$(opt input:sensitivity)"
    rate="$(opt input:repeat_rate)"
    saved="$(tr '\n' ',' <"${XDG_STATE_HOME:-${HOME}/.local/state}/robinos/input" 2>/dev/null)"
    if [[ "${name}" == input-changed ]]; then
      want_tap=0 want_natural=0 want_speed=0.4 want_rate=40
    else
      want_tap=1 want_natural=1 want_speed=0 want_rate=25
    fi
    check "tap=${tap} natural=${natural} speed=${speed} rate=${rate} file=${saved:-none}" \
      bash -c "[ '${tap}' = ${want_tap} ] && [ '${natural}' = ${want_natural} ] && [ '${rate}' = ${want_rate} ] \
        && awk -v s='${speed}' 'BEGIN { exit !(s - ${want_speed} < 0.001 && ${want_speed} - s < 0.001) }' \
        && [[ '${saved}' == *'speed ${want_speed},'* && '${saved}' == *'repeat_rate ${want_rate},'* ]]"
    ;;
  *)
    printf 'usage: %s <scene>  (see the top of this file)\n' "$0" >&2
    exit 2
    ;;
esac
