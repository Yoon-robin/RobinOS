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
    taskmgr)             printf '%s' 'missioncenter|작업 관리자에 해당하는 앱이에요 (Ctrl+Shift+Esc도 돼요)' ;;
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
    explorer)            printf '%s' 'nautilus|파일 탐색기에 해당하는 앱이에요 (Win+E)' ;;
    control|msconfig)    printf '%s' 'Win+S|빠른 설정을 열어요. 서비스 목록은 systemctl list-unit-files' ;;
    regedit)             printf '%s' 'ls /etc|리눅스에는 레지스트리가 없어요. 설정은 /etc와 ~/.config의 파일이에요' ;;
    powershell|cmd)      printf '%s' 'bash|지금 쓰고 있는 이 셸이 리눅스의 명령 프롬프트예요' ;;
    calc)                printf '%s' 'gnome-calculator|계산기에 해당하는 앱이에요 (터미널에서는 echo $((1+2)))' ;;
    eventvwr|eventvwr.msc) printf '%s' 'journalctl -b|이번 부팅의 시스템 기록을 보여 줘요 (오류만: journalctl -b -p err)' ;;
    services.msc)        printf '%s' 'systemctl list-units --type=service|서비스 목록을 보여 줘요' ;;
    devmgmt.msc)         printf '%s' 'lspci -k|장치와 쓰고 있는 드라이버를 보여 줘요 (USB 장치는 lsusb)' ;;
    diskmgmt.msc)        printf '%s' 'gnome-disks|디스크 관리에 해당하는 앱이에요 (터미널에서는 lsblk)' ;;
    getmac)              printf '%s' 'ip link|네트워크 장치의 MAC 주소(link/ether)를 보여 줘요' ;;
    winver)              printf '%s' 'fastfetch|운영체제 이름과 버전을 보여 줘요' ;;
    nslookup)            printf '%s' 'getent hosts 이름|이름으로 주소를 찾아요 (nslookup과 dig는 network 프로필에 있어요)' ;;
    start)               printf '%s' 'xdg-open 파일|파일이나 주소를 알맞은 앱으로 열어요 (폴더는 nautilus 폴더)' ;;
    clip)                printf '%s' 'wl-copy|글을 클립보드에 넣어요 (예: echo 안녕 | wl-copy, 붙여 넣기는 wl-paste)' ;;
    net)                 printf '%s' 'id|사용자 정보는 id, 서비스는 systemctl, 공유 폴더는 mount로 다뤄요' ;;
    powercfg)            printf '%s' 'powerprofilesctl|전원 모드를 보여 주고 바꿔요 (빠른 설정의 전원 모드와 같아요)' ;;
    ncpa.cpl)            printf '%s' 'nmtui|네트워크 연결을 설정해요 (런처에서 "와이파이"를 찾아도 돼요)' ;;
    appwiz.cpl)          printf '%s' 'pacman -Q|설치된 프로그램 목록이에요 (지우기는 sudo pacman -Rs 이름, 앱은 소프트웨어 앱)' ;;
    taskschd.msc)        printf '%s' 'systemctl list-timers|예약된 작업(타이머)을 보여 줘요' ;;
    perfmon|resmon)      printf '%s' 'missioncenter|CPU, 메모리, 디스크 사용량을 보여 주는 앱이에요 (터미널에서는 top)' ;;
    msinfo32|wmic)       printf '%s' 'hostnamectl|시스템 정보를 보여 줘요 (하드웨어는 lscpu, lsblk, lspci)' ;;
    snippingtool)        printf '%s' 'Win+Shift+S|화면 일부를 캡처해요 (전체 화면은 Shift+Print)' ;;
    mspaint)             printf '%s' 'loupe 그림|사진 보기는 loupe예요. 그림판은 없어서 앱 스토어에서 그리기 앱을 받아요' ;;
    doskey)              printf '%s' "alias 이름='명령'|명령에 짧은 이름을 붙여요 (~/.bashrc에 적으면 계속 써요)" ;;
    bcdedit)             printf '%s' 'efibootmgr|부팅 항목을 보여 줘요 (부팅 메뉴는 GRUB이 맡아요)' ;;
    certutil)            printf '%s' 'sha256sum 파일|파일의 해시를 봐요 (certutil -hashfile 자리, 미션 39)' ;;
    cipher)              printf '%s' 'gpg -c 파일|파일을 비밀번호로 암호화해요 (미션 40)' ;;
    runas)               printf '%s' 'sudo 명령|관리자(root) 권한으로 실행해요 (wheel 그룹만 돼요, 미션 36)' ;;
    cacls)               printf '%s' 'chmod 600 파일|나만 읽고 쓰게 해요 (권한은 ls -l로 봐요, 미션 37)' ;;
    netsh)               printf '%s' 'nmcli|네트워크와 Wi-Fi를 설정해요 (빠른 설정의 Wi-Fi 화살표도 돼요)' ;;
    tree)                printf '%s' 'find . -maxdepth 2|폴더 구조를 보여 줘요 (ls -R도 돼요)' ;;
    comp)                printf '%s' 'cmp 파일1 파일2|두 파일이 바이트까지 같은지 봐요 (다른 줄은 diff)' ;;
    sc)                  printf '%s' 'systemctl status 서비스|서비스 상태를 보고 켜고 꺼요 (미션 34)' ;;
    schtasks)            printf '%s' 'systemctl list-timers|예약된 작업을 보여 줘요' ;;
    pathping)            printf '%s' 'tracepath 주소|목적지까지의 경로와 지연을 함께 봐요' ;;
    assoc|ftype)         printf '%s' 'xdg-mime query default 형식|파일 형식을 여는 기본 앱을 봐요' ;;
  esac
}

command_not_found_handle() {
  local name="${1,,}"
  local hint
  name="${name%.exe}"
  hint="$(__robinos_windows_hint "${name}")"

  if [[ -n "${hint}" ]]; then
    printf '\033[1m%s\033[0m 명령은 윈도우용이에요. 리눅스에서는\n  \033[1;32m%s\033[0m  \033[2m%s\033[0m\n' \
      "$1" "${hint%%|*}" "${hint#*|}" >&2
  else
    printf 'bash: %s: 명령을 찾을 수 없어요\n' "$1" >&2
  fi
  return 127
}
