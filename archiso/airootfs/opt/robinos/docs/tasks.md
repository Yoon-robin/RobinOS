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
| 2026-10-10 (아침) | `030455d` 테스트 ISO | 설치 테스트 windows(9.1분) | 다섯 단계 통과. 윈도우 파티션, EFI 파일, C: 그대로, GRUB 메뉴에 Windows Boot Manager. 새벽 뒤로 바뀐 것(LLMNR 끄기, 앱 제거, 설치 테스트의 UDP 확인)이 윈도우 옆 설치 경로에서도 문제없음 |
| 2026-10-10 (새벽) | `857383b` 테스트 ISO | 설치 테스트 archinstall(11.4분) | 다섯 단계 통과. 어제 저녁 뒤로 바뀐 설치 코드(openssh, baobab, wtype, 힌트)가 archinstall+post-install 경로에서도 문제없음(`ssh-keygen`, `baobab` 확인) |

## 품질 점검 기록

백로그 채우기 7번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 설계 점검 | 2026-10-10 | 사용자 방향 결정("보안 학습에만 두지 말고 나만의 새로운 OS") 뒤 design·vision·brand·README를 다시 봄. 정체성이 문서마다 달랐고(보안 학습 OS / 윈도우 이주 OS), 빈 곳은 실기기 0번, 보안 부팅 안내 없음, 설정 앱 없음, 부팅 화면 없음. design.md "설계 점검" 표와 T-147~T-151 |
| 코드 검토 | 2026-10-10 | 새벽에 들어간 작업 보기, 독 미리보기, 바탕 화면 Alt+F4, CTF 9번 서버, 공휴일, 이모지를 다시 봄: 묶음 완료 메시지가 5·10·15번 같은 번호에만 붙어 순서를 바꿔 풀면 틀리던 것을 고치고(T-113), 이모지 입력 여유를 0.3초에서 0.4초로(런처가 닫히는 데 0.18초). 나머지는 문제없음(T-114). 이전(2026-10-09 세 번째): 밤에 들어간 연결 창, 소리 창, 트레이, 창 붙이기, Alt+Tab을 다시 봄: Alt+Tab 목록에 닫힌 창이 남던 것을 고침(T-096). 이전(두 번째): 오늘 들어간 학습 센터, 배경화면 포털, 화면 배율, 배터리 알림, 프롬프트, os-release를 다시 봄: 학습 센터의 새로 읽기 놓침과 배터리 경고 반복을 고침(`b9bd1d9`). 이전(오전): 오늘 들어간 코드를 다시 봄: 클립보드(명령에 넘기는 id는 숫자만), 업데이트 알림, 전원 모드, 달력, 웹 연습 서버(127.0.0.1만), CTF. `ctf_prepare`가 지운 문제 파일을 다시 만들지 않던 것을 고침(`a4e3beb`). 이전: robin-install, robinctl 스냅샷·랩, post-install, 셸 QML 전체(2026-10-08) |
| 문서와 코드 맞추기 | 2026-10-10 | 새벽 뒤로 들어간 기능(Alt+Tab, 작업 보기, 빠른 메뉴, 이모지, 독 미리보기, 보안 점검, 앱 제거, 최근 파일, CTF 6~10, 알림 센터 열기)을 기준으로 다시 봄: 단축키 카드의 Print 설명, CTF 9번 서버가 접속마다 1시간을 다시 기다리던 것, 스크린샷 폴더 경로, 빠른 메뉴·구성 요소·윈도우 이름 표, 테스트 문서, 발표문을 고침(T-129). 이전(2026-10-09 밤): 밤에 들어간 기능(연결·소리 창, 트레이, 창 붙이기, Alt+Tab, 이모지, 보안 미션) 기준으로 다시 봄: desktop.md 구성 요소 표에 이모지·트레이, 환영 마법사 단축키 안내에 창 반쪽 붙이기·이모지를 넣음(T-099). 단축키 표, 단축키 보기 카드, README, 발표문, testing.md 장면 목록은 맞음. 이전(낮): desktop.md의 구성 요소·설치 위치 표(새 스크립트, 포털, mimeapps, fastfetch, 프롬프트), testing.md의 부팅 테스트 장면 수(41장)와 설치 테스트 확인 항목, README의 초기 명령(ctf), v0.2 발표문의 장면 목록을 오늘 들어간 것에 맞춤. 이전(2026-10-08 두 번째): 오늘 바뀐 것 기준으로 다시 봄: `robinctl help`의 learn·update 설명, testing.md의 부팅 테스트 장면(최소화, Super+D, 셸 다시 띄우기, 단추 배치)과 설치 테스트 확인 항목, "설치 방식은 두 가지" → 세 가지, roadmap의 미션 수, CLAUDE.md 저장소 지도(`apps.txt`, `practice/`), docs/README.md의 같이 고칠 문서 표(학습 미션, 패키지 목록)를 고침 |
| 보안과 윤리 | 2026-10-10 (오전) | 새벽 뒤로 들어간 것을 다시 봄: 텍스트 미션이 인터넷 방문자를 사설 주소(192.168.0.x)로 적어서 문서용 주소(198.51.100.x)로 바꾸고 테스트를 넣음, ethics.md의 주소 기준을 정확히(집 네트워크는 사설 주소), 런처 웹 검색은 고를 때만 보낸다고 적음(T-140). 계산은 eval 없이 직접 파싱, 앱 제거는 id를 글자 검사한 뒤 터미널에서 pacman이 묻고, 알림의 `x-robinos-open`은 `/`로 시작하는 로컬 파일만 xdg-open에 인자로 넘김(로컬 앱은 이미 무엇이든 실행할 수 있어 새 권한 없음), 독의 창 닫기는 앱에 닫기를 부탁만 함, CTF 9번 서버는 띄운 지 1시간 뒤 꺼짐(T-129), `vmware-checkvm`은 VMware로 감지될 때만 root로 돌고 open-vm-tools의 공식 도구. 이전(새벽): 새 `robinctl audit`이 라이브 ISO의 LLMNR(5355/udp, 모든 주소)을 찾아 끔(T-121). 그 앞(밤): 밤에 들어간 것을 다시 봄: 입문 CTF 9번 서버는 127.0.0.1에만 열리고 1시간 뒤 꺼짐(테스트가 확인), 8번 사전 공격은 CTF 쪽지에만, openssh는 클라이언트만(sshd는 꺼짐, 설치 테스트가 확인), 트레이 테스트 도우미는 ISO의 /opt/robinos/scripts에만 있고 자동으로 돌지 않음. 이전(2026-10-09): 오늘 들어간 것을 다시 봄: 학습 센터는 robinctl 출력의 숫자만 터미널 명령에 넣음, Steam·알림·배터리 알림은 고정된 인자, 기본 앱 연결은 /etc/xdg라 사용자 설정이 이김, os-release 스크립트는 임시 파일에 쓰고 바꿈. 새 네트워크 서비스 없음. 이전(2026-10-08): 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음, 이미지 고정(T-014). 라이브 ISO: sshd는 이미 꺼져 있음, releng의 cloud-init 유닛을 뺌. 설치본: root 잠금(robin-install), wheel은 비밀번호 sudo |
| 접근성 | 2026-10-10 | 밤에 들어간 창(연결·소리 창, 작업 보기, 알림 센터)을 다시 봄: 연결 창의 네트워크·장치 줄과 소리 창의 장치 줄이 마우스로만 눌려서 Tab·Enter·포커스 테두리를 넣음(T-106). 작업 보기는 화살표·Enter·Esc, Alt+Tab은 키보드 자체가 조작이라 문제없음. 이전(2026-10-09): 셸 QML의 누르는 곳은 모두 접근성 이름이 있고(이름 없는 MouseArea는 바깥을 눌러 닫는 배경뿐), 새 학습 센터의 미션 줄도 Tab·Enter와 이름이 있음. 이전(2026-10-08): 버튼과 선택지가 마우스 전용이던 것(T-015), 보조 글자 대비(subtle 3.9:1·2.6:1 → muted). 화면 읽기(Orca)는 Hyprland에 키보드 감시 인터페이스가 없어 막힘(T-040) |
| 성능 | 2026-10-10 (아침) | 묶음 63 부팅 테스트 시리얼 로그: SDDM 8.4초, Hyprland 11.1초인데 부팅 끝이 83.7초. 시계 동기화 대기(`systemd-time-wait-sync`)가 IPv6 NTP 시간 초과로 78초까지 붙잡아서 고침(T-139). 부팅 테스트 요약에 `Startup finished` 줄을 남겨 다음부터 바로 보이게. 이전(묶음 38): SDDM 8.6초, Hyprland 시작 11.4초, 부팅 끝 13.9초(전에는 9.0초, 11.4초, 15.9초). 독은 미리보기 자리까지 늘 큰 표면이지만 투명한 곳은 흐림에서 빠짐(`ignore_alpha`). 이전(2026-10-09): 부팅 테스트 시리얼 로그: SDDM 9.0초, Hyprland 시작 11.4초, 부팅 끝 15.9초(전에는 19.8초, 21.4초). 이전(2026-10-08): 부팅 테스트 시리얼 로그: 라이브에서 데스크톱까지 35초 중 ldconfig 14초(`/etc/.updated` 없음), Docker 5초 → 고침(`37de032`, 다음 부팅 테스트에서 확인). `fcitx5-remote` 1초 폴링은 작은 프로세스 하나라 그대로 둬요 |
| 업스트림 변화 | 2026-10-10 (오전) | Hyprland 0.56.2, Quickshell 0.3.2, Qt 6.12.0, systemd 262, linux 7.2.9, Firefox 157.0.1, archiso 91 그대로(묶음 65 빌드와 같음). 묶음 65 시리얼 로그의 Hyprland 경고는 start-hyprland와 실시간 스케줄링 실패(권한 없음, 동작에는 영향 없음)뿐. 이전: Hyprland 0.56.2, Quickshell 0.3.2 그대로. 묶음 38 시리얼 로그에 Hyprland 경고는 알려진 start-hyprland 하나뿐. 이전(2026-10-09): quickshell이 0.3.2로 올라옴(Qt 6.12로 다시 빌드). 묶음 10·11 부팅 테스트에서 Qt 경고도 QML 오류도 없어서 지켜보던 것은 끝. design.md 버전 고침. Hyprland 0.56이 `start-hyprland` 없이 띄우면 경고하는데, 비정상 종료 때 `--safe-mode`로 다시 띄워서 소프트웨어 렌더링 재시도와 부딪혀 직접 실행을 유지(design.md). 그 밖에는 Hyprland 0.56.2, SDDM 0.21.0, GRUB 2.16, archinstall 4.5, linux 7.2.9 그대로 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| `9b5d5f3` (브랜치 `claude/eoseohae-7nleia`) | T-145 설치본이 RobinOS 저장소를 쓰게 | `verify -Installer robinos`(ISO 빌드가 패키지를 넣는지, 설치 테스트의 `pacman -Qo`·저장소 확인), 이어서 `install-test`(archinstall 경로) |
| `1549271`과 그 뒤 문서 커밋 (같은 브랜치) | 방향 고침, 설계 점검, 문서 최종 점검(`install-test.sh`와 `doctor-build.sh` 한 줄씩 포함) | 정적 검증(통과). 앞의 T-145와 함께 기다려요 |

