#!/usr/bin/env bash
set -euo pipefail

# Builds the robinos pacman package (packaging/robinos) from this checkout's HEAD into
# out/packages, signs it with the release key when this machine has it, and checks it:
# the same files as scripts/stage-robinos.sh lays out (plus /etc/robinos/config.toml),
# a robinctl that runs, a signature the repository's public key accepts.
# Runs as root in the WSL build environment (scripts/wsl-build.ps1 package); makepkg
# won't run as root, so the build itself runs as the robinbuild user.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out/packages"
BUILD_USER="robinbuild"
SIGNING_HOME="${ROBINOS_SIGNING_HOME:-/root/.robinos-signing}"
RELEASE_KEY="${ROOT_DIR}/keys/robinos-release.asc"

[[ "${EUID}" -eq 0 ]] || { printf 'error: run as root (it makes the build user)\n' >&2; exit 1; }
command -v fakeroot >/dev/null 2>&1 || pacman -S --needed --noconfirm fakeroot >/dev/null
id "${BUILD_USER}" >/dev/null 2>&1 || useradd -m -s /bin/bash "${BUILD_USER}"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
git clone -q "${ROOT_DIR}" "${work}/src"
chown -R "${BUILD_USER}:" "${work}"
(cd "${work}/src/packaging/robinos" && runuser -u "${BUILD_USER}" -- makepkg -f --nodeps --noconfirm >"${work}/makepkg.log" 2>&1) || {
  cat "${work}/makepkg.log" >&2
  exit 1
}
pkg="$(find "${work}/src/packaging/robinos" -maxdepth 1 -name 'robinos-*.pkg.tar.zst' -print -quit)"
[[ -n "${pkg}" ]] || { printf 'error: makepkg made no package\n' >&2; exit 1; }

# Same files as the installer lays out
expected="${work}/expected"
"${ROOT_DIR}/scripts/stage-robinos.sh" --root "${expected}"
install -Dm644 "${ROOT_DIR}/config/robinos.toml" "${expected}/etc/robinos/config.toml"
(cd "${expected}" && find . ! -type d -printf '%P\n' | LC_ALL=C sort) >"${work}/want"
bsdtar -tf "${pkg}" | grep -Ev '^\.(PKGINFO|BUILDINFO|MTREE|INSTALL)$' | grep -v '/$' | LC_ALL=C sort >"${work}/got"
if [[ "$(sha256sum <"${work}/want")" != "$(sha256sum <"${work}/got")" ]]; then
  printf 'error: the package files differ from scripts/stage-robinos.sh\n' >&2
  python3 -c 'import sys; a=set(open(sys.argv[1])); b=set(open(sys.argv[2])); [print("  missing", l.strip()) for l in sorted(a-b)][:20]; [print("  extra  ", l.strip()) for l in sorted(b-a)][:20]' "${work}/want" "${work}/got" >&2
  exit 1
fi

# robinctl from the package runs
mkdir -p "${work}/root"
bsdtar -xf "${pkg}" -C "${work}/root"
bash "${work}/root/usr/local/bin/robinctl" version >/dev/null

mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}"/robinos-*.pkg.tar.zst "${OUT_DIR}"/robinos-*.pkg.tar.zst.sig
cp "${pkg}" "${OUT_DIR}/"
out_pkg="${OUT_DIR}/$(basename "${pkg}")"

signer="$(gpg --batch --show-keys --with-colons "${RELEASE_KEY}" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}' || true)"
if [[ -n "${signer}" ]] && GNUPGHOME="${SIGNING_HOME}" gpg --batch --list-secret-keys "${signer}" >/dev/null 2>&1; then
  GNUPGHOME="${SIGNING_HOME}" gpg --batch --yes --detach-sign -u "${signer}" -o "${out_pkg}.sig" "${out_pkg}"
  check_home="${work}/gnupg"
  install -d -m 700 "${check_home}"
  GNUPGHOME="${check_home}" gpg --batch --quiet --import "${RELEASE_KEY}"
  GNUPGHOME="${check_home}" gpg --batch --quiet --verify "${out_pkg}.sig" "${out_pkg}"
  printf 'Signed: %s.sig\n' "${out_pkg}"
else
  printf 'note: no release key on this machine, the package is not signed\n'
fi
printf 'Package: %s (%s files)\n' "${out_pkg}" "$(wc -l <"${work}/got")"
