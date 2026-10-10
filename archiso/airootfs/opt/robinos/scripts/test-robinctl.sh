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
# Mission 5 finishes the Linux basics group: a desktop notification too, when there is a desktop
mkdir -p "${WORK}/fakebin"
printf '#!/bin/sh\nprintf "%%s|" "$@" >> "%s/notified"\n' "${WORK}" >"${WORK}/fakebin/notify-send"
chmod 755 "${WORK}/fakebin" "${WORK}/fakebin/notify-send"
check "5 passes with grep's output" 0 learner env WAYLAND_DISPLAY=wayland-test PATH="${WORK}/fakebin:${PATH}" bash "${ROBINCTL}" learn check 5
said "5 says the Linux basics group is done" "리눅스 기초를 끝냈어요"
grep -q '리눅스 기초를 끝냈어요|다음은 네트워크 기초예요' "${WORK}/notified" 2>/dev/null && ok "5 sends a desktop notification for the group" || bad "5 sent no group notification"
check "checking 5 again" 0 learner env WAYLAND_DISPLAY=wayland-test PATH="${WORK}/fakebin:${PATH}" bash "${ROBINCTL}" learn check 5
[[ "$(grep -o '끝냈어요' "${WORK}/notified" | wc -l)" == "1" ]] && ok "a mission already done doesn't notify again" || bad "the group notification came twice"
check "list after the first five" 0 learn
said "list counts 5 of 45" "5/45"
said "list shows the network group" "네트워크 기초"
said "list points to mission 6" "robinctl learn show 6"
# The shell's learning center (LearnCenter.qml) reads this
check "tsv for the learning center" 0 learn tsv
if [[ "$(grep -c '^mission	' "${WORK}/out")" == "45" && "$(awk -F'\t' '$1 == "mission" && $6 == 1' "${WORK}/out" | wc -l)" == "5" ]] \
    && grep -qx 'mission	6	네트워크 기초	내 IP 주소 보기	ip a	0' "${WORK}/out" && grep -qx 'ctf	0	10' "${WORK}/out" \
    && [[ "$(grep -c '^ctfitem	' "${WORK}/out")" == "10" ]] && grep -qx 'ctfitem	9	포트 뒤의 목소리	네트워크	0' "${WORK}/out"; then
  ok "tsv: 45 missions, 5 done, groups, then the CTF"
else
  bad "tsv: $(head -n 7 "${WORK}/out" | tr '\t' '|')"
fi

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
said "list counts 10 of 45" "10/45"
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
said "list counts 15 of 45" "15/45"
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

check "list after the first twenty" 0 learn
said "list counts 20 of 45" "20/45"
said "list shows the web group" "웹 기초"
said "list points to mission 21" "robinctl learn show 21"

# Web basics: show 21 writes the practice server; curl against it solves 21-25
WEB="practice/web"
WEB_PORT=18$((RANDOM % 900 + 100))
# Until the practice server answers (up to 10 s): a fixed second wasn't enough while
# an install test VM ran next to it (2026-10-10)
wait_web() {
  local i
  for i in $(seq 50); do
    curl -s -o /dev/null "http://127.0.0.1:${WEB_PORT}/" && return 0
    sleep 0.2
  done
  return 1
}
check "21 fails before the server exists" fail learn check 21
check "show 21 writes the practice server" 0 learn show 21
said "show 21 says how to start it" "python3 ~/practice/web/server.py"
embedded="$(sed -n 's/^LEARN_WEB_SERVER_B64="\(.*\)"$/\1/p' "${ROBINCTL}" | base64 -d | gzip -dc | sha256sum)"
if [[ "${embedded}" == "$(sha256sum <"${ROOT_DIR}/practice/web/server.py")" ]]; then
  ok "the server in robinctl is practice/web/server.py (run practice/web/build.sh after changing it)"
else
  bad "the server in robinctl differs from practice/web/server.py (run practice/web/build.sh)"
