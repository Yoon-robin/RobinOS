# RobinOS 작업 목록

루프가 회차마다 읽고 갱신하는 작업 목록이에요. 절차는 [loop.md](loop.md), 제품 범위와 상태는 [design.md](design.md)에 있어요.

상태: `할 일` → `진행 중` → `검증 대기` → `완료`. 사용자가 해야 하는 일을 기다리거나 같은 실패가 세 번 반복되면 `막힘`으로 두고 다른 작업을 해요. `할 일`이 비면 [loop.md](loop.md)의 "백로그 채우기"로 채워요.

## 백그라운드 작업

WSL에서 도는 긴 작업이에요. WSL 작업은 한 번에 하나만 돌려요(`scripts/wsl-build.ps1 status`로 확인).

| 작업 | 시작 | 대상 | 결과 위치 | 상태 |
|---|---|---|---|---|
| (없음) | | | | |

## 정기 점검

처음부터 다시 확인하는 회귀 점검이에요. 마지막 날짜가 하루 넘게 지났거나 그 뒤 커밋이 10개 넘게 쌓이면 다시 해요([loop.md](loop.md) "정기 점검").

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-10-08 | `933ca31` ISO, `e038f2a` 테스트 | ISO 빌드, 부팅 테스트(WHPX, 29장, 새 장면 `shell-restarted`), 설치 테스트 robinos(다섯 단계) | 통과. 셸을 끄면 1초 뒤 다시 뜸(`exited with 143` → `starting the shell`). 환영 마법사 단축키가 `Win`으로, 윈도우 명령 힌트가 새 문구로 나옴. 설치기 마무리가 "설치가 끝났어요"까지 감. 테스트 도중 WSL에 `cmp`가 없어 ISO를 매번 복사하던 것을 고침(`e038f2a`) |
| 2026-10-08 | `5de4149` | 두 번째 PC(사용자 `robin`, 한글 경로)에서 처음 검증: ISO 빌드(처음부터, 6분, Qt 6.12), 부팅 테스트(WHPX, 254초, 24장) | 통과. 한글 경로에서 WHPX QEMU가 파일을 못 열던 문제를 고친 뒤 통과. 스크린샷 24장 모두 정상(라이트 모드, 잠금 화면 포함) |
| 2026-10-08 | `4fbb2c6` | ISO 빌드(처음부터, 8분), 부팅 테스트(221초, 21장), 설치 테스트 windows(8분, 다섯 단계) | 통과. 같은 날 archinstall·robinos 설치 테스트도 각각 통과 |
| 2026-10-08 | `7a000b9` | ISO 빌드(처음부터, 9분), 부팅 테스트(WHPX, 207초) | 통과. 스크린샷 18장 모두 정상 |
| 2026-10-07 | `16d652f` | ISO 빌드, 부팅 테스트 | 빌드 성공. 부팅 테스트에서 마법사 키 반복 문제(고침), 런처 검색 미확인 (T-001) |

## 품질 점검 기록

