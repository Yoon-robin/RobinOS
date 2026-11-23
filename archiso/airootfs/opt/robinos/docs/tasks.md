# RobinOS 작업 목록

루프가 회차마다 읽고 갱신하는 작업 목록이에요. 절차는 [loop.md](loop.md), 제품 범위와 상태는 [design.md](design.md)에 있어요.

상태: `할 일` → `진행 중` → `검증 대기` → `완료`. 사용자가 해야 하는 일을 기다리거나 같은 실패가 세 번 반복되면 `막힘`으로 두고 다른 작업을 해요. `보류`는 지금 하지 않기로 한 작업이에요(이유를 적어 둬요). `막힘`, `보류`, `검증 대기`는 작업을 고를 때 건너뛰어요. `할 일`이 비면 [loop.md](loop.md)의 "백로그 채우기"로 채워요.

## 백그라운드 작업

WSL에서 도는 긴 작업이에요. WSL 작업은 한 번에 하나만 돌려요(`scripts/wsl-build.ps1 status`로 확인).

| 작업 | 시작 | 대상 | 결과 위치 | 상태 |
|---|---|---|---|---|
| (없음) | | | | |

## 정기 점검

처음부터 다시 확인하는 회귀 점검이에요. 묶음 검증(`verify`)이 이걸 겸하고, 묶음이 하루 넘게 없었으면 한 번 돌려요([loop.md](loop.md) "정기 점검"). 최근 두 줄만 두고 나머지는 [done.md](done.md)로 옮겨요.

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-11-24 (새벽 1시) | `ddcb219` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 4.4분, 테스트 17.7분), 이어서 `install-test -Installer encrypted` | 통과. 장면 판정 열다섯 개 모두 PASS, 키트 토큰의 다크·라이트 스크린샷(바탕 화면, 빠른 설정, 잠금 화면, 학습 센터) 확인. 설치 테스트 다섯 단계. 암호화 설치도 다섯 단계 모두 통과: 단계마다 GRUB이 비밀번호를 묻고(`*-grub-password.png`) 풀린 뒤 설치본·스냅샷 부팅·되돌리기까지 |
| 2026-10-13 (새벽 3시) | `b2a3624` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.4분, 테스트 17.7분) | 통과. 장면 판정 열다섯 개 모두 PASS, 새 `zoomed`(zoom_factor 2)·`unzoomed`(1), 확대 스크린샷 확인. 설치 테스트 다섯 단계 |

## 품질 점검 기록

백로그 채우기 7번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 설계 점검 | 2026-10-10 | 사용자 방향 결정("보안 학습에만 두지 말고 나만의 새로운 OS") 뒤 design·vision·brand·README를 다시 봄. 정체성이 문서마다 달랐고(보안 학습 OS / 윈도우 이주 OS), 빈 곳은 실기기 0번, 보안 부팅 안내 없음, 설정 앱 없음, 부팅 화면 없음. design.md "설계 점검" 표와 T-147~T-151 |
| 코드 검토 | 2026-11-24 | robinctl·robin-install·desktop/bin을 다시 봄(T-169): 미션 31·32가 sleep.pid 없이 확인하면 안내 없이 멈추던 것, `audit`이 `ufw disable` 뒤에도 방화벽이 켜졌다고 하던 것(ufw.service는 계속 active), 400 권한 SSH 열쇠를 남도 읽는다고 하던 것, 꽂아 둔 암호화 USB만 열려 있어도 디스크가 암호화됐다고 하던 것, `update --preview`가 NetworkManager나 snapper 실패에 조용히 끝나던 것, 지운 연습 파일(포렌식·리버싱·미션 39)이 표시 파일 때문에 다시 안 생기던 것, `robinos-vm-display`가 배율 "1.00"과 "1"을 달리 봐서 화면 이벤트마다 모드를 다시 걸던 것, 설치기가 예상 못 한 예외에 `@@ error` 없이 죽던 것, 암호화할 때 GRUB에서 칠 수 없는 한글 비밀번호를 받던 것을 고침. 테스트 일곱 개 더함. 이전(2026-10-10): 새벽에 들어간 작업 보기, 독 미리보기, 바탕 화면 Alt+F4, CTF 9번 서버, 공휴일, 이모지를 다시 봄: 묶음 완료 메시지가 5·10·15번 같은 번호에만 붙어 순서를 바꿔 풀면 틀리던 것을 고치고(T-113), 이모지 입력 여유를 0.3초에서 0.4초로(런처가 닫히는 데 0.18초). 나머지는 문제없음(T-114). 이전(2026-10-09 세 번째): 밤에 들어간 연결 창, 소리 창, 트레이, 창 붙이기, Alt+Tab을 다시 봄: Alt+Tab 목록에 닫힌 창이 남던 것을 고침(T-096). 이전(두 번째): 오늘 들어간 학습 센터, 배경화면 포털, 화면 배율, 배터리 알림, 프롬프트, os-release를 다시 봄: 학습 센터의 새로 읽기 놓침과 배터리 경고 반복을 고침(`b9bd1d9`). 이전(오전): 오늘 들어간 코드를 다시 봄: 클립보드(명령에 넘기는 id는 숫자만), 업데이트 알림, 전원 모드, 달력, 웹 연습 서버(127.0.0.1만), CTF. `ctf_prepare`가 지운 문제 파일을 다시 만들지 않던 것을 고침(`a4e3beb`). 이전: robin-install, robinctl 스냅샷·랩, post-install, 셸 QML 전체(2026-10-08) |
| 문서와 코드 맞추기 | 2026-10-10 | 새벽 뒤로 들어간 기능(Alt+Tab, 작업 보기, 빠른 메뉴, 이모지, 독 미리보기, 보안 점검, 앱 제거, 최근 파일, CTF 6~10, 알림 센터 열기)을 기준으로 다시 봄: 단축키 카드의 Print 설명, CTF 9번 서버가 접속마다 1시간을 다시 기다리던 것, 스크린샷 폴더 경로, 빠른 메뉴·구성 요소·윈도우 이름 표, 테스트 문서, 발표문을 고침(T-129). 이전(2026-10-09 밤): 밤에 들어간 기능(연결·소리 창, 트레이, 창 붙이기, Alt+Tab, 이모지, 보안 미션) 기준으로 다시 봄: desktop.md 구성 요소 표에 이모지·트레이, 환영 마법사 단축키 안내에 창 반쪽 붙이기·이모지를 넣음(T-099). 단축키 표, 단축키 보기 카드, README, 발표문, testing.md 장면 목록은 맞음. 이전(낮): desktop.md의 구성 요소·설치 위치 표(새 스크립트, 포털, mimeapps, fastfetch, 프롬프트), testing.md의 부팅 테스트 장면 수(41장)와 설치 테스트 확인 항목, README의 초기 명령(ctf), v0.2 발표문의 장면 목록을 오늘 들어간 것에 맞춤. 이전(2026-10-08 두 번째): 오늘 바뀐 것 기준으로 다시 봄: `robinctl help`의 learn·update 설명, testing.md의 부팅 테스트 장면(최소화, Super+D, 셸 다시 띄우기, 단추 배치)과 설치 테스트 확인 항목, "설치 방식은 두 가지" → 세 가지, roadmap의 미션 수, CLAUDE.md 저장소 지도(`apps.txt`, `practice/`), docs/README.md의 같이 고칠 문서 표(학습 미션, 패키지 목록)를 고침 |
| 보안과 윤리 | 2026-10-10 (오전) | 새벽 뒤로 들어간 것을 다시 봄: 텍스트 미션이 인터넷 방문자를 사설 주소(192.168.0.x)로 적어서 문서용 주소(198.51.100.x)로 바꾸고 테스트를 넣음, ethics.md의 주소 기준을 정확히(집 네트워크는 사설 주소), 런처 웹 검색은 고를 때만 보낸다고 적음(T-140). 계산은 eval 없이 직접 파싱, 앱 제거는 id를 글자 검사한 뒤 터미널에서 pacman이 묻고, 알림의 `x-robinos-open`은 `/`로 시작하는 로컬 파일만 xdg-open에 인자로 넘김(로컬 앱은 이미 무엇이든 실행할 수 있어 새 권한 없음), 독의 창 닫기는 앱에 닫기를 부탁만 함, CTF 9번 서버는 띄운 지 1시간 뒤 꺼짐(T-129), `vmware-checkvm`은 VMware로 감지될 때만 root로 돌고 open-vm-tools의 공식 도구. 이전(새벽): 새 `robinctl audit`이 라이브 ISO의 LLMNR(5355/udp, 모든 주소)을 찾아 끔(T-121). 그 앞(밤): 밤에 들어간 것을 다시 봄: 입문 CTF 9번 서버는 127.0.0.1에만 열리고 1시간 뒤 꺼짐(테스트가 확인), 8번 사전 공격은 CTF 쪽지에만, openssh는 클라이언트만(sshd는 꺼짐, 설치 테스트가 확인), 트레이 테스트 도우미는 ISO의 /opt/robinos/scripts에만 있고 자동으로 돌지 않음. 이전(2026-10-09): 오늘 들어간 것을 다시 봄: 학습 센터는 robinctl 출력의 숫자만 터미널 명령에 넣음, Steam·알림·배터리 알림은 고정된 인자, 기본 앱 연결은 /etc/xdg라 사용자 설정이 이김, os-release 스크립트는 임시 파일에 쓰고 바꿈. 새 네트워크 서비스 없음. 이전(2026-10-08): 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음, 이미지 고정(T-014). 라이브 ISO: sshd는 이미 꺼져 있음, releng의 cloud-init 유닛을 뺌. 설치본: root 잠금(robin-install), wheel은 비밀번호 sudo |
| 접근성 | 2026-10-10 | 밤에 들어간 창(연결·소리 창, 작업 보기, 알림 센터)을 다시 봄: 연결 창의 네트워크·장치 줄과 소리 창의 장치 줄이 마우스로만 눌려서 Tab·Enter·포커스 테두리를 넣음(T-106). 작업 보기는 화살표·Enter·Esc, Alt+Tab은 키보드 자체가 조작이라 문제없음. 이전(2026-10-09): 셸 QML의 누르는 곳은 모두 접근성 이름이 있고(이름 없는 MouseArea는 바깥을 눌러 닫는 배경뿐), 새 학습 센터의 미션 줄도 Tab·Enter와 이름이 있음. 이전(2026-10-08): 버튼과 선택지가 마우스 전용이던 것(T-015), 보조 글자 대비(subtle 3.9:1·2.6:1 → muted). 화면 읽기(Orca)는 Hyprland에 키보드 감시 인터페이스가 없어 막힘(T-040) |
| 성능 | 2026-10-10 (아침) | 묶음 63 부팅 테스트 시리얼 로그: SDDM 8.4초, Hyprland 11.1초인데 부팅 끝이 83.7초. 시계 동기화 대기(`systemd-time-wait-sync`)가 IPv6 NTP 시간 초과로 78초까지 붙잡아서 고침(T-139). 부팅 테스트 요약에 `Startup finished` 줄을 남겨 다음부터 바로 보이게. 이전(묶음 38): SDDM 8.6초, Hyprland 시작 11.4초, 부팅 끝 13.9초(전에는 9.0초, 11.4초, 15.9초). 독은 미리보기 자리까지 늘 큰 표면이지만 투명한 곳은 흐림에서 빠짐(`ignore_alpha`). 이전(2026-10-09): 부팅 테스트 시리얼 로그: SDDM 9.0초, Hyprland 시작 11.4초, 부팅 끝 15.9초(전에는 19.8초, 21.4초). 이전(2026-10-08): 부팅 테스트 시리얼 로그: 라이브에서 데스크톱까지 35초 중 ldconfig 14초(`/etc/.updated` 없음), Docker 5초 → 고침(`37de032`, 다음 부팅 테스트에서 확인). `fcitx5-remote` 1초 폴링은 작은 프로세스 하나라 그대로 둬요 |
| 업스트림 변화 | 2026-10-10 (오전) | Hyprland 0.56.2, Quickshell 0.3.2, Qt 6.12.0, systemd 262, linux 7.2.9, Firefox 157.0.1, archiso 91 그대로(묶음 65 빌드와 같음). 묶음 65 시리얼 로그의 Hyprland 경고는 start-hyprland와 실시간 스케줄링 실패(권한 없음, 동작에는 영향 없음)뿐. 이전: Hyprland 0.56.2, Quickshell 0.3.2 그대로. 묶음 38 시리얼 로그에 Hyprland 경고는 알려진 start-hyprland 하나뿐. 이전(2026-10-09): quickshell이 0.3.2로 올라옴(Qt 6.12로 다시 빌드). 묶음 10·11 부팅 테스트에서 Qt 경고도 QML 오류도 없어서 지켜보던 것은 끝. design.md 버전 고침. Hyprland 0.56이 `start-hyprland` 없이 띄우면 경고하는데, 비정상 종료 때 `--safe-mode`로 다시 띄워서 소프트웨어 렌더링 재시도와 부딪혀 직접 실행을 유지(design.md). 그 밖에는 Hyprland 0.56.2, SDDM 0.21.0, GRUB 2.16, archinstall 4.5, linux 7.2.9 그대로 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| (없음) | | |