fi
# in_home runs "cd ~ && ...", so the server line gets its own cd: with "&" the whole
# "cd ~ && python3 ..." list would go to the background and $! would land elsewhere
in_home "true; cd ~ && { ROBIN_WEB_PORT=${WEB_PORT} python3 ${WEB}/server.py >/dev/null 2>&1 & echo \$! > ${WEB}/.test-server; }"
wait_web
URL="http://127.0.0.1:${WEB_PORT}"
in_home "curl -s ${URL}/ | grep -o 'ROBIN-[A-Z-]*' > ${WEB}/hello.txt"
check "21 passes with the code on the first page" 0 learn check 21
in_home "curl -sI ${URL}/ | grep -i '^x-robin-code' | grep -o 'ROBIN-[A-Z-]*' > ${WEB}/header.txt"
check "22 passes with the X-Robin-Code header" 0 learn check 22
in_home "curl -s ${URL}/robots.txt" | grep -q "Disallow: /secret-notes/" && ok "robots.txt names the hidden page" || bad "robots.txt doesn't name /secret-notes/"
in_home "curl -s ${URL}/secret-notes/ | grep -o 'ROBIN-[A-Z-]*' > ${WEB}/notes.txt"
check "23 passes with the code from /secret-notes/" 0 learn check 23
[[ "$(in_home "curl -s -o /dev/null -w '%{http_code}' ${URL}/me")" == "401" ]] && ok "/me without a cookie is 401" || bad "/me without a cookie isn't 401"
in_home "echo robin-practice > ${WEB}/cookie.txt"
check "24 fails with the cookie value" fail learn check 24
in_home "cd ${WEB} && curl -s -c jar.txt ${URL}/login >/dev/null && curl -s -b jar.txt ${URL}/me | grep -o 'ROBIN-[A-Z-]*' > cookie.txt"
check "24 passes with the code /me shows for the cookie" 0 learn check 24
in_home "curl -si ${URL}/old-page" | grep -q "^Location: /new-page" && ok "/old-page points to /new-page" || bad "/old-page has no Location"
in_home "curl -sL ${URL}/old-page | grep -o 'ROBIN-[A-Z-]*' > ${WEB}/redirect.txt"
check "25 passes after following the redirect" 0 learn check 25
in_home "kill \$(cat ${WEB}/.test-server)"
if ss -Htln 2>/dev/null | grep -q ":${WEB_PORT} "; then bad "the practice server is still listening"; fi

check "list after twenty-five" 0 learn
said "list counts 25 of 45" "25/45"
said "list shows the shell group" "셸 기초"

# Shell basics: answers written the way the missions ask
check "show 26 makes ~/practice/shell" 0 learn show 26
in_home "test -d practice/shell" && ok "practice/shell was made" || bad "practice/shell was not made"
in_home "echo /home/someone-else > practice/shell/home.txt"
check "26 fails with somebody else's home" fail learn check 26
in_home 'echo $HOME > practice/shell/home.txt; echo $(id -un) >> practice/shell/home.txt'
check "26 passes with \$HOME and the user name" 0 learn check 26
in_home "echo ls > practice/shell/ls-path.txt"
check "27 fails without a full path" fail learn check 27
in_home "which ls > practice/shell/ls-path.txt"
check "27 passes with which's answer" 0 learn check 27
check "28 fails without the alias" fail learn check 28
in_home "echo \"alias practice='cd ~/practice'\" >> .bashrc"
check "28 passes with the alias in ~/.bashrc" 0 learn check 28
in_home "printf '%s\n' '#!/bin/bash' 'echo '\''hi \$1'\''' > practice/shell/greet.sh && chmod +x practice/shell/greet.sh"
check "29 fails when single quotes keep \$1 as text" fail learn check 29
said "29 explains the quotes" "큰따옴표"
in_home "printf '%s\n' '#!/bin/bash' 'echo \"안녕, \$1\"' > practice/shell/greet.sh"
check "29 passes when the argument is printed" 0 learn check 29
in_home "printf '%s\n' 0 0 > practice/shell/exit-codes.txt"
check "30 fails when both codes are 0" fail learn check 30
in_home "{ ls ~ > /dev/null; echo \$?; ls /no-such-dir 2> /dev/null; echo \$?; } > practice/shell/exit-codes.txt; true"
check "30 passes with 0 and a failure code" 0 learn check 30

check "list after thirty" 0 learn
said "list counts 30 of 45" "30/45"
said "list shows the system group" "시스템 기초"

