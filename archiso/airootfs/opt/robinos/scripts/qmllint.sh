#!/usr/bin/env bash
set -euo pipefail

# Lints the RobinOS shell QML against the installed Quickshell type info, which
# catches what qmlformat (scripts/check-desktop.sh) can't: misspelled or missing
# properties, signals and types. A single bad property stops the whole shell.
#
# Usage: scripts/qmllint.sh [file.qml ...]      (default: every desktop/shell/*.qml)
# Needs: quickshell, qt6-declarative (pacman -S quickshell qt6-declarative)
#
# Quickshell's types make qmllint print some warnings that are always there
# (PanelWindow is "not creatable", GlobalShortcut and margins "not resolved", ...);
# they are filtered out so only new problems show. Exit status 1 when any remain.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QMLLINT="$(command -v qmllint6 || command -v qmllint || printf '/usr/lib/qt6/bin/qmllint')"
[[ -x "${QMLLINT}" ]] || { printf 'error: qmllint not found (pacman -S qt6-declarative)\n' >&2; exit 1; }
[[ -d /usr/lib/qt6/qml/Quickshell ]] || { printf 'error: Quickshell types not found (pacman -S quickshell)\n' >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
cp -r "${ROOT_DIR}/desktop/shell/." "${work}/"
cd "${work}"

# Quickshell registers the config directory's singletons itself; qmllint needs a qmldir
{
  printf 'module shell\n'
  for file in *.qml; do
    name="${file%.qml}"
    if grep -q '^pragma Singleton' "${file}"; then
      printf 'singleton %s 1.0 %s\n' "${name}" "${file}"
    else
      printf '%s 1.0 %s\n' "${name}" "${file}"
    fi
  done
} >qmldir

files=()
for arg in "$@"; do
  files+=("$(basename "${arg}")")
done
[[ "${#files[@]}" -gt 0 ]] || files=(*.qml)

known='unqualified|Type PanelWindow is not creatable|Type GlobalShortcut is used but it is not resolved'
known+='|Type margins is used but it is not resolved|PostReloadHook was not found|incomplete type "FileViewAdapter"'
known+='|QProcess::ExitStatus|"BluetoothAdapter" of property "defaultAdapter" not found'

report="$("${QMLLINT}" -I /usr/lib/qt6/qml -I "${work}" "${files[@]}" 2>&1 || true)"
problems="$(printf '%s\n' "${report}" | grep -E '^(Warning|Error)' | grep -Ev "${known}" || true)"

if [[ -n "${problems}" ]]; then
  printf '%s\n' "${problems}"
  printf '\nqmllint: %s problem(s)\n' "$(printf '%s\n' "${problems}" | wc -l)"
  exit 1
fi
printf 'qmllint: ok (%s files)\n' "${#files[@]}"
