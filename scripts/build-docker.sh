#!/usr/bin/env bash
#
# 로컬 Docker로 RobinOS ISO 빌드 (Docker만 있으면 Arch 없이도 가능).
# 결과 ISO는 ./out/ 에 생긴다.
#
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker run --rm --privileged \
    -v "${REPO_ROOT}:/repo" -w /repo \
    archlinux:latest \
    bash -c "pacman -Syu --noconfirm archiso librsvg && bash build/build.sh"