`ddcb219`까지 2026-11-24 묶음 검증(`verify -Installer robinos`)과 `install-test -Installer encrypted`(집 PC)를 마치고 푸시했어요.

## 사용자 확인 필요

- **정체성 "예쁜 UI를 가진 OS" 읽은 방식 (2026-11-24)**: 이렇게 읽고 진행하고 있어요. 다르면 알려 주세요. ① 한 줄 정의를 그 말 그대로 쓰고, 화면(로고 아래 포함)에는 이름만 둬요 ② 예전 목적("처음 쓰는 리눅스")의 기능(윈도우 단축키, 터미널 힌트, 학습 센터)은 남기되 앞세우지 않아요 ③ 키트의 "설명 문장 쓰지 않기"를 셸 전체에 적용해요. 처음 쓰는 사람에게 꼭 필요한 안내(설치기 지우기 경고, 복구 키)는 키트가 허락하는 자리로 옮겨요 ④ 강조색 고르기(빨강·주황·초록…)와 "투명도 줄이기"를 없앴어요(파랑 하나, 유리 없음) ⑤ 키트의 출처(Figma Community, CC BY 4.0)를 README와 릴리스 노트에 적어요

- **실기기 라이브 부팅 (지금 가장 값진 검증, 2026-10-10 설계 점검)**: 검증 묶음 73번(2026-10-12까지)이 모두 VM이었고 실제 PC에서는 한 번도 켜 보지 않았어요. USB로 실제 PC에서 ISO를 부팅해 봐 주세요. 먼저 펌웨어 설정에서 보안 부팅을 꺼야 해요([install.md](install.md) "보안 부팅 끄기", 윈도우를 남길 거면 BitLocker 복구 키부터 확인). 데스크톱이 뜨는지, Wi-Fi·소리·화면 밝기·한글 입력이 되는지가 먼저예요. NVIDIA 카드(GTX 16, RTX 20 이후)가 있는 PC라면 설치한 뒤 데스크톱이 뜨는지, `lsmod | grep nvidia`에 나오는지도 봐 주세요(T-030). 노트북이라면 전원을 뽑고 배터리가 10%가 될 때 "배터리가 10% 남았어요" 알림이 뜨는지(T-070), 런처의 "Steam 설치하기"로 받은 Steam에서 게임이 켜지는지(T-066)도 봐 주세요. 빠른 설정의 "야간 모드"를 켜면 화면이 따뜻한 색이 되는지도 봐 주세요(T-076, VM에서는 안 돼요). (`막힘`)
- **실제 윈도우 PC에서 "윈도우 옆에 설치"**: VM의 가짜 윈도우 디스크로는 파티션과 부팅 파일이 그대로인 것까지 확인했어요(T-006). 진짜 윈도우가 GRUB 메뉴에 나오는지, BitLocker 복구 키를 묻는지는 실제 PC에서만 볼 수 있어요. 백업해 둔 PC나 남는 디스크로 해 주세요. (`막힘`)

## 진행 중

### T-147 보안 부팅과 BitLocker 안내
- 상태: 진행 중
- 출처: 설계 점검(2026-10-10) "보안 부팅". 문서 어디에도 없었어요
- 한 것: install.md "보안 부팅 끄기"(BitLocker 복구 키 확인, 윈도우의 고급 시작 → UEFI 펌웨어 설정, 설치 뒤에도 꺼 둬야 하는 것), 준비 목록, README 내려받기 안내
- 한 것(2026-10-12 집 PC): 설치기가 디스크의 `BitLocker` 파티션을 알아보고(`lsblk`의 FSTYPE) 디스크 카드에 "윈도우 있음 (BitLocker)", "윈도우 옆에 설치"의 확인 단계에서 "복구 키를 따로 적어 두었어요"에 체크해야 설치 시작. 백엔드도 계획에 `bitlocker_key_saved`가 없으면 디스크를 건드리기 전에 멈춰요. `test-robin-install.py`에 가짜 BitLocker 디스크 검사 여덟 개. 확인 상자는 `ConfirmBox` 하나로 합쳤어요(지우기 확인과 같이 써요)
- 남은 것: 설치 테스트 windows의 가짜 디스크에 BitLocker 서명(`-FVE-FS-`)을 넣은 장면. 다음 릴리스 노트에 보안 부팅 안내
- 완료 기준: 설치기 테스트(`test-robin-install.py`)에 가짜 BitLocker 파티션, 설치 테스트 windows에서 경고 장면

### T-025 VMware에서 쓰기
- 상태: 진행 중
- 출처: 사용자 요청("vmware로 깔아줘"). VMware Workstation Pro 26H1, VM은 `문서\Virtual Machines\RobinOS\RobinOS.vmx`(EFI, 8GB, NVMe 64GB, 3D 가속 켬)
- 찾은 것: ① 3D 가속을 켜면 Hyprland는 `vmwgfx`로 잘 그리는데 셸(Qt)은 `Could not create EGL surface`로 아무것도 안 그림. ② 화면이 물리 크기를 알려 주지 않아 Hyprland 자동 배율이 2배 → 1280×800 창이 640×400 바탕 화면(환영 마법사가 위아래로 잘림). ③ VMware 창 크기를 바꾸면 커널은 새 크기를 받는데 Hyprland는 처음 해상도를 그대로 씀. ④ 설치본에는 `open-vm-tools`가 없음
- 한 것: `robinos-shell`(EGL 실패를 보면 셸만 소프트웨어로 다시 띄움, 죽으면 다시 띄움), VM 화면(`Virtual-*`)은 배율 1, `robinos-vm-display`(창 크기를 따라감), 설치기가 VMware에서는 `open-vm-tools`와 `vmtoolsd`를, QEMU/KVM에서는 `qemu-guest-agent`를 설치. 라이브 VM에서 셋 다 직접 확인(셸 강제 종료 후 다시 뜸, 1718×920·배율 1로 맞춤, udev change 신호로 다시 맞춤)
- `426e32d` ISO를 VMware에서 띄우니 셸이 GPU 실패 뒤 아무것도 안 그리는 대신 Wayland 오류(`wl_surface.attach` invalid arguments)로 바로 죽었어요. `robinos-shell`은 살아 있는 셸에서만 GPU 실패를 확인해서 이걸 그냥 "죽음"으로 세고 GPU 모드로 다섯 번 다시 띄운 뒤 포기했어요. 셸이 죽은 뒤에도 로그를 보고 소프트웨어로 바꾸게 고쳤고, 라이브 VM에서 확인했어요
- 같이 한 것: 화면에 보이는 단축키를 `Super` 대신 `Win`으로 적어요(사용자 질문 "Super 키가 뭐야?"). 환영 마법사 마지막 단계에 "Win 키는 리눅스에서 Super 키라고 불러요"를 넣었어요
- 지금까지(2026-10-08, robin PC): `426e32d` ISO를 VMware VM에 설치함. 설치기가 마지막 `umount`에서 멈췄고(gpg-agent, `933ca31`에서 고침) 손으로 분리한 뒤 고친 `robinos-shell`을 넣어 부팅. 설치본에서 `open-vm-tools` 설치, `vmtoolsd` 켜짐, SDDM 로그인 화면까지 확인. 로그인 뒤 데스크톱은 아직 못 봄(VMware에는 키 입력을 보낼 방법이 없어 사람이 로그인해야 해요)
- 검증: `933ca31` ISO로 부팅 테스트(29장)와 설치 테스트 robinos(다섯 단계) 통과, `e038f2a`까지 main 푸시(정기 점검 표)
- 2026-10-11: 사용자가 집 PC(Blitz)의 VMware 서비스(Authorization, DHCP, NAT)를 켜서 `Running` 확인. 이제 이 PC에서 VM을 만들어 최신 ISO로 설치해 볼 수 있어요
- 2026-10-12 집 PC(Blitz): 묶음 72의 ISO(`bd8c495`, robinos 패키지 포함)를 `build\vmware\vmware-test.py install`로 VM에 설치하는 중. 끝나면 `installed`로 설치본 부팅·해상도·vmtoolsd 확인. 다른 PC로 옮기면 이 VM은 집 PC에만 있어요
- 2026-11-24: 스크립트를 `scripts/vmware-test.py`로 옮겨 커밋했어요(어느 PC에서나 `python scripts/vmware-test.py create|install|installed|stop`, ISO는 `build\vmware\robinos.iso`). [build-environment.md](build-environment.md) "다른 PC에서 이어서 하기"
- 남은 것 (VMware가 있는 PC: robin PC, 집 PC(Blitz, VMware Workstation 26.0)): 최종 ISO로 VMware VM에 다시 설치(`vmrun` 게스트 명령, 계획은 디스크 `/dev/nvme0n1` 전체), 로그인 뒤 셸·해상도 확인. VMware가 없는 PC의 루프는 이 작업을 건너뛰어요

