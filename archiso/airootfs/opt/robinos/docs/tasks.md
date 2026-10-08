# RobinOS 작업 목록

루프가 회차마다 읽고 갱신하는 작업 목록이에요. 절차는 [loop.md](loop.md), 제품 범위와 상태는 [design.md](design.md)에 있어요.

상태: `할 일` → `진행 중` → `검증 대기` → `완료`. 사용자가 해야 하는 일을 기다리거나 같은 실패가 세 번 반복되면 `막힘`으로 두고 다른 작업을 해요. `할 일`이 비면 [loop.md](loop.md)의 "백로그 채우기"로 채워요.

## 백그라운드 작업

WSL에서 도는 긴 작업이에요. WSL 작업은 한 번에 하나만 돌려요(`scripts/wsl-build.ps1 status`로 확인).

| 작업 | 시작 | 대상 | 결과 위치 | 상태 |
|---|---|---|---|---|
| (없음) | | | | |

## 정기 점검

처음부터 다시 확인하는 회귀 점검이에요. 묶음 검증(`verify`)이 이걸 겸하고, 묶음이 하루 넘게 없었으면 한 번 돌려요([loop.md](loop.md) "정기 점검"). 최근 두 줄만 두고 나머지는 [done.md](done.md)로 옮겨요.

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-10-09 | `ba358cb` 테스트 ISO | 설치 테스트 windows(6.7분), archinstall(10.1분) | 둘 다 다섯 단계 통과. 오늘 고친 설치 코드(`apps.txt`, 서비스, nsswitch, NVIDIA 감지, 전원 모드)가 윈도우 옆 설치와 archinstall+post-install 경로에서도 문제없음 |
| 2026-10-08 | `968795d` ISO | 집 PC(Blitz)에서 ISO 빌드, 부팅 테스트(WHPX, 30장, 새 장면 `button-layout`), 설치 테스트 robinos(다섯 단계) | 통과. 설치기에 Qt 제목 표시줄(최대화, 닫기), 라이브 독에 Wireshark 없음, 설치본 독은 터미널·파일·브라우저 |

## 품질 점검 기록

백로그 채우기 6번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 코드 검토 | 2026-10-09 | 오늘 들어간 코드를 다시 봄: 클립보드(명령에 넘기는 id는 숫자만), 업데이트 알림, 전원 모드, 달력, 웹 연습 서버(127.0.0.1만), CTF. `ctf_prepare`가 지운 문제 파일을 다시 만들지 않던 것을 고침(`a4e3beb`). 이전: robin-install, robinctl 스냅샷·랩, post-install, 셸 QML 전체(2026-10-08) |
| 문서와 코드 맞추기 | 2026-10-08 (두 번째) | 오늘 바뀐 것 기준으로 다시 봄: `robinctl help`의 learn·update 설명, testing.md의 부팅 테스트 장면(최소화, Super+D, 셸 다시 띄우기, 단추 배치)과 설치 테스트 확인 항목, "설치 방식은 두 가지" → 세 가지, roadmap의 미션 수, CLAUDE.md 저장소 지도(`apps.txt`, `practice/`), docs/README.md의 같이 고칠 문서 표(학습 미션, 패키지 목록)를 고침 |
| 보안과 윤리 | 2026-10-08 | 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음, 이미지 고정(T-014). 라이브 ISO: sshd는 이미 꺼져 있음, releng의 cloud-init 유닛을 뺌. 설치본: root 잠금(robin-install), wheel은 비밀번호 sudo |
| 접근성 | 2026-10-09 | 셸 QML의 누르는 곳은 모두 접근성 이름이 있고(이름 없는 MouseArea는 바깥을 눌러 닫는 배경뿐), 새 학습 센터의 미션 줄도 Tab·Enter와 이름이 있음. 이전(2026-10-08): 버튼과 선택지가 마우스 전용이던 것(T-015), 보조 글자 대비(subtle 3.9:1·2.6:1 → muted). 화면 읽기(Orca)는 Hyprland에 키보드 감시 인터페이스가 없어 막힘(T-040) |
| 성능 | 2026-10-09 | 부팅 테스트 시리얼 로그: SDDM 9.0초, Hyprland 시작 11.4초, 부팅 끝 15.9초(전에는 19.8초, 21.4초). 이전(2026-10-08): 부팅 테스트 시리얼 로그: 라이브에서 데스크톱까지 35초 중 ldconfig 14초(`/etc/.updated` 없음), Docker 5초 → 고침(`37de032`, 다음 부팅 테스트에서 확인). `fcitx5-remote` 1초 폴링은 작은 프로세스 하나라 그대로 둬요 |
| 업스트림 변화 | 2026-10-09 | quickshell이 0.3.2로 올라옴(Qt 6.12로 다시 빌드). 묶음 10·11 부팅 테스트에서 Qt 경고도 QML 오류도 없어서 지켜보던 것은 끝. design.md 버전 고침. Hyprland 0.56이 `start-hyprland` 없이 띄우면 경고하는데, 비정상 종료 때 `--safe-mode`로 다시 띄워서 소프트웨어 렌더링 재시도와 부딪혀 직접 실행을 유지(design.md). 그 밖에는 Hyprland 0.56.2, SDDM 0.21.0, GRUB 2.16, archinstall 4.5, linux 7.2.9 그대로 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| (없음) | | |