모두 클라우드 세션에서 만들어 작업 브랜치에만 올렸어요. 이 PC에서 브랜치를 받아 검증하고, 통과하면 main에 합치고 푸시해요. main은 `c910682`까지 푸시했어요(묶음 69는 `f6ceb6d`, T-144는 실제 올리기로 확인).

## 사용자 확인 필요

- **실기기 라이브 부팅 (지금 가장 값진 검증, 2026-10-10 설계 점검)**: 검증 묶음 69번이 모두 VM이었고 실제 PC에서는 한 번도 켜 보지 않았어요. USB로 실제 PC에서 ISO를 부팅해 봐 주세요. 먼저 펌웨어 설정에서 보안 부팅을 꺼야 해요([install.md](install.md) "보안 부팅 끄기", 윈도우를 남길 거면 BitLocker 복구 키부터 확인). 데스크톱이 뜨는지, Wi-Fi·소리·화면 밝기·한글 입력이 되는지가 먼저예요. NVIDIA 카드(GTX 16, RTX 20 이후)가 있는 PC라면 설치한 뒤 데스크톱이 뜨는지, `lsmod | grep nvidia`에 나오는지도 봐 주세요(T-030). 노트북이라면 전원을 뽑고 배터리가 10%가 될 때 "배터리가 10% 남았어요" 알림이 뜨는지(T-070), 런처의 "Steam 설치하기"로 받은 Steam에서 게임이 켜지는지(T-066)도 봐 주세요. 빠른 설정의 "야간 모드"를 켜면 화면이 따뜻한 색이 되는지도 봐 주세요(T-076, VM에서는 안 돼요). (`막힘`)
- **라이선스**: 저장소에 라이선스 파일이 없어서 RobinOS 패키지에 `license=(unknown)`으로 적었어요. 공개 프로젝트라 정해 두는 게 좋아요(예: MIT, GPL-3.0). 정해 주면 `LICENSE`와 패키지에 넣어요
- **실제 윈도우 PC에서 "윈도우 옆에 설치"**: VM의 가짜 윈도우 디스크로는 파티션과 부팅 파일이 그대로인 것까지 확인했어요(T-006). 진짜 윈도우가 GRUB 메뉴에 나오는지, BitLocker 복구 키를 묻는지는 실제 PC에서만 볼 수 있어요. 백업해 둔 PC나 남는 디스크로 해 주세요. (`막힘`)
- **집 PC의 VMware 서비스 켜기(T-025)**: 집 PC(Blitz)에서 VM을 만들어 켜려 했더니 VMware의 윈도우 서비스(Authorization, DHCP, NAT, USB Arbitration)가 모두 "사용 안 함"이라 VM이 켜지지 않아요. 관리자 권한이 필요해서 직접 하지 않아요. 쓰려면 관리자 PowerShell에서 `'VMAuthdService','VMnetDHCP','VMware NAT Service','VMUSBArbService' | ForEach-Object { Set-Service -Name $_ -StartupType Manual }; Start-Service VMAuthdService,VMnetDHCP,'VMware NAT Service'` (2026-10-10 처음 알려 드린 명령은 `Set-Service`에 이름을 한꺼번에 넘겨서 윈도우 PowerShell 5.1에서 실패했어요). VM(`문서\Virtual Machines\RobinOS`)과 스크립트(`build\vmware\vmware-test.py`)는 준비돼 있어요 (`막힘`)