### T-151 정체성 문구를 화면에
- 상태: 진행 중 (화면 문구는 묶음 73에서 검증, 스크린샷 바꾸기 남음)
- 출처: 설계 점검(2026-10-10) "정체성 문구". 2026-10-12에 목적을 "처음 쓰는 리눅스"로 정해서(design.md "목적 결정") 화면에 넣을 말이 생겼어요
- 한 것(2026-10-12): 로고 한 줄 소개와 SVG(푸시함), 환영 마법사 첫 화면. 사용자 요청("T-151 남은 화면 문구도 바꿔줘")으로 나머지도 바꿨어요: 로그인 화면(SDDM, 방패 아이콘 → 터미널 아이콘)과 잠금 화면(hyprlock)의 "허가받은 환경에서만 쓰는 보안 학습용 시스템이에요", 설치본 부팅 메뉴의 "Security Learning Workstation" → 한 줄 소개(Unifont라 한글이 나와야 해요)와 윤리 안내 줄 빼기, 라이브 부팅 메뉴·콘솔·ISO 이름 "RobinOS Security Learning Live" → "RobinOS Live"(영어로 둔 건 syslinux와 리눅스 콘솔이 한글을 못 그려서예요), 터미널 인사 "RobinOS 보안 학습 환경" → "RobinOS · 쓰다 보면 리눅스를 알게 되는 OS", `robinctl` 도움말의 "허가받은 환경에서 보안을 배우는 시스템이에요" 줄 빼기(실습 안내 줄은 그대로), 기본 배경화면 그림(`robinos-default.svg`)의 글, `config.toml`의 `purpose`(읽는 코드 없음)를 `learn-linux`로. 윤리 안내는 motd, 학습 센터, 랩, ethics.md에 그대로예요
- 한 줄 소개 다시(2026-10-12, 사용자: "쓰다 보면 리눅스를 알게 되는 OS 이거 살짝 cringe야" → "화면엔 이름만"): 부팅 메뉴(설치본 GRUB, 라이브 BIOS 스플래시), 로그인·잠금 화면, 기본 배경화면 그림, 터미널 인사에서 소개 줄을 빼고 이름만 뒀어요. 환영 마법사 첫 화면도 소개 문장을 뺐어요. 로고 아래와 README, 소개 영상 끝에만 "처음 쓰는 리눅스"를 써요(`work/batch74`)
- 남은 것: 묶음 검증(`verify -Installer robinos`)으로 확인하기. 특히 설치 테스트의 부팅 메뉴 스크린샷에서 한글 한 줄 소개가 네모로 깨지지 않는지. 통과하면 README 학습 센터 스크린샷("1 / 40")과 소개 영상의 부팅 메뉴·로그인 화면을 새 스크린샷으로 바꾸고, 영상에서 가린 부분을 없애기
- 완료 기준: 부팅 테스트의 SDDM·잠금 화면 장면, 설치 테스트의 부팅 메뉴 스크린샷, README 로고

## 할 일 (위에서부터)

2026-11-24 정체성 결정("예쁜 UI를 가진 OS", [design.md](design.md))으로 순서를 다시 봤어요. 모든 화면을 robin-ui V5 키트로 옮기는 일(T-168)이 맨 앞이에요. 그다음이 실제 PC에서 켜지는 것과 이미 하던 기능이에요.

### T-168 robin-ui V5로 모든 화면 옮기기
- 상태: 진행 중
- 출처: 사용자(2026-11-24) "아이덴티티 다시 설정, 예쁜 UI를 가진 OS"와 robin-ui 브랜드 키트(V5). 키트는 `assets/brand/robin-ui/`, 규칙은 [brand.md](brand.md)
- 한 것(①, 2026-11-24 집 PC): 정체성 문서(design.md, brand.md, CLAUDE.md, README, vision.md, loop.md, desktop.md). `Theme.qml` 토큰을 키트 값으로(푸른 검정 면, 파랑 하나, 살구색 `note`, 초록 없음, 모서리 6/7/10/12/14, Pretendard, 150/200/240ms, 굵기 토큰), 유리 토큰을 판 토큰으로 이름 바꾸기(`glass`→`panel`, `glassBorder`→`panelBorder`, `glassTile`→`tile`), 강조색 고르기(설정, 빠른 설정, 환영 마법사)와 "투명도 줄이기" 빼기, 배경화면 빛을 파랑 하나로, Hyprland 셸 블러 규칙 빼기·창 모서리 14·테두리와 바탕색, GNOME 강조색 파랑
- 한 것(②, 2026-11-24 `work/batch-home8`): `ActionButton`(모서리 7, 보통 컨트롤은 컨트롤 면 + 1px 선, `danger`·`danger-fill` 더함, 누르면 0.98), `Switch`(34×19, 꺼지면 어두운 홈과 선), `InputField`(컨트롤 면, 초점에 파란 선), `QsSlider`(3px 홈, 흰 손잡이 11), `ToggleTile`(켜지면 파랑 옅은 면 + 파란 아이콘, 파란 채움은 주 동작에만), `IconButton`, `Kbd`, `FocusRing`(파란 링). 빠른 설정의 고른 칸(밝기 모드, 배율)은 회색 면 + 흰 글자, 독 이름 풍선은 표시기 면. 굵기 `Font.*`를 모두 `Theme.weight`·`weightStrong`·`weightHead`로. 테마 미리보기 그림의 zinc 색을 키트 색으로
- 한 것(③ 일부): 토스트 알림을 알림 카드(모서리 14, 왼쪽 짧은 막대: 보통·빨강, 제목 굵기 550)로. 바의 "스냅샷 · 임시"와 "녹화 중"을 상태 칩(`BarButton`의 `tone`: 알약, 표시기 면, 왼쪽 막대, 살구색·빨강 글자)으로. 패널이 열릴 때 튀는 스프링(OutBack)을 빼고 4px만 들어오게(OutQuint)
- 한 것(⑥ 일부): 잠금 화면(hyprlock), 로그인 화면(SDDM), GRUB 테마, 라이브 BIOS 메뉴(syslinux), qt6ct 다크·라이트 팔레트, 배경화면 SVG 두 장, 스크린샷 영역 선택 색을 키트 색으로(zinc → 푸른 검정, 빨강 → 파랑, 초록 → 파랑). 잠금·로그인 글꼴은 Pretendard. 남은 것: 로고 SVG(`build-logo.py`의 색과 한 줄 소개 빼기, 글꼴이 있는 WSL에서 다시 만들기), fastfetch 울새, Ptyxis·foot 팔레트
- 한 것(④ 일부): 설정 창을 옆 기둥(폭 178, `side` 면, 줄 33, 고른 것은 회색 면 + 파란 아이콘) + 판 + 카드(이름표는 카드 밖 11px, 스위치 줄과 정보 줄은 카드 면, 줄 41, 줄 사이 선은 9 들여서)로
- 한 것(⑥ 이어서, 2026-11-24 밤): 로고 SVG 다섯 개를 키트 색과 Pretendard 650으로 다시 만들고 한 줄 소개를 뺐어요(`build-logo.py`). 라이브 BIOS 메뉴 배경(`splash.png`), fastfetch 울새(프롬프트가 파랑), 셸 마크(`Mark.qml`: 거의 검은 네모 + 흰 울새 + 파란 번짐), 로그인 화면 마크. README에 키트 출처(CC BY 4.0)
- 한 것(개발 스택, 2026-11-24 밤): [design.md](design.md) "개발 스택 다시 보기"(바탕은 그대로, 키트 `tokens.json`이 값의 원본). `scripts/check-kit.py`가 `check`에서 키트를 벗어난 색·굵기·스프링·모서리·셸 블러를 잡아요
- 한 것(⑤ 일부): 런처(묶음 이름표 11px, 줄 41, 고른 줄은 회색 면 + 파란 아이콘, 아이콘 칸은 컨트롤 면, "켜짐" 칩은 왼쪽 파란 막대, 키 안내가 있던 아래 줄과 esc 키 표시 빼기), 빠른 설정(전원 끄기는 빨간 테 + 빨간 글자, 업데이트 줄에 컨트롤 선)
- 한 것(④·⑥·⑦ 이어서, 2026-11-24 새벽): 설치기·환영 마법사의 고른 카드는 두꺼운 흰 테 대신 회색 면 + 진한 선(테마 미리보기만 파란 선), 학습 센터의 다음 미션 칸과 끝낸 미션 원은 파랑 옅은 면 + 파란 아이콘(파란 채움은 "터미널에서 시작" 하나), 진행 막대 3px, 머리의 설명 문장 빼기(미션 화면이 `robinctl learn check`를 알려 줘요), 환영 마법사의 한글 켬 표시도 옅은 파랑. 잠금 화면의 흐림과 키 안내 빼기. 프롬프트 `>`를 파랑으로, foot 팔레트의 면을 키트 색으로(ANSI 초록·노랑은 프로그램 출력의 뜻이라 남겨요). 코드 글꼴을 키트의 Cascadia로(합자 없는 Cascadia Mono, `ttf-cascadia-code`), 기본 글꼴을 Pretendard로(dconf, qt6ct, fontconfig). 아이콘은 Lucide 그대로 둬요: 키트 아이콘(31개)과 같은 24 칸·둥근 끝 선 아이콘이고, 셸에는 그보다 많은 아이콘이 필요해요
- 남은 단계(한 단계가 1~3회차):
  - ② 공용 부품: `ActionButton`(모서리 7, 파란 채움·빨간 테), `Switch`(34×19, 꺼지면 어두운 홈), `InputField`, `QsSlider`(3px 홈, 흰 손잡이 11), `ToggleTile`, `FocusRing`(파란 링), 굵기를 `Theme.weight*`로
  - ③ 표시기: 토스트·알림(왼쪽 짧은 막대, `data-tone` 같은 tone 속성), 독(짙은 면), 상태 칩
  - ④ 창들: 설정·학습 센터·설치기·환영 마법사를 옆 기둥(`side`) + 판 + 카드(`rk-label`은 카드 밖) 구조로, 줄 높이 41, 설명 문장 정리
  - ⑤ 바·런처·빠른 설정·달력·알림 센터·연결·소리 패널의 줄·타일·이름표
  - ⑥ 시스템 화면: SDDM(`themes/sddm/robinos`), hyprlock, GRUB, syslinux, qt6ct 팔레트, Ptyxis·foot 팔레트, `robinos-screenshot` 선택 색, 배경화면 SVG, 로고(`build-logo.py` 색과 한 줄 소개 빼기), fastfetch 울새
  - ⑦ 아이콘을 키트의 선 아이콘으로 맞추기(`icons.js`), 코드 글꼴(Cascadia) 정하기, README 스크린샷·소개 영상 다시 찍기와 키트 출처 적기
- 검증: 단계마다 `wsl-build.ps1 check`(qmllint), 부팅 테스트 스크린샷을 다크·라이트로 직접 보기. 키트에서 벗어난 것을 세는 검사(`check-desktop.sh`에 셸 QML의 `#`색 리터럴, 초록·노랑, `Theme.` 밖의 모서리 값)도 넣어요
- 완료 기준: 부팅 테스트의 모든 장면이 키트 문법(면 셋, 파랑 하나, 컨트롤 모서리 7, 유리 없음)을 따르고, 시스템 화면(로그인, 잠금, 부팅 메뉴)도 같은 색

