#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--yes" ]]; then
  cat <<'EOF'
This removes RobinOS build work directories and generated ISO outputs.

Run:
  scripts/clean-build.sh --yes
EOF
  exit 0
fi

rm -rf "${ROOT_DIR}/build/work" "${ROOT_DIR}/build/archiso-profile"
rm -rf "${ROOT_DIR}/out"

printf 'Removed build/work, build/archiso-profile, and out.\n'

