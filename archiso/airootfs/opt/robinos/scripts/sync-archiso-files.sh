#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
AIROOTFS="${ROOT_DIR}/archiso/airootfs"

# RobinOS's own files, laid out as on an installed system (the same list as the
# robinos package, scripts/stage-robinos.sh)
"${ROOT_DIR}/scripts/stage-robinos.sh" --root "${AIROOTFS}"

# Only the live ISO has the installer
install -Dm755 "${ROOT_DIR}/installer/robin-install" "${AIROOTFS}/usr/local/bin/robin-install"

printf 'Synced RobinOS files into archiso/airootfs\n'