# System basics: a real background process, the disk, a service and the journal
check "show 31 makes ~/practice/system" 0 learn show 31
check "31 fails without a PID" fail learn check 31
# Started inside the learner's shell the way the mission says, with its output
# sent away so it doesn't hold this script's pipe open for 600 seconds
# (braces: in_home runs "cd ~ && ...", and a bare & would send the cd along too)
in_home "{ sleep 600 > /dev/null 2>&1 & } ; echo \$! > practice/system/sleep.pid"
sleep 0.5
check "31 passes with the running sleep's PID" 0 learn check 31
check "32 fails while the sleep still runs" fail learn check 32
kill "$(cat "${LEARNER_HOME}/practice/system/sleep.pid")" 2>/dev/null
sleep 0.5
check "32 passes once the sleep is gone" 0 learn check 32
in_home "echo 999% > practice/system/disk.txt"
check "33 fails with a made-up percentage" fail learn check 33
in_home "df --output=pcent / | tail -n 1 > practice/system/disk.txt"
check "33 passes with df's percentage" 0 learn check 33
in_home "echo nonsense > practice/system/service.txt"
check "34 fails with a made-up state" fail learn check 34
in_home "systemctl is-active NetworkManager > practice/system/service.txt; true"
check "34 passes with systemctl's answer" 0 learn check 34
in_home "echo 1.0.0 > practice/system/kernel.txt"
check "35 fails with another kernel version" fail learn check 35
in_home "uname -r > practice/system/kernel.txt"
check "35 passes with the running kernel" 0 learn check 35

check "list after thirty-five" 0 learn
said "list counts 35 of 45" "35/45"
said "list shows the security group" "보안 기초"

# Security basics: groups, a private file, an SSH key, a tampered download, encryption
check "show 36 makes ~/practice/security" 0 learn show 36
check "36 fails without groups.txt" fail learn check 36
in_home "echo wheel > practice/security/groups.txt"
check "36 fails when groups are missing" fail learn check 36
in_home "id -Gn > practice/security/groups.txt"
check "36 passes with id -Gn" 0 learn check 36
check "37 fails without secret.txt" fail learn check 37
in_home "echo memo > practice/security/secret.txt && chmod 644 practice/security/secret.txt"
check "37 fails while others can read it" fail learn check 37
in_home "chmod 600 practice/security/secret.txt"
check "37 passes with 600" 0 learn check 37
check "38 fails without a key" fail learn check 38
# The check only looks at the files, so made-up ones stand in when ssh-keygen is missing
if learner bash -c 'command -v ssh-keygen' >/dev/null 2>&1; then
  in_home "ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519"
else
  in_home "mkdir -p -m 700 .ssh && printf '%s\n' '-----BEGIN OPENSSH PRIVATE KEY-----' > .ssh/id_ed25519 && echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample learner@test' > .ssh/id_ed25519.pub && chmod 600 .ssh/id_ed25519"
fi
in_home "chmod 644 .ssh/id_ed25519"
check "38 fails while the private key is readable by others" fail learn check 38
in_home "chmod 600 .ssh/id_ed25519"
check "38 passes with the key pair" 0 learn check 38
check "39 fails before the downloads exist" fail learn check 39
check "show 39 makes the downloads" 0 learn show 39
if learner bash -c 'cd ~/practice/security/downloads && ! sha256sum --quiet -c SHA256SUMS' >/dev/null 2>&1; then
  ok "one download doesn't match SHA256SUMS"
else
  bad "every download matches SHA256SUMS"
fi
tampered="$(learner bash -c 'cd ~/practice/security/downloads && sha256sum -c SHA256SUMS 2>/dev/null | grep FAILED | cut -d: -f1')"
good="$(learner bash -c 'cd ~/practice/security/downloads && sha256sum -c SHA256SUMS 2>/dev/null | grep ": OK" | head -n 1 | cut -d: -f1')"
in_home "echo ${good} > practice/security/tampered.txt"
check "39 fails with a file that matches" fail learn check 39
in_home "echo ${tampered} > practice/security/tampered.txt"
check "39 passes with the tampered file" 0 learn check 39
check "40 fails without secret.txt.gpg" fail learn check 40
in_home "cp practice/security/secret.txt practice/security/secret.txt.gpg"
check "40 fails with a plain copy" fail learn check 40
in_home "rm practice/security/secret.txt.gpg && GNUPGHOME=\$(mktemp -d) gpg -q --batch --passphrase test --pinentry-mode loopback -c practice/security/secret.txt"
check "40 passes with gpg -c" 0 learn check 40

check "list after forty" 0 learn
said "list counts 40 of 45" "40/45"
said "list shows the text group" "텍스트 다루기"

# Text: grep -c, sort | uniq -c, awk, sed and diff on ~/practice/text
check "41 fails before the files exist" fail learn check 41
said "it says to show the mission first" "robinctl learn show 41"
check "45 fails before the files exist" fail learn check 45
said "45 says so too" "연습 파일이 아직 없어요"
check "show 41 makes ~/practice/text" 0 learn show 41
# Internet addresses in the made-up log come from the documentation ranges only
if in_home "awk '{print \$1}' practice/text/access.log | grep -Evq '^(192\.0\.2|198\.51\.100|203\.0\.113)\.'"; then
  bad "41: access.log has addresses outside RFC 5737 (docs/ethics.md)"
