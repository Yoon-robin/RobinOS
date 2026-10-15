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

printf '%s\n' "snapshot booted: the snapshot the boot menu started, from the kernel line"
SNAPS="${WORK}/snaps"
mkdir -p "${SNAPS}/7"
printf '<snapshot><description>pacman -S cowsay</description></snapshot>\n' >"${SNAPS}/7/info.xml"
printf 'BOOT_IMAGE=/@/boot/vmlinuz-linux root=UUID=x rw rootflags=subvol=@\n' >"${WORK}/cmdline-normal"
printf 'BOOT_IMAGE=/@snapshots/7/snapshot/boot/vmlinuz-linux root=UUID=x rw rootflags=subvol=@snapshots/7/snapshot\n' >"${WORK}/cmdline-snap"
booted() { ROBINOS_CMDLINE="${WORK}/cmdline-$1" ROBINOS_SNAPSHOT_DIR="${SNAPS}" bash "${ROBINCTL}" snapshot booted; }
check "a normal start is no snapshot" fail booted normal
check "a snapshot start gives its number" 0 booted snap
said "with its description" "pacman -S cowsay"

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

printf '%s\n' "Update preview (T-162) with stand-in checkupdates, pacman and busctl"
PREVIEW_BIN="${WORK}/preview-bin"
mkdir -p "${PREVIEW_BIN}"
printf '#!/bin/sh\nprintf "linux 7.2.9-1 -> 7.3.0-1\\nfirefox 157.0.1-1 -> 158.0-1\\n"\n' >"${PREVIEW_BIN}/checkupdates"
# pacman -Sup --print-format %%s: download sizes in bytes (150 MiB together)
printf '#!/bin/sh\nprintf "104857600\\n52428800\\n"\n' >"${PREVIEW_BIN}/pacman"
printf '#!/bin/sh\necho "u 4"\n' >"${PREVIEW_BIN}/busctl"
chmod 755 "${PREVIEW_BIN}"/*
check "update preview" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --preview
said "preview counts the updates" "업데이트 2개"
said "preview gives the download size" "받을 크기 150MB"
said "preview says the kernel changes" "커널이 바뀌어요"
if grep -q "데이터 요금" "${WORK}/out"; then bad "preview warns on an unmetered connection"; else ok "no metered warning on Wi-Fi"; fi
printf '#!/bin/sh\necho "u 1"\n' >"${PREVIEW_BIN}/busctl"
check "update preview on a metered connection" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --preview
said "preview warns about a metered connection" "데이터 요금이 드는 연결"
# At a terminal too (a person, or wsl.exe started from a PowerShell window) the preview
# only warns: it used to ask and wait for an answer, which kept the all-in-one check on
# a school PC waiting for hours behind a question it never showed (2026-10-15)
if command -v script >/dev/null 2>&1; then
  timeout 20 script -qec "env PATH='${PREVIEW_BIN}:/usr/bin' bash '${ROBINCTL}' update --preview" /dev/null < <(sleep 5) >"${WORK}/out" 2>&1
  if grep -q "받을까요" "${WORK}/out"; then bad "preview at a terminal asks on a metered connection"; else ok "preview at a terminal only warns"; fi
fi
printf '#!/bin/sh\nexit 2\n' >"${PREVIEW_BIN}/checkupdates"
check "update preview with nothing new" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --preview
said "preview says everything is current" "모두 최신이에요"
# checkupdates exits 1 when it cannot look: that is not "up to date"
printf '#!/bin/sh\nexit 1\n' >"${PREVIEW_BIN}/checkupdates"
check "update preview when checkupdates fails" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --preview
said "a failed look is not called up to date" "확인하지 못했어요"
if grep -q "모두 최신이에요" "${WORK}/out"; then bad "a failed look says everything is current"; else ok "a failed look doesn't say everything is current"; fi

printf '%s\n' "Update status for the settings app (robinctl update --status)"
# One JSON line; json_is <description> <key> <value> reads the last check's output
json_is() {
  local got
  got="$(python3 -c 'import json,sys; v = json.loads(open(sys.argv[1]).read().strip().splitlines()[-1])[sys.argv[2]]; print(str(v).lower() if isinstance(v, bool) else v)' "${WORK}/out" "$2" 2>&1)"
  if [[ "${got}" == "$3" ]]; then ok "$1"; else bad "$1: ${2} is \"${got}\", not \"$3\""; fi
}
printf '#!/bin/sh\nprintf "linux 7.2.9-1 -> 7.3.0-1\\nfirefox 157.0.1-1 -> 158.0-1\\n"\n' >"${PREVIEW_BIN}/checkupdates"
printf '#!/bin/sh\necho "u 4"\n' >"${PREVIEW_BIN}/busctl"
check "update status with updates" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --status
json_is "status: there are updates" state updates
json_is "status: two of them" count 2
json_is "status: 150 MB to download" bytes 157286400
json_is "status: the kernel changes" kernel true
json_is "status: not metered" metered false
printf '#!/bin/sh\necho "u 1"\n' >"${PREVIEW_BIN}/busctl"
check "update status on a metered connection" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --status
json_is "status: metered" metered true
printf '#!/bin/sh\nexit 2\n' >"${PREVIEW_BIN}/checkupdates"
check "update status with nothing new" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --status
json_is "status: up to date" state current
json_is "status: no updates" count 0
json_is "status: no kernel change" kernel false
printf '#!/bin/sh\nexit 1\n' >"${PREVIEW_BIN}/checkupdates"
check "update status when checkupdates fails" 0 env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --status
json_is "status: it could not look, which isn't up to date" state unknown
check "update refuses an option it doesn't know" fail env PATH="${PREVIEW_BIN}:/usr/bin" bash "${ROBINCTL}" update --frobnicate

printf '%s\n' "The shell starts again after an update brought new RobinOS files"
# A pacman that keeps its own version of robinos in a file and "installs" a new one on -Syu
RESTART_BIN="${WORK}/restart-bin"
mkdir -p "${RESTART_BIN}"
printf '0.3.0.r1-1\n' >"${WORK}/robinos-version"
cat >"${RESTART_BIN}/pacman" <<EOF
#!/bin/sh
case "\$*" in
  "-Q robinos") [ -f '${WORK}/robinos-version' ] || exit 1; echo "robinos \$(cat '${WORK}/robinos-version')" ;;
  *-Sy) echo "pacman \$*" >>'${WORK}/pacman-calls'
    # A list that can't be reached: the [robinos] one (GitHub), or every one
    [ -f '${WORK}/all-down' ] && exit 1
    [ -f '${WORK}/github-down' ] && grep -q '^\[robinos\]' "\$2" && exit 1
    exit 0 ;;
  *-Su*) echo "pacman \$*" >>'${WORK}/pacman-calls'; cp "\$2" '${WORK}/su-conf'
    [ -f '${WORK}/new-version' ] && cp '${WORK}/new-version' '${WORK}/robinos-version'; exit 0 ;;
  *) exit 1 ;;
esac
EOF
printf '#!/bin/sh\nexit 2\n' >"${RESTART_BIN}/checkupdates"
printf '#!/bin/sh\necho 4242\n' >"${RESTART_BIN}/pgrep"
printf '#!/bin/sh\necho "pkill $*" >>"%s/pkill-calls"\n' "${WORK}" >"${RESTART_BIN}/pkill"
chmod 755 "${RESTART_BIN}"/*
if [[ "${EUID}" -eq 0 ]]; then
  : >"${WORK}/pkill-calls"
  rm -f "${WORK}/new-version"
  check "an update with no new RobinOS files" 0 env SUDO_USER=learner PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  if [[ -s "${WORK}/pkill-calls" ]]; then bad "the shell was ended without new RobinOS files"; else ok "the shell stays when nothing changed"; fi
  if grep -q -- '-Su --noconfirm$' "${WORK}/pacman-calls"; then ok "update passes --yes on to pacman"; else bad "pacman didn't get --noconfirm: $(cat "${WORK}/pacman-calls")"; fi
  printf '0.3.0.r2-1\n' >"${WORK}/new-version"
  check "an update that brings new RobinOS files" 0 env SUDO_USER=learner PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  said "it tells which versions" "0.3.0.r1-1에서 0.3.0.r2-1로"
  if grep -qx 'pkill -u learner -x qs' "${WORK}/pkill-calls"; then ok "the person's shell is ended so it comes back new"; else bad "pkill wasn't called for the person's shell: $(cat "${WORK}/pkill-calls")"; fi
  : >"${WORK}/pkill-calls"
  printf '0.3.0.r2-1\n' >"${WORK}/robinos-version"
  printf '0.3.0.r3-1\n' >"${WORK}/new-version"
  check "the same as plain root, without sudo" 0 env -u SUDO_USER PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  said "without a user it says to log in again" "다시 로그인"
  if [[ -s "${WORK}/pkill-calls" ]]; then bad "the shell was ended without a known user"; else ok "no shell is ended without a user"; fi
  # Files copied without the package (a checkout, an older install): pacman -Q robinos
  # fails, which under pipefail used to end the update before pacman -Syu
  rm -f "${WORK}/robinos-version" "${WORK}/new-version"
  : >"${WORK}/pacman-calls"
  check "an update without the robinos package" 0 env SUDO_USER=learner PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  if grep -q -- '-Su' "${WORK}/pacman-calls"; then ok "pacman -Syu runs without the robinos package"; else bad "pacman -Syu didn't run without the robinos package"; fi
  # GitHub (the RobinOS repository) can't be reached: Arch's updates still come
  printf '[options]\nHoldPkg = pacman\n\n[core]\nInclude = /etc/pacman.d/mirrorlist\n\n# RobinOS\n[robinos]\nSigLevel = Required DatabaseRequired\nServer = https://github.com/Yoon-robin/RobinOS/releases/download/repo\n\n[extra]\nInclude = /etc/pacman.d/mirrorlist\n' >"${WORK}/pacman.conf"
  touch "${WORK}/github-down"
  : >"${WORK}/pacman-calls"
  rm -f "${WORK}/su-conf"
  check "an update while GitHub can't be reached" 0 env SUDO_USER=learner ROBINOS_PACMAN_CONF="${WORK}/pacman.conf" PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  said "it says RobinOS files come next time" "RobinOS 파일은 다음 업데이트 때 받아요"
  if [[ -f "${WORK}/su-conf" ]] && ! grep -q '^\[robinos\]' "${WORK}/su-conf" && grep -q '^\[core\]' "${WORK}/su-conf" && grep -q '^\[extra\]' "${WORK}/su-conf"; then
    ok "Arch's packages update without the RobinOS repository"
  else
    bad "the update without GitHub used: $(cat "${WORK}/su-conf" 2>/dev/null || echo nothing)"
  fi
  if grep -q "${WORK}/pacman.conf -Su" "${WORK}/pacman-calls"; then bad "-Su ran with the full pacman.conf"; else ok "pacman.conf itself is left alone"; fi
  touch "${WORK}/all-down"
  : >"${WORK}/pacman-calls"
  check "an update with no internet at all fails" fail env SUDO_USER=learner ROBINOS_PACMAN_CONF="${WORK}/pacman.conf" PATH="${RESTART_BIN}:/usr/bin" bash "${ROBINCTL}" update --yes
  said "it says to check the connection" "인터넷 연결을 확인해 주세요"
  if grep -q -- '-Su' "${WORK}/pacman-calls"; then bad "-Su ran without any package lists"; else ok "nothing is installed without the lists"; fi
  rm -f "${WORK}/github-down" "${WORK}/all-down"
fi

printf '%s\n' "Idle suspend (robinos-idle-suspend): a laptop on battery sleeps, nothing else does"
IDLE_BIN="${WORK}/idle-bin"
mkdir -p "${IDLE_BIN}"
printf '#!/bin/sh\necho "systemctl $*" >>"%s/idle-calls"\n' "${WORK}" >"${IDLE_BIN}/systemctl"
chmod 755 "${IDLE_BIN}/systemctl"
# supply <dir> <name> <type> [online] [scope]
supply() {
  mkdir -p "$1/$2"
  printf '%s\n' "$3" >"$1/$2/type"
  [[ -n "${4:-}" ]] && printf '%s\n' "$4" >"$1/$2/online"
  [[ -n "${5:-}" ]] && printf '%s\n' "$5" >"$1/$2/scope"
  return 0
}
# idle_case <description> <sleeps: yes|no> <dir>
idle_case() {
  : >"${WORK}/idle-calls"
  PATH="${IDLE_BIN}:${PATH}" ROBINOS_POWER_SUPPLY="$3" bash "${ROOT_DIR}/desktop/bin/robinos-idle-suspend"
  if grep -qx 'systemctl suspend' "${WORK}/idle-calls"; then got=yes; else got=no; fi
  if [[ "${got}" == "$2" ]]; then ok "$1"; else bad "$1: sleeps=${got}"; fi
}
supply "${WORK}/p1" BAT0 Battery
supply "${WORK}/p1" AC Mains 0
idle_case "a laptop on battery sleeps" yes "${WORK}/p1"
supply "${WORK}/p2" BAT0 Battery
supply "${WORK}/p2" AC Mains 1
idle_case "a laptop on the charger stays awake" no "${WORK}/p2"
supply "${WORK}/p3" AC Mains 1
idle_case "a PC without a battery stays awake" no "${WORK}/p3"
mkdir -p "${WORK}/p4"
idle_case "no power supplies at all (a VM) stays awake" no "${WORK}/p4"
supply "${WORK}/p5" hidpp_battery_0 Battery "" Device
idle_case "a wireless mouse's battery is no laptop" no "${WORK}/p5"
supply "${WORK}/p6" BAT1 Battery
supply "${WORK}/p6" ucsi-source-psy USB_PD 1
idle_case "a laptop charged over USB-C stays awake" no "${WORK}/p6"
supply "${WORK}/p7" BAT0 Battery
supply "${WORK}/p7" ucsi-source-psy USB_PD 0
supply "${WORK}/p7" ACAD Mains 0
supply "${WORK}/p7" hidpp_battery_0 Battery "" Device
idle_case "a laptop on battery with a mouse around sleeps" yes "${WORK}/p7"
supply "${WORK}/p8" BAT0 Battery
printf '0\n' >"${WORK}/p8/BAT0/present"
idle_case "a desktop whose firmware reports an empty battery slot stays awake" no "${WORK}/p8"
supply "${WORK}/p9" BAT0 Battery
printf 'Charging\n' >"${WORK}/p9/BAT0/status"
idle_case "a laptop that shows the charger only on the battery stays awake" no "${WORK}/p9"
supply "${WORK}/p10" BAT0 Battery
supply "${WORK}/p10" AC Mains 0
printf '1\n' >"${WORK}/p10/BAT0/present"
printf 'Discharging\n' >"${WORK}/p10/BAT0/status"
idle_case "a laptop that says it is discharging sleeps" yes "${WORK}/p10"

printf '%s\n' "UPower's battery action (packaging/robinos/robinos.install)"
upower_case() {
  printf '# comment\nCriticalPowerAction=%s\n' "$2" >"${WORK}/UPower.conf"
  (. "${ROOT_DIR}/packaging/robinos/robinos.install" && robinos_upower_conf "${WORK}/UPower.conf")
  if grep -qx "CriticalPowerAction=$3" "${WORK}/UPower.conf"; then ok "$1"; else bad "$1: $(grep CriticalPowerAction "${WORK}/UPower.conf")"; fi
}
upower_case "UPower 1.91's default (Auto) becomes PowerOff" Auto PowerOff
upower_case "the older default (HybridSleep) becomes PowerOff" HybridSleep PowerOff
upower_case "a person's Hibernate stays" Hibernate Hibernate
upower_case "PowerOff stays PowerOff" PowerOff PowerOff
(. "${ROOT_DIR}/packaging/robinos/robinos.install" && robinos_upower_conf "${WORK}/no-such-UPower.conf") && ok "no UPower.conf: nothing to do" || bad "a missing UPower.conf is an error"

printf '%s\n' "Screen recording (robinos-screenshot record): the bar's red dot follows the recorder"
REC_BIN="${WORK}/rec-bin"
REC_RUN="${WORK}/rec-run"
mkdir -p "${REC_BIN}" "${REC_RUN}"
printf '#!/bin/sh\necho "qs $*" >>"%s/rec-calls"\n' "${WORK}" >"${REC_BIN}/qs"
printf '#!/bin/sh\necho "notify $*" >>"%s/rec-calls"\n' "${WORK}" >"${REC_BIN}/notify-send"
printf '#!/bin/sh\necho "[]"\n' >"${REC_BIN}/hyprctl"
printf '#!/bin/sh\necho "%s"\n' "${WORK}" >"${REC_BIN}/xdg-user-dir"
chmod 755 "${REC_BIN}"/*
record() { env PATH="${REC_BIN}:/usr/bin" XDG_RUNTIME_DIR="${REC_RUN}" HOME="${WORK}" bash "${ROOT_DIR}/desktop/bin/robinos-screenshot" record >/dev/null 2>&1; }
# A wf-recorder that can't capture the screen and gives up at once
printf '#!/bin/sh\necho "failed to capture" >&2\nexit 1\n' >"${REC_BIN}/wf-recorder"
chmod 755 "${REC_BIN}/wf-recorder"
: >"${WORK}/rec-calls"
record
if grep -q 'setRecording true' "${WORK}/rec-calls"; then bad "the red dot shows for a recorder that gave up"; else ok "no red dot when the recorder gives up"; fi
if grep -q '녹화하지 못했어요' "${WORK}/rec-calls" && [[ ! -e "${REC_RUN}/robinos-record.pid" ]]; then ok "it says the recording failed, nothing is left behind"; else bad "no failure notice, or a pid file was left: $(cat "${WORK}/rec-calls")"; fi
# A recording that died on its own: the next press clears the dot instead of starting again
printf '999999\n%s/x.mp4\n' "${WORK}" >"${REC_RUN}/robinos-record.pid"
: >"${WORK}/rec-calls"
record
if grep -q 'setRecording false' "${WORK}/rec-calls" && grep -q '중간에 멈췄어요' "${WORK}/rec-calls" && [[ ! -e "${REC_RUN}/robinos-record.pid" ]]; then
  ok "a recording that died: the press clears the dot and says so"
else
  bad "a recording that died: $(cat "${WORK}/rec-calls")"
fi
# A recorder that keeps going: the dot shows, the next press stops it. Like the real
# one it sets its own SIGINT handler (a background job starts with SIGINT ignored)
printf '#!/usr/bin/env python3\nimport signal, sys, time\nsignal.signal(signal.SIGINT, lambda *a: sys.exit(0))\ntime.sleep(30)\n' >"${REC_BIN}/wf-recorder"
: >"${WORK}/rec-calls"
record
if grep -q 'setRecording true' "${WORK}/rec-calls" && [[ -s "${REC_RUN}/robinos-record.pid" ]]; then ok "a recording that runs shows the dot"; else bad "a running recording: $(cat "${WORK}/rec-calls")"; fi
rec_pid="$(head -n 1 "${REC_RUN}/robinos-record.pid" 2>/dev/null)"
record
if [[ ! -e "${REC_RUN}/robinos-record.pid" ]] && ! kill -0 "${rec_pid:-999999}" 2>/dev/null; then ok "the next press stops it"; else bad "the recording didn't stop"; kill "${rec_pid}" 2>/dev/null; fi

printf '%s\n' "Idle policy (robinos-idle-config): the 전원 page's minutes become hypridle's listeners"
IDLE_STATE="${WORK}/idle-state"
# idle_policy <prefs text or "-" for no file>: renders and prints the policy
idle_policy() {
  rm -rf "${IDLE_STATE}"
  mkdir -p "${IDLE_STATE}/robinos"
  [[ "$1" == "-" ]] || printf '%s' "$1" >"${IDLE_STATE}/robinos/power"
  XDG_STATE_HOME="${IDLE_STATE}" bash "${ROOT_DIR}/desktop/bin/robinos-idle-config" render >"${WORK}/idle-path" && cat "${IDLE_STATE}/robinos/hypridle.conf"
}
# idle_timeouts: the listeners' timeouts in order, e.g. "240 300 600 900"
idle_timeouts() { sed -n 's/^ *timeout = //p' | tr '\n' ' ' | sed 's/ $//'; }
# idle_case_policy <description> <expected timeouts> <prefs text>
idle_case_policy() {
  local got
  got="$(idle_policy "$3" | idle_timeouts)"
  if [[ "${got}" == "$2" ]]; then ok "$1"; else bad "$1: timeouts '${got}', wanted '$2'"; fi
}
idle_case_policy "no file: dim at 4 minutes, lock at 5, screen off at 10, sleep at 15" "240 300 600 900" "-"
idle_case_policy "the saved minutes are used" "120 180 300 1800" $'lock 3\nscreen_off 5\nsuspend 30\n'
idle_case_policy "never means no listener (lock 0 also takes the dimming)" "600 900" $'lock 0\n'
idle_case_policy "a lock after one minute has no dimming before it" "60 600 900" $'lock 1\n'
idle_case_policy "everything never leaves nothing to wait for" "" $'lock 0\nscreen_off 0\nsuspend 0\n'
idle_case_policy "odd values keep the defaults" "240 300 600 900" $'lock abc\nscreen_off -5\nsuspend 99999\nbogus 3\n'
idle_case_policy "a leading zero isn't octal" "240 300 480 900" $'screen_off 08\n'
if [[ "$(cat "${WORK}/idle-path")" == "${IDLE_STATE}/robinos/hypridle.conf" ]]; then ok "render says where the policy is"; else bad "render printed $(cat "${WORK}/idle-path")"; fi
default_policy="$(idle_policy "-")"
if grep -q 'lock_cmd = pidof hyprlock || hyprlock -c /usr/share/robinos/hypr/hyprlock.conf' <<<"${default_policy}" \
  && grep -q "robinos-idle-suspend" <<<"${default_policy}"; then ok "the lock command and the sleep script are in it"; else bad "the policy lacks the lock command or the sleep script"; fi
# The shipped hypridle.conf is the same policy as the defaults
if [[ "$(idle_timeouts <<<"${default_policy}")" == "$(idle_timeouts <"${ROOT_DIR}/desktop/hypr/hypridle.conf")" ]]; then ok "the defaults match desktop/hypr/hypridle.conf"; else bad "the defaults differ from desktop/hypr/hypridle.conf"; fi

printf '%s\n' "Problem report (robinctl report): facts in one file, names and addresses masked"
REPORT_BIN="${WORK}/report-bin"
mkdir -p "${REPORT_BIN}"
printf '#!/bin/sh\necho robin\n' >"${REPORT_BIN}/id"
printf '#!/bin/sh\n[ "$1" = "-n" ] && echo sandras-laptop || exec /usr/bin/uname "$@"\n' >"${REPORT_BIN}/uname"
printf '#!/bin/sh\nprintf "00:02.0 VGA compatible controller [0300]: Intel Corporation Iris Xe [8086:46a6]\\n\\tKernel driver in use: i915\\n00:14.3 Network controller [0280]: Intel Wi-Fi 6 AX201 [8086:a0f0]\\n\\tKernel driver in use: iwlwifi\\n00:1f.3 ISA bridge [0601]: Intel LPC [8086:a082]\\n\\tKernel driver in use: lpc_ich\\n"\n' >"${REPORT_BIN}/lspci"
printf '#!/bin/sh\ncase "$*" in\n  *"-p err"*) echo "Oct 14 robin@sandras-laptop kernel: eth0 aa:bb:cc:dd:ee:ff 192.168.0.12 fe80::1c2d:3e4f:5a6b:7c8d Serial Number: ABC123XYZ disk 0a1b2c3d-1111-2222-3333-444455556666 robinos robin"; echo "Oct 14 systemd[1]: dev-disk-by\\\\x2duuid-0a1b2c3d\\\\x2d1111\\\\x2d2222\\\\x2d3333\\\\x2d444455556666.device: Job timed out"; echo "Oct 14 bluetoothd: /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF failed"; echo "Oct 14 sudo: robin : 1 incorrect password attempt ; PWD=/home/sandra/Documents" ;;\n  *) echo "iwlwifi 0000:00:14.3: loaded firmware version 77.0" ;;\nesac\n' >"${REPORT_BIN}/journalctl"
chmod 755 "${REPORT_BIN}"/*
REPORT_FILE="${WORK}/report.txt"
check "robinctl report writes a file" 0 env PATH="${REPORT_BIN}:${PATH}" HOME="${WORK}" bash "${ROBINCTL}" report "${REPORT_FILE}"
said "it says where the report is" "${REPORT_FILE}"
for heading in "## RobinOS" "## 컴퓨터" "## 장치와 드라이버" "## 화면" "## 네트워크" "## 소리" "## 배터리와 전원" "## 문제 신호"; do
  if grep -qF -- "${heading}" "${REPORT_FILE}"; then ok "the report has ${heading}"; else bad "the report lacks ${heading}"; fi
done
if grep -q 'Kernel driver in use: i915' "${REPORT_FILE}" && grep -q 'Kernel driver in use: iwlwifi' "${REPORT_FILE}"; then ok "the graphics and Wi-Fi drivers are in it"; else bad "the drivers of the graphics card and Wi-Fi are missing"; fi
if grep -q 'ISA bridge' "${REPORT_FILE}"; then bad "parts that don't matter (the ISA bridge) are in it"; else ok "parts that don't matter are left out"; fi
if grep -qE 'aa:bb:cc:dd:ee:ff|AA_BB_CC|192\.168\.0\.12|fe80::|ABC123XYZ|0a1b2c3d|sandra|\brobin\b' "${REPORT_FILE}"; then
  bad "something private is still in the report: $(grep -E 'aa:bb:cc|192\.168|fe80|ABC123|0a1b2c3d|sandra|\brobin\b' "${REPORT_FILE}" | head -n 3)"
else
  ok "the MAC address, IPs, serial number, UUID and the names are masked"
fi
if grep -q 'xx:xx:xx:xx:xx:xx' "${REPORT_FILE}" && grep -q '<ip>' "${REPORT_FILE}" && grep -q '<user>@<host>' "${REPORT_FILE}"; then ok "the masks say what was there"; else bad "the masks are not where they should be: $(grep 'kernel: eth0' "${REPORT_FILE}")"; fi
if grep -q '8086:46a6' "${REPORT_FILE}"; then ok "PCI ids (vendor:device) are not taken for addresses"; else bad "a PCI id was masked"; fi
if grep -qF "커널: $(uname -r)" "${REPORT_FILE}"; then ok "the kernel version is not taken for an address"; else bad "the kernel version was changed: $(grep '커널:' "${REPORT_FILE}")"; fi
if grep -q ' robinos ' "${REPORT_FILE}" && ! grep -q '<user>os' "${REPORT_FILE}"; then ok "a user name inside a word (robinos) is left alone"; else bad "robinos was cut by the user mask"; fi
if grep -qF 'by\x2duuid-<uuid>' "${REPORT_FILE}" && grep -q 'dev_xx_xx_xx_xx_xx_xx' "${REPORT_FILE}" && grep -qF 'PWD=/home/<user>/Documents' "${REPORT_FILE}"; then
  ok "systemd's escaped UUIDs, BlueZ addresses and home folders are masked too"
else
  bad "escaped UUID, BlueZ address or home folder: $(grep -E 'systemd|bluetoothd|sudo:' "${REPORT_FILE}" | head -n 3)"
fi
# With sudo the report runs as root: the person's name (SUDO_USER) is masked, not root's
printf '#!/bin/sh\necho root\n' >"${REPORT_BIN}/id"
check "robinctl report with sudo" 0 env PATH="${REPORT_BIN}:${PATH}" HOME="${WORK}" SUDO_USER=robin bash "${ROBINCTL}" report "${REPORT_FILE}"
if grep -qE '\brobin\b' "${REPORT_FILE}"; then bad "with sudo the person's name stays: $(grep -E '\brobin\b' "${REPORT_FILE}" | head -n 2)"; else ok "with sudo the person's name is masked"; fi
check "a report that can't be written says so" fail env PATH="${REPORT_BIN}:${PATH}" HOME="${WORK}" bash "${ROBINCTL}" report "${WORK}/no-such-folder/report.txt"

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
    "calc:gnome-calculator" "taskmgr:missioncenter" "start:xdg-open" "clip:wl-copy" "powercfg:powerprofilesctl" "ncpa.cpl:nmtui" "doskey:alias" "eventvwr:journalctl -b" "services.msc:systemctl" "diskmgmt.msc:gnome-disks" "nslookup:getent hosts" \
    "certutil:sha256sum" "cipher:gpg -c" "runas:sudo" "netsh:nmcli" "sc:systemctl status"; do
  out="$(hint "${pair%%:*}")"
  if [[ "${out}" == *"${pair#*:}"* ]]; then ok "hint for ${pair%%:*}"; else bad "hint for ${pair%%:*}: ${out}"; fi
done
# Each Windows command with a mission (T-169) shows its hint and the mission to try,
# and the mission numbers exist (learn_title in robinctl)
out="$(hint ipconfig)"
if [[ "${out}" == *"학습 미션 6"*"robinctl learn show 6"* ]]; then ok "ipconfig points to mission 6"; else bad "ipconfig mission: ${out}"; fi
missions_total="$(sed -n '/^learn_title()/,/^}/p' "${ROBINCTL}" | grep -cE '^ +[0-9]+\) printf')"
while read -r cmds number; do
  for c in ${cmds//|/ }; do
    out="$(hint "${c}")"
    [[ "${out}" == *"robinctl learn show ${number}"* ]] || bad "mission link for ${c}: ${out}"
  done
  ((number >= 1 && number <= missions_total)) || bad "mission ${number} for ${cmds} is not one of the ${missions_total} missions"
done < <(sed -n '/^__robinos_hint_mission()/,/^}/p' "${HINTS}" | sed -nE "s/^ +([a-z.|]+)\) +printf '([0-9]+)'.*/\1 \2/p")
ok "every mission link has a hint and a real mission (${missions_total} missions)"
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
