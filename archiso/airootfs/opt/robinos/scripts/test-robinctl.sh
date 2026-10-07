#!/usr/bin/env bash
# Fast checks for bin/robinctl and the Windows command hints, no VM needed:
# the Linux basics missions' grading, the security profiles, the lab's sudo
# path and the hints. Runs in a throwaway HOME; as root it runs the missions as
# "nobody" (robinctl learn refuses root). wsl-build.ps1 check runs it.
#
#   bash scripts/test-robinctl.sh
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROBINCTL="${ROOT_DIR}/bin/robinctl"
HINTS="${ROOT_DIR}/desktop/bash/robinos-hints.sh"
failures=0

ok() { printf '  ok      %s\n' "$1"; }
bad() {
  printf '  FAILED  %s\n' "$1"
  failures=$((failures + 1))
}

# check <description> <expected status: 0 or "fail"> <command...>
check() {
  local what="$1" want="$2"
  shift 2
  local status=0
  "$@" >"${WORK}/out" 2>&1 || status=$?
  if [[ "${want}" == "0" && "${status}" -eq 0 ]] || [[ "${want}" == "fail" && "${status}" -ne 0 ]]; then
    ok "${what}"
  else
    bad "${what} (exit ${status})"
    sed 's/^/          /' "${WORK}/out" | head -n 15
  fi
}

# Output of the last check contains a text
said() {
  if grep -qF -- "$2" "${WORK}/out"; then ok "$1"; else bad "$1: no \"$2\" in the output"; fi
}

if [[ -d /opt/robinos ]]; then
  printf 'note: /opt/robinos exists, so robinctl reads its package lists from there\n'
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
LEARNER_HOME="${WORK}/home"
mkdir -p "${LEARNER_HOME}"
chmod 777 "${WORK}" "${LEARNER_HOME}"

# Runs a command as the learner: an ordinary user with LEARNER_HOME as home
learner() {
  if [[ "${EUID}" -eq 0 ]]; then
    runuser -u nobody -- env -u XDG_STATE_HOME HOME="${LEARNER_HOME}" "$@"
  else
    env -u XDG_STATE_HOME HOME="${LEARNER_HOME}" "$@"
  fi
}
learn() { learner bash "${ROBINCTL}" learn "$@"; }
in_home() { learner bash -c "cd ~ && $1"; }

printf '%s\n' "Missions (robinctl learn)"
check "list before starting" 0 learn
said "list shows mission 1 as next" "robinctl learn show 1"
if [[ "${EUID}" -eq 0 ]]; then
  check "learn refuses root" fail bash "${ROBINCTL}" learn
fi

check "1 fails with no folders" fail learn check 1
said "1 suggests mkdir" "mkdir ~/practice"
in_home "mkdir -p practice/notes"
check "1 passes with ~/practice/notes" 0 learn check 1
said "1 points to mission 2" "robinctl learn show 2"

in_home "echo 'hello linux' > practice/notes/hello.txt"
check "2 fails with one line" fail learn check 2
in_home "echo '리눅스 첫날' >> practice/notes/hello.txt"
check "2 passes with two lines" 0 learn check 2

check "3 fails before the practice file exists" fail learn check 3
check "show 3 prepares the practice file" 0 learn show 3
in_home "test -f practice/old.txt" && ok "practice/old.txt was made" || bad "practice/old.txt was not made"
in_home "mkdir -p practice/backup && cp practice/notes/hello.txt practice/backup/ && cp practice/notes/hello.txt practice/notes/memo.txt && rm practice/old.txt"
check "3 fails when hello.txt was copied, not moved" fail learn check 3
said "3 explains cp vs mv" "mv"
in_home "rm practice/notes/hello.txt"
check "3 passes after moving" 0 learn check 3

in_home "printf '#!/bin/bash\necho \"hello robinos\"\n' > practice/hello.sh"
check "4 fails without the execute bit" fail learn check 4
said "4 suggests chmod" "chmod +x"
in_home "chmod +x practice/hello.sh"
check "4 passes with chmod +x" 0 learn check 4

in_home "echo 'root:x:0:0::/root:/bin/bash' > practice/bash-users.txt; echo 'made up line with bash' >> practice/bash-users.txt"
check "5 fails with a made-up line" fail learn check 5
in_home "grep bash /etc/passwd > practice/bash-users.txt"
check "5 passes with grep's output" 0 learn check 5
check "list after all five" 0 learn
said "list says all done" "5/5"
check "reset" 0 learn reset
check "check 1 still passes after reset (files stay)" 0 learn check 1