백로그 채우기 6번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 코드 검토 | 2026-10-08 | `robin-install`(fstab의 `subvolid=`), `robinctl`(스냅샷 부팅 상태의 되돌리기, 랩 권한), `post-install.sh`(영어 출력), `Installer.qml`, `ShellState.qml`, `Launcher.qml`(열 때 hover 선택), `Dock.qml`(설치 안 된 Wireshark가 고정돼 눌러도 반응 없음 → `6faf853`), `Bar.qml`(좁은 화면에서 앱 이름이 가운데 시계와 겹칠 수 있음, 1024px 이하라 그대로 둠). QuickSettings, Welcome은 아직 |
| 문서와 코드 맞추기 | 2026-10-08 | 문서에 나오는 `robinctl` 명령, `scripts/` 경로, `wsl-build.ps1` 작업·옵션이 모두 실제와 같음. 단축키 표는 `robinos.lua`와 같고, 빠진 `Super+방향키`·`Super+휠`을 더함 |
| 보안과 윤리 | 2026-10-08 | 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음, 이미지 고정(T-014). 라이브 ISO: sshd는 이미 꺼져 있음, releng의 cloud-init 유닛을 뺌. 설치본: root 잠금(robin-install), wheel은 비밀번호 sudo |
| 접근성 | 2026-10-08 | 버튼과 선택지가 마우스 전용이던 것(T-015), 보조 글자 대비(subtle 3.9:1·2.6:1 → muted). 화면 읽기 프로그램(Orca)은 아직 |
| 성능 | 2026-10-08 | 부팅 테스트 시리얼 로그: 라이브에서 데스크톱까지 35초 중 ldconfig 14초(`/etc/.updated` 없음), Docker 5초 → 고침(`37de032`, 다음 부팅 테스트에서 확인). `fcitx5-remote` 1초 폴링은 작은 프로세스 하나라 그대로 둬요 |
| 업스트림 변화 | 2026-10-08 | 저장소 버전이 문서와 같음: Hyprland 0.56.2, Quickshell 0.3.1, SDDM 0.21.0, GRUB 2.16, grub-btrfs 4.14, snapper 0.13.2, archinstall 4.5, linux 7.2.9. 오늘 빌드와 테스트가 이 버전으로 통과. **지켜볼 것**: Qt 6.12.0이 extra로 들어왔는데 Arch가 quickshell만 다시 빌드하지 않았어요(`0.3.1-1`, 8월 21일, Qt 6.11.2로 빌드). quickshell이 실행할 때 "다시 빌드해야 한다, 충돌할 수 있다"고 경고해요. 부팅 테스트(`5de4149`)에서 셸은 정상이었어요. 같은 묶음의 hyprland, fcitx5-qt, qt6ct는 9월 30일에 다시 빌드됨. quickshell 새 빌드(`0.3.1-2` 이상)가 나오면 다시 확인해요 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| (없음) | | |

`6faf853`까지 2026-10-08 부팅 테스트(30장, 라이브 독에 설치·터미널·파일·브라우저만 보임)를 마치고 푸시했어요.

## 사용자 확인 필요

- **실기기 라이브 부팅**: USB로 실제 PC에서 ISO를 부팅해 봐야 해요. 사용자만 할 수 있어요. (`막힘`)
- **실제 윈도우 PC에서 "윈도우 옆에 설치"**: VM의 가짜 윈도우 디스크로는 파티션과 부팅 파일이 그대로인 것까지 확인했어요(T-006). 진짜 윈도우가 GRUB 메뉴에 나오는지, BitLocker 복구 키를 묻는지는 실제 PC에서만 볼 수 있어요. 백업해 둔 PC나 남는 디스크로 해 주세요. (`막힘`)
- **집 PC의 VMware 서비스 켜기(T-025)**: 집 PC(Blitz)에서 VM을 만들어 켜려 했더니 VMware의 윈도우 서비스(Authorization, DHCP, NAT, USB Arbitration)가 모두 "사용 안 함"이라 VM이 켜지지 않아요. 관리자 권한이 필요해서 직접 하지 않아요. 쓰려면 관리자 PowerShell에서 `Set-Service VMAuthdService,VMnetDHCP,'VMware NAT Service',VMUSBArbService -StartupType Manual`, `Start-Service VMAuthdService,VMnetDHCP,'VMware NAT Service'`. VM(`문서\Virtual Machines\RobinOS`)과 스크립트(`build\vmware\vmware-test.py`)는 준비돼 있어요 (`막힘`)
- **작업 브랜치 `work/t025-vmware` 지우기**: 내용은 모두 main에 들어갔어요. GitHub에서 지워도 되는지 알려 주세요
- **RobinOS 파일 업데이트 배포 방식(T-026)**: 2026-10-08 사용자가 중앙 서버가 필요한지 묻고 추천을 원함. 추천: 따로 서버 없이 깃허브 릴리스를 pacman 저장소로 쓰고, RobinOS 파일을 pacman 패키지로 만들어 서명해요. `robinctl update` 한 번에 함께 올라가고 snap-pac 스냅샷도 그대로 생겨요. 서명 열쇠(GPG)를 이 PC에 만들어야 해서 사용자 답을 기다려요

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

