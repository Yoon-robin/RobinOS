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
| 2026-10-09 (저녁) | `a39b6b8` 테스트 ISO | 설치 테스트 archinstall | 다섯 단계 통과. 오늘 바뀐 post-install(사용자 `.bashrc`의 RobinOS 설정, os-release와 pacman 훅, 기본 앱, 동영상·음악 앱, `which`)이 archinstall 경로에서도 문제없음 |
| 2026-10-09 | `ba358cb` 테스트 ISO | 설치 테스트 windows(6.7분), archinstall(10.1분) | 둘 다 다섯 단계 통과. 오늘 고친 설치 코드(`apps.txt`, 서비스, nsswitch, NVIDIA 감지, 전원 모드)가 윈도우 옆 설치와 archinstall+post-install 경로에서도 문제없음 |

## 품질 점검 기록

백로그 채우기 6번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 코드 검토 | 2026-10-09 (두 번째) | 오늘 들어간 학습 센터, 배경화면 포털, 화면 배율, 배터리 알림, 프롬프트, os-release를 다시 봄: 학습 센터의 새로 읽기 놓침과 배터리 경고 반복을 고침(`b9bd1d9`). 이전(오전): 오늘 들어간 코드를 다시 봄: 클립보드(명령에 넘기는 id는 숫자만), 업데이트 알림, 전원 모드, 달력, 웹 연습 서버(127.0.0.1만), CTF. `ctf_prepare`가 지운 문제 파일을 다시 만들지 않던 것을 고침(`a4e3beb`). 이전: robin-install, robinctl 스냅샷·랩, post-install, 셸 QML 전체(2026-10-08) |
| 문서와 코드 맞추기 | 2026-10-09 | desktop.md의 구성 요소·설치 위치 표(새 스크립트, 포털, mimeapps, fastfetch, 프롬프트), testing.md의 부팅 테스트 장면 수(41장)와 설치 테스트 확인 항목, README의 초기 명령(ctf), v0.2 발표문의 장면 목록을 오늘 들어간 것에 맞춤. 이전(2026-10-08 두 번째): 오늘 바뀐 것 기준으로 다시 봄: `robinctl help`의 learn·update 설명, testing.md의 부팅 테스트 장면(최소화, Super+D, 셸 다시 띄우기, 단추 배치)과 설치 테스트 확인 항목, "설치 방식은 두 가지" → 세 가지, roadmap의 미션 수, CLAUDE.md 저장소 지도(`apps.txt`, `practice/`), docs/README.md의 같이 고칠 문서 표(학습 미션, 패키지 목록)를 고침 |
| 보안과 윤리 | 2026-10-09 | 오늘 들어간 것을 다시 봄: 학습 센터는 robinctl 출력의 숫자만 터미널 명령에 넣음, Steam·알림·배터리 알림은 고정된 인자, 기본 앱 연결은 /etc/xdg라 사용자 설정이 이김, os-release 스크립트는 임시 파일에 쓰고 바꿈. 새 네트워크 서비스 없음. 이전(2026-10-08): 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음, 이미지 고정(T-014). 라이브 ISO: sshd는 이미 꺼져 있음, releng의 cloud-init 유닛을 뺌. 설치본: root 잠금(robin-install), wheel은 비밀번호 sudo |
| 접근성 | 2026-10-09 | 셸 QML의 누르는 곳은 모두 접근성 이름이 있고(이름 없는 MouseArea는 바깥을 눌러 닫는 배경뿐), 새 학습 센터의 미션 줄도 Tab·Enter와 이름이 있음. 이전(2026-10-08): 버튼과 선택지가 마우스 전용이던 것(T-015), 보조 글자 대비(subtle 3.9:1·2.6:1 → muted). 화면 읽기(Orca)는 Hyprland에 키보드 감시 인터페이스가 없어 막힘(T-040) |
| 성능 | 2026-10-09 | 부팅 테스트 시리얼 로그: SDDM 9.0초, Hyprland 시작 11.4초, 부팅 끝 15.9초(전에는 19.8초, 21.4초). 이전(2026-10-08): 부팅 테스트 시리얼 로그: 라이브에서 데스크톱까지 35초 중 ldconfig 14초(`/etc/.updated` 없음), Docker 5초 → 고침(`37de032`, 다음 부팅 테스트에서 확인). `fcitx5-remote` 1초 폴링은 작은 프로세스 하나라 그대로 둬요 |
| 업스트림 변화 | 2026-10-09 | quickshell이 0.3.2로 올라옴(Qt 6.12로 다시 빌드). 묶음 10·11 부팅 테스트에서 Qt 경고도 QML 오류도 없어서 지켜보던 것은 끝. design.md 버전 고침. Hyprland 0.56이 `start-hyprland` 없이 띄우면 경고하는데, 비정상 종료 때 `--safe-mode`로 다시 띄워서 소프트웨어 렌더링 재시도와 부딪혀 직접 실행을 유지(design.md). 그 밖에는 Hyprland 0.56.2, SDDM 0.21.0, GRUB 2.16, archinstall 4.5, linux 7.2.9 그대로 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| (없음) | | |

