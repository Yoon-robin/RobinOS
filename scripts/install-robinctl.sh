#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

install -Dm755 "${ROOT_DIR}/bin/robinctl" /usr/local/bin/robinctl
install -Dm644 "${ROOT_DIR}/config/robinos.toml" /etc/robinos/config.toml

printf 'robinctl을 /usr/local/bin/robinctl에 설치했어요\n'
printf '설정 파일을 /etc/robinos/config.toml에 설치했어요\n'

