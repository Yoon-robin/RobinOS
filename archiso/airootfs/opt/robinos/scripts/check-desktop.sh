#!/usr/bin/env bash
set -euo pipefail

# Static checks for the RobinOS desktop files (run on Arch Linux).
#
#   - Lua syntax of the Hyprland config      (luac -p)
#   - Hyprland config validation             (Hyprland --verify-config)
#   - Pointer and keyboard settings          (lua scripts/test-hypr-input.lua)
#   - QML syntax of the shell and SDDM theme (qmlformat)
#   - Syntax of desktop scripts              (bash -n, Python ast)
#   - JSON syntax of the Firefox policies    (python3 -m json.tool)
#   - fastfetch logo size matches its config (python3)
#   - Shell icon subpaths start with "M"     (python3)
#
# Missing tools are reported and skipped. Install them with:
#   sudo pacman -S --needed lua qt6-declarative hyprland

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failed="false"
skipped="false"

ok() {
  printf '  ok      %s\n' "$*"
}

fail() {
  printf '  FAILED  %s\n' "$*" >&2
  failed="true"
}

skip() {
  printf '  skipped %s\n' "$*"
  skipped="true"
}

printf 'Lua syntax\n'
if command -v luac >/dev/null 2>&1; then
  for file in "${ROOT_DIR}"/desktop/hypr/*.lua; do
    if luac -p "${file}"; then ok "${file#"${ROOT_DIR}/"}"; else fail "${file#"${ROOT_DIR}/"}"; fi
  done
else
  skip "luac not found (pacman -S lua)"
fi

printf 'Hyprland config\n'
if command -v Hyprland >/dev/null 2>&1; then
  hypr_args=(--verify-config -c "${ROOT_DIR}/desktop/hypr/robinos.lua")
  # Containers and CI run as root, which Hyprland refuses without this flag
  [[ "${EUID}" -eq 0 ]] && hypr_args+=(--i-am-really-stupid)
  # Hyprland exits before reading the config when there is no runtime dir (CI containers)
  if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    XDG_RUNTIME_DIR="$(mktemp -d)"
    chmod 700 "${XDG_RUNTIME_DIR}"
    export XDG_RUNTIME_DIR
  fi
  if output="$(Hyprland "${hypr_args[@]}" 2>&1)"; then
    ok "desktop/hypr/robinos.lua"
    printf '%s\n' "${output}" | sed -n '/Config parsing result/,$p' | sed '/^\s*$/d; s/^/          /'
  else
    printf '%s\n' "${output}" >&2
    fail "desktop/hypr/robinos.lua"
  fi
else
  skip "Hyprland not found (pacman -S hyprland)"
fi

printf 'Pointer and keyboard settings (Lua)\n'
if command -v lua >/dev/null 2>&1; then
  input_state="$(mktemp -d)"
  if XDG_STATE_HOME="${input_state}" lua "${ROOT_DIR}/scripts/test-hypr-input.lua" "${ROOT_DIR}/desktop/hypr/robinos.lua"; then
    ok "scripts/test-hypr-input.lua"
  else
    fail "scripts/test-hypr-input.lua"
  fi
  rm -rf "${input_state}"
else
  skip "lua not found (pacman -S lua)"
fi

printf 'QML syntax\n'
qmlformat=""
for candidate in qmlformat6 qmlformat /usr/lib/qt6/bin/qmlformat; do
  if command -v "${candidate}" >/dev/null 2>&1; then
    qmlformat="${candidate}"
    break
  fi
done
if [[ -n "${qmlformat}" ]]; then
  while IFS= read -r -d '' file; do
    if "${qmlformat}" "${file}" >/dev/null; then ok "${file#"${ROOT_DIR}/"}"; else fail "${file#"${ROOT_DIR}/"}"; fi
  done < <(find "${ROOT_DIR}/desktop/shell" "${ROOT_DIR}/themes/sddm/robinos" -name '*.qml' -print0 | sort -z)
else
  skip "qmlformat not found (pacman -S qt6-declarative)"
fi

printf 'Script syntax\n'
for file in "${ROOT_DIR}"/desktop/bin/*; do
  if head -n 1 "${file}" | grep -q python; then
    if ! command -v python3 >/dev/null 2>&1; then
      skip "python3 not found (${file#"${ROOT_DIR}/"})"
    elif python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "${file}"; then
      ok "${file#"${ROOT_DIR}/"}"
    else
      fail "${file#"${ROOT_DIR}/"}"
    fi
  elif bash -n "${file}"; then ok "${file#"${ROOT_DIR}/"}"; else fail "${file#"${ROOT_DIR}/"}"; fi
done

# Firefox ignores a policies.json it can't parse, without telling anyone
printf 'JSON syntax\n'
if command -v python3 >/dev/null 2>&1; then
  for file in "${ROOT_DIR}"/desktop/firefox/*.json; do
    if python3 -m json.tool "${file}" >/dev/null; then ok "${file#"${ROOT_DIR}/"}"; else fail "${file#"${ROOT_DIR}/"}"; fi
  done
else
  skip "python3 not found"
fi

# fastfetch draws nothing for a raw logo without its size, and a stale size
# misplaces the system info next to it
printf 'fastfetch logo\n'
if command -v python3 >/dev/null 2>&1; then
  if python3 - "${ROOT_DIR}/desktop/fastfetch" <<'PY'
import json, re, sys
folder = sys.argv[1]
text = open(folder + "/config.jsonc", encoding="utf-8").read()
logo = json.loads(re.sub(r"^\s*//.*$", "", text, flags=re.M))["logo"]
lines = open(folder + "/robinos-logo.ansi", encoding="utf-8").read().splitlines()
width = max(len(re.sub(r"\x1b\[[0-9;]*m", "", line)) for line in lines)
if (logo["width"], logo["height"]) != (width, len(lines)):
    sys.exit(f"config says {logo['width']}x{logo['height']}, robinos-logo.ansi is {width}x{len(lines)}")
