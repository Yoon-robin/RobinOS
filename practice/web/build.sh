#!/usr/bin/env bash
# Prints the web basics practice server (robinctl learn 21-25) as gzip + base64
# for bin/robinctl (LEARN_WEB_SERVER_B64). scripts/test-robinctl.sh checks that
# the copy in robinctl is the same as server.py.
#
#   bash practice/web/build.sh
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
printf 'LEARN_WEB_SERVER_B64="%s"\n' "$(gzip -9n <server.py | base64 -w0)"