### T-155 부팅 테스트에 성공 조건 넣기
- 상태: 진행 중
- 출처: ChatGPT 세 번째 검토(2026-10-12). 묶음 77이 "통과"로 나왔는데 라이브 ISO에서 터미널이 하나도 안 열렸어요. 스크린샷만 찍는 테스트는 화면이 틀려도 통과해요
- 한 것(2026-10-12): 멈춘 시나리오는 실패(종료 코드 1, WHPX·TCG 실행기 둘 다), 터미널을 연 뒤 "활성 창이 Ptyxis"일 때만 남는 `logger` 표시를 시리얼 로그에서 확인(`expect_serial`), 안 열리면 tty3 진단, 키·포인터 QMP 명령이 오류로 답하면 실패(`Qmp.act`), `build-iso.sh`가 빌드한 airootfs의 `/usr/share/robinos/bin`과 `/usr/local/bin`이 모두 실행 가능한지 확인
- 한 것(2026-10-13 집 PC): `scripts/e2e-check.sh`(ISO의 `/opt/robinos/scripts`)가 장면마다 VM 안에서 상태를 확인해 `robinos-e2e: scenario=<이름> status=PASS|FAIL <근거>`를 저널에 남기고, `boot-test-qmp.py`의 `check_scene`이 시리얼 로그에서 결과를 모아 하나라도 실패면 끝에 실패. 장면: 터미널(Ptyxis), 미션 1, 최대화(`fullscreen` 1, 바 아래·독 위, 화면 70% 넘게)와 되돌리기, 새 터미널이 창 하나만 늘리기, 셸 다시 띄우기(새 `qs`와 IPC 응답), 라이트·다크(저장된 값과 GTK `color-scheme`). 가짜 hyprctl로 판정 시험. [testing.md](testing.md) "상태로 판정하는 장면"
- 2026-10-13 묶음 검증(`a2c513a`): 열 장면 모두 PASS(최대화 y=37·높이 792/900, 되돌린 높이 673, Ptyxis 1→2, 녹화 4초, 새 qs, 라이트·다크 저장값과 GTK)
- 한 것(2026-10-13 두 번째): 같은 장면을 여러 번 확인할 수 있게(`label`, 입력한 뒤의 시리얼 로그만 봐요), 학습 센터에서 연 미션 터미널(`mission-terminal`), 결과 줄의 색 코드 빼기
- 남은 것: 일부러 망가뜨린 ISO로 실패하는 것 확인
- 처음 할 것(기록): 장면마다 게스트 안에서 확인하고 통과했을 때만 `logger -t robinos-e2e "scenario=<이름> status=PASS"`를 남기기. 후보: 최대화(`hyprctl clients -j`의 fullscreen, at, size가 바·독 사이), 학습 미션 터미널의 출력, 테마 바꾸기(저장된 값과 GTK 설정), 셸 재시작(새 Quickshell과 IPC 응답), 새 터미널을 열 때 창이 하나만 늘어나는지. 결과를 장면별로 모아 하나라도 실패면 전체 실패
- 완료 기준: 위 장면이 화면이 아니라 상태로 판정되고, 일부러 망가뜨린 ISO(실행 권한 빼기 등)에서 테스트가 실패하는 것을 한 번 확인

### T-156 설치본 펌웨어와 펌웨어 업데이트
- 상태: 완료 (2026-10-13 묶음 검증에서 설치본의 `pacman -Q sof-firmware fwupd` 확인. 실제 PC의 GNOME Software 펌웨어 목록은 실기기 확인 때 같이 봐요)
- 출처: 다른 OS와 비교(2026-10-12). `sof-firmware`, `linux-firmware-marvell`, `wireless-regdb`가 라이브 ISO(`archiso/packages.x86_64`)에만 있고 설치본 목록에는 없었어요. 라이브에서는 소리가 나던 요즘 인텔·AMD 노트북이 설치하고 나면 소리가 안 날 수 있어요. 펌웨어 업데이트(fwupd)는 Fedora, elementary, Ubuntu에 다 있는데 RobinOS에는 없었어요
- 한 것: 세 펌웨어를 `packages/core.txt`에, `fwupd`를 `packages/apps.txt`에 넣었어요. GNOME Software는 fwupd가 있으면 업데이트 목록에 펌웨어도 보여 줘요
- 완료 기준: 설치 테스트에서 설치본에 `pacman -Q sof-firmware fwupd`가 나오고, 실제 PC에서 GNOME Software 업데이트에 펌웨어가 보이는지 확인(실기기 확인은 사용자)

### T-157 방화벽 켜기
- 상태: 진행 중
- 한 것(2026-10-13 집 PC): ufw를 골랐어요(`ufw status`, `ufw allow 22`처럼 명령이 말에 가까워서 미션에서 설명하기 쉬워요). `packages/core.txt`에 `ufw`, `post-install.sh`가 `/etc/ufw/ufw.conf`의 `ENABLED=yes`와 `ufw.service`로 켜요(설치기 chroot에서 `ufw enable`을 하면 라이브 커널에 규칙이 들어가서요). 기본값이 들어오는 연결은 막고 나가는 연결은 그대로, ufw의 before.rules가 DHCP·ping·mDNS(프린터 찾기)를 열어 둬요. `robinctl audit`은 설치본에서 방화벽이 꺼져 있으면 경고(라이브는 괜찮다고). 설치 테스트에서 `ufw` 켜짐과 mDNS 규칙 확인
- 2026-10-13 묶음 검증 통과(설치본에서 ufw 켜짐, mDNS 규칙)
- 남은 것: 보안 기초 미션에 "방화벽 규칙 보기". 웹 보안 랩(Docker)이 그대로 되는지 실제로 띄워 보기
- 출처: 다른 OS와 비교(2026-10-12). Fedora는 firewalld가 켜져 있고, Mint는 환영 화면 체크리스트에서 방화벽을 켜게 해요. RobinOS는 방화벽이 꺼져 있는데 `robinctl audit`은 괜찮다고 해요
- 할 것: 들어오는 연결은 막고 나가는 연결은 그대로 두는 기본값(ufw나 firewalld 중 하나, 학습 미션에서 설명하기 쉬운 쪽). 프린터 찾기(mDNS)는 열어 두기. `robinctl audit`이 방화벽이 꺼져 있으면 알려 주기. 보안 기초 미션에 "방화벽 규칙 보기" 하나
- 완료 기준: 설치 테스트에서 방화벽이 켜져 있고, 네트워크 프린터 찾기와 웹 보안 랩이 그대로 동작

### T-158 개인 파일 백업
- 상태: 완료 (2026-10-13 묶음 검증. USB 디스크에 백업하고 되살리기는 실기기 확인 때 같이 봐요)
- 한 것(2026-10-12 집 PC): `deja-dup`을 `packages/apps.txt`에, 런처에서 "백업", "파일 히스토리", "Time Machine"으로 찾으면 Déjà Dup(윈도우의 파일 히스토리에 해당), [recovery.md](recovery.md) "스냅샷과 백업", 설치 테스트에서 `pacman -Q deja-dup`과 데스크톱 파일 확인
- 출처: 다른 OS와 비교(2026-10-12). 스냅샷은 시스템만 되돌리고 개인 파일은 지켜 주지 않아요. Mint는 백업 도구, GNOME 계열은 Déjà Dup, 윈도우는 "Windows 백업", macOS는 Time Machine이 있어요
- 할 것: Déjà Dup(`deja-dup`)을 `packages/apps.txt`에 넣고 런처에서 "백업", "파일 히스토리", "Time Machine"으로 찾게 하기. 환영 화면이나 [recovery.md](recovery.md)에 스냅샷과 백업의 차이를 한 줄로
- 완료 기준: 설치본에서 런처로 백업 앱이 열리고, USB 디스크에 백업하고 파일 하나를 되살리는 것을 확인

### T-159 윈도우 프로그램(.exe)을 열면 안내
- 상태: 진행 중
- 한 것(2026-10-13 집 PC): `.exe`·`.msi`·`.lnk`의 기본 앱을 `robinos-windows-app`(숨은 데스크톱 파일)으로, 이게 셸의 "윈도우 프로그램" 창(`WindowsApp.qml`)을 열어요. 파일 이름으로 알려진 프로그램 열일곱 가지(카카오톡, Chrome, 웨일, 한글, Office, 반디집·7-Zip, 곰플레이어·팟플레이어, Discord, Steam, VS Code, Zoom, Spotify, Telegram, OBS, Notepad++, Python, Git)를 알아보고 대신 쓸 것(RobinOS에 있는 앱, 앱 스토어의 Flathub 앱, 웹 버전)을 단추로. 모르는 파일은 "리눅스에서는 그대로 열리지 않아요"와 Bottles 설치 단추. 이름 표는 `windowsapps.js`, `check-desktop.sh`가 파일 이름 열여섯 개로 확인("DigitalClock.exe"가 Git으로 잡히지 않게 짧은 이름은 그대로만). 부팅 테스트 `windows-app` 장면과 상태 확인
- 2026-10-13 묶음 검증 통과(`windows-app` 장면). 제목의 조사("카카오톡는")를 "카카오톡 윈도우용 설치 파일이에요"로
- 남은 것: 학습 미션 쪽 설명(실행 파일 형식이 다른 이유), 설치본에서 Flathub 단추가 앱 스토어의 그 앱을 여는지
- 출처: 다른 OS와 비교(2026-10-12). Zorin은 `.exe`를 열면 170개 넘는 설치 파일을 알아보고 리눅스판, 웹 앱, Wine 중 무엇을 쓰면 되는지 알려 줘요. 처음 쓰는 사람이 가장 먼저 부딪히는 곳이에요
- 할 것: `.exe`·`.msi`의 기본 앱을 RobinOS 안내 창으로. 파일 이름으로 잘 알려진 프로그램(카카오톡, 크롬, 한글, 반디집, 곰플레이어 등)을 알아보고 대신 쓸 것(Flathub 앱, 웹 버전, 기본 앱)을 보여 주기. 모르는 파일이면 "리눅스에서는 바로 실행되지 않아요"와 Bottles(Flathub) 설치 단추. 학습 미션 쪽 설명(실행 파일 형식이 다른 이유)으로 이어지게
- 완료 기준: 부팅 테스트에서 `.exe`를 열면 안내 창이 뜨고 알려진 이름 하나는 대신 쓸 앱을 보여 줘요

