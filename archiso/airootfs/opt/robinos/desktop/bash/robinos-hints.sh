# RobinOS: Windows command hints for people learning Linux.
# Sourced from ~/.bashrc. Typing a Windows command (ipconfig, dir, cls, ...) shows
# the Linux equivalent instead of a bare "command not found".

# Prints "linux command|explanation" for a Windows command, or nothing.
__robinos_windows_hint() {
  case "$1" in
    ipconfig)            printf '%s' 'ip a|IP 주소와 네트워크 장치를 보여 줘요' ;;
    dir)                 printf '%s' 'ls -l|폴더 안의 파일 목록을 보여 줘요' ;;
    cls)                 printf '%s' 'clear|화면을 지워요 (Ctrl+L도 돼요)' ;;
    cd..)                printf '%s' 'cd ..|리눅스에서는 cd와 .. 사이에 띄어쓰기가 필요해요' ;;
    copy)                printf '%s' 'cp 원본 대상|파일을 복사해요' ;;
    xcopy|robocopy)      printf '%s' 'cp -r 원본 대상|폴더째 복사해요 (rsync -a도 많이 써요)' ;;
    move)                printf '%s' 'mv 원본 대상|파일을 옮기거나 이름을 바꿔요' ;;
    ren)                 printf '%s' 'mv 이전이름 새이름|리눅스에서는 이름 바꾸기도 mv로 해요' ;;
    del|erase)           printf '%s' 'rm 파일|파일을 지워요 (휴지통을 거치지 않으니 조심하세요)' ;;
    rd)                  printf '%s' 'rm -r 폴더|폴더를 통째로 지워요' ;;
    md)                  printf '%s' 'mkdir 폴더|폴더를 만들어요' ;;
    tasklist)            printf '%s' 'ps aux|실행 중인 프로세스를 보여 줘요 (실시간으로 보려면 top)' ;;
    taskkill)            printf '%s' 'kill PID|프로세스를 끝내요 (이름으로는 pkill 이름)' ;;
    taskmgr)             printf '%s' 'mission-center|작업 관리자에 해당하는 앱이에요' ;;
    tracert)             printf '%s' 'traceroute 주소|목적지까지 거치는 경로를 보여 줘요' ;;
    netstat)             printf '%s' 'ss -tulpn|열린 포트와 연결을 보여 줘요' ;;
    arp)                 printf '%s' 'ip neigh|같은 네트워크의 장치(ARP 테이블)를 보여 줘요' ;;
    route)               printf '%s' 'ip route|라우팅 테이블을 보여 줘요' ;;
    systeminfo)          printf '%s' 'fastfetch|시스템 정보를 보여 줘요 (자세히는 hostnamectl)' ;;
    ver)                 printf '%s' 'uname -a|커널 버전을 보여 줘요' ;;
    where)               printf '%s' 'which 명령|명령이 어디에 있는지 보여 줘요' ;;
    findstr)             printf '%s' 'grep 단어 파일|파일에서 글자를 찾아요' ;;
    attrib|icacls)       printf '%s' 'chmod / chown|파일 권한과 소유자를 바꿔요 (ls -l로 확인)' ;;
    chkdsk)              printf '%s' 'sudo fsck 장치|디스크를 검사해요 (마운트되지 않은 장치에만)' ;;
    diskpart)            printf '%s' 'lsblk|디스크와 파티션을 보여 줘요 (수정은 sudo fdisk)' ;;
    sfc)                 printf '%s' 'sudo pacman -Qkk|설치된 파일이 망가졌는지 검사해요' ;;
    winget|choco)        printf '%s' 'sudo pacman -S 패키지|프로그램을 설치해요 (앱 스토어 앱은 flatpak install)' ;;
    notepad)             printf '%s' 'gnome-text-editor|메모장에 해당하는 앱이에요 (터미널에서는 nano)' ;;
    explorer)            printf '%s' 'nautilus|파일 탐색기에 해당하는 앱이에요 (Super+E)' ;;
    control|msconfig)    printf '%s' 'Super+S|빠른 설정을 열어요. 서비스 목록은 systemctl list-unit-files' ;;
    regedit)             printf '%s' 'ls /etc|리눅스에는 레지스트리가 없어요. 설정은 /etc와 ~/.config의 파일이에요' ;;
    powershell|cmd)      printf '%s' 'bash|지금 쓰고 있는 이 셸이 리눅스의 명령 프롬프트예요' ;;
  esac
}

command_not_found_handle() {
  local name="${1,,}"
  local hint
  name="${name%.exe}"
  hint="$(__robinos_windows_hint "${name}")"

  if [[ -n "${hint}" ]]; then
    printf '\033[1m%s\033[0m은(는) 윈도우 명령이에요. 리눅스에서는\n  \033[1;32m%s\033[0m  \033[2m%s\033[0m\n' \
      "$1" "${hint%%|*}" "${hint#*|}" >&2
  else
    printf 'bash: %s: 명령을 찾을 수 없어요\n' "$1" >&2
  fi
  return 127
}
