#!/usr/bin/env bash
set -uo pipefail

# The quick checks that need no VM, one after another (wsl-build.ps1 check runs this
# in WSL): desktop config, qmllint, the ISO sync, robinctl's and the installer's tests.
#
# Every check runs even after one fails, so one run shows all the problems. Each gets
# a time limit (CHECK_LIMIT seconds, default 600) and no input: on a PC where a check
# hung, the all-in-one run sat at "6. 빠른 검사" for hours without a word (2026-10-15).
# A check over its limit is stopped, and what it was running is printed first.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LIMIT="${CHECK_LIMIT:-600}"
cd "${ROOT_DIR}"

failed=()

# The process and everything under it, by parent process id
descendants() {
  ps -eo pid=,ppid= | awk -v root="$1" '
    { parent[$1] = $2 }
    END { for (p in parent) { q = p; while (q in parent && q != root && q > 1) q = parent[q]; if (q == root) print p } }'
}

# run_check <name> <command...>
run_check() {
  local name="$1" start="${SECONDS}" pid rc over="false" pids
  shift
  printf '\n== %s\n' "${name}"
  # Not timeout(1): it moves the check out of the terminal's foreground process group,
  # where the prompt tests' interactive bash stops itself (SIGTTOU) when run by hand
  "$@" </dev/null &
  pid=$!
  while kill -0 "${pid}" 2>/dev/null; do
    if ((SECONDS - start >= LIMIT)); then
      over="true"
      pids="$(descendants "${pid}" | paste -sd, -)"
      printf '  FAILED  %s: still running after %s seconds; what it was running:\n' "${name}" "$((SECONDS - start))" >&2
      ps -o pid,etime,args --forest -p "${pids}" | sed 's/^/          /' >&2
      kill -TERM ${pids//,/ } 2>/dev/null
      sleep 3
      kill -KILL ${pids//,/ } 2>/dev/null
      break
    fi
    sleep 1
  done
  wait "${pid}"
  rc=$?
  if [[ "${over}" == "true" ]]; then
    failed+=("${name}: over ${LIMIT}s")
  elif ((rc != 0)); then
    failed+=("${name}")
  fi
  printf '   (%s: %ss)\n' "${name}" "$((SECONDS - start))"
}

run_check "Desktop files (check-desktop.sh)" bash scripts/check-desktop.sh
run_check "Shell QML (qmllint.sh)" bash scripts/qmllint.sh
run_check "ISO sync (check-sync.sh)" bash scripts/check-sync.sh
run_check "robinctl (test-robinctl.sh)" bash scripts/test-robinctl.sh
run_check "Installer (test-robin-install.py)" python3 scripts/test-robin-install.py

printf '\n'
if ((${#failed[@]} > 0)); then
  printf 'Quick checks FAILED: %s\n' "$(IFS=/; printf '%s' "${failed[*]}" | sed 's|/| / |g')" >&2
  exit 1
fi
printf 'Quick checks passed.\n'
