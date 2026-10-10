#!/usr/bin/env bash
set -euo pipefail

# Installs robinos from the RobinOS pacman repository into a throwaway root, the way
# an installed system will (SigLevel = Required, the release key trusted locally):
# proves the published database and package download and pass the signature checks.
#
# Usage: scripts/test-repo.sh [server]   (default: the GitHub release "repo")

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="${1:-https://github.com/Yoon-robin/RobinOS/releases/download/repo}"
RELEASE_KEY="${ROOT_DIR}/keys/robinos-release.asc"

t="$(mktemp -d)"
trap 'rm -rf "${t}"' EXIT
mkdir -p "${t}/root/var/lib/pacman" "${t}/cache" "${t}/gnupg" "${t}/hooks"
cat >"${t}/pacman.conf" <<EOF
[options]
RootDir = ${t}/root
DBPath = ${t}/root/var/lib/pacman
CacheDir = ${t}/cache
LogFile = ${t}/pacman.log
GPGDir = ${t}/gnupg
HookDir = ${t}/hooks
Architecture = auto
SigLevel = Required DatabaseRequired

[robinos]
Server = ${SERVER}
EOF
pm=(pacman --config "${t}/pacman.conf" --noconfirm)
keys=(pacman-key --config "${t}/pacman.conf" --gpgdir "${t}/gnupg")
fpr="$(gpg --batch --show-keys --with-colons "${RELEASE_KEY}" | awk -F: '/^fpr:/ {print $10; exit}')"

"${keys[@]}" --init >/dev/null 2>&1
"${keys[@]}" --add "${RELEASE_KEY}" >/dev/null 2>&1
"${keys[@]}" --lsign-key "${fpr}" >/dev/null 2>&1
"${pm[@]}" -Sy >/dev/null
# Only the package itself: its dependencies and scriptlets need a whole system
"${pm[@]}" -S --noscriptlet -dd robinos >/dev/null
"${pm[@]}" -Q robinos
test -x "${t}/root/usr/local/bin/robinctl"
test -f "${t}/root/usr/share/robinos/shell/shell.qml"
printf 'repo ok: %s\n' "${SERVER}"