### T-160 화면 녹화
- 상태: 완료 (2026-10-13 묶음 검증: `recorded` PASS, 4초 mp4, 바의 "녹화 중" 스크린샷)
- 한 것(2026-10-13 집 PC): `robinos-screenshot record`가 `wf-recorder`로 지금 화면을 `~/비디오/Screencasts/날짜.mp4`에 녹화하고, 한 번 더 부르면 멈추고 "열기·폴더 열기" 알림. `Win+Alt+R`(Hyprland), 런처 "화면 녹화"(윈도우 이름 "Xbox Game Bar"), 녹화 중에는 바에 빨간 점 "녹화 중"(누르면 멈춤, 셸 IPC `setRecording`). `wf-recorder`는 `packages/desktop.txt`와 라이브 목록에. 부팅 테스트 `recording` 장면과 `recorded` 상태 확인(1초 넘는 mp4)
- 나중에 할 수 있는 것: 소리 함께 녹화, 영역 녹화
- 출처: 다른 OS와 비교(2026-10-12). 윈도우(Win+Alt+R, 캡처 도구), macOS(Cmd+Shift+5), GNOME 기본 녹화가 있는데 RobinOS는 스크린샷만 있어요
- 할 것: `robinos-screenshot`에 녹화 추가(`wf-recorder`나 `gpu-screen-recorder`), 녹화 중에는 바에 빨간 점과 멈춤 단추, 파일은 `~/동영상`에. 단축키는 Win+Alt+R
- 완료 기준: 부팅 테스트에서 몇 초 녹화한 파일이 생기고 재생돼요

### T-161 접근성: 확대, 큰 글씨, 고대비, 움직임 줄이기
- 상태: 진행 중
- 한 것(2026-10-13 집 PC): 화면 확대는 윈도우 돋보기와 같은 `Win+=`·`Win+-`·`Win+Esc`(Hyprland `cursor:zoom_factor`, 0.5배씩 1~5배), 설정 창의 "손쉬운 사용"에 "움직임 줄이기"(셸 애니메이션 시간 0, Hyprland 애니메이션 끔, GTK `enable-animations`)와 "앱 글자 크게"(GTK `text-scaling-factor` 1.25). 저장은 `appearance.json`이라 다시 켜도 유지. 부팅 테스트 `zoomed`·`unzoomed`
- 2026-10-13 묶음 검증 통과(확대 2배와 되돌리기). 움직임 줄이기·앱 글자 크게는 아직 VM에서 켜 보지 않음
- 남은 것: 고대비 색, 셸 자체의 글자 크기(지금은 화면 배율로), 움직임 줄이기·글자 크게를 부팅 테스트 장면으로
- 출처: 다른 OS와 비교(2026-10-12). GNOME 계열(Ubuntu, Fedora, Zorin)은 Orca, 화면 확대, 움직임 줄이기가 기본이에요. RobinOS는 투명도 줄이기만 있고 Orca는 막혀 있어요(T-040)
- 할 것: 설정 앱(T-149)에 "손쉬운 사용" 쪽. 화면 확대는 Hyprland `cursor:zoom_factor`로(단축키 Win+더하기/빼기), 글자 크기(셸과 GTK 배율), 고대비 색, 움직임 줄이기(Theme의 시간 값을 0으로)
- 완료 기준: 네 가지가 설정에서 켜지고 다시 켜도 유지돼요

### T-162 업데이트 화면
- 상태: 진행 중
- 한 것(2026-10-13 집 PC): `robinctl update`가 pacman을 부르기 전에 "업데이트 N개, 받을 크기 X MB", 커널이 바뀌면 "끝나면 다시 시작", "업데이트 직전에 스냅샷 N번을 찍어요(되돌리기 명령)"를 보여 줘요. 데이터 요금 연결(NetworkManager `Metered` 1·3)이면 알리고 받을지 물어요. 목록은 `checkupdates`의 임시 데이터베이스로 봐서, 여기서 멈춰도 시스템의 패키지 데이터베이스는 그대로예요(부분 업데이트 없음). `robinctl update --preview`(root 없이 미리 보기)와 가짜 checkupdates·pacman·busctl 테스트 여덟 개
- 2026-10-13 묶음 검증 통과(빠른 테스트만, VM에서 실제 업데이트는 아직). 2026-11-24 묶음 검증도 통과(`a7a1cb9`, 빠른 설정의 "끝나면 다시 시작")
- 한 것(2026-10-13 두 번째): 빠른 설정의 "업데이트 N개가 있어요"에 커널이 들어 있으면 " · 끝나면 다시 시작". 셸은 업데이트를 알림으로 띄우지 않고 바의 점만 보여 줘서 데이터 요금 연결에서 따로 막을 것은 없어요(`checkupdates`는 목록만 받아요)
- 남은 것: 설치 테스트에서 업데이트가 있을 때 미리 보기 세 줄 확인(완료 기준)
- 출처: 다른 OS와 비교(2026-10-12). Mint는 보안·커널 업데이트를 먼저 보여 주고, elementary는 받을 크기를 보여 주고 데이터 요금 연결에서는 받지 않아요. RobinOS는 업데이트 전에 스냅샷을 자동으로 찍어서(snap-pac) Omarchy와 같은 장점이 있는데 화면에서는 보이지 않아요
- 할 것: 업데이트 창에 받을 크기, 커널이 바뀌는지(다시 시작 필요), "업데이트 전에 스냅샷 N번을 찍어요". 데이터 요금 연결(NetworkManager metered)에서는 알림만
- 완료 기준: 부팅 테스트나 설치 테스트에서 업데이트 창의 세 줄이 맞게 나와요

### T-163 디스크 암호화 (조사)
- 상태: 완료 (2026-10-13 집 PC: [design.md](design.md) "디스크 암호화"에 방식을 정하고 T-166, T-167로 나눴어요. GRUB 2.16의 `luks2.mod`·`argon2.mod`를 WSL에서 확인)
- 출처: 다른 OS와 비교(2026-10-12). Ubuntu는 TPM 암호화와 복구 키, Pop!_OS는 기본으로 켜져 있고, Omarchy는 필수예요. 노트북을 잃어버리면 지금은 파일을 그대로 읽을 수 있어요
- 할 것: 설치 프로그램에 "디스크 암호화" 선택을 넣을 수 있는지 조사. GRUB이 LUKS2(argon2)를 못 여는 문제, grub-btrfs 스냅샷 부팅과 함께 쓰는 방법, 비밀번호 입력 화면(T-150 Plymouth), 복구 키를 사람에게 어떻게 보여 줄지
- 완료 기준: 방식 하나를 정해 [design.md](design.md)에 쓰고 구현 작업으로 나누기

### T-166 설치기에 디스크 암호화 선택
- 상태: 완료 (2026-11-24 집 PC: `install-test -Installer encrypted` 다섯 단계 통과)
- 한 것(2026-10-13 집 PC): 백엔드 `"encrypt": true` → `cryptsetup luksFormat`(LUKS2, argon2id, 메모리 256MiB, 사용자 비밀번호), Btrfs는 `/dev/mapper/cryptroot` 위에. initramfs 키 파일(`/etc/cryptsetup-keys.d/cryptroot.key`, 빠른 PBKDF), `encrypt` 훅, `GRUB_ENABLE_CRYPTODISK=y`와 `cryptdevice=`·`cryptkey=`. 복구 키(6자리 숫자 여덟 묶음)를 세 번째 키 슬롯에 넣고 `@@ recovery-key` 줄로 화면에만(로그 파일에는 안 남겨요). 설치기 화면: 사용자 단계에 "디스크 암호화" 스위치(설명: 잊으면 되살릴 수 없음), 확인 단계 요약, 끝 화면에 복구 키 상자. GRUB의 `luks2` 모듈이 `argon2`에 의존해서 같이 들어가요(moddep.lst 확인). 같이 고친 것: 화면이 계획에 `bitlocker_key_saved`를 안 보내던 것(T-147 때 패치 하나가 조용히 빠짐) → `test-robin-install.py`가 백엔드가 읽는 계획 항목을 화면이 모두 보내는지 확인
- 출처: T-163 조사([design.md](design.md) "디스크 암호화")
- 할 것: 설치기 확인 단계 앞에 "디스크 암호화" 선택(기본 꺼짐, 비밀번호를 잊으면 되살릴 수 없다는 설명), 백엔드가 LUKS2(argon2id, GRUB이 견딜 메모리 비용)로 Btrfs 파티션을 잠그고 `GRUB_ENABLE_CRYPTODISK=y`, initramfs에 키 파일과 `encrypt` 훅, `systemd-cryptenroll --recovery-key`로 복구 키를 만들어 마지막 화면에 보여 주기. `robinctl audit`의 "디스크 암호화" 줄은 그대로 동작
- 완료 기준: T-167의 설치 테스트 통과

### T-167 설치 테스트에 암호화 설치
- 상태: 완료 (2026-11-24 집 PC: 다섯 단계 통과. GRUB이 비밀번호 뒤 4~7초 만에 디스크를 열었어요(argon2id 256MiB, WHPX). 스냅샷 단계는 비밀번호 대신 복구 키로 열었어요)
- 한 것(2026-10-13): `install-test -Installer encrypted`(`wsl-build.ps1`, `install-test.sh`), GRUB 비밀번호는 QMP로(`wait_menu`), 두 번째 부팅은 복구 키로, 잠금 해제 시간 로그
- 나중에 볼 것: 비밀번호를 묻는 화면이 펌웨어 글자 위의 GRUB 영어 한 줄("Enter passphrase for hd0,gpt2 (UUID):")이에요. GRUB이 정한 문구라 바꿀 수 없어요. 한글 화면으로 물으려면 `/boot`를 암호화 밖에 두고 initramfs(Plymouth, T-150)에서 물어야 하는데, 그러면 스냅샷 부팅(grub-btrfs)이 커널을 스냅샷 안에서 못 읽어요. 키트 화면에 맞출지는 T-150과 같이 정해요
- 출처: T-163
- 할 것: `install-test.py`에 암호화 계획(`"encrypt": true`)으로 설치하고, GRUB 비밀번호 화면에 QMP로 비밀번호를 입력해 부팅, 스냅샷으로 부팅·되돌리기까지 지금처럼 확인. 복구 키로도 한 번 열기. GRUB의 argon2 잠금 해제 시간 재기
- 완료 기준: 다섯 단계 통과, 잠금 해제 시간 기록

### T-164 처음 상태로 되돌리기 (조사)
- 상태: 할 일 (나중)
- 출처: 다른 OS와 비교(2026-10-12). 윈도우 "이 PC 초기화", ChromeOS Powerwash, Omarchy "Reset Computer", Pop!_OS의 파일을 남기는 다시 설치
- 할 것: 설치가 끝난 직후의 스냅샷을 "처음 상태"로 남겨 두고, 설정 앱에서 개인 파일은 남긴 채 시스템만 그때로 되돌리는 방법 조사. 다른 사람에게 PC를 넘길 때 쓰는 "새 주인 준비"는 그다음
- 완료 기준: 방식과 위험(남는 것과 지워지는 것)을 [recovery.md](recovery.md)에 정리