## 진행 중

### T-147 보안 부팅과 BitLocker 안내
- 상태: 진행 중
- 출처: 설계 점검(2026-10-10) "보안 부팅". 문서 어디에도 없었어요
- 한 것: install.md "보안 부팅 끄기"(BitLocker 복구 키 확인, 윈도우의 고급 시작 → UEFI 펌웨어 설정, 설치 뒤에도 꺼 둬야 하는 것), 준비 목록, README 내려받기 안내
- 남은 것: 설치기가 윈도우 옆에 설치할 때 윈도우 파티션이 BitLocker인지 보고(`lsblk -o FSTYPE`의 `BitLocker`) 확인 단계에서 "복구 키를 확인했나요?"를 묻기. 다음 릴리스 노트에 보안 부팅 안내
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
- 남은 것 (VMware가 있는 PC: robin PC, 집 PC(Blitz, VMware Workstation 26.0)): 최종 ISO로 VMware VM에 다시 설치(`vmrun` 게스트 명령, 계획은 디스크 `/dev/nvme0n1` 전체), 로그인 뒤 셸·해상도 확인. 집 PC에는 VM이 아직 없어서 새로 만들어요(`build\vmware\guest-*.sh`는 robin PC에만 있어요). VMware가 없는 PC의 루프는 이 작업을 건너뛰어요