`71333c8`까지 2026-10-09 묶음 30 검증(`verify`: 빌드 3.1분 + 테스트 9.9분)을 마치고 푸시했어요.

## 사용자 확인 필요

- **실기기 라이브 부팅**: USB로 실제 PC에서 ISO를 부팅해 봐야 해요. 사용자만 할 수 있어요. NVIDIA 카드(GTX 16, RTX 20 이후)가 있는 PC라면 설치한 뒤 데스크톱이 뜨는지, `lsmod | grep nvidia`에 나오는지도 봐 주세요(T-030). 노트북이라면 전원을 뽑고 배터리가 10%가 될 때 "배터리가 10% 남았어요" 알림이 뜨는지(T-070), 런처의 "Steam 설치하기"로 받은 Steam에서 게임이 켜지는지(T-066)도 봐 주세요. 빠른 설정의 "야간 모드"를 켜면 화면이 따뜻한 색이 되는지도 봐 주세요(T-076, VM에서는 안 돼요). (`막힘`)
- **실제 윈도우 PC에서 "윈도우 옆에 설치"**: VM의 가짜 윈도우 디스크로는 파티션과 부팅 파일이 그대로인 것까지 확인했어요(T-006). 진짜 윈도우가 GRUB 메뉴에 나오는지, BitLocker 복구 키를 묻는지는 실제 PC에서만 볼 수 있어요. 백업해 둔 PC나 남는 디스크로 해 주세요. (`막힘`)
- **집 PC의 VMware 서비스 켜기(T-025)**: 집 PC(Blitz)에서 VM을 만들어 켜려 했더니 VMware의 윈도우 서비스(Authorization, DHCP, NAT, USB Arbitration)가 모두 "사용 안 함"이라 VM이 켜지지 않아요. 관리자 권한이 필요해서 직접 하지 않아요. 쓰려면 관리자 PowerShell에서 `Set-Service VMAuthdService,VMnetDHCP,'VMware NAT Service',VMUSBArbService -StartupType Manual`, `Start-Service VMAuthdService,VMnetDHCP,'VMware NAT Service'`. VM(`문서\Virtual Machines\RobinOS`)과 스크립트(`build\vmware\vmware-test.py`)는 준비돼 있어요 (`막힘`)
- **작업 브랜치 `work/t025-vmware` 지우기**: 내용은 모두 main에 들어갔어요. GitHub에서 지워도 되는지 알려 주세요
- **RobinOS 파일 업데이트 배포 방식(T-026)**: 2026-10-08 사용자가 중앙 서버가 필요한지 묻고 추천을 원함. 추천: 따로 서버 없이 깃허브 릴리스를 pacman 저장소로 쓰고, RobinOS 파일을 pacman 패키지로 만들어 서명해요. `robinctl update` 한 번에 함께 올라가고 snap-pac 스냅샷도 그대로 생겨요. 서명 열쇠(GPG)를 이 PC에 만들어야 해서 사용자 답을 기다려요
- **v0.2 프리뷰 공개**: v0.1 뒤로 오피스·앱 스토어·프린터·NVIDIA·업데이트 알림·Win+V 등과 미션 25개, 입문 CTF가 들어갔어요. 발표문 초안은 `docs/release-notes-v0.2.md`. 공개하기로 하면 릴리스용 xz ISO(2GiB 안)를 빌드하고 부팅 테스트한 뒤 깃허브 릴리스로 올려요(태그 `v0.2.0`, 프리릴리스)

## 진행 중

### T-090 소리 창 (출력 장치, 마이크, 앱별 음량)
- 상태: 진행 중
- 출처: 백로그 채우기 3(화면 다듬기와 윈도우에서 넘어온 사람의 불편). 빠른 설정에는 음량 막대만 있어서 스피커와 이어폰을 바꾸거나 앱별 음량을 줄일 곳이 없었어요. 부팅 테스트 VM에는 소리 장치가 없어서 음량이 늘 0이었어요
- 한 것: `SoundPanel.qml`(출력 장치, 입력 장치와 마이크 음량, 지금 출력 장치로 소리 내는 앱마다 음량). 음량 막대 끝 화살표와 IPC `sound`. 테스트 VM 두 곳(WHPX, WSL)에 `hda-duplex` 사운드 카드
- 완료 기준: 부팅 테스트 `sound` 장면에 VM 사운드 카드가 출력·입력 장치로, `pw-play`가 앱별 음량에 보임. 빠른 설정 장면의 음량 막대가 0이 아님