### T-165 휴대폰 연결과 스캐너
- 상태: 진행 중 (스캐너 먼저)
- 한 것(2026-10-13 집 PC): 스캐너. `sane`, `sane-airscan`(드라이버 없이 네트워크·요즘 USB 스캐너), `simple-scan`을 `packages/apps.txt`에, 런처에서 "팩스 및 스캔"(윈도우 이름)으로 찾기, 설치 테스트에서 패키지와 데스크톱 파일 확인
- 2026-10-13 묶음 검증 통과(설치본에 스캔 패키지와 데스크톱 파일)
- 남은 것: 휴대폰 연결(KDE Connect와 LocalSend 중 고르기)
- 출처: 다른 OS와 비교(2026-10-12). Zorin Connect(알림, 문자, 파일), Mint Warpinator(아이폰 앱도 있음), 윈도우 "휴대폰과 연결". 스캐너는 대부분 기본으로 돼요
- 할 것: 휴대폰은 KDE Connect(크기 큼)와 LocalSend(Flathub, 아이폰도 됨) 중 고르기. 스캐너는 `sane`과 `simple-scan`을 `packages/apps.txt`에 넣고 런처에서 "팩스 및 스캔"으로
- 완료 기준: 고른 것을 설치본에 넣고 런처에서 열려요

### T-154 터미널 창을 마우스로 옮기기 (제목 표시줄)
- 상태: 진행 중 (사용자 결정 2026-10-12: "Ptyxis로 바꾸기". foot 대신 Ptyxis를 기본 터미널로)
- 출처: 사용자 질문(2026-10-12, VMware 라이브에서) "창들은 어떻게 이동시키는데", ChatGPT 검토(2026-10-12) "초보자용 OS라면 Win+드래그를 유일한 이동 방법으로 두어서는 안 됩니다". T-011에 있던 일을 앞으로 당겼어요
- 지금: 셸 창(학습 센터, 설치기)과 GTK·Qt 앱은 제목 표시줄을 끌면 돼요. foot 터미널은 제목 표시줄이 없어서 `Win`+왼쪽 끌기(이동), `Win`+오른쪽 끌기(크기)만 돼요(`robinos.lua`의 `hl.dsp.window.drag`). `desktop/foot/foot.ini`에 `[csd] preferred=client`가 있는데 Hyprland가 xdg-decoration에 "서버가 그린다"고 답해서 foot이 제목 표시줄을 그리지 않아요(design.md "창 제목 표시줄")
- 찾은 것(2026-10-12): Hyprland 0.56.2 소스(`src/protocols/XDGDecoration.cpp`)에서 `xdgModeOnRequestCSD()`가 앱이 무엇을 요청하든 `MODE_SERVER_SIDE`를 돌려줘요. 설정으로 바꿀 수 없어서 foot은 언제나 제목 표시줄을 그리지 않아요
- 할 것: 비교: hyprbars 플러그인(Hyprland 버전마다 다시 빌드해야 해서 롤링 업데이트에 약해요), 제목 표시줄을 스스로 그리는 터미널(GNOME 콘솔·Ptyxis 등, foot의 테마 전환·힌트를 옮겨야 해요), 셸이 그리는 얇은 끌기 막대 ④ 제품 방향이 바뀌는 선택(터미널 교체)이면 사용자 확인 필요로
- 한 것(2026-10-12, `work/batch74`): 기본 터미널을 Ptyxis로. `ShellState.terminal`(`ptyxis --new-window`) 하나를 독, 런처(터미널 앱 실행 포함), Win+X, 바탕 화면 메뉴, 미션·업데이트 터미널(`openTerminal`, `runInTerminal`)이 같이 써요. Hyprland `Win+Enter`도 Ptyxis. dconf 기본값 `[org/gnome/Ptyxis]`: 다크·라이트를 셸 선택대로(`interface-style='system'`), 지난 창 복원 끄기, 100×28. foot은 대체용으로 남기고 런처에서는 숨겨요. 패키지 목록(설치본, 라이브)에 ptyxis. 부팅 테스트의 최소화 장면은 `org.gnome.Ptyxis`로
- 남은 것: 묶음 검증. RobinOS zinc 팔레트(Ptyxis 기본은 GNOME 팔레트), 이미 설치한 시스템에 ptyxis 깔기(`robinos` 패키지 의존성 또는 `robinctl update` 안내)
- ChatGPT 두 번째 검토(2026-10-12) 반영: Ptyxis가 깔려 있는데 바로 실패하면(5초 안) foot으로. 남은 것: 파일 관리자(Nautilus)의 "터미널에서 열기"(지금은 없음. Nautilus 47 이후의 `xdg-terminal-exec` 또는 확장), RobinOS zinc 팔레트(`.palette`의 [Light]/[Dark], 프로필 UUID 처리), 한글 2칸 폭과 상자 그리기 문자(│├└─) 정렬, 닫기 확인 창이 실행 중인 작업에만 뜨는지
- 한글 폭(2026-10-12): Ptyxis에서 한글 음절 사이가 벌어져요(한글 두 칸 = 1.2em인데 Noto Sans Mono CJK KR의 한글은 1.0em). fontconfig matrix로 가로세로 1.16배는 틈이 없어졌지만 한국어 환경에서 줄 높이가 22→28px로 커져 28줄 창이 900px 화면을 넘었고, 가로로만 1.16배는 VTE에 효과가 없었어요. 규칙은 뺐어요. 남은 후보: 한글과 영문 폭이 맞는 고정폭 글꼴로 터미널 글꼴 자체를 바꾸기, 기본 줄 수를 줄이고 가로세로 확대를 다시 쓰기
- 완료 기준: 처음 쓰는 사람이 단축키 없이 터미널 창을 마우스로 옮기고 닫을 수 있음. 부팅 테스트에 끌어서 옮기는 장면

### T-153 스냅샷으로 켰을 때 알려 주고 화면에서 되돌리기
- 상태: 진행 중
- 출처: ChatGPT 검토(2026-10-12). [recovery.md](recovery.md)대로 부팅 메뉴에서 스냅샷을 골라 켜면 그 상태는 임시예요(grub-btrfs 오버레이). 완전히 되돌리려면 `sudo robinctl snapshot rollback`을 쳐야 하는데, 처음 쓰는 사람은 이미 되돌려졌다고 생각하기 쉬워요
- 할 것: 셸이 스냅샷으로 켠 것을 알아채면(`/proc/cmdline`의 `rootflags=subvol=@snapshots/...` 또는 `robinctl snapshot status`) 바 아래에 알림: "업데이트 전 상태로 켰어요(임시). 이 상태로 되돌릴까요?" [되돌리기] [그냥 둘게요]. 되돌리기는 관리자 확인 뒤 `robinctl snapshot rollback`을 돌리고 다시 시작을 권해요
- 한 것(2026-10-12, `work/batch74`): `robinctl snapshot booted`(커널 줄의 `rootflags=subvol=@snapshots/N/snapshot`에서 번호, `/.snapshots/N/info.xml`에서 설명), `desktop/bin/robinos-snapshot-notice`(로그인 때 Hyprland가 실행. 알림 "스냅샷 N번으로 켰어요"와 [이 상태로 되돌리기] [나중에], 되돌리기는 pkexec 비밀번호 창으로 `robinctl snapshot rollback N --yes`, 끝나면 [지금 다시 시작]). doctor도 번호를 말해요. test-robinctl.sh에 가짜 커널 줄 시험, 설치 테스트 snapshot-boot 단계에서 번호 확인. 남은 것: 설치 테스트에서 알림과 단추를 화면으로 확인(그 단계는 콘솔 로그인이라 데스크톱이 없어요)
- ChatGPT 두 번째 검토(2026-10-12) 반영: "나중에"를 눌러도 바에 "스냅샷 N · 임시" 단추가 남고 누르면 알림이 다시 떠요(`ShellState.bootedSnapshot`). 알림에 "되돌리면 시스템과 설치한 프로그램이 이 상태가 되고, 내 파일(홈 폴더)은 그대로예요". 비밀번호 창을 닫으면(pkexec 126) 아무 일도 없던 것으로. 커널 사본이 없는 스냅샷이면 끝 알림이 그렇게 말해요. robinctl이 root로 번호를 다시 확인해요(스냅샷이 없으면 멈춤). 남은 것: 실패 시나리오(없는 번호, 커널 사본 없음, 취소)를 설치 테스트에 더 넣기, 다시 켠 뒤 이전 시스템(@.broken)을 지우는 일도 화면에서
- 완료 기준: 터미널 없이 이전 상태로 돌아가고 다시 켜도 유지됨. 설치 테스트 rollback 단계에 알림과 버튼 장면

### T-152 shadcn × macOS: 질감과 움직임
- 상태: 보류 (2026-11-24 정체성 결정으로 robin-ui V5(T-168)가 대신해요. 키트는 유리·흐림이 없어서 ①의 유리와 블러, ②의 색 빛은 되돌렸어요. ③ 런처 검색 칸 크기와 ④ 빠른 설정 타일 묶음은 키트 값으로 다시 맞춰요)
- 출처: 사용자 제안(2026-10-12) "우리 디자인도 MAC OS 참고하면 어떨까, SHADCN과 mac os의 콜라보 같은 느낌"
- 한 것(2026-10-12, `work/batch74`): ① `Theme.qml`에 `glass`(다크 70%, 라이트 72% 불투명), `glassBorder`, `radiusPanel`(16). 바 55%·독 58%(라이트 62%·64%)로 더 비치게. 소프트웨어 모드(`lowPower`)에서는 지금처럼 거의 불투명. 떠 있는 패널 11개(빠른 설정, 달력, 연결, 소리, 알림 센터, 런처, 메뉴, 창 전환, 단축키, 알림, 음량 표시)를 유리 토큰으로. `robinos.lua` 블러 size 6→10, vibrancy 0.17→0.22, 패널 이름공간에 블러 규칙(`ignore_alpha 0.5`로 카드 아래만) ② 기본 배경화면에 RobinOS 빨강·주황·보라의 부드러운 빛(`Wallpaper.qml`) ③ 런처를 Spotlight처럼: 검색 칸 62px·글자 18px, 뒤는 살짝만 어둡게(`scrimSoft`), 블러는 카드 아래만, 열 때 96%에서 스프링처럼 자리 잡기 ④ 빠른 설정을 제어 센터처럼: 꺼진 타일과 버튼을 단색 대신 유리 위 옅은 색조(`glassTile`), 타일 모서리 12, 열 때 오른쪽 위 모서리에서 자라며 자리 잡기
- 지금: 배치는 이미 macOS와 같아요(위에 바, 아래 가운데 독). 바·독·런처에 Hyprland 블러가 켜져 있지만 배경이 72~85% 불투명이고(`Theme.qml`의 `barBg`, `dockBg`) 블러가 작아서(`size 6`) 유리처럼 보이지 않아요. 배경화면도 무늬 없는 검정에 점이라 비쳐 보일 색이 없어요
- 가져올 것(macOS): ① 반투명 재질. 바·독·런처·빠른 설정·알림·달력을 50~65% 불투명 + 큰 블러(size 10~14) + 1px 안쪽 밝은 테두리. 소프트웨어 렌더링(VM)에서는 지금처럼 불투명 ② 색이 있는 기본 배경화면(zinc 위에 RobinOS 빨강·주황의 부드러운 빛, 다크·라이트 두 장). 유리가 비쳐 보일 색 ③ 떠 있는 패널의 깊이: 큰 모서리(16~20), 부드러운 그림자 두 겹 ④ 런처를 Spotlight처럼: 큰 검색 칸이 가운데, 결과는 그 아래로 펼쳐짐 ⑤ 빠른 설정을 제어 센터처럼 묶음 타일로 ⑥ 움직임은 창 스프링("easy")을 패널에도: 열 때 살짝 커지며(96%→100%) 착지
- 가져오지 않을 것: 창의 신호등 단추(Hyprland에 제목 표시줄이 없고, 윈도우 사용자는 닫기가 오른쪽에 있다고 알아요), 앱 메뉴를 바에 올리는 전역 메뉴(Wayland 앱 대부분이 지원하지 않아요), Cmd 단축키(Win 단축키 그대로)
- 그대로 둘 것(shadcn): zinc 색, 1px 테두리, Geist·Pretendard, Lucide 아이콘, 절제(큰 그라데이션 없이)
- 단계: ① `Theme.qml` 재질 토큰(`glass`, `glassBorder`, `radiusPanel`)과 소프트웨어 모드 대체, `robinos.lua` 블러 값과 패널 이름공간 ② 기본 배경화면 두 장(`Wallpaper.qml`, SDDM·hyprlock도 같은 그림) ③ 런처 ④ 빠른 설정 ⑤ 알림·달력·소리 패널 ⑥ brand.md·design.md "디자인" 절에 shadcn × macOS 기준을 적고, 소개 영상 스크린샷을 새로 찍기
- 더 할 것(ChatGPT 검토 2026-10-12): 흰 웹 페이지, 검은 터미널, 영상 위에서 유리 패널 글자 대비 확인. 설정 앱(T-149)에 "투명도 줄이기"와 "움직임 줄이기"
- 검증: `wsl-build.ps1 check`(qmllint), 부팅 테스트 스크린샷(GPU 블러는 WHPX VM에서도 소프트웨어 렌더링이라 안 보여요. 블러는 VMware 3D 가속이나 실기기에서 확인)
- 완료 기준: 부팅 테스트 장면이 모두 새 재질로 바뀌고, 소프트웨어 모드에서 글자 대비가 지금과 같거나 더 좋음