`3e31b43`까지 2026-10-09 묶음 11 검증(`verify`: 빌드 3.6분 + 테스트 9.4분)을 마치고 푸시했어요.

## 사용자 확인 필요

- **실기기 라이브 부팅**: USB로 실제 PC에서 ISO를 부팅해 봐야 해요. 사용자만 할 수 있어요. NVIDIA 카드(GTX 16, RTX 20 이후)가 있는 PC라면 설치한 뒤 데스크톱이 뜨는지, `lsmod | grep nvidia`에 나오는지도 봐 주세요(T-030). (`막힘`)
- **실제 윈도우 PC에서 "윈도우 옆에 설치"**: VM의 가짜 윈도우 디스크로는 파티션과 부팅 파일이 그대로인 것까지 확인했어요(T-006). 진짜 윈도우가 GRUB 메뉴에 나오는지, BitLocker 복구 키를 묻는지는 실제 PC에서만 볼 수 있어요. 백업해 둔 PC나 남는 디스크로 해 주세요. (`막힘`)
- **집 PC의 VMware 서비스 켜기(T-025)**: 집 PC(Blitz)에서 VM을 만들어 켜려 했더니 VMware의 윈도우 서비스(Authorization, DHCP, NAT, USB Arbitration)가 모두 "사용 안 함"이라 VM이 켜지지 않아요. 관리자 권한이 필요해서 직접 하지 않아요. 쓰려면 관리자 PowerShell에서 `Set-Service VMAuthdService,VMnetDHCP,'VMware NAT Service',VMUSBArbService -StartupType Manual`, `Start-Service VMAuthdService,VMnetDHCP,'VMware NAT Service'`. VM(`문서\Virtual Machines\RobinOS`)과 스크립트(`build\vmware\vmware-test.py`)는 준비돼 있어요 (`막힘`)
- **작업 브랜치 `work/t025-vmware` 지우기**: 내용은 모두 main에 들어갔어요. GitHub에서 지워도 되는지 알려 주세요
- **RobinOS 파일 업데이트 배포 방식(T-026)**: 2026-10-08 사용자가 중앙 서버가 필요한지 묻고 추천을 원함. 추천: 따로 서버 없이 깃허브 릴리스를 pacman 저장소로 쓰고, RobinOS 파일을 pacman 패키지로 만들어 서명해요. `robinctl update` 한 번에 함께 올라가고 snap-pac 스냅샷도 그대로 생겨요. 서명 열쇠(GPG)를 이 PC에 만들어야 해서 사용자 답을 기다려요
- **v0.2 프리뷰 공개**: v0.1 뒤로 오피스·앱 스토어·프린터·NVIDIA·업데이트 알림·Win+V 등과 미션 25개, 입문 CTF가 들어갔어요. 발표문 초안은 `docs/release-notes-v0.2.md`. 공개하기로 하면 릴리스용 xz ISO(2GiB 안)를 빌드하고 부팅 테스트한 뒤 깃허브 릴리스로 올려요(태그 `v0.2.0`, 프리릴리스)

