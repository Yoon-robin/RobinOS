#!/usr/bin/env bash
#
# RobinOS ISO 빌드 스크립트
#
# 공식 Arch releng 프로파일을 복사한 뒤 그 위에 RobinOS 레이어를 얹고 mkarchiso를 돌린다.
# Arch 환경 + root 권한에서 실행해야 한다 (archiso, librsvg 필요).
#   sudo bash build/build.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELENG="/usr/share/archiso/configs/releng"
WORK="${REPO_ROOT}/work"
OUT="${REPO_ROOT}/out"
PROFILE="${WORK}/profile"
AIROOTFS="${PROFILE}/airootfs"

log() { printf '\033[1;34m[robinos]\033[0m %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "root 권한이 필요하다 (sudo)."; exit 1; }
[[ -d "$RELENG" ]] || { echo "releng 프로파일이 없다. 'pacman -S archiso' 후 다시 실행."; exit 1; }
command -v rsvg-convert >/dev/null || { echo "rsvg-convert 가 없다. 'pacman -S librsvg' 필요."; exit 1; }

log "작업 디렉터리 초기화"
rm -rf "$PROFILE"
mkdir -p "$PROFILE" "$OUT"
cp -a "${RELENG}/." "${PROFILE}/"

log "패키지 목록 병합"
{
    echo ""
    echo "# ---- RobinOS ----"
    cat "${REPO_ROOT}/iso/packages.x86_64"
} >> "${PROFILE}/packages.x86_64"

log "airootfs 오버레이 적용"
cp -a "${REPO_ROOT}/iso/airootfs/." "${AIROOTFS}/"

log "데스크톱 dotfiles 배치 (root + /etc/skel)"
mkdir -p "${AIROOTFS}/root" "${AIROOTFS}/etc/skel"
cp -a "${REPO_ROOT}/iso/skel/." "${AIROOTFS}/root/"
cp -a "${REPO_ROOT}/iso/skel/." "${AIROOTFS}/etc/skel/"

log "배경화면 렌더 (SVG → PNG)"
mkdir -p "${AIROOTFS}/usr/share/backgrounds/robinos"
rsvg-convert -w 2560 -h 1440 \
    "${REPO_ROOT}/branding/wallpaper.svg" \
    -o "${AIROOTFS}/usr/share/backgrounds/robinos/wallpaper.png"

log "profiledef 브랜딩"
PROFILEDEF="${PROFILE}/profiledef.sh"
sed -i \
    -e 's/^iso_name=.*/iso_name="robinos"/' \
    -e 's|^iso_label=.*|iso_label="ROBINOS_$(date +%Y%m)"|' \
    -e 's|^iso_publisher=.*|iso_publisher="RobinOS <https://github.com/Yoon-robin/RobinOS>"|' \
    -e 's|^iso_application=.*|iso_application="RobinOS Live/Install Medium"|' \
    -e 's/^install_dir=.*/install_dir="robinos"/' \
    "$PROFILEDEF"

log "실행 권한 강제 (file_permissions)"
# git/Windows/mkarchiso 사이에서 +x 비트가 유실되는 걸 막는다 — archiso의
# file_permissions 배열이 squashfs에 권한을 확정한다. /usr/local/bin 의 모든
# 스크립트를 자동 등록한다 (스크립트가 늘어도 안전).
for f in "${AIROOTFS}/usr/local/bin/"*; do
    [ -e "$f" ] || continue
    name="/usr/local/bin/$(basename "$f")"
    chmod 0755 "$f"
    sed -i "/^file_permissions=(/a\\  [\"${name}\"]=\"0:0:0755\"" "$PROFILEDEF"
done

log "부트 메뉴 텍스트 리브랜딩 (Arch Linux → RobinOS)"
grep -rl --null "Arch Linux" "${PROFILE}/efiboot" "${PROFILE}/grub" "${PROFILE}/syslinux" 2>/dev/null \
    | xargs -0 -r sed -i 's/Arch Linux/RobinOS/g'

log "mkarchiso 실행 — ISO 빌드 시작 (시간이 좀 걸린다)"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

log "완료. 결과물:"
ls -lh "$OUT"/*.iso