else
  ok "41: access.log uses documentation addresses only"
fi
in_home "echo 0 > practice/text/404.txt"
check "41 fails with a wrong count" fail learn check 41
in_home "cd practice/text && grep -c ' 404 ' access.log > 404.txt"
check "41 passes with grep -c" 0 learn check 41
in_home "cd practice/text && cut -d' ' -f1 access.log | sort | uniq -c | sort -n | head -n 1 | awk '{print \$2}' > top-ip.txt"
check "42 fails with the quietest address" fail learn check 42
in_home "cd practice/text && cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 1 | awk '{print \$2}' > top-ip.txt"
check "42 passes with sort | uniq -c | sort -rn" 0 learn check 42
in_home "cd practice/text && awk '{print \$7}' access.log | sort -u > paths.txt"
check "43 fails with every address's paths" fail learn check 43
in_home "cd practice/text && awk -v ip=\$(cat top-ip.txt) '\$1 == ip {print \$7}' access.log | sort -u > paths.txt"
check "43 passes with awk and sort -u" 0 learn check 43
in_home "cd practice/text && cp config.ini masked.ini"
check "44 fails with the passwords still there" fail learn check 44
in_home "cd practice/text && sed 's/^password=.*/password=***/' config.ini | grep -v '^#' > masked.ini"
check "44 fails when another line is gone" fail learn check 44
in_home "cd practice/text && sed 's/^password=.*/password=***/' config.ini > masked.ini"
check "44 passes with sed" 0 learn check 44
in_home "cd practice/text && head -n 1 users-old.txt > added.txt"
check "45 fails with an old user" fail learn check 45
if learner bash -c 'command -v diff' >/dev/null 2>&1; then
  in_home "cd practice/text && diff users-old.txt users-new.txt | grep '^>' > added.txt"
  check "45 passes with diff's > line" 0 learn check 45
else
  # The same "> name" line diff would give
  in_home "cd practice/text && comm -13 users-old.txt users-new.txt | sed 's/^/> /' > added.txt"
  check "45 passes with a diff-style > line" 0 learn check 45
fi
in_home "cd practice/text && comm -13 users-old.txt users-new.txt > added.txt"
check "45 passes with comm -13" 0 learn check 45

check "list after all forty-five" 0 learn
said "list says all forty-five are done" "45/45"
said "list points to the CTF" "robinctl ctf"
check "show 45" 0 learn show 45
check "mission 46 doesn't exist" fail learn show 46