## 진행 중

### T-025 VMware에서 쓰기
- 상태: 진행 중
- 출처: 사용자 요청("vmware로 깔아줘"). VMware Workstation Pro 26H1, VM은 `문서\Virtual Machines\RobinOS\RobinOS.vmx`(EFI, 8GB, NVMe 64GB, 3D 가속 켬)
- 찾은 것: ① 3D 가속을 켜면 Hyprland는 `vmwgfx`로 잘 그리는데 셸(Qt)은 `Could not create EGL surface`로 아무것도 안 그림. ② 화면이 물리 크기를 알려 주지 않아 Hyprland 자동 배율이 2배 → 1280×800 창이 640×400 바탕 화면(환영 마법사가 위아래로 잘림). ③ VMware 창 크기를 바꾸면 커널은 새 크기를 받는데 Hyprland는 처음 해상도를 그대로 씀. ④ 설치본에는 `open-vm-tools`가 없음
- 한 것: `robinos-shell`(EGL 실패를 보면 셸만 소프트웨어로 다시 띄움, 죽으면 다시 띄움), VM 화면(`Virtual-*`)은 배율 1, `robinos-vm-display`(창 크기를 따라감), 설치기가 VMware에서는 `open-vm-tools`와 `vmtoolsd`를, QEMU/KVM에서는 `qemu-guest-agent`를 설치. 라이브 VM에서 셋 다 직접 확인(셸 강제 종료 후 다시 뜸, 1718×920·배율 1로 맞춤, udev change 신호로 다시 맞춤)
- `426e32d` ISO를 VMware에서 띄우니 셸이 GPU 실패 뒤 아무것도 안 그리는 대신 Wayland 오류(`wl_surface.attach` invalid arguments)로 바로 죽었어요. `robinos-shell`은 살아 있는 셸에서만 GPU 실패를 확인해서 이걸 그냥 "죽음"으로 세고 GPU 모드로 다섯 번 다시 띄운 뒤 포기했어요. 셸이 죽은 뒤에도 로그를 보고 소프트웨어로 바꾸게 고쳤고, 라이브 VM에서 확인했어요
- 같이 한 것: 화면에 보이는 단축키를 `Super` 대신 `Win`으로 적어요(사용자 질문 "Super 키가 뭐야?"). 환영 마법사 마지막 단계에 "Win 키는 리눅스에서 Super 키라고 불러요"를 넣었어요
- 지금까지(2026-10-08, robin PC): `426e32d` ISO를 VMware VM에 설치함. 설치기가 마지막 `umount`에서 멈췄고(gpg-agent, `933ca31`에서 고침) 손으로 분리한 뒤 고친 `robinos-shell`을 넣어 부팅. 설치본에서 `open-vm-tools` 설치, `vmtoolsd` 켜짐, SDDM 로그인 화면까지 확인. 로그인 뒤 데스크톱은 아직 못 봄(VMware에는 키 입력을 보낼 방법이 없어 사람이 로그인해야 해요)
- 검증: `933ca31` ISO로 부팅 테스트(29장)와 설치 테스트 robinos(다섯 단계) 통과, `e038f2a`까지 main 푸시(정기 점검 표)
- 남은 것 (VMware가 있는 PC: robin PC, 집 PC(Blitz, VMware Workstation 26.0)): 최종 ISO로 VMware VM에 다시 설치(`vmrun` 게스트 명령, 계획은 디스크 `/dev/nvme0n1` 전체), 로그인 뒤 셸·해상도 확인. 집 PC에는 VM이 아직 없어서 새로 만들어요(`build\vmware\guest-*.sh`는 robin PC에만 있어요). VMware가 없는 PC의 루프는 이 작업을 건너뛰어요

## 할 일 (위에서부터)

