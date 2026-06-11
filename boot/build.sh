#!/usr/bin/env bash
# RobinOS 라이브 ISO 빌드 (Debian live-build). Debian/Ubuntu 호스트에서 root로 실행.
# ⚠️ 검증 안 된 템플릿 — phase-cd-plan.md 참고.
set -euo pipefail

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build가 없어요:  sudo apt install -y live-build"
  exit 1
fi

if [ ! -d config/includes.chroot/opt/robinos ]; then
  echo "⚠️  config/includes.chroot/opt/robinos 가 비었어요."
  echo "    먼저 'flutter build linux --release' 후 bundle/ 을 거기로 복사하세요 (README 참고)."
fi

# 1) 부트스트랩 설정: Debian bookworm, amd64, 라이브 시스템
#    --mode debian + 데비안 미러를 명시 — 우분투 호스트(CI)에서 빌드해도
#    우분투 기본값(archive.ubuntu.com)으로 새지 않도록.
lb config \
  --mode debian \
  --distribution bookworm \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap http://deb.debian.org/debian/ \
  --mirror-chroot http://deb.debian.org/debian/ \
  --mirror-binary http://deb.debian.org/debian/ \
  --security false \
  --debian-installer none \
  --bootappend-live "boot=live components quiet splash"

# 2) 빌드 (config/ 의 패키지·includes·hooks 가 자동 반영됨)
lb build

echo "완료. 생성된 ISO를 USB로 구우세요 (live-image-amd64.hybrid.iso)."
