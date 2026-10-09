#!/usr/bin/env bash
set -euo pipefail

# Runs scripts/sync-archiso-files.sh on a throwaway copy of the working tree, the
# way the ISO build does in WSL. The Windows side syncs with the PowerShell version,
# so a mistake in the shell version (a folder under docs/ that `install` can't copy,
# 2026-10-10) used to show up only minutes into `wsl-build.ps1 build`.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

rsync -a --exclude=.git --exclude=/build --exclude=/out --exclude=/work "${ROOT_DIR}/" "${work}/"
if bash "${work}/scripts/sync-archiso-files.sh" >"${work}/sync.log" 2>&1; then
  printf 'ISO sync (sync-archiso-files.sh): ok\n'
else
  cat "${work}/sync.log" >&2
  printf 'ISO sync (sync-archiso-files.sh): failed\n' >&2
  exit 1
fi
