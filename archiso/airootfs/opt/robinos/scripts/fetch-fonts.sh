#!/usr/bin/env bash
set -euo pipefail

# Downloads the RobinOS interface fonts that are not in the Arch repositories,
# verifies them against pinned SHA-256 checksums, and installs them into a fonts directory.
#
#   Geist / Geist Mono 1.7.2 (Vercel)       SIL Open Font License 1.1
#   Pretendard 1.3.9 (Kil Hyung-jin)        SIL Open Font License 1.1
#
# Usage:
#   scripts/fetch-fonts.sh <fonts-dir>
#   scripts/fetch-fonts.sh build/archiso-profile/airootfs/usr/share/fonts/robinos
#   sudo scripts/fetch-fonts.sh /usr/share/fonts/robinos
#
# Downloads are cached in build/cache/fonts (override with ROBINOS_FONT_CACHE).

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${ROBINOS_FONT_CACHE:-${ROOT_DIR}/build/cache/fonts}"
DEST_DIR="${1:-}"

GEIST_URL="https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip"
GEIST_SHA256="7fc800d2ac6b92844895196e5041aca55d814c15db70c44f79b3b83ab82b04e2"
PRETENDARD_URL="https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip"
PRETENDARD_SHA256="04be351a74d6bf7d60c480a3087e51d185485d35a52023142af1df19eb8c428a"

die() {
  printf '오류: %s\n' "$*" >&2
  exit 1
}

[[ -n "${DEST_DIR}" ]] || die "사용법: scripts/fetch-fonts.sh <글꼴 폴더>"

for cmd in curl sha256sum bsdtar; do
  command -v "${cmd}" >/dev/null 2>&1 || die "${cmd} 명령이 필요해요"
done

fetch() {
  local url="$1"
  local sha="$2"
  local file="${CACHE_DIR}/$(basename "${url}")"

  if [[ -f "${file}" ]] && printf '%s  %s\n' "${sha}" "${file}" | sha256sum --check --status; then
    printf '%s\n' "${file}"
    return
  fi

  printf '내려받는 중: %s\n' "${url}" >&2
  curl --fail --location --silent --show-error --output "${file}.part" "${url}"
  printf '%s  %s\n' "${sha}" "${file}.part" | sha256sum --check --status \
    || die "체크섬이 맞지 않아요: ${url}"
  mv "${file}.part" "${file}"
  printf '%s\n' "${file}"
}

mkdir -p "${CACHE_DIR}"
work_dir="$(mktemp -d "${CACHE_DIR}/extract.XXXXXX")"
trap 'rm -rf "${work_dir}"' EXIT

geist_zip="$(fetch "${GEIST_URL}" "${GEIST_SHA256}")"
pretendard_zip="$(fetch "${PRETENDARD_URL}" "${PRETENDARD_SHA256}")"

mkdir -p "${work_dir}/geist" "${work_dir}/pretendard"
bsdtar -xf "${geist_zip}" -C "${work_dir}/geist"
bsdtar -xf "${pretendard_zip}" -C "${work_dir}/pretendard"

mkdir -p "${DEST_DIR}"
install -m644 "${work_dir}/geist/geist-font/Geist/variable/Geist[wght].ttf" "${DEST_DIR}/Geist[wght].ttf"
install -m644 "${work_dir}/geist/geist-font/Geist/variable/Geist-Italic[wght].ttf" "${DEST_DIR}/Geist-Italic[wght].ttf"
install -m644 "${work_dir}/geist/geist-font/GeistMono/variable/GeistMono[wght].ttf" "${DEST_DIR}/GeistMono[wght].ttf"
install -m644 "${work_dir}/geist/geist-font/OFL.txt" "${DEST_DIR}/LICENSE-Geist.txt"
install -m644 "${work_dir}/pretendard/public/variable/PretendardVariable.ttf" "${DEST_DIR}/PretendardVariable.ttf"
install -m644 "${work_dir}/pretendard/LICENSE.txt" "${DEST_DIR}/LICENSE-Pretendard.txt"

printf 'RobinOS 글꼴을 %s에 설치했어요\n' "${DEST_DIR}"