### T-011 v0.2 후보 (지금은 하지 않아요)
- foot 제목 표시줄(hyprbars), 학습 센터 앱, 네트워크·CTF 랩 (최소화와 `Win+D`는 T-024, Qt 앱 제목 표시줄은 T-029)

## 완료

최근 것이 위에 있어요.

- 2026-10-08 T-029 Qt 앱 제목 표시줄(`cc63716`): Hyprland 0.56.2는 xdg-decoration 요청에 언제나 "서버가 그린다"고 답하면서 제목 표시줄은 그리지 않아요(`XDGDecoration.cpp`). Qt가 그 프로토콜을 보지 않게 하고(`QT_WAYLAND_DISABLED_INTERFACES=zxdg_decoration_manager_v1`) qt6-wayland의 Adwaita 장식을 씀. 앱의 최소화 요청(`xdg_toplevel.set_minimized`)은 0.56.2가 받기만 하고 처리하지 않아서(Lua 이벤트 `window.minimize`는 위키에만 있고 `hl.on: unknown event`), dconf `button-layout='appmenu:maximize,close'`로 GTK, Firefox, Qt의 최소화 단추를 뺌. 부팅 테스트(30장)에서 설치기에 어두운 제목 표시줄(최대화, 닫기), 포털 값 `appmenu:maximize,close` 확인. foot은 이 방법이 안 통해서 그대로예요. Hyprland에 `window.minimize`가 들어오면 최소화 단추를 다시 켜요