printf '%s\n' "Local CTF (robinctl ctf): each challenge solved the way its hints say"
CTF="practice/ctf"
ctf_submit() { learner bash "${ROBINCTL}" ctf submit "$1" "$2"; }
check "ctf list makes the challenge files" 0 learner bash "${ROBINCTL}" ctf
said "ctf list counts 0 of 10" "0/10"
check "ctf show 4" 0 learner bash "${ROBINCTL}" ctf show 4
check "challenge 11 doesn't exist" fail learner bash "${ROBINCTL}" ctf show 11
check "a wrong flag fails" fail ctf_submit 1 'ROBIN{nope}'
check "a flag without ROBIN{} fails" fail ctf_submit 1 'hello'
said "the shape of a flag is explained" "ROBIN{...}"
in_home "ls ${CTF}/1" | grep -q flag && bad "challenge 1 shows its flag to plain ls" || ok "challenge 1 hides its flag from plain ls"
check "1: the flag in the hidden folders" 0 ctf_submit 1 "$(in_home "find ${CTF}/1 -name '.flag' -exec cat {} +")"
check "2: base64 twice" 0 ctf_submit 2 "$(in_home "base64 -d ${CTF}/2/note.txt | base64 -d")"
odd="$(in_home "grep -v ' 200 ' ${CTF}/3/access.log | grep -oE 'q=[0-9a-f]{20,}' | cut -d= -f2")"
check "3: the hex in the odd log line" 0 ctf_submit 3 "$(python3 -c 'import sys; print(bytes.fromhex(sys.argv[1]).decode())' "${odd}")"
cat >"${WORK}/brute.py" <<'PY'
import hashlib, re, sys
wanted = re.search(r'PIN_SHA256 = "([0-9a-f]+)"', open(sys.argv[1]).read()).group(1)
print(next(f"{i:04d}" for i in range(10000) if hashlib.sha256(f"{i:04d}".encode()).hexdigest() == wanted))
PY
chmod 644 "${WORK}/brute.py"
pin="$(in_home "python3 ${WORK}/brute.py ${CTF}/4/lock.py")"
in_home "python3 ${CTF}/4/lock.py 0000; true" | grep -q "틀렸어요" && ok "4: a wrong PIN stays locked" || bad "4: a wrong PIN opened the lock"
check "4: the PIN found from its hash" 0 ctf_submit 4 "$(in_home "python3 ${CTF}/4/lock.py ${pin}" | grep -o 'ROBIN{[^}]*}')"
in_home "true; cd ~ && { ROBIN_WEB_PORT=${WEB_PORT} python3 ${WEB}/server.py >/dev/null 2>&1 & echo \$! > ${WEB}/.test-server; }"
wait_web
[[ "$(in_home "curl -s -o /dev/null -w '%{http_code}' ${URL}/ctf/admin")" == "403" ]] && ok "5: /ctf/admin is 403 for a guest" || bad "5: /ctf/admin isn't 403 for a guest"
in_home "curl -si ${URL}/ctf" | grep -q "Set-Cookie: role=guest" && ok "5: /ctf hands out role=guest" || bad "5: /ctf gives no role cookie"
check "5: role=admin in the cookie" 0 ctf_submit 5 "$(in_home "curl -s -b 'role=admin' ${URL}/ctf/admin" | grep -o 'ROBIN{[^}]*}')"
in_home "kill \$(cat ${WEB}/.test-server)"
decoys="$(in_home "cat ${CTF}/6/tool-*.bin" | grep -c 'ROBIN{')"
[[ "${decoys}" == "12" ]] && ok "6: all twelve downloads carry a flag-shaped line" || bad "6: ${decoys} flag-shaped lines, not 12"
tampered="$(in_home "cd ${CTF}/6 && sha256sum -c SHA256SUMS 2>/dev/null | grep FAILED | cut -d: -f1")"
[[ "$(printf '%s\n' "${tampered}" | grep -c .)" == "1" ]] && ok "6: exactly one download fails sha256sum -c" || bad "6: failing downloads: ${tampered}"
check "6: the flag in the file that fails sha256sum -c" 0 ctf_submit 6 "$(in_home "grep -o 'ROBIN{[^}]*}' ${CTF}/6/${tampered}")"
in_home "cat ${CTF}/7/vault.txt" >/dev/null 2>&1 && bad "7: the vault reads without chmod" || ok "7: the vault can't be read at first"
check "7: chmod, then the flag" 0 ctf_submit 7 "$(in_home "chmod 600 ${CTF}/7/vault.txt && cat ${CTF}/7/vault.txt")"
if learner bash -c 'command -v gpg' >/dev/null 2>&1; then
  cat >"${WORK}/dict.sh" <<'SH'
cd ~/practice/ctf/8 || exit 1
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
for p in $(cat passwords.txt); do
  gpg --batch --quiet --pinentry-mode loopback --passphrase "$p" -d note.txt.gpg 2>/dev/null && break
done
gpgconf --kill gpg-agent >/dev/null 2>&1
rm -rf "${GNUPGHOME}"
SH
  chmod 644 "${WORK}/dict.sh"
  check "8: the password found from the list" 0 ctf_submit 8 "$(learner bash "${WORK}/dict.sh" | grep -o 'ROBIN{[^}]*}')"
else
  ok "8: skipped, no gpg here"
fi
check "show 9 starts the server" 0 learner bash "${ROBINCTL}" ctf show 9
sleep 1
# Like ss -tln would show: whatever answers on 127.0.0.1:4000-4999
door="$(python3 - <<'PY'
import socket
for port in range(4000, 5000):
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.2) as conn:
            data = conn.recv(200).decode(errors="replace")
            if "ROBIN{" in data:
                print(data)
                break
    except OSError:
        pass
