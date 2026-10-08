#!/usr/bin/env bash
# Builds the reversing practice programs (robinctl learn 16-20) and prints each
# one as gzip + base64 for bin/robinctl (LEARN_REV_*_B64). The programs are
# harmless: each prints a code when the mission's trick is used.
#
#   bash practice/reversing/build.sh        (Arch Linux with gcc)
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
out="$(mktemp -d)"
trap 'rm -rf "${out}"' EXIT

flags=(-Os -Wl,-z,noseparate-code -Wl,--build-id=none)
for name in hello vault gate seeker; do
  gcc "${flags[@]}" -s -o "${out}/${name}" "${name}.c"
done
# count keeps its symbols: mission 20 disassembles check() by name
gcc "${flags[@]}" -o "${out}/count" count.c

for name in hello vault gate seeker count; do
  printf 'LEARN_REV_%s_B64="%s"\n' "${name^^}" "$(gzip -9n <"${out}/${name}" | base64 -w0)"
done