PY
  then ok "desktop/fastfetch/robinos-logo.ansi"; else fail "desktop/fastfetch/robinos-logo.ansi"; fi
else
  skip "python3 not found"
fi

# icons.js joins each icon's subpaths into one SVG path, so a subpath copied from
# Lucide that starts with a relative "m" lands next to the previous one instead
# (the night light icon, 2026-10-10)
printf 'Shell icons\n'
if command -v python3 >/dev/null 2>&1; then
  if python3 - "${ROOT_DIR}/desktop/shell/icons.js" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
bad = re.findall(r'"m[-0-9.][^"]*"', text)
if bad:
    sys.exit("subpaths must start with an absolute M: " + ", ".join(bad))
PY
  then ok "desktop/shell/icons.js"; else fail "desktop/shell/icons.js"; fi
else
  skip "python3 not found"
fi

# A JS library used without its import ("Keyboard is not defined") only fails when
# that code runs, and qmllint's unqualified warnings are filtered (scripts/qmllint.sh):
# every file that says Keyboard. must import "keys.js" as Keyboard (2026-10-10)
printf 'Shell JS imports\n'
if command -v python3 >/dev/null 2>&1; then
  if python3 - "${ROOT_DIR}/desktop/shell" <<'PY'
import glob, os, re, sys
files = sorted(glob.glob(os.path.join(sys.argv[1], "*.qml")))
aliases = set()
for path in files:
    aliases.update(re.findall(r'^import\s+"[^"]+\.js"\s+as\s+(\w+)', open(path, encoding="utf-8").read(), re.M))
bad = []
for path in files:
    text = open(path, encoding="utf-8").read()
    imported = set(re.findall(r'^import\s+"[^"]+\.js"\s+as\s+(\w+)', text, re.M))
    code = re.sub(r"//[^\n]*", "", text)
    for alias in sorted(aliases - imported):
        if re.search(r"\b%s\." % alias, code):
            bad.append("%s uses %s without importing it" % (os.path.basename(path), alias))
if bad:
    sys.exit("\n".join(bad))
PY
  then ok "desktop/shell/*.qml"; else fail "desktop/shell/*.qml"; fi
else
  skip "python3 not found"
fi

# The launcher's calculator (calc.js) with the QML engine that runs it
printf 'Launcher calculator\n'
qml_bin="$(command -v qml6 || command -v qml || true)"
if [[ -n "${qml_bin}" ]]; then
  calc_dir="$(mktemp -d)"
  cp "${ROOT_DIR}/desktop/shell/calc.js" "${calc_dir}/"
  cat >"${calc_dir}/test.qml" <<'QML'
import QtQml
import "calc.js" as Calc

QtObject {
    Component.onCompleted: {
        const cases = [
            ["2+3", "5"], ["2 + 3 * 4", "14"], ["(2+3)*4", "20"], ["2^10", "1024"],
            ["10/4", "2.5"], ["0.1+0.2", "0.3"], ["-3+5", "2"], ["2×3÷4", "1.5"],
            ["7-2-1", "4"], ["2^3^2", "512"], ["3", null], ["(3)", null], ["-5", null],
            ["1/0", null], ["2+", null], ["(1+2", null], ["abc", null], ["2+x", null],
            ["-2^2", "-4"], ["2^-1", "0.5"], ["(-2)^2", "4"], ["1 2+3", null], ["10 - 3", "7"],
            [" (1+2) * 3 ", "9"], ["2026-10-10", null], ["010-1234-5678", null], ["10-3-2", "5"]
        ];
        let bad = 0;
        for (const [text, want] of cases) {
            const value = Calc.evaluate(text);
            const got = value === null ? null : Calc.format(value);
            if (got !== want) {
                console.log("calc " + JSON.stringify(text) + ": " + got + ", want " + want);
                bad++;
            }
        }
        Qt.exit(bad === 0 ? 0 : 1);
    }
}
QML
  if QT_QPA_PLATFORM=offscreen "${qml_bin}" "${calc_dir}/test.qml"; then ok "desktop/shell/calc.js"; else fail "desktop/shell/calc.js"; fi
  rm -rf "${calc_dir}"