## 할 일 (위에서부터)

2026-10-10 방향 결정("나만의 새로운 OS", [design.md](design.md))과 설계 점검으로 순서를 다시 잡았어요. RobinOS다운 경험(설정, 부팅 화면, 정체성)과 실제 PC에서 켜지는 것을 먼저 하고, 윈도우 기능 따라 하기와 학습 기능은 그 뒤예요.

### T-145 설치본이 RobinOS 저장소를 쓰게 (RobinOS 파일 업데이트 3단계)
- 상태: 검증 대기 (2026-10-10 클라우드 세션에서 만듦, 이 PC의 VM 검증 전)
- 할 것: 설치기·post-install이 `[robinos]` 저장소와 열쇠(로컬 서명)를 넣고 RobinOS 파일을 패키지로 설치. 이미 깐 파일에서 옮겨 가는 `robinctl update`(처음 한 번 `--overwrite`)
- 한 것: `robinctl repo`(상태), `repo setup`(열쇠 지문 고정, `[robinos]` 넣기), `repo adopt`(패키지에 든 경로에만 `--overwrite`). `post-install.sh`가 설치 끝에 둘 다 하고, `robinctl update`는 저장소가 켜졌는데 패키지가 아니면 한 번 옮겨요. `build-iso.sh`가 같은 커밋의 패키지를 라이브 ISO `/opt/robinos/pkg`에 넣어서 설치기는 그걸 써요(개발 ISO에서 저장소의 옛 파일로 돌아가지 않게, design.md). 릴리스 열쇠는 `/opt/robinos/keys`. 설치 테스트에 `pacman -Qo`·`pacman -Qk`·저장소·열쇠·`pacman -Si robinos` 확인, archinstall 경로는 ISO의 `pkg/`도 복사
- 확인한 것(클라우드 세션, Arch 컨테이너의 실제 pacman): ① 복사한 파일 위에 `repo setup` + `repo adopt <패키지>` → `pacman -Qo`가 `robinos`, `-Qk` 빠진 파일 없음, 다시 setup해도 `[robinos]` 한 번, 깃허브 저장소가 서명된 DB로 답함(`0.3.0.r400-1`) ② 패키지 없이 파일만 있는 시스템에서 `robinctl update`가 깃허브에서 받아 옮기고, 고친 `config.toml`은 남고 `.pacnew` ③ `post-install.sh --dry-run`이 `pkg/`가 있으면 `pacman -U`, 없으면 `pacman -S`(여기서 `pkg/`가 없을 때 `find` 실패로 스크립트가 멈추던 것을 찾아 고침) ④ 정적 검증(pwsh), `check-sync.sh`, `test-robinctl.sh`(새 repo 시험 통과, 컨테이너에 systemd가 없어 미션 34 관련 5개는 전부터 실패), `test-robin-install.py`
- 남은 것: 이 PC에서 `verify -Installer robinos`. 서명한 로컬 패키지(`.sig`)를 `pacman -U`가 받아들이는지는 VM에서 처음 봐요(컨테이너에는 개인 열쇠가 없어 서명 없이 시험). 스냅샷과 함께 받는 것은 실제 새 버전이 저장소에 올라간 뒤 설치본에서 확인
- 완료 기준: 설치 테스트에서 `pacman -Qo /usr/share/robinos/shell/shell.qml`이 `robinos`, `robinctl update`가 스냅샷과 함께 새 버전을 받음