### T-149 RobinOS 설정 앱
- 상태: 진행 중 (ChatGPT 검토 2026-10-12도 가장 먼저 할 일로 꼽았어요)
- 한 것(2026-10-12, `work/batch74`): ① `desktop/shell/Settings.qml`. macOS 시스템 설정처럼 왼쪽에 항목, 오른쪽에 내용이에요. "개인 설정"(다크·라이트 미리보기 카드, 강조색, 투명도 줄이기, 배경화면 바꾸기·되돌리기)과 "정보"(버전, `robinos` 패키지, 커널, 컴퓨터, CPU, 메모리, 그래픽, 디스크, 렌더링 방식). 소리·Wi-Fi·블루투스는 이미 있는 패널을 열어요. `Win+I`, 런처의 "설정"(윈도우 이름 "제어판"), `Win+X`의 "설정", `qs ipc ... call shell settings`로 열려요. 투명도 줄이기는 `Theme.solid`(GPU가 없을 때와 같이 유리를 불투명하게). 공용 `Switch.qml`. 부팅 테스트에 `light-settings`, `light-settings-about` 장면
- 출처: 설계 점검(2026-10-10) "설정". 런처의 "제어판"과 바탕 화면 메뉴의 "디스플레이 설정"이 빠른 설정(배율, 밝기)으로 가요. 해상도, 여러 모니터, 날짜·시간, 사용자, 기본 앱은 화면이 없고 Lua 파일을 고쳐야 해요
- 방향: 환영 마법사·학습 센터처럼 셸 안의 QML 창(`desktop/shell/Settings.qml`)으로 만들어요. 왼쪽에 항목, 오른쪽에 내용. 빠른 설정은 자주 쓰는 것만 남기고 "모든 설정"으로 이 창을 열어요. 바꾼 값은 사용자 설정 파일에 저장해 RobinOS 기본값을 덮어요(시스템 파일은 건드리지 않아요)
- 단계(한 단계가 1~3회차): ① 창 틀과 "개인 설정"(테마, 강조색, 배경화면)·"정보"(RobinOS 버전과 `robinos` 패키지 버전, 하드웨어 요약) ② "디스플레이"(모니터마다 해상도·주사율·배율·위치, `hyprctl monitors`로 읽고 사용자 Hyprland 설정에 저장) ③ "소리"·"네트워크"·"블루투스"는 이미 있는 창으로 연결 ④ "날짜와 시간"(시간대, 자동 동기화)·"키보드"(한/영 키, 반복 속도) ⑤ "기본 앱"·"사용자 계정"(비밀번호 바꾸기는 `passwd`를 터미널에서) ⑥ "업데이트와 복구"(`robinctl update`, 스냅샷 목록)
- ChatGPT 두 번째 검토(2026-10-12): 다음은 디스플레이 → 날짜와 시간 → 키보드 순서. 디스플레이는 바꾼 뒤 "이 설정을 유지할까요? 15초 뒤 되돌려요"를 두되, 되돌리는 타이머를 셸(QML) 밖의 따로 된 프로세스에 둬요(화면이 사라져 셸이 죽어도 돌아오게). `hyprctl monitors all -j`로 읽고, 확인한 뒤에만 저장. 날짜와 시간은 systemd-timedated(D-Bus, polkit)로, 하드웨어 시계 방식은 고급 설정에. 키보드는 배열·입력기·한/영 단축키를 따로 저장하고 기본 한/영 키는 남겨요
- 검증: `wsl-build.ps1 check`(qmllint), 부팅 테스트에 설정 창 장면(단계마다 하나), 디스플레이는 두 번째 가상 모니터로
- 완료 기준: 런처에서 "설정"·"제어판"으로 이 창이 열리고, 위 여섯 항목이 키보드만으로도 동작

### T-150 부팅 화면 (Plymouth)
- 상태: 할 일
- 출처: 설계 점검(2026-10-10) "부팅 화면". GRUB 메뉴 뒤에 커널 글자가 지나가고 SDDM이 떠요. [brand.md](brand.md)의 "부팅 스플래시"가 아직 없어요
- 할 것: Plymouth와 RobinOS 테마(울새 마크, zinc 배경, 진행 표시). 설치본(`robin-install`·`post-install.sh`의 initramfs 훅, `quiet splash`)과 라이브 ISO 둘 다. 디스크 암호화를 나중에 넣을 때 비밀번호 입력도 이 화면이 맡아요
- 확인할 것: 패키지 크기(라이브 ISO 한도까지 약 44MiB), 소프트웨어 렌더링 VM에서 SDDM으로 넘어가는 시간, 스냅샷으로 부팅할 때(grub-btrfs-overlayfs 훅과 함께)
- 완료 기준: 부팅 테스트에 스플래시 장면, 부팅 시간이 전과 비슷함, 설치 테스트의 스냅샷 부팅 통과

### T-148 보안 부팅을 켠 채로 부팅 (조사)
- 상태: 할 일 (조사 뒤 사용자 확인이 필요할 수 있어요)
- 출처: 설계 점검(2026-10-10) "보안 부팅"
- 조사할 것: ① 마이크로소프트가 서명한 shim(다른 배포판의 `shim-signed`) + RobinOS 열쇠를 MOK로 한 번 등록(처음 부팅 때 파란 화면에서 등록) ② `sbctl`로 사용자 PC의 열쇠를 직접 만들어 펌웨어에 넣기(설정 모드가 필요해 입문자에게 어려움) ③ RobinOS 자체 shim을 마이크로소프트에 서명받기(돈과 계정이 들어서 사용자 결정). 라이브 ISO와 설치본, 커널 업데이트·스냅샷 부팅과 어떻게 맞물리는지
- 완료 기준: design.md에 방식과 이유, 고른 방식이 VM(보안 부팅을 켠 OVMF)에서 라이브 부팅

### T-104 2029년 공휴일 넣기
- 상태: 할 일 (2028년 가을에 해요)
- 출처: T-103. `desktop/shell/holidays.js`의 음력 공휴일·대체공휴일 표가 2028년까지예요
- 할 것: 2029년 설날·추석·부처님오신날, 대체공휴일, 선거일을 공식 발표(인사혁신처, 한국천문연구원 월력요항)로 확인해 넣기
- 완료 기준: 달력의 2029년 1월·2월·9월에 공휴일이 나옴

### T-040 화면 읽기 (Orca)
- 상태: 막힘 (Hyprland가 `org.freedesktop.a11y.KeyboardMonitor`를 제공할 때까지)
- 출처: 품질 점검(접근성) "화면 읽기 프로그램(Orca)은 아직"
- 조사(2026-10-08): Orca 51 패키지와 libatspi 2.62를 받아 확인. Orca는 `Atspi.Device.new_full`로 키를 받고, Wayland에서는 `org.freedesktop.a11y.Manager`(Mutter 제공)를 써요. Hyprland 0.56.2 소스에 없어서 Orca 키 명령은 안 되고 포커스 읽기만 돼요. 결론과 이유를 design.md 미결정 사항에 적음. 업스트림 변화 점검 때 Hyprland가 이 인터페이스를 넣었는지 봐요

### T-146 이미 설치한 시스템 안내 (RobinOS 파일 업데이트 4단계)
- 상태: 보류 (2026-10-10 설계 점검: 깃허브 ISO 내려받기가 v0.1·v0.2 모두 0번이라 옮겨 줄 설치본이 거의 없어요. 실사용자가 생기면 꺼내요)
- 할 것: v0.2 이하 설치본이 저장소를 켜는 방법을 install.md와 다음 발표문에. 업데이트가 나왔다는 알림(바의 업데이트 점은 pacman을 보니 그대로 동작)

### T-021 웹 보안 미션 (Juice Shop)
- 상태: 보류. 범위를 다시 잡을 때까지 다른 작업을 먼저 해요. 랩 안내(`robinctl lab info web`)와 Juice Shop 자체의 점수판으로 시작할 수 있어요
- 출처: 백로그 채우기 5 (학습 기능 늘리기), design.md 학습 순서의 세 번째(웹 보안)
- 목표: `robinctl learn` 11~15번. 웹 랩을 켜고(`robinctl lab start web`), Juice Shop의 쉬운 문제를 풀어요. 예: 점수판 찾기(Score Board), 브라우저 개발자 도구로 숨은 정보 보기, 로그인 SQL 인젝션(관리자로 로그인), 오류 메시지 보기, 리뷰에 XSS 넣기. 채점은 Juice Shop이 스스로 기록하는 문제 상태(`http://127.0.0.1:3000/api/Challenges`)를 읽어요. 대상은 내 컴퓨터의 랩뿐이라는 안내를 붙여요
- 확인할 것: v20.2.0의 문제 이름과 API 응답 모양(설치 테스트 -Lab에서 받아 보기), 랩이 꺼져 있을 때 안내
- 완료 기준: 채점 테스트(가짜 API 응답으로), 설치 테스트 -Lab에서 한 문제를 실제로 풀고 채점