### T-040 화면 읽기 (Orca)
- 상태: 막힘 (Hyprland가 `org.freedesktop.a11y.KeyboardMonitor`를 제공할 때까지)
- 출처: 품질 점검(접근성) "화면 읽기 프로그램(Orca)은 아직"
- 조사(2026-10-08): Orca 51 패키지와 libatspi 2.62를 받아 확인. Orca는 `Atspi.Device.new_full`로 키를 받고, Wayland에서는 `org.freedesktop.a11y.Manager`(Mutter 제공)를 써요. Hyprland 0.56.2 소스에 없어서 Orca 키 명령은 안 되고 포커스 읽기만 돼요. 결론과 이유를 design.md 미결정 사항에 적음. 업스트림 변화 점검 때 Hyprland가 이 인터페이스를 넣었는지 봐요

### T-026 RobinOS 자체 파일 업데이트
- 상태: 할 일 (배포 방식은 사용자 결정, "사용자 확인 필요" 참고)
- 출처: T-025. `robinctl update`는 `pacman -Syu`만 해요. 셸, `robinctl`, 설정 같은 RobinOS 파일은 설치할 때의 ISO 버전에 머물러서, 셸 버그를 고쳐도 설치한 사람에게 갈 길이 없어요
- 후보: ① RobinOS 파일을 pacman 패키지(`robinos-desktop` 등)로 만들고 자체 저장소에서 서명해 배포, ② `/opt/robinos`를 GitHub 릴리스 태그로 받아 서명이나 체크섬을 확인한 뒤 `install-desktop.sh`로 다시 설치. ①은 pacman과 스냅샷(snap-pac)에 자연스럽게 묶이고, ②는 빨리 만들 수 있어요
- 완료 기준: 설치 테스트에서 옛 버전을 설치한 뒤 `robinctl update`로 새 버전 파일이 들어오고, 업데이트 전 스냅샷이 생김

### T-021 웹 보안 미션 (Juice Shop)
- 상태: 보류. 범위를 다시 잡을 때까지 다른 작업을 먼저 해요. 랩 안내(`robinctl lab info web`)와 Juice Shop 자체의 점수판으로 시작할 수 있어요
- 출처: 백로그 채우기 4 (학습 기능 늘리기), design.md 학습 순서의 세 번째(웹 보안)
- 목표: `robinctl learn` 11~15번. 웹 랩을 켜고(`robinctl lab start web`), Juice Shop의 쉬운 문제를 풀어요. 예: 점수판 찾기(Score Board), 브라우저 개발자 도구로 숨은 정보 보기, 로그인 SQL 인젝션(관리자로 로그인), 오류 메시지 보기, 리뷰에 XSS 넣기. 채점은 Juice Shop이 스스로 기록하는 문제 상태(`http://127.0.0.1:3000/api/Challenges`)를 읽어요. 대상은 내 컴퓨터의 랩뿐이라는 안내를 붙여요
- 확인할 것: v20.2.0의 문제 이름과 API 응답 모양(설치 테스트 -Lab에서 받아 보기), 랩이 꺼져 있을 때 안내
- 완료 기준: 채점 테스트(가짜 API 응답으로), 설치 테스트 -Lab에서 한 문제를 실제로 풀고 채점

### T-011 v0.2 후보 (백로그 1~6에서 쓸 만한 일이 없을 때 꺼내요)
- foot 제목 표시줄(hyprbars), 학습 센터 앱, 네트워크·CTF 랩 (최소화와 `Win+D`는 T-024, Qt 앱 제목 표시줄은 T-029)

## 완료

최근 것이 위에 있어요. 더 오래된 기록은 [done.md](done.md)에 있어요.

- 2026-10-09 묶음 11 검증(`3e31b43`, verify 빌드 3.6분 + 테스트 9.4분 통과)
  - T-060 터미널 프롬프트(`ac72a6a`): 부팅 테스트 터미널에 흐린 `robin@robinos ~`, 빨간 `>`, `ipconfig` 힌트 뒤 `127 >`. 라이트 모드에서도 잘 보임
  - T-061 시스템 이름(`ac72a6a`): fastfetch "운영체제 RobinOS x86_64". 설치 테스트에서 `filesystem`을 다시 설치한 뒤에도 os-release가 RobinOS(pacman 훅), 사용자 `~/.bashrc`가 robinos-bashrc.sh를 불러옴. 버전 0.2.0-dev
  - T-062 라이브 시간대(`66cf348`): 바와 잠금 화면 시계가 한국 시간(오전 8:3x)