PY
)"
check "9: the flag from the port on 127.0.0.1" 0 ctf_submit 9 "$(printf '%s' "${door}" | grep -o 'ROBIN{[^}]*}')"
check "show 9 again keeps the same server" 0 learner bash "${ROBINCTL}" ctf show 9
[[ "$(in_home "pgrep -c -f 'ctf-[d]oor.py'")" == "1" ]] && ok "9: one server, not two" || bad "9: the server was started twice"
in_home "kill \$(cut -d' ' -f2 ~/.local/state/robinos/ctf/door)"
# It goes away on its own after its time (an hour; 2 seconds here), visitors or not
in_home "echo 'ROBIN{t}' | python3 ~/.local/state/robinos/ctf/ctf-door.py 4999 2 & echo \$! > ~/door-pid"
sleep 1
in_home "python3 -c 'import socket; print(socket.create_connection((\"127.0.0.1\", 4999), 1).recv(200).decode())'" \
  | grep -q 'ROBIN{t}' && ok "9: the server answers while it's up" || bad "9: the short-lived server didn't answer"
sleep 2.5
in_home "kill -0 \$(cat ~/door-pid) 2>/dev/null" && bad "9: the server outlived its time" || ok "9: the server stops after its time"
in_home "kill \$(cat ~/door-pid) 2>/dev/null; rm -f ~/door-pid"
in_home "file -b ${CTF}/10/photo.png" | grep -q '^PNG image data' && ok "10: photo.png is a PNG" || bad "10: photo.png isn't a PNG"
check "10: the zip glued to the photo" 0 ctf_submit 10 "$(in_home "python3 -m zipfile -e ${CTF}/10/photo.png ${CTF}/10/out && cat ${CTF}/10/out/secret.txt")"
check "ctf list after all ten" 0 learner bash "${ROBINCTL}" ctf
said "ctf list says 10 of 10" "10/10"
check "ctf reset" 0 learner bash "${ROBINCTL}" ctf reset
in_home "rm ${CTF}/2/note.txt"
check "ctf show after a deleted file" 0 learner bash "${ROBINCTL}" ctf show 2
in_home "test -s ${CTF}/2/note.txt" && ok "a deleted challenge file is made again" || bad "a deleted challenge file stays gone"
qml_total="$(grep -oE 'learnTotal: [0-9]+' "${ROOT_DIR}/desktop/shell/ShellState.qml" | grep -oE '[0-9]+$')"
if [[ "${qml_total}" == "$(grep -oE '^readonly LEARN_COUNT=[0-9]+' "${ROBINCTL}" | grep -oE '[0-9]+$')" ]]; then
  ok "the shell's mission count (learnTotal) matches LEARN_COUNT"
else
  bad "ShellState.qml learnTotal (${qml_total}) differs from LEARN_COUNT in robinctl"
fi
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

printf '%s\n' "audit: the security check reads without changing anything"
check "audit runs as an ordinary user" 0 learner bash "${ROBINCTL}" audit
said "audit looks at services other computers can reach" "밖에서 닿는 서비스"
said "audit looks at sshd" "SSH 서버(sshd)"
said "audit ends with a count or an all-clear" "살펴볼"
# The test's home is chmod 777 (root owns it, so the learner can't tighten it)
said "audit says the home folder is open to others" "홈 폴더 권한이 777"

printf '%s\n' "app remove: RobinOS's own apps stay, others go through pacman"
APPS="${WORK}/apps"
mkdir -p "${APPS}"
printf '[Desktop Entry]\nName=Foot\n' >"${APPS}/foot.desktop"
printf '[Desktop Entry]\nName=Writer\n' >"${APPS}/libreoffice-writer.desktop"
app_remove() { ROBINOS_NO_FLATPAK=1 ROBINOS_APP_DIRS="${APPS}" ROBINOS_APP_OWNER="$1" bash "${ROBINCTL}" app remove "$2" --dry-run; }
check "the terminal (foot, core list) can't be removed" fail app_remove foot foot
said "it says why" "기본 구성에 들어 있는 앱"
check "LibreOffice (apps.txt) can" 0 app_remove libreoffice-still libreoffice-writer
said "it shows the pacman command" "sudo pacman -Rns libreoffice-still"
check "an app that isn't there" fail app_remove x nope
check "an id with a path in it" fail bash "${ROBINCTL}" app remove ../etc/passwd