- 2026-10-08 T-028 포렌식 기초 미션 5개(`ce6a092`): 파일 종류(`file`), 해시(`sha256sum`), 사진 메타데이터(`exiftool`), 숨은 압축 파일(`binwalk`·`bsdtar`), 로그 분석(`grep | sort | uniq -c`). 채점 테스트 통과, 부팅 테스트에서 미션 목록 15개(세 묶음) 확인. forensics 프로필과 라이브 ISO에 `7zip`(binwalk가 ZIP을 꺼낼 때 씀). ISO 2,099,478,528바이트
- 2026-10-08 T-027 v0.1 프리뷰 공개: https://github.com/Yoon-robin/RobinOS/releases/tag/v0.1.0 (프리릴리스, 태그 `v0.1.0` = `87f3e9a`). 첨부: `robinos-2026.10.08-x86_64.iso`(2,097,446,912바이트), `SHA256SUMS`(`5b36e9f8...`). 깃허브 파일 한도(2GiB) 때문에 라이브 ISO에서 무거운 보안 묶음, hydra·gdb·Nerd 글꼴, 다른 언어 번역과 문서를 뺌. 이 ISO로 부팅 테스트 29장, 설치 테스트 robinos 통과. 서명은 아직 없음
- 2026-10-08 T-024 창 최소화와 Win+D: 독의 앱 아이콘이 윈도우 작업 표시줄처럼 열기, 앞으로 가져오기, 최소화, 되돌리기를 해요. 최소화한 창은 숨은 작업 공간(`special:minimized`)에 두고 원래 작업 공간을 기억해요. `Super+D`는 지금 작업 공간의 창을 모두 숨기고 다시 누르면 되돌려요(`8d48883`). 부팅 테스트에 최소화, 되돌리기, Super+D 두 번 장면을 넣고 확인(29장, 290초). 처음 테스트에서 숨긴 창의 이름이 바에 남는 걸 찾아 고침(`e00b911`). foot의 자체 제목 표시줄(`[csd] preferred=client`)이 실제로는 그려지지 않는 것도 확인해서 design.md 미결정 사항에 적음
- 2026-10-08 두 번째 PC(사용자 `robin`)에 빌드 환경 준비: WSL 2 + archlinux, `wsl-build.ps1 setup`, Windows용 QEMU 11.1.0(체크섬 확인, 7-Zip은 GitHub 공식 릴리스에서 받아 설치 없이 풂). 여기서 드러난 것 세 가지를 고침. Qt 6.12의 qmllint가 잡은 `InputField`의 id 충돌과 Theme 오탐, WSL DNS 터널링 주소(`10.255.255.254`) 때문에 틀린 미션 6 테스트(`5de4149`), 저장소 경로에 한글(`바탕화면`)이 있으면 WHPX QEMU가 ISO를 못 여는 문제(QEMU를 `build\`에서 상대 경로로 실행)

- 2026-10-08 T-006 윈도우 옆에 설치(VM): windows 설치 테스트 다섯 단계 통과. 윈도우 파티션 세 개와 C: 앞부분·부팅 파일이 그대로, `EFI/RobinOS`만 더해짐, 하드웨어 시계 LOCAL, GRUB 메뉴에 "Windows Boot Manager (on /dev/vda1)". 고친 것: os-prober가 chroot에서 udev를 못 봄(`6707c00`), GRUB 한국어 번역과 printf(`10a0c28`), 테스트의 가짜 윈도우에 BCD(`2e03020`). 진짜 윈도우 PC 확인은 "사용자 확인 필요"에 남김
- 2026-10-08 T-020 라이트 모드: 부팅 테스트에서 셸 IPC로 라이트 모드로 바꿔 터미널, 런처, 빠른 설정을 찍음. 바, 독, 런처, 빠른 설정, foot이 함께 밝게 바뀌고 글자가 잘 읽힘. 처음에는 QMP 키 표에 `;`가 없어 바뀌지 않았음(`92d0686`)
- 2026-10-08 윈도우와 같이 쓸 때 grub-mkconfig 실패: GRUB 한국어 번역의 "%2$s에서 %1$s 발견"을 셸 printf가 못 받아 30_os-prober가 실패. GRUB 설정 조각에서 `LC_ALL=C`, 설치기의 grub-mkconfig에도 붙임(`10a0c28`). 가짜 윈도우에 BCD를 넣자 드러남
- 2026-10-08 부팅 시간: 라이브 ISO에서 그래픽 화면까지 33.7초 → 19.8초, Hyprland 시작 34.7초 → 21.4초(링커 캐시 재생성 건너뜀, Docker는 소켓만). `37de032`
- 2026-10-08 T-014 웹 랩: 설치 테스트 -Lab에서 web 프로필 설치, Juice Shop v20.2.0과 DVWA(공식 이미지)가 127.0.0.1에서만 응답, 셸의 랩 상태 확인이 보고, 끄면 사라짐(`c4cd523`). 되돌린 뒤 pacman 잠금 문제(`62c231e`)도 여기서 확인. `06e8652`까지 푸시
- 2026-10-08 검증 묶음(06:10, `4fbb2c6`): 부팅 테스트에서 네트워크 미션 목록(T-018)과 한국어 fastfetch(T-019) 확인, windows 설치 테스트 다섯 단계 통과(설치본에서 `robinctl profile` 확인으로 T-010, GRUB 메뉴에 BootNext 없음과 제목 글자 없음 확인). archinstall -Lab은 되돌린 시스템의 pacman 잠금 파일 때문에 멈춤 → 고침(`62c231e`). `5975525`까지 푸시
- 2026-10-08 T-019 화면 다듬기: GRUB 제목 글자 지움, fastfetch 한국어 라벨(설치 테스트·부팅 테스트 스크린샷)
- 2026-10-08 T-010 보안 프로필: 설치한 시스템에서 `robinctl profile list`, `network --dry-run`, `packages web` 확인(`3021eda`)
- 2026-10-08 T-018 네트워크 기초 미션 5개(`4f54a7b`): IP 주소, 이름 풀이, network 프로필 설치, 포트 열고 `ss`로 확인, `nmap 127.0.0.1`(다른 대상 스캔 결과는 거절). 채점 테스트 통과. 다음 부팅 테스트에서 미션 화면 확인
- 2026-10-08 T-005 설치기 화면: 런처에서 Enter로 바로 열리고(hover 3px 기준, `89b2a7a`), 바에 "RobinOS 설치", 라이브 독의 설치 아이콘, 디스크 카드 정렬까지 부팅 테스트에서 확인. 결정: 화면으로 끝까지 설치하는 경로는 설치 테스트에 넣지 않아요. 화면은 선택을 모아 같은 백엔드에 계획을 넘기고, 백엔드는 robinos·windows 설치 테스트가, 화면 1·2단계는 부팅 테스트가 확인해요. 키 입력으로 전체를 몰아가는 테스트는 느리고 깨지기 쉬워요
- 2026-10-08 런처 검색에서 Foot Client·Foot Server 숨김(`e4338b7`): "term" 검색에 Foot 하나만 나옴
- 2026-10-08 T-017 robinctl 자동 테스트: `scripts/test-robinctl.sh`(미션 채점, 보안 프로필, 랩의 sudo 경로, 윈도우 명령 힌트)를 `wsl-build.ps1 check`에 넣음(`b9930f5`). 첫 실행에서 실제 문제 두 개를 찾아 고침: 미션 3이 base에 없는 `cmp`를 써서 설치본에서 통과할 수 없었음, 힌트가 알려 주는 fastfetch가 설치본에 없었음(`9918285`). 힌트 테스트가 WSL에서 윈도우 메모장을 띄운 실수가 있어서 명령을 직접 실행하지 않게 고침
- 2026-10-08 T-016 설치기로 설치한 시스템의 스냅샷 부팅: initramfs를 udev 방식으로 바꾼 뒤(`6264844`) robinos 설치 테스트에서 스냅샷으로 부팅한 루트가 overlay(쓰기 가능)로 뜸, 모든 단계 통과(10분)
- 2026-10-08 T-009 브랜드 색: 로고, GRUB 테마, 배경화면을 zinc와 Robin red로. 설치 테스트의 GRUB 화면에서 확인(`2fca31f`, `a5a21aa`)
- 2026-10-08 T-015 셸 키보드 접근성: 부팅 테스트에서 빠른 설정에 Tab을 세 번 누르니 "네트워크" 타일에 포커스 테두리가 보임(`d4a4a60`). 보조 글자 대비도 함께 고침
- 2026-10-08 T-007 설치기 결정과 설치 문서: design.md에 자체 설치기 결정(Calamares를 쓰지 않는 이유)을 옮기고, install.md를 설치기 기준으로 다시 씀(준비, 설치기 단계, 윈도우 옆 설치 준비와 BitLocker·빠른 시작 안내, 명령 설치, archinstall 방법). README에 설치 절 추가
- 2026-10-08 T-004 설치기 백엔드 검증: `robin-install`로 디스크 전체에 설치하는 설치 테스트가 다섯 단계 모두 통과(8분). EFI는 `/efi`, fstab에 `subvolid=` 없음(`6a472db`), 스냅샷으로 부팅할 때 그 스냅샷 안의 커널로 부팅됨(`/boot`가 `@` 안), chroot에서 돈 post-install과 스냅샷 설정도 정상. 첫 실행부터 통과했어요
- 2026-10-08 검증 묶음(`c5e9794`): ISO 빌드 8분, 부팅 테스트 215초, 설치 테스트 archinstall 11분, robinos 8분
- 2026-10-08 T-013 스냅샷으로 부팅한 상태에서 되돌리기: 설치 테스트에 `snapshot-boot` 단계를 넣고 통과. GRUB 스냅샷 메뉴에서 cowsay 설치 전 스냅샷을 골라 부팅하니 루트가 overlay였고, 그 안에서 `robinctl snapshot rollback` → 다음 부팅에서 cowsay가 사라짐(`5f22e5e`, `a82252a`)
- 2026-10-08 T-008 부팅 메뉴 이름: GRUB 메뉴가 "RobinOS Linux", 스냅샷 하위 메뉴가 "RobinOS snapshots"로 보임(설치 테스트 스크린샷, `grub.cfg` 확인, `1f40c18`)
- 2026-10-08 런처를 열자마자 Enter를 누르면 마우스 아래 항목이 열리던 문제: 고친 뒤 부팅 테스트에서 설치기 1·2단계가 제대로 찍힘(`d5e4e47`)
- 2026-10-08 T-012 설치본 첫 로그인 확인: 설치 테스트(`1295721`, 모든 단계 약 10분)에서 SDDM이 사용자 robin과 RobinOS 세션을 스스로 고르고, 로그인하면 환영 마법사가 뜨고, GRUB 스냅샷 메뉴의 설명이 영어로 제대로 보임
- 2026-10-08 T-002 VM 테스트를 WHPX로: 부팅 테스트 207초(TCG의 몇 분의 일), 설치 테스트는 모든 단계 통과. WHPX가 게스트의 재부팅을 처리하지 못해서(`Unexpected VP exit code 4`) 설치 테스트는 부팅마다 QEMU를 새로 띄워요(`8c3293d`). QEMU 11.1은 `C:\Users\Blitz\RobinOS-tools\qemu`, OVMF는 QEMU에 들어 있는 edk2 파일을 써요
- 2026-10-08 T-003 설치 테스트(archinstall 방식) 통과: archinstall 설치 → post-install → 스냅샷 설정(`@snapshots` fstab, 커널 백업 훅, grub-btrfs 항목) → GRUB 스냅샷 하위 메뉴 → cowsay 설치로 snap-pac 전후 스냅샷 → `robinctl snapshot rollback` → 다음 부팅에서 cowsay가 사라짐. 그 과정에서 테스트 쪽 문제 일곱 개를 고침(archinstall 무인 실행의 멈춤 두 가지, 한글 프롬프트와 UTF-8 조각, 캡처의 프롬프트, WHPX가 재부팅을 못 하는 문제 등, `90035c1`~`8c3293d`). 제품 쪽에서 찾은 것: 설치본 첫 로그인에서 SDDM이 사용자를 고르지 않고 세션이 Hyprland로 잡힘, 스냅샷 한글 설명이 GRUB에서 깨짐 → 고침(다음 설치 테스트에서 확인, T-012)
- 2026-10-08 T-001 데스크톱 변경 부팅 테스트 확인: 마법사 5단계와 미션 터미널, `notepad` 검색, 미션 화면, 잠금 화면 모두 정상(WHPX 부팅 테스트, ISO `7a000b9`). 마법사 키 반복 무시(`12e6b2a`), ISO 빌드가 이전 빌드를 다시 포장하던 문제(`7a000b9`), WSL 동기화 CRLF 문제(`3f110df`)를 같이 고침
- 2026-10-07 GitHub Actions를 수동 실행 전용으로, 문서 체계와 루프 절차 정리 (이번 커밋)
- 2026-10-07 WSL 2 빌드 도우미 `scripts/wsl-build.ps1`, 설치 테스트 `scripts/install-test.*` (`d1b4577`). 로컬 ISO 빌드 9분 성공
- 2026-10-07 업데이트 전 자동 스냅샷과 되돌리기 (`16d652f`, VM 검증 전)
- 2026-10-07 환영 마법사 (`99db372`), 터미널 한글 간격 (`200c07d`)
- 2026-10-07 문서 한국어화 (`521181c`), 런처 윈도우 이름 검색 (`7b4011b`), 리눅스 기초 미션 `robinctl learn` (`7f0ed7f`)
