#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/build/work"
OUT_DIR="${ROOT_DIR}/out"
LOG_DIR="${ROOT_DIR}/build/logs"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/mkarchiso-${STAMP}.log"
SKIP_PACKAGE_CHECK="false"
SKIP_DOCTOR="false"

for arg in "$@"; do
  case "${arg}" in
    --skip-doctor)
      SKIP_DOCTOR="true"
      ;;
    --skip-package-check)
      SKIP_PACKAGE_CHECK="true"
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  scripts/build-iso.sh [--skip-doctor] [--skip-package-check]

Builds the RobinOS ISO on Arch Linux.

Steps:
  1. Checks the build environment
  2. Optionally validates package names with pacman -Si
  3. Prepares build/archiso-profile from Arch releng
  4. Builds the robinos package into it (/opt/robinos/pkg)
  5. Runs mkarchiso
  6. Writes SHA256SUMS for generated ISO files
EOF
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "${arg}" >&2
      exit 1
      ;;
  esac
done

command -v pacman >/dev/null 2>&1 || {
  printf 'error: pacman is required; run this on Arch Linux\n' >&2
  exit 1
}

command -v mkarchiso >/dev/null 2>&1 || {
  printf 'error: mkarchiso is required; install it with: sudo pacman -S --needed archiso\n' >&2
  exit 1
}

mkdir -p "${OUT_DIR}" "${LOG_DIR}"

if [[ "${SKIP_DOCTOR}" != "true" ]]; then
  "${ROOT_DIR}/scripts/doctor-build.sh"
fi

if [[ "${SKIP_PACKAGE_CHECK}" != "true" ]]; then
  "${ROOT_DIR}/scripts/check-arch-packages.sh"
fi

"${ROOT_DIR}/scripts/prepare-archiso.sh"

# The robinos package of this same commit, for post-install.sh to hand the copied
# files to pacman (docs/design.md "RobinOS 파일 업데이트"). Kept out of the
# committed overlay: it is a build output, a few hundred KB.
sudo "${ROOT_DIR}/scripts/build-package.sh"
iso_pkg_dir="${ROOT_DIR}/build/archiso-profile/airootfs/opt/robinos/pkg"
mkdir -p "${iso_pkg_dir}"
cp "${ROOT_DIR}"/out/packages/robinos-*.pkg.tar.zst* "${iso_pkg_dir}/"

# ROBINOS_FAST_ISO=1 (wsl-build.ps1 verify): zstd instead of xz for a test ISO. It
# builds a few minutes faster and boots a little faster, but it is bigger than
# GitHub's 2 GiB release limit, so releases are built without it (docs/release.md).
if [[ "${ROBINOS_FAST_ISO:-}" == "1" ]]; then
  sed -i 's/^airootfs_image_tool_options=.*/airootfs_image_tool_options=("-comp" "zstd" "-Xcompression-level" "3" "-b" "1M")/' \
    "${ROOT_DIR}/build/archiso-profile/profiledef.sh"
  printf 'Test ISO: zstd squashfs (faster, not for a release)\n'
fi

printf 'Building RobinOS ISO...\n'
# mkarchiso skips every stage that has a marker in its work directory, so a
# leftover build/work makes it repackage the previous build. Start clean, and
# drop old ISOs (2.5 GB each) so out/ holds just this build.
sudo rm -rf "${WORK_DIR}"
rm -f "${OUT_DIR}"/robinos-*.iso
sudo mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${ROOT_DIR}/build/archiso-profile" 2>&1 | tee "${LOG_FILE}"

mapfile -t iso_files < <(find "${OUT_DIR}" -maxdepth 1 -type f -name 'robinos-*.iso' -print | sort)

if [[ "${#iso_files[@]}" -eq 0 ]]; then
  printf 'error: no RobinOS ISO found in %s\n' "${OUT_DIR}" >&2
  exit 1
fi

(
  cd "${OUT_DIR}"
  sha256sum ./*.iso > SHA256SUMS
)

# Signed with the release key when this build machine has it (docs/release.md):
# gpg --verify SHA256SUMS.sig SHA256SUMS checks it against keys/robinos-release.asc
rm -f "${OUT_DIR}/SHA256SUMS.sig"
signing_home="${ROBINOS_SIGNING_HOME:-/root/.robinos-signing}"
release_key="${ROOT_DIR}/keys/robinos-release.asc"
signer="$(gpg --batch --show-keys --with-colons "${release_key}" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}' || true)"
if [[ -n "${signer}" ]] && GNUPGHOME="${signing_home}" gpg --batch --list-secret-keys "${signer}" >/dev/null 2>&1; then
  GNUPGHOME="${signing_home}" gpg --batch --yes --detach-sign -u "${signer}" -o "${OUT_DIR}/SHA256SUMS.sig" "${OUT_DIR}/SHA256SUMS"
  # Checked the way a downloader would: only the public key from the repository
  check_home="$(mktemp -d)"
  GNUPGHOME="${check_home}" gpg --batch --quiet --import "${release_key}"
  GNUPGHOME="${check_home}" gpg --batch --verify "${OUT_DIR}/SHA256SUMS.sig" "${OUT_DIR}/SHA256SUMS"
  rm -rf "${check_home}"
  printf 'Signed: %s (key %s)\n' "${OUT_DIR}/SHA256SUMS.sig" "${signer}"
else
  printf 'note: no release key on this machine, SHA256SUMS is not signed\n'
fi

printf '\nBuild complete.\n'
printf 'Log: %s\n' "${LOG_FILE}"
printf 'Output:\n'
for iso in "${iso_files[@]}"; do
  printf '  %s\n' "${iso}"
done
printf 'Checksums: %s\n' "${OUT_DIR}/SHA256SUMS"