### T-149 RobinOS 설정 앱
- 상태: 할 일
- 출처: 설계 점검(2026-10-10) "설정". 런처의 "제어판"과 바탕 화면 메뉴의 "디스플레이 설정"이 빠른 설정(배율, 밝기)으로 가요. 해상도, 여러 모니터, 날짜·시간, 사용자, 기본 앱은 화면이 없고 Lua 파일을 고쳐야 해요
- 방향: 환영 마법사·학습 센터처럼 셸 안의 QML 창(`desktop/shell/Settings.qml`)으로 만들어요. 왼쪽에 항목, 오른쪽에 내용. 빠른 설정은 자주 쓰는 것만 남기고 "모든 설정"으로 이 창을 열어요. 바꾼 값은 사용자 설정 파일에 저장해 RobinOS 기본값을 덮어요(시스템 파일은 건드리지 않아요)
- 단계(한 단계가 1~3회차): ① 창 틀과 "개인 설정"(테마, 강조색, 배경화면)·"정보"(RobinOS 버전, `robinctl repo` 상태, 하드웨어 요약) ② "디스플레이"(모니터마다 해상도·주사율·배율·위치, `hyprctl monitors`로 읽고 사용자 Hyprland 설정에 저장) ③ "소리"·"네트워크"·"블루투스"는 이미 있는 창으로 연결 ④ "날짜와 시간"(시간대, 자동 동기화)·"키보드"(한/영 키, 반복 속도) ⑤ "기본 앱"·"사용자 계정"(비밀번호 바꾸기는 `passwd`를 터미널에서) ⑥ "업데이트와 복구"(`robinctl update`, 스냅샷 목록)
- 검증: `wsl-build.ps1 check`(qmllint), 부팅 테스트에 설정 창 장면(단계마다 하나), 디스플레이는 두 번째 가상 모니터로
- 완료 기준: 런처에서 "설정"·"제어판"으로 이 창이 열리고, 위 여섯 항목이 키보드만으로도 동작