else
  skip "qml6 not found (pacman -S qt6-declarative)"
fi

# Windows installers' file names -> what to use instead (windowsapps.js, T-159)
printf 'Windows program names\n'
if [[ -n "${qml_bin}" ]]; then
  apps_dir="$(mktemp -d)"
  cp "${ROOT_DIR}/desktop/shell/windowsapps.js" "${apps_dir}/"
  cat >"${apps_dir}/test.qml" <<'QML'
import QtQml
import "windowsapps.js" as WindowsApps

QtObject {
    Component.onCompleted: {
        const cases = [
            ["KakaoTalk_Setup.exe", "카카오톡"], ["Kakao Talk Setup (1).exe", "카카오톡"],
            ["ChromeSetup.exe", "Chrome"], ["Hoffice2024_Setup.exe", "한글(한컴오피스)"],
            ["OfficeSetup.exe", "Microsoft Office"], ["BANDIZIP-SETUP-STD-X64.EXE", "압축 프로그램"],
            ["7z2301-x64.exe", "압축 프로그램"], ["GOMPLAYERGLOBALSETUP.EXE", "동영상 플레이어"],
            ["DiscordSetup.exe", "Discord"], ["VSCodeUserSetup-x64-1.95.exe", "Visual Studio Code"],
            ["Git-2.47.0-64-bit.exe", "Git"], ["npp.8.7.Installer.x64.exe", "메모장 프로그램"],
            ["MicrosoftEdgeSetup.exe", "Microsoft Edge"], ["OperaSetup.exe", "Opera"], ["FirefoxSetup.exe", "Firefox"],
            ["SteamSetup.exe", "Steam"], ["TeamsSetup_c_w_.exe", "Microsoft Teams"], ["TeamViewer_Setup.exe", "TeamViewer"],
            ["Adobe_Photoshop_Setup.exe", "Adobe 프로그램"], ["AcroRdrDC2300820380_en_US.exe", "PDF 보기"],
            ["Adobe Acrobat Reader.exe", "PDF 보기"], ["qbittorrent_4.6.4_x64_setup.exe", "토렌트 프로그램"],
            ["EpicInstaller-15.17.exe", "게임 런처"], ["Bandicam_Setup.exe", "화면 녹화 프로그램"],
            ["ALYac_Setup.exe", "백신 프로그램"], ["TouchEnKey_Setup.exe", "은행·공공기관 보안 프로그램"],
            ["nProtect Online Security.exe", "은행·공공기관 보안 프로그램"], ["WizveraVeraport.exe", "은행·공공기관 보안 프로그램"],
            ["Slack Setup.exe", "Slack"], ["notes.exe", null], ["Signal.exe", null], ["cooperate_setup.exe", null],
            ["DigitalClock.exe", null], ["setup.exe", null], ["game.msi", null], ["jobs.exe", null]
        ];
        let bad = 0;
        for (const [file, want] of cases) {
            const found = WindowsApps.find(file);
            const got = found ? found.name : null;
            if (got !== want) {
                console.log("windowsapps " + JSON.stringify(file) + ": " + got + ", want " + want);
                bad++;
            }
        }
        for (const program of WindowsApps.known)
            if (!program.choices || program.choices.length === 0) {
                console.log("windowsapps: " + program.name + " has no choices");
                bad++;
            }
        Qt.exit(bad === 0 ? 0 : 1);
    }
}
QML
  if QT_QPA_PLATFORM=offscreen "${qml_bin}" "${apps_dir}/test.qml"; then ok "desktop/shell/windowsapps.js"; else fail "desktop/shell/windowsapps.js"; fi
  rm -rf "${apps_dir}"
else
  skip "qml6 not found (pacman -S qt6-declarative)"
fi

if [[ "${failed}" == "true" ]]; then
  printf 'Desktop check failed.\n' >&2
  exit 1
fi

if [[ "${skipped}" == "true" ]]; then
  printf 'Desktop check passed with skipped steps.\n'
else
  printf 'Desktop check passed.\n'
fi