printf '%s\n' "Security profiles (robinctl profile, packages)"
check "profile list" 0 bash "${ROBINCTL}" profile list
for name in network web forensics reversing passwords wireless vm security; do
  said "list has ${name}" "${name}"
done
check "network dry run" 0 bash "${ROBINCTL}" profile network --dry-run
said "network includes nmap" "  nmap"
check "unknown profile" fail bash "${ROBINCTL}" profile nope
check "packages of an unknown profile" fail bash "${ROBINCTL}" packages nope
all="$(grep -Ev '^[[:space:]]*(#|$)' "${ROOT_DIR}/packages/security-baseline.txt" | sort)"
union="$(for name in network web forensics reversing passwords wireless vm; do bash "${ROBINCTL}" packages "${name}"; done | sort)"
if [[ "${all}" == "${union}" ]]; then
  ok "every package belongs to exactly one profile"
else
  bad "profiles don't cover the list exactly once: $(diff <(printf '%s\n' "${all}") <(printf '%s\n' "${union}") | grep '^[<>]' | tr '\n' ' ')"
fi
if [[ "$(bash "${ROBINCTL}" packages security | sort)" == "${all}" ]]; then
  ok "security is every package"
else
  bad "security is not every package"
fi

printf '%s\n' "Web lab (robinctl lab) with stand-in docker, sudo and systemctl"
FAKE="${WORK}/fake"
mkdir -p "${FAKE}"
printf '#!/bin/sh\necho "docker $*"\n' >"${FAKE}/docker"
printf '#!/bin/sh\necho "sudo $*"\n' >"${FAKE}/sudo"
printf '#!/bin/sh\n[ "$1" = is-active ] && exit 3\necho "systemctl $*"\n' >"${FAKE}/systemctl"
chmod 755 "${FAKE}" "${FAKE}"/*
check "lab start as a user" 0 learner env PATH="${FAKE}:/usr/bin" bash "${ROBINCTL}" lab start web
said "starts Docker through sudo" "sudo systemctl start docker.service"
said "runs compose through sudo" "sudo docker compose -f ${ROOT_DIR}/labs/web/docker-compose.yml up -d"
said "reminds to stop the lab" "robinctl lab stop web"
check "lab stop as a user" 0 learner env PATH="${FAKE}:/usr/bin" bash "${ROBINCTL}" lab stop web
said "stops through sudo" "sudo docker compose"
if grep -q 'restart: "no"' "${ROOT_DIR}/labs/web/docker-compose.yml" && ! grep -q 'unless-stopped\|always' "${ROOT_DIR}/labs/web/docker-compose.yml"; then
  ok "lab containers don't restart on boot"
else
  bad "lab containers restart on boot (labs/web/docker-compose.yml)"
fi
if grep -E '^\s*- "' "${ROOT_DIR}/labs/web/docker-compose.yml" | grep -qv '127\.0\.0\.1:'; then
  bad "a lab port is published beyond 127.0.0.1"
else
  ok "lab ports are on 127.0.0.1 only"
fi

printf '%s\n' "Windows command hints (robinos-hints.sh)"
# Calls the not-found handler directly: running "ipconfig" or "notepad" for real
# would start the Windows programs through WSL's interop
hint() { bash -c ". '${HINTS}'; command_not_found_handle '$1'" 2>&1; }
for pair in "ipconfig:ip a" "IPCONFIG.EXE:ip a" "dir:ls -l" "tasklist:ps aux" "notepad:gnome-text-editor"; do
  out="$(hint "${pair%%:*}")"
  if [[ "${out}" == *"${pair#*:}"* ]]; then ok "hint for ${pair%%:*}"; else bad "hint for ${pair%%:*}: ${out}"; fi
done
out="$(hint "surely-not-a-command-xyz")"
if [[ "${out}" == *"명령을 찾을 수 없어요"* ]]; then ok "unknown commands say so"; else bad "unknown command: ${out}"; fi
# Apps the hints send people to must be installed by RobinOS
for app in gnome-text-editor nautilus mission-center fastfetch traceroute; do
  if grep -qx "${app}" "${ROOT_DIR}/packages/core.txt" "${ROOT_DIR}/packages/desktop.txt" "${ROOT_DIR}/packages/security-baseline.txt"; then
    ok "hinted app ${app} is in a package list"
  else
    bad "hinted app ${app} is in no package list"
  fi
done

if [[ "${failures}" -gt 0 ]]; then
  printf 'robinctl tests: %d failed\n' "${failures}"
  exit 1
fi
printf 'robinctl tests: all passed\n'
