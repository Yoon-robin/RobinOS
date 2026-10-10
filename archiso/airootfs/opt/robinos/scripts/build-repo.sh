#!/usr/bin/env bash
set -euo pipefail

# Makes the RobinOS pacman repository (docs/design.md "RobinOS 파일 업데이트") in
# out/repo from the package scripts/build-package.sh left in out/packages: the
# package and its signature, and a database signed with the release key. The files
# have plain names (no symlinks), ready to upload as assets of the GitHub release
# "repo", which pacman reads as Server = .../releases/download/repo.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="${ROOT_DIR}/out/packages"
REPO_DIR="${ROOT_DIR}/out/repo"
SIGNING_HOME="${ROBINOS_SIGNING_HOME:-/root/.robinos-signing}"
RELEASE_KEY="${ROOT_DIR}/keys/robinos-release.asc"

pkg="$(find "${PKG_DIR}" -maxdepth 1 -name 'robinos-*.pkg.tar.zst' -print -quit 2>/dev/null || true)"
[[ -n "${pkg}" && -f "${pkg}.sig" ]] || { printf 'error: no signed package in %s (scripts/build-package.sh)\n' "${PKG_DIR}" >&2; exit 1; }
signer="$(gpg --batch --show-keys --with-colons "${RELEASE_KEY}" | awk -F: '/^fpr:/ {print $10; exit}')"
GNUPGHOME="${SIGNING_HOME}" gpg --batch --list-secret-keys "${signer}" >/dev/null 2>&1 \
  || { printf 'error: the release key is not on this machine (%s)\n' "${SIGNING_HOME}" >&2; exit 1; }

# Only the newest package: the database lists one robinos, older files would just
# take space in the release
rm -rf "${REPO_DIR}"
mkdir -p "${REPO_DIR}"
cp "${pkg}" "${pkg}.sig" "${REPO_DIR}/"
cd "${REPO_DIR}"
GNUPGHOME="${SIGNING_HOME}" repo-add --quiet --sign --key "${signer}" --verify robinos.db.tar.gz "$(basename "${pkg}")"

# GitHub release assets can't be symlinks: robinos.db and robinos.files as files
for name in db files; do
  rm -f "robinos.${name}" "robinos.${name}.sig"
  cp "robinos.${name}.tar.gz" "robinos.${name}"
  cp "robinos.${name}.tar.gz.sig" "robinos.${name}.sig"
done
ls -1 "${REPO_DIR}"
