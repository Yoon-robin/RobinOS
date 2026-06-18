#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

install -Dm755 "${ROOT_DIR}/bin/robinctl" /usr/local/bin/robinctl
install -Dm644 "${ROOT_DIR}/config/robinos.toml" /etc/robinos/config.toml

printf 'Installed robinctl to /usr/local/bin/robinctl\n'
printf 'Installed config to /etc/robinos/config.toml\n'