printf '%s\n' "doctor: NVIDIA cards on a stand-in /sys/bus/pci/devices"
pci_dev() {
  mkdir -p "$1"
  printf '%s\n' "$2" >"$1/vendor"
  printf '%s\n' "$3" >"$1/device"
  printf '%s\n' "$4" >"$1/class"
}
PCI="${WORK}/pci"
pci_dev "${PCI}/none/0000:00:02.0" 0x8086 0x9bc4 0x030000
check "doctor without an NVIDIA card" 0 env ROBINOS_PCI_DEVICES="${PCI}/none" bash "${ROBINCTL}" doctor
if grep -q "NVIDIA" "${WORK}/out"; then bad "doctor talks about NVIDIA without a card"; else ok "no NVIDIA line without a card"; fi
pci_dev "${PCI}/rtx/0000:01:00.0" 0x10de 0x2504 0x030000
pci_dev "${PCI}/rtx/0000:01:00.1" 0x10de 0x228e 0x040300
if ! pacman -Q nvidia-open >/dev/null 2>&1; then
  check "doctor with an RTX card and no driver" 0 env ROBINOS_PCI_DEVICES="${PCI}/rtx" ROBINOS_NVIDIA_MODULE="${WORK}/no-module" bash "${ROBINCTL}" doctor
  said "doctor says how to install nvidia-open" "sudo pacman -S nvidia-open"
fi
mkdir -p "${WORK}/module"
check "doctor with the driver loaded" 0 env ROBINOS_PCI_DEVICES="${PCI}/rtx" ROBINOS_NVIDIA_MODULE="${WORK}/module" bash "${ROBINCTL}" doctor
said "doctor says the driver is in use" "드라이버(nvidia-open)를 쓰고 있어요"
pci_dev "${PCI}/old/0000:01:00.0" 0x10de 0x1c03 0x030000
check "doctor with a GTX 10 card" 0 env ROBINOS_PCI_DEVICES="${PCI}/old" bash "${ROBINCTL}" doctor
said "doctor says old cards keep nouveau" "nouveau"

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

printf '%s\n' "RobinOS repository (robinctl repo) with the stand-in pacman"
check "repo status" 0 env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" repo
said "status says the files aren't a package yet" "아직 패키지가 아니에요"
check "repo setup dry run" 0 env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" repo setup --dry-run
said "setup adds the release key" "keys/robinos-release.asc"
key_fpr="$(gpg --batch --show-keys --with-colons "${ROOT_DIR}/keys/robinos-release.asc" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
said "setup trusts the release key's fingerprint (${key_fpr:-no gpg})" "pacman-key --lsign-key ${key_fpr:-?}"
touch "${WORK}/robinos-0.3.0.r1-1-any.pkg.tar.zst"
check "repo adopt dry run with a package file" 0 env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" repo adopt --dry-run "${WORK}/robinos-0.3.0.r1-1-any.pkg.tar.zst"
said "adopt overwrites only the existing RobinOS files" "--overwrite <이미 있는 RobinOS 파일>"
check "repo adopt with a missing file" fail env PATH="${UPDATE_BIN}:/usr/bin" bash "${ROBINCTL}" repo adopt --dry-run "${WORK}/nothing.pkg.tar.zst"

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

# Network scan lab: same sudo path, nothing published on the host, nothing restarts
NET_COMPOSE="${ROOT_DIR}/labs/net/docker-compose.yml"
check "net lab start as a user" 0 learner env PATH="${FAKE}:/usr/bin" bash "${ROBINCTL}" lab start net
said "net lab runs its own compose file" "sudo docker compose -f ${NET_COMPOSE} up -d"
said "net lab names its network" "172.30.66.0/24"
said "net lab reminds to stop it" "robinctl lab stop net"
check "net lab info" 0 bash "${ROBINCTL}" lab info net
said "net lab info teaches host discovery" "nmap -sn 172.30.66.0/24"
said "net lab info points to the ethics rules" "docs/ethics.md"
check "an unknown lab fails" fail learner env PATH="${FAKE}:/usr/bin" bash "${ROBINCTL}" lab start nope
if grep -qE '^\s*ports:' "${NET_COMPOSE}"; then bad "the net lab publishes host ports"; else ok "the net lab publishes no host ports"; fi
if [[ "$(grep -cE '^\s+restart: "no"' "${NET_COMPOSE}")" == "4" ]] && ! grep -q 'unless-stopped\|always' "${NET_COMPOSE}"; then
  ok "net lab containers don't restart on boot"
else
  bad "net lab containers may restart on boot"
fi