### T-011 다음 버전 후보 (백로그 1~7에서 쓸 만한 일이 없을 때 꺼내요)
- 학습 센터, 네트워크 랩, 입문 CTF는 이미 들어갔어요(최소화와 `Win+D`는 T-024, Qt 앱 제목 표시줄은 T-029, 터미널 제목 표시줄은 T-154)

## 완료

최근 것이 위에 있어요. 더 오래된 기록은 [done.md](done.md)에 있어요.

- 2026-10-12 목적을 다시 정함(사용자: 소개 영상의 "매일 쓰는, 나만의 OS."를 보고 "뭐 어쩌라는 건지 모르겠어, 목적을 제대로 정해야 할 것 같은데"): 세 안(쓰면서 배우는 리눅스, 윈도우 대신 쓰는 리눅스, 개발자용 작업 OS) 가운데 사용자가 "쓰면서 배우는 리눅스"를 골랐어요. 한 줄 정의는 "쓰다 보면 리눅스를 알게 되는 OS"이고, 10월 10일의 "나만의 새로운 OS"는 만드는 원칙으로 남겼어요. design·vision·brand·README·roadmap·loop·CLAUDE.md, 로고 한 줄 소개(SVG 다시 만듦), 환영 마법사 첫 화면, 소개 영상 문구를 바꿨어요. 함께 humanizer로 AI 같은 말을 덜어 냈어요(사용자: "claude humanizer 스킬 사용해서 AI 같은 말 다 정리해"): 영상의 대구 "밤에는 다크, 낮에는 라이트.", 쉼표로 가른 제목("켜는 순간부터, RobinOS.", "매일 쓰는 화면, 하나하나 직접."), 세 줄 대구 자막, 문서의 "A가 아니라 B" 문장과 의인화
- 2026-10-12 10월 10일 방향 결정을 main에 합침(Robin: "10월 10일 브랜치 main에 합칠까" → 합치기로): `origin/claude/eoseohae-7nleia`에서 문서 두 커밋(`1549271` 방향 고침과 설계 점검, `57e2410` 문서 최종 점검)만 가져왔어요. 같은 브랜치의 `9b5d5f3`(T-145 코드)은 main이 그 뒤에 T-145를 다른 방식으로 끝내고 검증해서 뺐어요. 그래서 브랜치 문서가 가리키던 `robinctl repo`(main에 없는 명령)를 vision·roadmap·testing·docs/README·T-149에서 지우고, 할 일로 다시 들어온 T-145 절을 뺐어요. 충돌한 곳은 main의 최신 사실(묶음 73까지, T-145 완료, GPL-3.0)을 남기고 새 방향 문장을 얹었어요. 이제 정체성은 "직접 만든 데스크톱과 도구로 이루어진, 매일 쓰는 나만의 OS"이고, 백로그 출처 4번이 "RobinOS다운 경험 넓히기"예요(loop.md). 새 작업: T-147~T-151(보안 부팅 안내, 보안 부팅 조사, 설정 앱, 부팅 화면, 화면의 정체성 문구)
- 2026-10-12 RobinOS 소개 영상(`promo/intro/`, 사용자 요청 "RobinOS 소개 영상 모션그래픽으로 예쁘고 모던하게"): 41초, 1920×1080, 60fps, 소리 포함. 세 번째 판이에요. 첫 판은 ITCS Connect 광고와 비슷했고, 둘째 판(RobinOS 세션 스타일)은 "PPT 슬라이드 같아"라고 해서 "애플 느낌의 모션그래픽"으로 다시 만들었어요. 검은 바탕에 한 번에 한 문장(단어가 흐림에서 떠올라 박마다 착지, 강조는 빨강→주황 그라데이션), 실제 스크린샷이 원근을 두고 떠서 내려앉고, 뒤의 빛이 떠다니며 킥마다 숨을 쉬어요. 장면: 로고 → "매일 쓰는, 나만의 OS." → 누운 화면이 일어서며 부팅 → 입체 키캡과 패널 덱("윈도우에서 쓰던 그대로") → 터미널 힌트와 학습 미션 45 → 쉬는 마디에 다크에서 라이트로 → 스냅샷 줄과 되돌리기, 실제 부팅 메뉴 → 벤토 격자 → 끝 로고. 곡은 `music.mjs`가 직접 합성한 일렉트로닉 펑크(116BPM, D단조, 사용자 요청 "노래 그냥 너가 만들고")라 저작권 걱정이 없어요. 크롬 5개로 약 70초에 녹화해요. 결과물 mp4는 git에 없어요(`npm run render`로 다시 만들어요)
- 2026-10-12 묶음 71~73 검증(`e82be3c`, 빌드 4분 + 부팅 테스트 79장 통과, 설치 테스트 다섯 단계 통과)
  - T-145 설치본이 RobinOS 저장소를 쓰게(`bd8c495`~`e82be3c`): 빌드가 `robinos-0.3.0.r405`를 만들어 ISO에 넣고, 설치본에서 `pacman -Q robinos` = 0.3.0.r405-1, `[robinos]` 저장소와 열쇠, `pacman -Si robinos`가 깃허브의 0.3.0.r400을 서명 확인과 함께 받음, `filesystem` 재설치 통과. 검증 중 찾은 것: ① 설치 테스트 VM의 일시적인 네트워크 끊김 ② 저장소를 켜고 목록을 받지 않아 `pacman -S`가 실패하던 버그(고침) ③ 한국어 설치본에서 `pacman -Qo` 문구를 영어로 찾던 시험(`-Qqo`로 고침). GPL-3.0 `LICENSE`(사용자 결정)
- 2026-10-10 T-144 깃허브 릴리스를 pacman 저장소로(`e3ace38`, `816c352`): `wsl-build.ps1 publish-repo`가 `robinos-0.3.0.r400-1`과 서명한 데이터베이스를 깃허브 프리릴리스 [repo](https://github.com/Yoon-robin/RobinOS/releases/tag/repo)에 올리고, `scripts/test-repo.sh`가 버린 루트에 `SigLevel = Required DatabaseRequired`로 깃허브에서 받아 설치(`robinos 0.3.0.r400-1`, `repo ok`). 빌드·배포 도구만 바뀌어서 이 실제 올리기와 설치가 검증이에요
- 2026-10-10 묶음 69 검증(`f6ceb6d`, verify 빌드 3.6분 + 테스트 14.5분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장, 부팅 끝 14.8초)
  - T-143 RobinOS 파일을 pacman 패키지로(`30cfd62`): `wsl-build.ps1 package`가 `robinos-0.2.0.r395-1-any.pkg.tar.zst`(파일 264개)를 만들고 파일 목록·robinctl 실행·서명 확인 통과. `stage-robinos.sh`로 바꾼 ISO 동기화의 오버레이가 옛 것과 파일 하나까지 같고, 그 ISO로 부팅·설치 테스트 통과. 개발 버전 0.3.0-dev(`f6ceb6d`)
- 2026-10-10 묶음 68 검증(`82600be`, verify 빌드 3.5분 + 테스트 14.5분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - 부팅 테스트의 실패한 서비스 장면(`82600be`): `30-failed-units`에 vmware, 0 loaded units, inactive, active가 다 찍히고, `72-light-learn-center`가 다시 1/45
- 2026-10-10 T-142 v0.2 프리뷰 공개(사용자 결정 "공개해, 만들어, 지워"): `b4072b0`을 `wsl-build.ps1 build`(xz)로 빌드, ISO 2,101,510,144바이트(한도까지 43.8MiB), SHA-256 `b1e3c36c…f1b51b8`, `SHA256SUMS.sig`(열쇠 `D8EB…9AAD`). 이 ISO로 부팅 테스트 79장(부팅 끝 17.6초) 통과, 학습 센터가 0/45로 나온 것은 테스트의 pager 문제(다음 묶음에서 고침). 깃허브 프리릴리스 [v0.2.0](https://github.com/Yoon-robin/RobinOS/releases/tag/v0.2.0)에 ISO, SHA256SUMS, 서명, 공개 열쇠. 깃허브가 계산한 ISO 체크섬이 서명된 SHA256SUMS와 같고, 내려받은 서명이 공개 열쇠로 "Good signature". 같은 날 릴리스 서명 열쇠를 만들고 깃허브의 `work/t025-vmware`를 지웠어요
- 2026-10-10 묶음 66 검증(`8312625`, verify 빌드 3.2분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장, 부팅 끝 15.2초)
  - T-141 코드 검토 고침(`8312625`): 정적 검사에 Shell JS imports, 계산 시험 27가지, robinctl 테스트 "it says to show the mission first". `50-notification-opened`는 전과 같음
  - T-142 릴리스 서명(`8312625`): 빌드 로그에 `Signed: /root/RobinOS/out/SHA256SUMS.sig (key D8EB0C495CBF5B2BBB57EACCFD9B53B8B79E9AAD)`, 저장소의 공개 열쇠만으로 "Good signature"
- 2026-10-10 묶음 65 검증(`d05bb6a`, verify 빌드 3.3분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장, 부팅 끝 13.9초)
  - T-140 보안과 윤리 점검(`d05bb6a`): robinctl 테스트 "41: access.log uses documentation addresses only", ethics.md의 주소 기준과 런처 웹 검색
- 2026-10-10 묶음 64 검증(`f96dd13`, verify 빌드 3.5분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-139 라이브 ISO 부팅이 NTP를 기다리지 않게(`f96dd13`): 시리얼 로그 `Startup finished ... = 13.993s`(전에는 83.7초), pacman 열쇠 준비 13.8초, 전원 모드 데몬 14.0초, 시계 동기화 대기 없음. `verify-boot.log`에 `Startup finished` 줄이 남음
- 2026-10-10 묶음 63 검증(`a31a8f8`, verify 빌드 3.4분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-138 텍스트 다루기 미션 41~45(`a31a8f8`): robinctl 테스트가 다섯 미션을 틀린 답과 맞는 답으로 채점(목록에 "텍스트 다루기", 45/45). `72-light-learn-center`에 1/45, `74-learn-center-ctf`는 휠 60번으로 목록 끝의 입문 CTF까지. 설치 테스트에 `/usr/bin/diff`
- 2026-10-10 묶음 62 검증(`eab6589`, verify 빌드 3.4분 + 테스트 14.2분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-137 VMware가 아닌 VM의 VMware 도구(`eab6589`): QEMU(WHPX) 테스트 VM은 여전히 `vmware`로 감지되지만, 라이브 단계 vmtoolsd가 `ExecCondition`(vmware-checkvm)으로 건너뛰어 `ConditionResult=no`, 실패한 서비스 없음. 설치본에는 `open-vm-tools`가 깔리지 않고 실패한 서비스 없음. `30-failed-units`에 0 loaded units, networkd inactive, NetworkManager active
- 2026-10-10 묶음 61 검증(`b1319d5`, verify 빌드 3.6분 + 테스트 14.3분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-137 원인 찾기(`b1319d5`): 설치 테스트 로그에서 QEMU(WHPX) 테스트 VM을 systemd가 라이브·설치본 모두 `vmware`로 감지(`ConditionResult=yes`), 설치기가 `open-vm-tools`를 깔고 설치본에서도 vmtoolsd가 실패. 고침은 다음 묶음
