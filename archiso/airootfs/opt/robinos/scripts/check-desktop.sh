#!/usr/bin/env bash
set -euo pipefail

# Static checks for the RobinOS desktop files (run on Arch Linux).
#
#   - Lua syntax of the Hyprland config      (luac -p)
#   - Hyprland config validation             (Hyprland --verify-config)
#   - QML syntax of the shell and SDDM theme (qmlformat)
#   - Bash syntax of desktop scripts         (bash -n)
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
  else
    printf '%s\n' "${output}" >&2
    fail "desktop/hypr/robinos.lua"
  fi
else
  skip "Hyprland not found (pacman -S hyprland)"
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

printf 'Bash syntax\n'
for file in "${ROOT_DIR}"/desktop/bin/*; do
  if bash -n "${file}"; then ok "${file#"${ROOT_DIR}/"}"; else fail "${file#"${ROOT_DIR}/"}"; fi
done

if [[ "${failed}" == "true" ]]; then
  printf 'Desktop check failed.\n' >&2
  exit 1
fi

if [[ "${skipped}" == "true" ]]; then
  printf 'Desktop check passed with skipped steps.\n'
else
  printf 'Desktop check passed.\n'
fi