### T-150 부팅 화면 (Plymouth)
- 상태: 할 일
- 출처: 설계 점검(2026-10-10) "부팅 화면". GRUB 메뉴 뒤에 커널 글자가 지나가고 SDDM이 떠요. [brand.md](brand.md)의 "부팅 스플래시"가 아직 없어요
- 할 것: Plymouth와 RobinOS 테마(울새 마크, zinc 배경, 진행 표시). 설치본(`robin-install`·`post-install.sh`의 initramfs 훅, `quiet splash`)과 라이브 ISO 둘 다. 디스크 암호화를 나중에 넣을 때 비밀번호 입력도 이 화면이 맡아요
- 확인할 것: 패키지 크기(라이브 ISO 한도까지 약 44MiB), 소프트웨어 렌더링 VM에서 SDDM으로 넘어가는 시간, 스냅샷으로 부팅할 때(grub-btrfs-overlayfs 훅과 함께)
- 완료 기준: 부팅 테스트에 스플래시 장면, 부팅 시간이 전과 비슷함, 설치 테스트의 스냅샷 부팅 통과

### T-151 정체성 문구를 화면에
- 상태: 할 일
- 출처: 설계 점검(2026-10-10) "정체성 문구". 문서(design, vision, README, brand)는 고쳤고 화면이 남았어요
- 할 것: 로고 한 줄 소개("매일 쓰면서 배우는 보안 학습 OS")를 새 방향에 맞게 바꾸고 `assets/brand/build-logo.py`로 SVG 다시 만들기, 로그인·잠금 화면의 "허가받은 환경에서만 쓰는 보안 학습용 시스템이에요"를 RobinOS 인사로 바꾸기(윤리 안내는 학습 센터·랩·motd·ethics.md에 그대로), 라이브 부팅 메뉴 이름 "RobinOS Security Learning Live"(`scripts/customize-iso-boot.sh`, testing.md), 터미널 인사 "RobinOS 보안 학습 환경"(`desktop/bash/robinos-bashrc.sh`, fastfetch가 없을 때), `config/robinos.toml`의 `purpose = "security-learning"`(읽는 코드가 없는지 먼저 확인), 환영 마법사 첫 화면 문구 다시 보기. README의 학습 센터 스크린샷이 "1 / 40"이라 다시 찍기
- 완료 기준: 부팅 테스트의 SDDM·잠금 화면 장면, README 로고

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
- foot 제목 표시줄(hyprbars). 학습 센터, 네트워크 랩, 입문 CTF는 이미 들어갔어요(최소화와 `Win+D`는 T-024, Qt 앱 제목 표시줄은 T-029)

## 완료

최근 것이 위에 있어요. 더 오래된 기록은 [done.md](done.md)에 있어요.

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
