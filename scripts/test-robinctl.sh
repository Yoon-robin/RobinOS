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
check "list after the first five" 0 learn
said "list counts 5 of 20" "5/20"
said "list shows the network group" "네트워크 기초"
said "list points to mission 6" "robinctl learn show 6"

# Network basics: answers written the way the missions ask
in_home "mkdir -p practice/net"
# TEST-NET-1 (RFC 5737) is never assigned. Not 10.255.255.254: WSL's DNS tunneling puts it on lo
in_home "echo 192.0.2.123 > practice/net/my-ip.txt"
check "6 fails with an address this machine doesn't have" fail learn check 6
my_ip="$(ip -4 -o addr show | awk '{ split($4, a, "/"); print a[1] }' | grep -v '^127\.' | head -n 1)"
[[ -n "${my_ip}" ]] || my_ip="127.0.0.1"
if [[ "${my_ip}" != "127.0.0.1" ]]; then
  in_home "echo 127.0.0.1 > practice/net/my-ip.txt"
  check "6 fails with 127.0.0.1 when there is a real address" fail learn check 6
  said "6 explains loopback" "자기 자신"
fi
in_home "echo ${my_ip} > practice/net/my-ip.txt"
check "6 passes with this machine's address" 0 learn check 6

in_home "echo 1.2.3.4 > practice/net/localhost.txt"
check "7 fails with a wrong address" fail learn check 7
in_home "getent hosts localhost > practice/net/localhost.txt || echo '127.0.0.1 localhost' > practice/net/localhost.txt"
check "7 passes with getent's answer" 0 learn check 7