### T-089 Wi-Fi·블루투스 연결 창
- 상태: 진행 중
- 출처: 백로그 채우기 3(윈도우에서 넘어온 사람의 불편). 빠른 설정의 Wi-Fi 화살표는 터미널의 `nmtui`만 열고, 블루투스 타일에는 화살표가 없어서 이어폰을 연결할 길이 터미널(`bluetoothctl`)뿐이었어요
- 한 것: `ConnectPanel.qml`. Wi-Fi 목록(연결됨·저장됨·신호 순, 자물쇠 네트워크는 비밀번호 칸, `nmtui`는 맨 아래 고급 설정), 블루투스 목록(페어링·연결·끊기·지우기, 배터리). 열려 있는 동안만 주변을 찾아요. IPC `connect wifi|bluetooth`
- 완료 기준: 부팅 테스트에서 Wi-Fi 화살표로 연 창(VM에는 Wi-Fi 장치가 없다는 안내)과 IPC로 연 블루투스 창, 창 밖을 눌러 닫기

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

- 2026-10-09 묶음 30 검증(`71333c8`, verify 빌드 3.1분 + 테스트 9.9분 통과)
  - T-088 알림 센터(`52ec050`): `31-notification-center`에 방금 온 알림(RobinOS, "방금"), 모두 지우기, 방해 금지 켜기, 종 아이콘의 점이 사라짐. 첫 실행(18:28)은 사용자가 PC를 다시 시작해서 설치 테스트 시작에서 끊겨(이벤트 로그 1074, RuntimeBroker) 21:36에 다시 돌림
- 2026-10-09 묶음 29 검증(`85b8e82`, verify 빌드 3.1분 + 테스트 9.9분 통과)
  - T-087 런처 최근에 연 앱(`a3bb880`): `37-light-launcher`에 "최근에 연 앱 · 계산기". 학습 센터 미션 줄을 클릭하면 `40-learn-center-mission`에 미션 2 터미널, 창의 닫기 단추로 닫힘
- 2026-10-09 묶음 28 검증(`97b431b`, verify 빌드 3.0분 + 테스트 9.6분 통과)
  - 독 툴팁(`f86f13a`): `33-dock-pinned`에서 고정한 뒤 툴팁 없음. 빠른 설정 타일 클릭(`f6d4cb3`): `18-quick-settings-dnd`에서 방해 금지 "켜짐", 바의 종 아이콘이 꺼진 모양
- 2026-10-09 묶음 27 검증(`5228973`, verify 빌드 3.1분 + 테스트 9.6분 통과)
  - T-086 부팅 테스트 마우스 클릭(`7063634`): `32-dock-pinned`에서 실행 중인 계산기의 독 아이콘을 오른쪽 클릭해 고정, `33-launcher-pin`에서 런처의 계산기를 오른쪽 클릭해 고정(T-084, T-085를 실제 클릭으로 확인). 고정한 뒤에도 툴팁이 "독에 고정"으로 남는 것을 찾음
- 2026-10-09 묶음 26 검증(`24851db`, verify 빌드 3.1분 + 테스트 9.4분 통과)
  - 독 고정 알림 이름(`8f1e2a6`): `32-dock-pinned` 알림에 "계산기". T-085 런처에서 독에 고정(`a0ca676`): 셸 QML 오류 없음(오른쪽 클릭은 부팅 테스트로 누르지 않음)
- 2026-10-09 묶음 25 검증(`8738119`, verify 빌드 3.2분 + 테스트 9.4분 통과)
  - T-084 독에 앱 고정(`984e95b`): `32-dock-pinned`에 계산기 아이콘과 "독에 고정했어요" 알림. IPC로 부르면 알림에 앱 이름 대신 id가 나와서 다음 묶음에서 다듬음
- 2026-10-09 묶음 24 검증(`89f1ef5`, verify 빌드 3.4분 + 테스트 9.7분 통과)
  - T-082 시스템 기초 미션 31~35(`9549ff0`): robinctl 테스트가 실제 sleep으로 31·32를, df·systemctl·uname으로 33~35를 채점. `36-light-learn-center`에 "1 / 35 완료"
- 2026-10-09 묶음 23 검증(`e62be69`, verify 빌드 3.3분 + 테스트 9.7분 통과)
  - T-081 런처 파일 찾기(`63430ae`): `35-launcher-files`에 "파일 · notes ~/practice"