printf '%s\n' "Windows command hints (robinos-hints.sh)"
# Calls the not-found handler directly: running "ipconfig" or "notepad" for real
# would start the Windows programs through WSL's interop
hint() { bash -c ". '${HINTS}'; command_not_found_handle '$1'" 2>&1; }
for pair in "ipconfig:ip a" "IPCONFIG.EXE:ip a" "dir:ls -l" "tasklist:ps aux" "notepad:gnome-text-editor" \
    "calc:gnome-calculator" "taskmgr:missioncenter" "start:xdg-open" "clip:wl-copy" "powercfg:powerprofilesctl" "ncpa.cpl:nmtui" "doskey:alias" "eventvwr:journalctl -b" "services.msc:systemctl" "diskmgmt.msc:gnome-disks" "nslookup:getent hosts" \n    "certutil:sha256sum" "cipher:gpg -c" "runas:sudo" "netsh:nmcli" "sc:systemctl status"; do
  out="$(hint "${pair%%:*}")"
  if [[ "${out}" == *"${pair#*:}"* ]]; then ok "hint for ${pair%%:*}"; else bad "hint for ${pair%%:*}: ${out}"; fi
done
out="$(hint "surely-not-a-command-xyz")"
if [[ "${out}" == *"명령을 찾을 수 없어요"* ]]; then ok "unknown commands say so"; else bad "unknown command: ${out}"; fi
# Apps the hints send people to must be installed by RobinOS
for app in gnome-text-editor nautilus mission-center fastfetch traceroute gnome-calculator gnome-disk-utility \
    wl-clipboard xdg-utils power-profiles-daemon networkmanager loupe efibootmgr which baobab; do
  if grep -qx "${app}" "${ROOT_DIR}/packages/core.txt" "${ROOT_DIR}/packages/desktop.txt" "${ROOT_DIR}/packages/apps.txt" "${ROOT_DIR}/packages/security-baseline.txt"; then
    ok "hinted app ${app} is in a package list"
  else
    bad "hinted app ${app} is in no package list"
  fi
done

printf '%s\n' "Prompt and greeting (robinos-bashrc.sh), os-release, version"
BASHRC="${ROOT_DIR}/desktop/bash/robinos-bashrc.sh"
# PS1 after a command; an interactive bash without a terminal grumbles on stderr
prompt_after() { ROBINOS_NO_GREETING=1 bash --norc -ic ". '${BASHRC}'; $1; __robinos_prompt; printf '%s' \"\$PS1\"" 2>/dev/null; }
mark='>'
((EUID == 0)) && mark='#'
out="$(prompt_after true)"
if [[ "${out}" == *'\w'*"m\\]${mark}\\["* && "${out}" != *'m\]1\['* ]]; then ok "prompt ends in ${mark} without an exit code"; else bad "prompt after true: ${out}"; fi
out="$(prompt_after false)"
if [[ "${out}" == *'m\]1\['*"m\\]${mark}\\["* ]]; then ok "a failed command's exit code shows before ${mark}"; else bad "prompt after false: ${out}"; fi
out="$(ROBINOS_NO_GREETING=1 bash --norc -ic ". '${BASHRC}'; . '${BASHRC}'; printf '%s' \"\${PROMPT_COMMAND}\"" 2>/dev/null)"
if [[ "${out}" == "__robinos_prompt" ]]; then ok "sourcing twice keeps one prompt hook, no greeting"; else bad "PROMPT_COMMAND / greeting: ${out}"; fi
if grep -qF "robinos-bashrc.sh" "${ROOT_DIR}/desktop/bash/bashrc" "${ROOT_DIR}/scripts/post-install.sh"; then ok "/etc/skel/.bashrc and post-install.sh source it"; else bad "robinos-bashrc.sh is sourced nowhere"; fi
ROBINOS_OS_RELEASE="${WORK}/os-release" "${ROOT_DIR}/desktop/bin/robinos-os-release"
if (. "${WORK}/os-release" && [[ "${NAME}" == "RobinOS" && "${ID}" == "robinos" && "${ID_LIKE}" == "arch" ]]); then ok "os-release names RobinOS, like arch"; else bad "os-release: $(cat "${WORK}/os-release")"; fi
for config in config/robinos.toml archiso/airootfs/etc/robinos/config.toml; do
  [[ -f "${ROOT_DIR}/${config}" ]] || continue
  config_version="$(sed -n 's/^version = "\(.*\)"$/\1/p' "${ROOT_DIR}/${config}")"
  if [[ "$("${ROBINCTL}" version)" == "RobinOS ${config_version}" ]]; then ok "robinctl version matches ${config} (${config_version})"; else bad "robinctl version $("${ROBINCTL}" version) vs ${config} ${config_version}"; fi
done

if [[ "${failures}" -gt 0 ]]; then
  printf 'robinctl tests: %d failed\n' "${failures}"
  exit 1
fi
printf 'robinctl tests: all passed\n'