NET_FAKE="${WORK}/netfake"
mkdir -p "${NET_FAKE}"
for cmd in nmap dig nc; do printf '#!/bin/sh\n' >"${NET_FAKE}/${cmd}"; done
chmod 755 "${NET_FAKE}" "${NET_FAKE}"/*
check "8 passes once nmap, dig and nc exist" 0 learner env PATH="${NET_FAKE}:/usr/bin:/bin" bash "${ROBINCTL}" learn check 8
if ! command -v nmap >/dev/null && ! command -v dig >/dev/null; then
  check "8 fails without the network profile" fail learn check 8
  said "8 suggests the profile" "sudo robinctl profile network"
fi

in_home "echo 'LISTEN 0 1 127.0.0.1:8000 0.0.0.0:*' > practice/net/listen.txt"
check "9 fails without port 9000" fail learn check 9
in_home "echo 'LISTEN 0 1 127.0.0.1:9000 0.0.0.0:*' > practice/net/listen.txt"
check "9 passes with ss's 9000 line" 0 learn check 9

in_home "printf 'Nmap scan report for scanme.nmap.org (45.33.32.156)\n9000/tcp open  cslistener\n' > practice/net/scan.txt"
check "10 fails when another host was scanned" fail learn check 10
said "10 points to the ethics rules" "docs/ethics.md"
in_home "printf 'Nmap scan report for localhost (127.0.0.1)\n22/tcp closed ssh\n' > practice/net/scan.txt"
check "10 fails when 9000 isn't open" fail learn check 10
in_home "printf '# Nmap 7.95 scan\nNmap scan report for localhost (127.0.0.1)\nPORT     STATE SERVICE\n9000/tcp open  cslistener\n' > practice/net/scan.txt"
check "10 passes with 9000 open on 127.0.0.1" 0 learn check 10

check "list after the first ten" 0 learn
said "list counts 10 of 20" "10/20"
said "list shows the forensics group" "포렌식 기초"
said "list points to mission 11" "robinctl learn show 11"

# Forensics basics: show 11 makes the practice files, the tools solve them
check "11 fails before the practice files exist" fail learn check 11
check "show 11 makes the practice files" 0 learn show 11
said "show 11 says where the files are" "~/practice/forensics"
in_home "test -s practice/forensics/report.txt && test -s practice/forensics/photo.jpg && test -s practice/forensics/logo.png && test -s practice/forensics/auth.log" \
  && ok "practice files are there" || bad "practice files are missing"
if command -v file >/dev/null; then
  in_home "file practice/forensics/report.txt" | grep -q PNG && ok "report.txt really is a PNG" || bad "report.txt is not a PNG"
fi
in_home "echo text > practice/forensics/report-type.txt"
check "11 fails with the extension's type" fail learn check 11
in_home "echo PNG > practice/forensics/report-type.txt"
check "11 passes with PNG" 0 learn check 11

in_home "echo memo2.txt memo3.txt > practice/forensics/same.txt"
check "12 fails with the look-alike memo3" fail learn check 12
said "12 explains the trailing space" "빈칸"
in_home "cd practice/forensics/hash && sha256sum memo*.txt | sort | awk '{print \$1}' | uniq -d | wc -l" | grep -qx 1 \
  && ok "exactly one pair of memos is the same" || bad "the memos should hold exactly one identical pair"
in_home "printf 'memo5.txt\nmemo2.txt\n' > practice/forensics/same.txt"
check "12 passes with memo2 and memo5" 0 learn check 12

in_home "echo Robin > practice/forensics/photographer.txt"
check "13 fails with a wrong name" fail learn check 13
in_home "echo 'kim  haneul' > practice/forensics/photographer.txt"
check "13 passes with the Artist field" 0 learn check 13

in_home "bsdtar -xOf practice/forensics/logo.png secret.txt > practice/forensics/found.txt"
check "14 passes with what bsdtar pulls out of logo.png" 0 learn check 14
in_home "echo nothing > practice/forensics/found.txt"
check "14 fails with a wrong code" fail learn check 14

in_home "echo 198.51.100.7 > practice/forensics/attacker.txt"
check "15 fails with the second address" fail learn check 15
in_home "cd practice/forensics && grep 'Failed password' auth.log | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -n | tail -n 1 | awk '{print \$3}' > attacker.txt"
check "15 passes with the pipeline from the mission" 0 learn check 15

in_home "bsdtar -xOf practice/forensics/logo.png secret.txt > practice/forensics/found.txt"
check "14 passes again" 0 learn check 14
check "list after the first fifteen" 0 learn
said "list counts 15 of 20" "15/20"
said "list shows the reversing group" "리버싱 기초"
said "list points to mission 16" "robinctl learn show 16"

# Reversing basics: show 16 unpacks the practice programs, the tools solve them
REV="practice/reversing"
check "16 fails before the practice programs exist" fail learn check 16
check "show 16 unpacks the practice programs" 0 learn show 16
said "show 16 says where the programs are" "~/practice/reversing"
in_home "cd ${REV} && test -x hello && test -x vault && test -x gate && test -x seeker && test -x count" \
  && ok "practice programs are there and executable" || bad "practice programs are missing"
in_home "${REV}/hello" | grep -q "연습용 프로그램" && ok "hello runs" || bad "hello doesn't run"
in_home "readelf -d ${REV}/hello | grep NEEDED | grep -o 'libc[^]]*' > ${REV}/library.txt"
check "16 passes with the NEEDED library" 0 learn check 16
in_home "echo libc > ${REV}/library.txt"
check "16 fails with half a name" fail learn check 16
in_home "echo libc.so.6 > ${REV}/library.txt"

in_home "strings ${REV}/vault" | grep -q "robin-sesame-2026" && ok "strings shows the vault password" || bad "strings doesn't show the vault password"
in_home "strings ${REV}/vault" | grep -q "ROBIN-VAULT" && bad "strings shows the vault code" || ok "strings doesn't show the vault code"
in_home "echo robin-sesame-2026 > ${REV}/vault.txt"
check "17 fails with the password instead of the code" fail learn check 17
said "17 explains password vs code" "비밀번호"
in_home "cd ${REV} && echo robin-sesame-2026 | ./vault | grep -o 'ROBIN-[A-Z-]*' > vault.txt"
check "17 passes with the code the vault prints" 0 learn check 17

in_home "strings ${REV}/gate" | grep -q "open-sesame-7" && bad "strings shows the gate key" || ok "strings doesn't show the gate key"
if command -v ltrace >/dev/null; then
  in_home "cd ${REV} && ltrace ./gate guess 2>&1; true" | grep -q 'strcmp("guess", "open-sesame-7")' \
    && ok "ltrace shows the key going into strcmp" || bad "ltrace doesn't show the key in strcmp"
fi
in_home "cd ${REV} && ./gate open-sesame-7 | grep -o 'ROBIN-[A-Z-]*' > gate.txt"
check "18 passes with the code the gate prints" 0 learn check 18

check "19 fails before the key file exists" fail learn check 19
if command -v strace >/dev/null; then
  in_home "cd ${REV} && strace -e trace=openat ./seeker 2>&1; true" | grep -q "practice/reversing/.hidden/seeker.key" \
    && ok "strace shows the path seeker opens" || bad "strace doesn't show the key file path"
fi
in_home "cd ${REV} && mkdir -p .hidden && touch .hidden/seeker.key && ./seeker | grep -o 'ROBIN-[A-Z-]*' > seeker.txt"
check "19 passes with the key file and the code" 0 learn check 19

if command -v objdump >/dev/null; then
  in_home "objdump -d ${REV}/count --disassemble=check" | grep -q 'cmp.*\$0x539' \
    && ok "objdump shows cmp \$0x539 in check" || bad "objdump doesn't show the constant in check"
fi
in_home "echo 0x539 > ${REV}/number.txt"
check "20 fails with the hexadecimal number" fail learn check 20
said "20 explains hexadecimal" "16진수"
in_home "cd ${REV} && ./count 1337 | grep -q ROBIN-COUNT-1337 && echo \$((0x539)) > number.txt"
check "20 passes with 1337" 0 learn check 20

check "list after all twenty" 0 learn
said "list says all twenty are done" "20/20"
said "list points to the web lab" "robinctl lab info web"
check "show 20" 0 learn show 20
check "mission 21 doesn't exist" fail learn show 21
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

printf '%s\n' "Update (dry run) with stand-in pacman and flatpak"
UPDATE_BIN="${WORK}/update-bin"
mkdir -p "${UPDATE_BIN}"
printf '#!/bin/sh\nexit 1\n' >"${UPDATE_BIN}/pacman"
chmod 755 "${UPDATE_BIN}" "${UPDATE_BIN}/pacman"
if [[ ! -e /usr/bin/flatpak ]]; then
  check "update dry run without flatpak" 0 env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" update --dry-run
  said "update runs pacman -Syu" "pacman -Syu"
  if grep -q flatpak "${WORK}/out"; then bad "update mentions flatpak without it"; else ok "no flatpak, no flatpak step"; fi
fi
printf '#!/bin/sh\nexit 0\n' >"${UPDATE_BIN}/flatpak"
chmod 755 "${UPDATE_BIN}/flatpak"
check "update dry run with flatpak" 0 env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" update --dry-run
said "update also updates app store apps" "flatpak update --system"

printf '%s\n' "Web lab (robinctl lab) with stand-in docker, sudo and systemctl"
FAKE="${WORK}/fake"
mkdir -p "${FAKE}"
printf '#!/bin/sh\necho "docker $*"\n' >"${FAKE}/docker"
printf '#!/bin/sh\necho "sudo $*"\n' >"${FAKE}/sudo"
printf '#!/bin/sh\n[ "$1" = is-active ] && exit 3\necho "systemctl $*"\n' >"${FAKE}/systemctl"
chmod 755 "${FAKE}" "${FAKE}"/*
# Without the web profile there is no docker: point to it before asking for a password
NODOCKER="${WORK}/nodocker"
mkdir -p "${NODOCKER}"
cp "${FAKE}/sudo" "${FAKE}/systemctl" "${NODOCKER}/"
if [[ ! -e /usr/bin/docker ]]; then
  check "lab start without docker" fail learner env PATH="${NODOCKER}:/usr/bin" bash "${ROBINCTL}" lab start web
  said "points to the web profile" "sudo robinctl profile web"
  if grep -q '^sudo ' "${WORK}/out"; then
    bad "lab start without docker still asks for sudo"
  else
    ok "lab start without docker doesn't ask for sudo"
  fi
fi
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
for pair in "ipconfig:ip a" "IPCONFIG.EXE:ip a" "dir:ls -l" "tasklist:ps aux" "notepad:gnome-text-editor" \
    "calc:gnome-calculator" "eventvwr:journalctl -b" "services.msc:systemctl" "diskmgmt.msc:gnome-disks" "nslookup:getent hosts"; do
  out="$(hint "${pair%%:*}")"
  if [[ "${out}" == *"${pair#*:}"* ]]; then ok "hint for ${pair%%:*}"; else bad "hint for ${pair%%:*}: ${out}"; fi
done
out="$(hint "surely-not-a-command-xyz")"
if [[ "${out}" == *"명령을 찾을 수 없어요"* ]]; then ok "unknown commands say so"; else bad "unknown command: ${out}"; fi
# Apps the hints send people to must be installed by RobinOS
for app in gnome-text-editor nautilus mission-center fastfetch traceroute gnome-calculator gnome-disk-utility; do
  if grep -qx "${app}" "${ROOT_DIR}/packages/core.txt" "${ROOT_DIR}/packages/desktop.txt" "${ROOT_DIR}/packages/apps.txt" "${ROOT_DIR}/packages/security-baseline.txt"; then
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
