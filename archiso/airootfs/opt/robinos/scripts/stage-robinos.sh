#!/usr/bin/env bash
set -euo pipefail

# Puts RobinOS's own files under a root directory, laid out as on an installed system:
# robinctl, /opt/robinos (package lists, scripts, docs, labs, the release key, the
# desktop sources the installer copies), the desktop files from desktop/install-map.txt
# and the branding.
# One list for every place they go: the live ISO overlay (sync-archiso-files.sh) and
# the robinos pacman package (packaging/robinos/PKGBUILD), so both match.
#
# Usage: scripts/stage-robinos.sh --root DIR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --root)
      TARGET="${2:-}"
      shift 2
      ;;
    *)
      printf 'usage: %s --root DIR\n' "$0" >&2
      exit 1
      ;;
  esac
done
[[ -n "${TARGET}" ]] || { printf 'usage: %s --root DIR\n' "$0" >&2; exit 1; }
TARGET="${TARGET%/}"
opt="${TARGET}/opt/robinos"

install -Dm755 "${ROOT_DIR}/bin/robinctl" "${TARGET}/usr/local/bin/robinctl"
# /etc/robinos/config.toml differs: the live ISO keeps its own (purpose and default
# profile for the live session); the package installs config/robinos.toml

mkdir -p "${opt}/assets"
cp -a "${ROOT_DIR}/assets/." "${opt}/assets/"
mkdir -p "${opt}/themes"
cp -a "${ROOT_DIR}/themes/." "${opt}/themes/"
install -Dm755 "${ROOT_DIR}/bin/robinctl" "${opt}/bin/robinctl"
mkdir -p "${opt}/config"
cp -a "${ROOT_DIR}/config/." "${opt}/config/"
# Only the Markdown: docs/screenshots (README pictures) stays out
install -Dm644 "${ROOT_DIR}"/docs/*.md -t "${opt}/docs"
install -Dm644 "${ROOT_DIR}"/packages/*.txt -t "${opt}/packages"
# The release key robinctl repo setup trusts for the [robinos] repository
install -Dm644 "${ROOT_DIR}/keys/robinos-release.asc" "${opt}/keys/robinos-release.asc"
install -Dm755 "${ROOT_DIR}"/scripts/*.sh -t "${opt}/scripts"
install -Dm644 "${ROOT_DIR}"/scripts/*.ps1 -t "${opt}/scripts"
rm -rf "${opt}/labs"
cp -a "${ROOT_DIR}/labs" "${opt}/labs"
rm -rf "${opt}/desktop"
cp -a "${ROOT_DIR}/desktop" "${opt}/desktop"

"${ROOT_DIR}/scripts/install-desktop.sh" --root "${TARGET}" >/dev/null

install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-default.svg" "${TARGET}/usr/share/wallpapers/RobinOS/robinos-default.svg"
install -Dm644 "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${TARGET}/usr/share/wallpapers/RobinOS/robinos-lock.svg"
install -Dm644 "${ROOT_DIR}/assets/brand/robinos-mark.svg" "${TARGET}/usr/share/pixmaps/robinos-mark.svg"
mkdir -p "${TARGET}/usr/share/grub/themes/robinos"
cp -a "${ROOT_DIR}/themes/grub/robinos/." "${TARGET}/usr/share/grub/themes/robinos/"
install -Dm644 "${ROOT_DIR}/config/grub/10-robinos-theme.cfg" "${TARGET}/etc/default/grub.d/10-robinos-theme.cfg"
mkdir -p "${TARGET}/usr/share/sddm/themes/robinos"
cp -a "${ROOT_DIR}/themes/sddm/robinos/." "${TARGET}/usr/share/sddm/themes/robinos/"
cp "${ROOT_DIR}/assets/brand/robinos-mark.svg" "${TARGET}/usr/share/sddm/themes/robinos/logo.svg"
cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${TARGET}/usr/share/sddm/themes/robinos/background.svg"
cp "${ROOT_DIR}/assets/wallpapers/robinos-lock.svg" "${TARGET}/usr/share/sddm/themes/robinos/preview.svg"
mkdir -p "${TARGET}/etc/sddm.conf.d"
cat >"${TARGET}/etc/sddm.conf.d/10-robinos-theme.conf" <<'EOF'
[Theme]
Current=robinos
EOF