- 2026-10-09 묶음 10 검증(`f5572d4`, verify 빌드 4.2분 + 테스트 7.0분 통과)
  - T-059 fastfetch 울새 로고(`7651d99`): 부팅 테스트 `19-terminal-windows-hint`에 하얀 울새, 회색 부리·꼬리·다리, 빨간 `>`가 정보 옆에 나란히. 완료 기록 6개를 done.md로 옮김
- 2026-10-09 T-058 로고 다시 디자인(`07d87af`, 사용자 요청): 프롬프트 `> _` 커서 위의 하얀 울새, 빨강은 프롬프트에만. verify 통과, 부팅 테스트의 바·런처 바닥과 설치 테스트 `rollback-02-sddm`의 로그인 화면에 강조색 위 하얀 울새 글리프
- 2026-10-09 묶음 8 검증(`3d25877`, verify -Lab 빌드 3.5분 + 테스트 11.2분 통과)
  - T-057 네트워크 스캔 랩(`7dd7524`): 설치본에서 웹 페이지 코드, 31337 배너, Redis 포트, 포트 없는 컴퓨터 ping 확인, 호스트 포트 없음, 멈추면 네트워크까지 정리. 웹 랩(Juice Shop, DVWA)도 함께 통과
- 2026-10-09 묶음 7(`84fc527`~`7181213`): CTF 시작하기 문서 `docs/ctf.md`(T-054), 코드 검토와 CTF 파일 다시 만들기(T-055), v0.2 발표문 초안(T-056). 같은 날 설치 테스트 windows·archinstall 다섯 단계 통과
- 2026-10-09 묶음 6 검증(`9e02baa`, verify 빌드 3.3분 + 부팅·설치 테스트 7.3분 통과)
  - T-053 입문 CTF 5문제(`2e40881`): `light-launcher`의 "보안 랩"에 "입문 CTF"(깃발 아이콘), robinctl 테스트가 다섯 문제를 힌트대로 풂
  - /doctor 점검(2026-10-09): 사용자 설정에서 안 쓰는 디자인 스킬 6개와 engineering 플러그인을 끄고, CLAUDE.md의 저장소 지도를 코드로 모르는 사실 세 가지로 줄임(`4eddf37`). 기본 권한 모드는 사용자가 그대로 두기로 함
- 2026-10-09 묶음 5 검증(`2358ad0`, verify 빌드 3.5분 + 부팅·설치 테스트 8.0분 통과)
  - T-051 전원 모드(`f341174`): `quick-settings` 장면에 "전원 모드 절전 | 균형"(VM은 최고 성능 없음), 균형 선택됨
  - T-052 지시 파일 점검(`c96b025`), 검증 파이프라인 규칙(`2358ad0`)
- 2026-10-08 묶음 3 검증(`19a9582`, 새 `verify` 두 번째 실행: 빌드 3.6분 + 부팅·설치 테스트 동시 7.4분 = 약 11분, 전에는 약 20분)
  - T-046 웹 기초 미션 5개(`eac182f`): 연습 서버로 curl, 헤더, robots.txt, 쿠키, 리다이렉트. 미션 목록 25개(다섯 묶음)
  - T-047 달력(`70861a6`): `calendar` 장면에 2026년 10월(1일 목요일), 오늘 8일 강조, 일요일 빨간색
  - T-048 업데이트 알림(`38b5aac`): 첫 verify에서 설치 테스트가 `checkupdates`의 "Cannot find the fakeroot binary"를 찾음 → `fakeroot`를 core에(`19a9582`). 다시 돌린 설치본에서 `checkupdates=2`(업데이트 없음)
  - T-049 `verify`(`48ca7aa`): 첫 실행에서 부팅 테스트 종료 코드를 못 읽던 것(`Start-Process` 핸들)을 고침(`19a9582`)
  - T-050 `ready.ps1`과 확장자 없는 스크립트의 LF(`73c78cd`)
