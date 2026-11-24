# RobinOS 완료 기록 (보관)

[tasks.md](tasks.md)의 "완료"에서 옮긴 오래된 기록이에요. 최근 것이 위에 있어요. 루프가 회차마다 읽는 tasks.md를 가볍게 두려고 나눴어요.

## 끝낸 작업

tasks.md에서 옮긴 작업 카드예요(2026-11-24 T-176 정리부터). 최근에 옮긴 것이 위에 있어요.

### T-164 처음 상태로 되돌리기 (조사)
- 상태: 완료 (2026-11-24 robin PC, 조사. 만드는 일은 T-187)
- 출처: 다른 OS와 비교(2026-10-12). 윈도우 "이 PC 초기화", ChromeOS Powerwash, Omarchy "Reset Computer", Pop!_OS의 파일을 남기는 다시 설치
- 할 것: 설치가 끝난 직후의 스냅샷을 "처음 상태"로 남겨 두고, 설정 앱에서 개인 파일은 남긴 채 시스템만 그때로 되돌리는 방법 조사. 다른 사람에게 PC를 넘길 때 쓰는 "새 주인 준비"는 그다음
- ChatGPT 네 번째 검토: 개인 파일과 다른 하위 볼륨은 남으니 "공장 초기화"가 아니라 "시스템 재설정"이라고 불러요. Pop!_OS의 파일을 남기는 다시 설치와 비교
- 완료 기준: 방식과 위험(남는 것과 지워지는 것)을 [recovery.md](recovery.md)에 정리
- 한 것(2026-11-24 낮 robin PC): [recovery.md](recovery.md) "시스템 재설정"에 정리. 처음 상태는 `snapshot setup`의 첫 스냅샷이에요. 정리 규칙이 없어 snapper가 지우지 않고, RobinOS 설치기에서는 사용자 계정을 만든 뒤에 찍혀요. 지금도 `sudo robinctl snapshot rollback 1`로 돼요. 남는 것은 `@home`, `@log`, `@pkg`, `@snapshots`이고, 돌아가는 것은 `/etc`(계정·비밀번호·와이파이·방화벽 규칙), 시스템 Flatpak, Docker, 패키지 버전이에요. 찾은 위험: 윈도우 옆 설치는 설치기가 첫 스냅샷 뒤에 `grub.cfg`에 윈도우를 넣어서, 1번으로 되돌리면 부팅 메뉴에서 윈도우가 빠져요. 설치 뒤 바꾼 비밀번호도 옛것으로 돌아가요. "새 주인 준비"는 스냅샷이 아니라 USB로 다시 설치하는 길로 안내했어요

### T-184 윈도우 프로그램 안내의 남은 것
- 상태: 완료 (2026-11-24 robin PC, `97a1bb0` 묶음 검증)
- 할 것: ① 학습 미션 쪽 설명(실행 파일 형식이 왜 다른지, 안내 창에서 이어지게) ② 설치본에서 Flathub 단추가 앱 스토어의 그 앱을 여는지 설치 테스트로 확인
- 한 것(②, 2026-11-24 오전 robin PC): 설치 테스트가 데스크톱 없이 콘솔로 돌아서 단추를 누르는 대신, 단추가 여는 앱 ID(`windowsapps.js`의 `flathub:` 34개)가 모두 Flathub 앱 목록(`flatpak remote-ls`)에 있는지 설치본에서 확인해요. 만들기 전에 Flathub의 공개 목록과 맞춰 보니 Thunderbird만 틀렸어요: Flathub는 `org.mozilla.thunderbird`(소문자)라 단추를 눌러도 앱 스토어가 못 찾았어요. 고쳤어요
- ② 확인(2026-11-24): `install-test -Installer windows`에서 34개 ID가 모두 Flathub 목록에 있어요. 남은 것은 ①
- 한 것(①, 2026-11-24 낮 robin PC): 안내 창 아래의 글 한 줄을 "왜 안 열리는지 알아보기" 단추(ghost)로 바꿨어요. 누르면 창을 닫고 미션 16(실행 파일 살펴보기)을 터미널에 열어요. 미션 16은 이제 연습 파일 `hello.exe`(64비트 콘솔 .exe의 머리 부분만, 코드 없음, 실행 권한 없음)도 만들고, "윈도우 프로그램과 비교" 칸에서 `file`과 `xxd`로 ELF(7f 45 4c 46)와 MZ(4d 5a)를 나란히 보여 줘요. `hello.exe`를 `xdg-open`으로 열면 같은 안내 창이 떠서 둘이 서로 이어져요. 새 미션을 만들지 않은 건 미션 16이 이미 ".exe와 ELF"로 시작해서예요. 부팅 테스트에 `windows-app-learn` 장면(단추를 눌러 새 터미널의 미션 16, 판정은 창이 닫혔고 `file`이 `hello.exe`를 MS Windows용으로 알아보는지)
- 완료 기준: 미션 하나가 안내 창에서 열리고, 설치 테스트에 Flathub 단추 장면
- 확인(2026-11-24 `verify`, `97a1bb0`): `52-windows-app-learn`에서 단추가 창을 닫고 새 터미널에 미션 16의 "윈도우 프로그램과 비교"가 보여요. 판정 `windows-app-learn` PASS(`file`: PE32+ executable for MS Windows). 그 터미널을 닫은 뒤 다음 장면들도 처음 터미널에서 그대로 이어졌어요

### T-186 휴대폰 연결 (LocalSend)
- 상태: 완료 (2026-11-24 robin PC, `3b92fa1` 묶음 검증. 실제 휴대폰으로 받아 보기는 T-167)
- 한 것: 런처에 "LocalSend 설치하기"(앱 스토어가 있고 아직 안 깔렸을 때만)와 "휴대폰에서 받기 허용", 윈도우 이름 "휴대폰과 연결"(깔려 있으면 앱, 없으면 설치 항목). ufw 앱 프로필 `desktop/ufw/robinos-localsend`(53317 tcp·udp), 받기 허용은 사설 주소 세 대역에서만 열고 명령을 터미널에서 보여 줘요. 공용 와이파이도 사설 주소라는 점은 desktop.md에 그대로 적었어요. Flathub ID는 공개 목록에서 확인했어요. 설치 테스트가 `ufw app info LocalSend`와 `ufw --dry-run allow ...`를 봐요. 남은 것: 실제 휴대폰으로 받아 보기(T-167)
- 확인(2026-11-24 `verify`, `3b92fa1`): 설치 테스트 `rollback-10-launcher-phone`에서 설치본 런처가 "phone"에 "LocalSend 설치하기"(윈도우에서 쓰던 이름 묶음)와 "휴대폰에서 받기 허용"을 보여 줘요. 방화벽 규칙은 `ufw --dry-run`으로 확인했고, 실제로 파일을 받는 것은 휴대폰이 있어야 해서 T-167로 넘겨요
- 할 것: ChatGPT 네 번째 검토대로 LocalSend(Flathub, 아이폰도 돼요)를 먼저. 앱 스토어에서 바로 설치하는 런처 항목("휴대폰과 연결"이라는 윈도우 이름으로 찾기), 방화벽(ufw)에서 LocalSend 포트(53317)를 집 네트워크에만 여는 방법. KDE Connect는 권한과 방화벽 규칙까지 생각해야 해서 나중
- 완료 기준: 런처에서 "휴대폰"으로 찾아 설치할 수 있고, 방화벽이 켜진 설치본에서 파일을 받을 수 있어요(VM 두 대나 설치 테스트로 확인)

### T-185 접근성: 고대비와 셸 글자 크기
- 상태: 완료 (2026-11-24 robin PC, `3b92fa1` 묶음 검증)
- 할 것: 설정 "손쉬운 사용"에 고대비(robin-ui 키트의 면·글자 대비를 높인 토큰 한 벌), 셸 자체의 글자 크기(지금은 화면 배율로만), 움직임 줄이기·앱 글자 크게를 켠 부팅 테스트 장면
- 완료 기준: 두 가지가 설정에서 켜지고 다시 켜도 유지되고, 부팅 테스트에 켠 장면이 있어요
- 한 것(2026-11-24 robin PC): 키트에 고대비 토큰 두 벌(`robin-ui.css`의 `[data-contrast="high"]`, 라이트는 `[data-theme="light"][data-contrast="high"]`, `tokens.json`의 `dark-high`·`light-high`). 면·파란색·알림 색은 그대로 두고 선(모든 면에 3:1 넘게)과 흐린 글자(7:1 넘게)만 진하게. 셸은 `Theme.highContrast`(appearance.json에 저장)가 `border`·`borderStrong`·`input`·`panelBorder`·`controlLineHover`·`muted`·`subtle`을 바꾸고 GTK의 `org.gnome.desktop.a11y.interface high-contrast`와 Hyprland 창 테두리도 따라가요. 설정 "손쉬운 사용"에 "고대비" 스위치, IPC `setHighContrast`·`setReduceMotion`·`setLargeText`, 부팅 테스트에서 셋을 모두 켜고 GTK가 받은 값(true, false, 1.25)을 보여 주는 `high-contrast-light`, `high-contrast-launcher`, 설정 화면 `accessibility-settings` 장면. shell-load.sh로 두 테마 모두 찍어 봤어요
- 셸 글자 크기는 따로 두지 않기로(2026-11-24): 셸 QML에 글자 크기 숫자가 189곳, 행 높이 41 같은 고정값이 있어서 글자만 키우면 잘리고, 빠른 설정의 화면 배율(125%~200%)이 셸 전체를 같은 비율로 키워요. 윈도우도 "텍스트 크기"와 "배율"이 따로지만 RobinOS는 배율 하나로 해요
- 확인(2026-11-24 `verify`, `3b92fa1`): `95-high-contrast-light`에서 터미널이 GTK 값 true·false·1.25를 보여 주고, `96-high-contrast-launcher`의 선이 진해졌고, `97-accessibility-settings`에 세 스위치가 모두 켜져 있어요

### T-177 업데이트 길의 약한 곳
- 상태: 완료 (2026-11-24 robin PC: ②의 `install-test -Installer archinstall` 다섯 단계 통과, 복사본이 `robinos` 패키지로 옮겨지고 `pacman -Qo`가 robinos. 같은 시험에서 post-install 직후 ufw가 꺼져 있던 것을 찾아 고침 `a9687cb`)
- 출처: 업데이트 시스템 점검(2026-10-15, [unfinished.md](unfinished.md) 7번 표)
- 할 것: ① 깃허브가 안 될 때도 Arch 업데이트는 되게: `robinctl update`가 `[robinos]` 목록을 못 받으면 그 저장소를 뺀 설정으로 `pacman -Syu`를 하고 "RobinOS 파일은 다음에 받아요"라고 알려요(Arch 컨테이너에서 받을 수 없는 서버로 시험) ② git으로 받은 파일로 설치한 시스템을 패키지로 옮기기: 저장소에서 받은 `robinos` 패키지의 파일 목록에만 `--overwrite`(설치 후 설정과 `robinctl update`, design.md "RobinOS 파일 업데이트" 5번) ③ 서명 열쇠: 백업 확인, 열쇠를 바꾸는 절차(새 열쇠를 옛 열쇠로 서명해 `robinos` 패키지로 보내기), 만료 전 연장을 release.md에
- 한 것(2026-10-15 클라우드 세션): ① `robinctl update`가 `pacman -Sy`에 실패하면 `[robinos]` 블록을 뺀 임시 설정으로 다시 받고 `-Su`를 해요(pacman.conf는 그대로). 시험 7개(`test-robinctl.sh`: 깃허브만 안 될 때, 인터넷이 아예 없을 때), Arch 컨테이너의 실제 pacman으로 닿지 않는 `[robinos]`에서 그냥 `pacman -Syu`는 멈추고 `robinctl update`는 끝까지 가는 것을 확인. 남은 것: 설정 앱의 업데이트 상태(`checkupdates`도 같은 이유로 실패해 "알 수 없음"), ②, ③
- 한 것(③, 2026-11-24 새벽): 설치본은 처음 설치 때 넣은 공개 열쇠를 계속 들고 있어서, 만료를 늘리거나 열쇠를 바꿔도 닿지 않고 2029-10-09에 업데이트가 멈출 뻔했어요. `robinos.install`이 패키지가 바뀔 때마다 패키지에 든 열쇠를 pacman 열쇠 꾸러미에 다시 넣고 서명해요(이미 그 열쇠를 가진 시스템만, 시험 3개). [release.md](release.md) "서명"에 백업 확인, 만료 늘리기, 열쇠 바꾸기 절차
- 한 것(②, 2026-11-24 오전 robin PC): `robinctl`의 `robinos_adopt`가 `robinos`를 캐시로 받아(`pacman -Sw`) 파일 목록(`pacman -Qlpq`)의 파일마다 `--overwrite`를 줘서 설치해요(디렉터리는 빼고, `[`·`*`·`?`·`\`는 이스케이프, 쉼표가 든 이름은 빼요). 설치 후 설정은 `pkg/`가 없으면 `robinctl update --adopt`로 하고, 못 받으면 예전처럼 복사해요. `robinctl update`는 `-Su` 뒤에 복사된 파일(`/usr/share/robinos/shell/shell.qml`)이 있고 `robinos`가 없을 때만 옮겨요(패키지를 일부러 지운 시스템은 그대로). 시험: `test-robinctl.sh` 14개(옮기기, 덮어쓸 목록에 디렉터리 없음, 괄호 이스케이프, 두 번 안 함, 못 받을 때 안내, 저장소 없음), WSL 임시 루트의 진짜 pacman으로 복사본 셋을 덮어쓰고 주인이 `robinos`인지, 괄호를 이스케이프하지 않으면 그 파일이 충돌로 남는지 확인. 알게 된 것: `--root`를 주면 pacman은 `--overwrite` 패턴을 루트를 붙인 경로와 비교해요(실제 시스템은 루트가 `/`라 상관없어요). 설치 테스트 archinstall은 ISO 패키지로 만든 로컬 저장소와 예전 방식의 복사본으로 옮기기를 확인하고 진짜 저장소로 되돌려요
- 완료 기준: ①② 시험(`test-robinctl.sh`와 Arch 컨테이너의 실제 pacman), 설치 테스트 archinstall 경로에서 `pacman -Qo`가 `robinos`, ③ release.md 절차

### T-147 보안 부팅과 BitLocker 안내
- 상태: 완료 (2026-11-24 robin PC: `install-test -Installer windows` 다섯 단계 통과, `live-06-installer-bitlocker`에서 경고 체크 전까지 "설치 시작"이 막혀요)
- 출처: 설계 점검(2026-10-10) "보안 부팅". 문서 어디에도 없었어요
- 한 것: install.md "보안 부팅 끄기"(BitLocker 복구 키 확인, 윈도우의 고급 시작 → UEFI 펌웨어 설정, 설치 뒤에도 꺼 둬야 하는 것), 준비 목록, README 내려받기 안내
- 한 것(2026-10-12 집 PC): 설치기가 디스크의 `BitLocker` 파티션을 알아보고(`lsblk`의 FSTYPE) 디스크 카드에 "윈도우 있음 (BitLocker)", "윈도우 옆에 설치"의 확인 단계에서 "복구 키를 따로 적어 두었어요"에 체크해야 설치 시작. 백엔드도 계획에 `bitlocker_key_saved`가 없으면 디스크를 건드리기 전에 멈춰요. `test-robin-install.py`에 가짜 BitLocker 디스크 검사 여덟 개. 확인 상자는 `ConfirmBox` 하나로 합쳤어요(지우기 확인과 같이 써요)
- 한 것(2026-11-24 오전 robin PC): 설치 테스트 windows의 가짜 디스크에 BitLocker로 잠긴 64MB "D:"(9번 파티션)를 넣었어요. 부트 섹터의 `ëX-FVE-FS-`와 176바이트째의 FVE 메타데이터 위치, 그 자리의 `-FVE-FS-`만 있으면 blkid가 `BitLocker`로 봐요(WSL에서 확인). 시험: 디스크가 `bitlocker`인지, 복구 키 확인 없이 `prepare_disk`가 파티션 표를 건드리기 전에 멈추는지, 설치 화면이 지우기 확인 뒤에도 복구 키를 체크해야 "설치 시작"을 여는지(`installer-bitlocker` 스크린샷), D:의 앞부분이 그대로인지
- 다음 릴리스 노트의 보안 부팅 안내는 [release.md](release.md) 릴리스 노트 항목으로 옮겼어요
- 완료 기준: 설치기 테스트(`test-robin-install.py`)에 가짜 BitLocker 파티션, 설치 테스트 windows에서 경고 장면

### T-176 반쪽 작업 끝내기
- 상태: 완료 (2026-11-24 오전 robin PC: 진행 중 6개, tasks.md 250줄 이하)
- 출처: 부족한 점 점검(2026-10-15, [unfinished.md](unfinished.md) 9번 표). `진행 중`이 21개라 새 일을 시작하는 속도가 끝내는 속도보다 빨라요
- 할 것: 진행 중인 작업마다 "남은 것"을 ① 이번에 끝낼 것 ② 따로 떼어 낼 새 작업 ③ 버릴 것으로 나눠요. ①만 남은 작업은 끝내고 `완료`로, ②는 새 번호로 `할 일`에 넣어요. 끝난 단계의 긴 기록은 done.md로 옮겨 tasks.md를 가볍게 해요. 그동안 [loop.md](loop.md) "3. 작업 고르기"의 진행 중 한도(10개)를 지켜요
- 한 것(2026-11-24 새벽): T-151·T-155·T-159·T-162를 완료로(T-159의 남은 것은 T-184로), T-154의 남은 것을 상태 줄에 모음. 21개 → 17개
- 한 것(2026-11-24 오전 robin PC): 완료 기준을 채운 T-157·T-161·T-165·T-169·T-170·T-171·T-172·T-173·T-174·T-175를 완료로, 끝난 카드 22개를 [done.md](done.md) "끝낸 작업"으로 옮김. 남은 것은 T-149(사용자 계정·디스플레이), T-167(실기기), T-185(고대비·셸 글자 크기), T-186(휴대폰 연결), [unfinished.md](unfinished.md), T-011 후보로. T-168은 실기기가 필요해 막힘. T-149·T-167의 보충 카드를 본 카드에 합침. 진행 중 17개 → 6개(T-176을 빼고)(T-147, T-025, T-180, T-154, T-153, T-149)
- 같이 한 것: T-025와 T-154의 지난 기록을 [done.md](done.md)로 옮기고 카드에는 요약 한 줄만
- 완료 기준: `진행 중` 10개 이하, tasks.md 250줄 이하

### T-025 기록 (2026-11-24 T-176 정리에서 카드에서 옮김)
- 찾은 것: ① 3D 가속을 켜면 Hyprland는 `vmwgfx`로 잘 그리는데 셸(Qt)은 `Could not create EGL surface`로 아무것도 안 그림. ② 화면이 물리 크기를 알려 주지 않아 Hyprland 자동 배율이 2배 → 1280×800 창이 640×400 바탕 화면(환영 마법사가 위아래로 잘림). ③ VMware 창 크기를 바꾸면 커널은 새 크기를 받는데 Hyprland는 처음 해상도를 그대로 씀. ④ 설치본에는 `open-vm-tools`가 없음
- 한 것: `robinos-shell`(EGL 실패를 보면 셸만 소프트웨어로 다시 띄움, 죽으면 다시 띄움), VM 화면(`Virtual-*`)은 배율 1, `robinos-vm-display`(창 크기를 따라감), 설치기가 VMware에서는 `open-vm-tools`와 `vmtoolsd`를, QEMU/KVM에서는 `qemu-guest-agent`를 설치. 라이브 VM에서 셋 다 직접 확인(셸 강제 종료 후 다시 뜸, 1718×920·배율 1로 맞춤, udev change 신호로 다시 맞춤)
- `426e32d` ISO를 VMware에서 띄우니 셸이 GPU 실패 뒤 아무것도 안 그리는 대신 Wayland 오류(`wl_surface.attach` invalid arguments)로 바로 죽었어요. `robinos-shell`은 살아 있는 셸에서만 GPU 실패를 확인해서 이걸 그냥 "죽음"으로 세고 GPU 모드로 다섯 번 다시 띄운 뒤 포기했어요. 셸이 죽은 뒤에도 로그를 보고 소프트웨어로 바꾸게 고쳤고, 라이브 VM에서 확인했어요
- 같이 한 것: 화면에 보이는 단축키를 `Super` 대신 `Win`으로 적어요(사용자 질문 "Super 키가 뭐야?"). 환영 마법사 마지막 단계에 "Win 키는 리눅스에서 Super 키라고 불러요"를 넣었어요
- 지금까지(2026-10-08, robin PC): `426e32d` ISO를 VMware VM에 설치함. 설치기가 마지막 `umount`에서 멈췄고(gpg-agent, `933ca31`에서 고침) 손으로 분리한 뒤 고친 `robinos-shell`을 넣어 부팅. 설치본에서 `open-vm-tools` 설치, `vmtoolsd` 켜짐, SDDM 로그인 화면까지 확인. 로그인 뒤 데스크톱은 아직 못 봄(VMware에는 키 입력을 보낼 방법이 없어 사람이 로그인해야 해요)
- 검증: `933ca31` ISO로 부팅 테스트(29장)와 설치 테스트 robinos(다섯 단계) 통과, `e038f2a`까지 main 푸시(정기 점검 표)
- 2026-10-11: 사용자가 집 PC(Blitz)의 VMware 서비스(Authorization, DHCP, NAT)를 켜서 `Running` 확인. 이제 이 PC에서 VM을 만들어 최신 ISO로 설치해 볼 수 있어요
- 2026-10-12 집 PC(Blitz): 묶음 72의 ISO(`bd8c495`, robinos 패키지 포함)를 `build\vmware\vmware-test.py install`로 VM에 설치하는 중. 끝나면 `installed`로 설치본 부팅·해상도·vmtoolsd 확인. 다른 PC로 옮기면 이 VM은 집 PC에만 있어요
- 2026-11-24: 스크립트를 `scripts/vmware-test.py`로 옮겨 커밋했어요(어느 PC에서나 `python scripts/vmware-test.py create|install|installed|stop`, ISO는 `build\vmware\robinos.iso`). [build-environment.md](build-environment.md) "다른 PC에서 이어서 하기"

### T-154 기록 (2026-11-24 T-176 정리에서 카드에서 옮김)
- 지금: 셸 창(학습 센터, 설치기)과 GTK·Qt 앱은 제목 표시줄을 끌면 돼요. foot 터미널은 제목 표시줄이 없어서 `Win`+왼쪽 끌기(이동), `Win`+오른쪽 끌기(크기)만 돼요(`robinos.lua`의 `hl.dsp.window.drag`). `desktop/foot/foot.ini`에 `[csd] preferred=client`가 있는데 Hyprland가 xdg-decoration에 "서버가 그린다"고 답해서 foot이 제목 표시줄을 그리지 않아요(design.md "창 제목 표시줄")
- 찾은 것(2026-10-12): Hyprland 0.56.2 소스(`src/protocols/XDGDecoration.cpp`)에서 `xdgModeOnRequestCSD()`가 앱이 무엇을 요청하든 `MODE_SERVER_SIDE`를 돌려줘요. 설정으로 바꿀 수 없어서 foot은 언제나 제목 표시줄을 그리지 않아요
- 할 것: 비교: hyprbars 플러그인(Hyprland 버전마다 다시 빌드해야 해서 롤링 업데이트에 약해요), 제목 표시줄을 스스로 그리는 터미널(GNOME 콘솔·Ptyxis 등, foot의 테마 전환·힌트를 옮겨야 해요), 셸이 그리는 얇은 끌기 막대 ④ 제품 방향이 바뀌는 선택(터미널 교체)이면 사용자 확인 필요로
- 한 것(2026-10-12, `work/batch74`): 기본 터미널을 Ptyxis로. `ShellState.terminal`(`ptyxis --new-window`) 하나를 독, 런처(터미널 앱 실행 포함), Win+X, 바탕 화면 메뉴, 미션·업데이트 터미널(`openTerminal`, `runInTerminal`)이 같이 써요. Hyprland `Win+Enter`도 Ptyxis. dconf 기본값 `[org/gnome/Ptyxis]`: 다크·라이트를 셸 선택대로(`interface-style='system'`), 지난 창 복원 끄기, 100×28. foot은 대체용으로 남기고 런처에서는 숨겨요. 패키지 목록(설치본, 라이브)에 ptyxis. 부팅 테스트의 최소화 장면은 `org.gnome.Ptyxis`로
- 남은 것: 묶음 검증. RobinOS zinc 팔레트(Ptyxis 기본은 GNOME 팔레트), 이미 설치한 시스템에 ptyxis 깔기(`robinos` 패키지 의존성 또는 `robinctl update` 안내)
- ChatGPT 두 번째 검토(2026-10-12) 반영: Ptyxis가 깔려 있는데 바로 실패하면(5초 안) foot으로. 남은 것: 파일 관리자(Nautilus)의 "터미널에서 열기"(지금은 없음. Nautilus 47 이후의 `xdg-terminal-exec` 또는 확장), RobinOS zinc 팔레트(`.palette`의 [Light]/[Dark], 프로필 UUID 처리), 한글 2칸 폭과 상자 그리기 문자(│├└─) 정렬, 닫기 확인 창이 실행 중인 작업에만 뜨는지
- 한글 폭(2026-10-12): Ptyxis에서 한글 음절 사이가 벌어져요(한글 두 칸 = 1.2em인데 Noto Sans Mono CJK KR의 한글은 1.0em). fontconfig matrix로 가로세로 1.16배는 틈이 없어졌지만 한국어 환경에서 줄 높이가 22→28px로 커져 28줄 창이 900px 화면을 넘었고, 가로로만 1.16배는 VTE에 효과가 없었어요. 규칙은 뺐어요. 남은 후보: 한글과 영문 폭이 맞는 고정폭 글꼴로 터미널 글꼴 자체를 바꾸기, 기본 줄 수를 줄이고 가로세로 확대를 다시 쓰기

### T-172 노트북 전원: 잠자기, 자동 절전, 덮개, 배터리가 거의 다 됐을 때
- 상태: 완료 (2026-11-24 T-176 정리: 완료 기준의 부팅 테스트 판정(`power-changed`, `power-default`)이 묶음마다 PASS. 실제 노트북의 덮개·깨우기는 T-167, 덮개 안내와 최대 절전은 [unfinished.md](unfinished.md) 4번 표)
- 한 것(2026-10-14): ① 빠른 설정 전원 메뉴와 런처에 "잠자기"(`systemctl suspend`, 잠그는 건 hypridle `before_sleep_cmd`) ② 노트북이 배터리로 돌 때 15분 쉬면 `robinos-idle-suspend`가 잠재움(충전기·USB-C 충전, 배터리 없는 PC, 마우스 배터리는 안 잠들어요; 단위 테스트 7경우) ③ 배터리가 거의 다 됐을 때 `CriticalPowerAction=PowerOff`(`robinos.install`이 설치·업데이트 때 UPower 설정을 바꿔요; UPower 기본값 HybridSleep은 디스크 스왑이 필요한데 RobinOS는 zram뿐) ④ 덮개는 logind 기본값(잠들고, 독에서는 그대로). 설치 테스트가 UPower 설정과 idle 스크립트를 확인
- 설정 앱 "전원"(2026-10-14, 부팅 테스트 판정 통과): 화면 잠그기·화면 끄기·배터리로 쓸 때 잠자기 시간을 고르는 선택 단추 줄. `ShellState.setPower`가 `~/.local/state/robinos/power`에 저장하고 `desktop/bin/robinos-idle-config apply`가 hypridle 설정을 다시 써서 hypridle을 새로 띄워요(로그인 때는 `robinos-idle-config start`). 시험: `test-robinctl.sh`의 정책 10개(기본값이 `desktop/hypr/hypridle.conf`와 같은지, "안 함"은 듣는 곳이 없는지, 이상한 값·앞자리 0), 부팅 테스트 `power-changed`·`power-default` 판정(정책 파일의 시간, hypridle이 그 파일로 도는지, 저장 파일)과 `light-settings-power` 장면
- 코드 검토(2026-10-15)에서 남긴 것: 충전 중에 15분이 지나고 그 뒤 전원을 뽑으면 다시 입력이 있을 때까지 잠들지 않아요(hypridle의 시간 초과는 쉬는 동안 한 번만 불려요. 스크립트가 전원이 빠지기를 기다리고 `on-resume`에서 끝내는 안), `robinos-idle-config apply`를 거의 동시에 두 번 하면 임시 파일이 부딪쳐 hypridle을 다시 띄우지 않을 수 있어요(`flock`과 `mktemp`)
- 남은 것: 덮개 닫기 동작(관리자 권한이 필요한 logind 설정이라 화면에서 바꾸지 않고 안내만), 최대 절전(디스크 스왑이 필요해 설치기와 같이 결정), 실제 노트북에서 덮개 닫았다 열기(T-167)
- 이전 상태: 할 일
- 출처: 미완성 기능 점검(2026-10-13, [unfinished.md](unfinished.md) 1·4번 표). 전원 메뉴는 로그아웃·재시작·끄기뿐이고, `hypridle.conf`는 5분에 잠그고 10분에 화면만 꺼요(시스템은 안 잠들어요). 덮개 닫기 동작과 최대 절전도 정한 게 없어요
- 할 것: 전원 메뉴에 "잠자기", `hypridle`에 자동 잠자기(전원 연결 여부로 시간을 다르게), 덮개 닫기(`logind`: 전원 연결·배터리 따로, 외부 모니터가 있으면 그대로 켜 두기), 배터리가 거의 다 됐을 때 UPower가 무엇을 하는지 정하고 설정(`CriticalPowerAction`; 스왑이 zram뿐이라 최대 절전은 안 돼요. 최대 절전은 디스크 스왑이 필요해 설치기와 같이 결정), 설정 앱에 "전원" 쪽(화면 꺼짐·절전 시간, 덮개)
- 완료 기준: 부팅 테스트에서 전원 메뉴의 잠자기 단추와 `hypridle` 설정이 맞고(VM은 잠자기를 못 깨울 수 있어 설정 검사로), 실제 노트북에서 덮개를 닫았다 열면 돌아와요(사용자 실기기)

### T-173 설정 앱 나머지: 터치패드, 사용자 계정, 기본 앱
- 상태: 완료 (2026-11-24 T-176 정리: 마우스와 터치패드·키보드·기본 앱 쪽이 묶음 검증 통과. 사용자 계정과 디스플레이는 T-149의 남은 것으로, 실제 터치패드는 T-167)
- 한 것(2026-10-14): 설정 앱에 "마우스와 터치패드"(탭해서 클릭, 스크롤 방향, 글 쓰는 동안 끄기, 휠 방향, 포인터 속도)와 "키보드"(한/영 단축키, 키 반복 빠르기·시작 시간, 눌러 보는 칸). `ShellState.setInput`이 `~/.local/state/robinos/input`에 저장하고 `hyprctl eval robinos.applyInput`으로 바로 적용해요. `robinos.lua`가 로그인 때 같은 함수로 읽어요. 시험: `scripts/test-hypr-input.lua`(Hyprland 대역으로 파일 읽기·범위·false 유지 6개, `check-desktop.sh`가 돌려요), 부팅 테스트 `input-changed`·`input-default` 판정(`hyprctl getoption`과 저장 파일), `light-settings-pointer`·`light-settings-keyboard` 장면. 알게 된 것: Lua 설정의 터치패드 옵션 이름은 `tap_to_click`(밑줄)이고 `tap-to-click`은 구문 오류예요(`--verify-config`가 잡았어요)
- 기본 앱(2026-10-14): 설정 앱 "기본 앱" 쪽. `desktop/bin/robinos-default-apps`(파이썬)가 설치된 앱의 `.desktop`(Flatpak 포함)에서 종류별로 열 수 있는 앱을 모아 `list`로 JSON을 주고, `set 종류 앱`이 그 종류의 모든 형식에 `xdg-mime default`를 해요. 종류: 웹 브라우저, 이메일, 사진, 동영상, 음악, PDF, 글 파일. 시험: `scripts/test-default-apps.py`(가짜 앱 폴더와 가짜 `xdg-mime`으로 18개, `check-desktop.sh`가 돌려요), 부팅 테스트 `default-apps` 판정(Firefox가 기본 브라우저, 고른 값이 `~/.config/mimeapps.list`에, 열 수 없는 앱은 거절)과 `light-settings-apps`·`light-settings-apps-open` 장면
- 남은 것: 실제 노트북 터치패드에서 값이 장치에 닿는지(`hl.config`로 바꾼 값이 이미 연결된 장치에 바로 적용되는지는 VM에서 못 봐요), 사용자 계정, 디스플레이(해상도·여러 모니터)
- 출처: 미완성 기능 점검(2026-10-13). 설정 앱은 개인 설정·소리·와이파이·블루투스·정보뿐이에요
- 할 것: "터치패드"(탭 클릭, 스크롤 방향, 속도; `input.touchpad`를 사용자 설정 파일에 저장), "사용자"(비밀번호 바꾸기는 터미널 `passwd`로 안내, 계정 추가는 관리자 확인 뒤), "기본 앱"(브라우저·메일·사진·동영상·PDF를 `xdg-mime`으로). T-149의 디스플레이·날짜와 시간·키보드와 같은 틀을 써요
- 완료 기준: 세 쪽이 키보드만으로도 동작하고, 바꾼 값이 다시 로그인해도 유지돼요

### T-175 프로젝트가 멈추면 (탈출 경로)
- 상태: 완료 (2026-11-24 T-176 정리: exit.md와 설치 테스트 `check_exit_path`가 묶음마다 통과. 서버가 사라진 상황 전체를 VM에서 해 보기와 이어 갈 사람의 열쇠 안내는 T-011 후보로)
- 출처: 비슷한 OS 사례 조사(2026-10-13, [references.md](references.md)): Antergos는 2019년에 스스로 끝내면서 사용자가 순수 Arch로 가는 길을 열어 두었고 두 달 뒤 EndeavourOS가 이어받았어요. 작은 배포판이 닫는 흔한 이유는 번아웃과 수익 부족이에요
- 한 것: [exit.md](exit.md)(RobinOS가 얹은 것, 멈췄을 때, 그만 쓰고 싶을 때, 확인한 것과 못 한 것), 설치 테스트 `check_exit_path`(`[robinos]` 블록을 뺀 설정으로 `pacman -Sy`와 `-Su --print`가 되는지, `robinos`가 저장소에 없는 패키지로 남는지, 다른 패키지가 기대지 않아 지울 수 있는지)
- 남은 것: 서버가 실제로 사라진 상황과 `robinos`를 지운 뒤 다른 데스크톱으로 가는 전 과정을 VM에서 해 보기. 이어 갈 사람을 위한 서명 열쇠 새로 만들기 안내(release.md)

### T-174 업데이트 이어 붙이기 (화면, 새 파일 적용, 진짜 업데이트 시험)
- 상태: 완료 (2026-11-24 T-176 정리: 완료 기준인 설치 테스트의 진짜 `robinctl update --yes`가 묶음마다 통과. 진행 화면, 펌웨어 점, 실패 안내, 커널 업데이트 시험은 [unfinished.md](unfinished.md) 7번 표, 실기기는 T-167)
- 출처: 사용자(2026-10-14) "알아서 해줘". 미완성 점검(2026-10-13)에서 업데이트가 터미널 명령까지만 되고 화면이 얇다고 나왔어요
- 한 것(2026-10-14): ① `robinctl update --status`(JSON 한 줄: 상태, 개수, 받을 크기, 커널, 데이터 요금, 다음 스냅샷 번호, 앱 스토어 업데이트 수, robinos 버전). 미리보기와 같은 계산을 `update_facts`로 모았어요 ② 설정 앱의 "업데이트" 쪽(개수·크기·커널·요금 안내, 지금 업데이트, 다시 확인, 스냅샷 안내, RobinOS 파일 버전) ③ `robinctl update`가 robinos 패키지가 새 버전이 되면 사용자의 셸을 끝내서 `robinos-shell`이 새 파일로 다시 띄우게 해요(sudo 없이 root로 돌면 다시 로그인하라고 안내, 패키지 스크립트도 같은 말) ④ 바의 업데이트 점이 앱 스토어(Flathub) 앱도 세요 ⑤ `--yes`(pacman --noconfirm, flatpak -y), 모르는 옵션은 오류 ⑥ 스냅샷 번호는 root만 알아서, 아니면 번호 없이 말해요(전에는 "1번"이라고 잘못 말했어요) ⑦ 설치 창 높이를 740으로(파티션 목록이 길어도 "설치하면" 막대가 보이게)
- 테스트: `test-robinctl.sh`(상태 JSON 네 경우, 셸 다시 띄우기 세 경우, --yes), 부팅 테스트 `light-settings-update`(라이브는 업데이트하지 않는다고 말해요), 설치 테스트가 설치된 시스템에서 진짜 `robinctl update --yes`를 돌려요: 로컬 저장소(`/srv/robinos-test-repo`)에 설치된 패키지를 높은 버전으로 다시 묶어 올려 놓고, `--status`가 "updates"인지, 업데이트 뒤 버전과 새 파일, `pacman -Syu` 앞의 스냅샷, os-release를 확인하고 pacman.conf를 되돌려요
- 남은 것: 업데이트하는 동안의 진행을 화면에서(지금은 터미널), 펌웨어(fwupd) 업데이트 점, 실패·디스크 부족 안내, 커널이 바뀌는 업데이트 시험, 업데이트 저장소(`repo` 릴리스)를 새 버전으로 올리는 일(사용자 확인 필요에 적어 둬요)
- 검증에서 잡은 것: pacman이 패키지의 파일 목록을 `.MTREE`에서 만들어서 시험이 끼워 넣은 새 파일이 설치 때 건너뛰어졌어요(시험을 기존 파일 수정으로 바꿈), 시험이 저장소를 바꿨다 되돌린 뒤 서명 없는 데이터베이스가 남아 다음 `pacman -S`가 막혔어요(되돌린 뒤 `pacman -Sy`)
- 완료 기준: `verify`와 `install-test`의 업데이트 확인 통과(됨), 실기기에서 한 번 해 보기

### T-171 설치기 다듬기 (빠진 것과 버그)
- 상태: 완료 (2026-11-24 T-176 정리: 완료 기준인 `verify`와 `install-test -Installer windows` 통과. 남은 것은 [unfinished.md](unfinished.md) 2번 표)
- 출처: 사용자(2026-10-13) "부족한 거 많은데 설치기도 제대로 다 안 만들어져 있고", "우리 아직 arch 브랜딩 남은 거 있던데"(실기기에서 USB를 꽂은 뒤 본 폴더 이름)
- 찾은 버그: ① 진행률이 패키지 설치 내내 12%에 멈췄다가 72%로 뛰었어요(설치 테스트의 `@@` 줄로 확인). 설치기가 `(3/987) installing`을 기다렸는데, pacman은 터미널이 아니면(파이프) 그 숫자 없이 `installing 이름...`이라고만 해요. 내려받기는 ` 이름 downloading...`. 라이브가 한국어라 pacman 글도 한국어가 될 수 있어서 `LC_ALL=C.UTF-8`로 영어로 고정. 처음엔 한국어 탓으로 짐작하고 고쳤다가 설치 테스트(`@@ 43~69` 줄 확인)에서 틀린 걸 알았어요 ② 화면에서 BitLocker 복구 키 확인에 체크해도 계획에 `bitlocker_key_saved`가 빠져서, BitLocker 디스크에 화면으로 윈도우 옆 설치를 하면 늘 오류였어요 ③ 윈도우 옆에 설치하다 멈추면 만든 파티션이 빈 공간을 다 차지해서 다시 할 수 없었어요 ④ ISO의 EFI 파티션 이름이 `ARCHISO_EFI`(mkarchiso가 정해요)라 윈도우 탐색기에 그대로 보였어요 ⑤ 설치본의 텍스트 콘솔 로그인 화면이 "Arch Linux"
- 한 것(2026-10-13): pacstrap은 `LC_ALL=C.UTF-8`로, 진행률은 내려받기 12~42%·설치 42~70%(`PacmanProgress`가 `Packages (N)`의 N으로 두 줄을 센다). 계획에 `bitlocker_key_saved`. 이전 RobinOS 파티션(GPT 이름 `RobinOS`, 리눅스 파일 시스템 형식)을 `disks`가 `robinos`로 알려 주고, 계획의 `replace`로 그 자리에 다시 설치(재설치도 같아요). 다른 고정 디스크의 윈도우(EFI 파티션 + NTFS)도 부팅 메뉴와 지역 시간 시계에. 시간대 검사에 경로 글자 제한. 설치 화면: 인터넷이 없으면 다음으로 못 넘어가요, 노트북이 배터리로 돌면 경고, 디스크의 지금·설치한 뒤 모습을 파티션 막대로, 시간대 고르기(자주 쓰는 도시 + `timedatectl list-timezones` 검색), 확인 단계에 부팅 메뉴·시간대·언어와 이전 파티션 지움 확인, 설치하는 동안 RobinOS 요령 카드(명령 기록은 "설치 기록 보기"), 실패하면 기록을 바로 보여 줘요. `build-iso.sh`가 mkarchiso 사본으로 EFI 파티션 이름을 `ROBINOS_EFI`로 하고 빌드 끝에 확인. `post-install.sh`가 `/etc/issue`를 RobinOS로. 압축 스왑 zram(`zram-generator`, 메모리 절반 최대 8GB, 라이브와 설치본)
- 파티션 고르기와 크기 정하기(2026-10-13, 사용자 "1번이랑 2번 같이 해줘"): 설치 방식이 셋이 됐어요. ① 빈 공간에 설치: RobinOS에 줄 크기를 40GB부터 빈 공간 전부까지 슬라이더로(`size_gb`; 1GB 미만이 남으면 끝까지) ② 만들어 둔 파티션에 설치(`mode: "partition"`, `partition`): 윈도우 디스크 관리에서 만든 NTFS 파티션이나 이전 RobinOS 파티션을 골라요. 윈도우가 들어 있는 파티션(읽기 전용으로 마운트해 `Windows\System32` 확인), EFI·복구·예약, BitLocker, 쓰는 중, 40GB 미만, 스왑·LUKS·LVM은 이유와 함께 흐리게 보이고 백엔드도 설치 직전에 다시 막아요. 고른 파티션은 이름 RobinOS, 형식 리눅스 파일 시스템으로 바꿔 다음 설치가 알아봐요. ③ 디스크 전체 사용. 예전 `replace`는 `partition`으로 받아 줘요. 확인 단계에 지워질 파티션을 이름과 크기로 적어서 체크하게 해요. 설치 테스트 windows: 크기(41GB)를 실제 sgdisk로 만들어 보고, NTFS 데이터 파티션을 만들어 목록에 나오는지·C:는 안 나오는지 보고, 화면 스크린샷(`installer-partitions`), 그 파티션에 설치한 뒤 윈도우 파티션이 그대로인지
- Codex 검토(2026-10-13, 파티션을 지우는 코드라 읽기 전용으로 맡김): 치명 넷과 중요 둘, 사소 하나가 맞아서 고쳤어요. ① 윈도우 판별이 대소문자 철자에 따라 놓칠 수 있었고 알 수 없는 형식(LDM, 손상된 NTFS)은 검사 없이 통과했어요 → 폴더 이름을 대소문자 없이 비교(`windows_in_tree`: Windows/System32, WINNT, bootmgr, Recovery, $WINDOWS.~BT), 형식은 허용 목록(btrfs·ext·xfs·f2fs·exfat·vfat·ntfs)만, 형식이 없는 파티션은 안이 비었을 때만 ② "쓰는 중"이 파티션 자신의 마운트만 봐서 그 위에 올라간 암호화·LVM 장치를 놓쳤어요 → 자식 장치와 sysfs holders도 봐요 ③ 화면에서 확인한 디스크가 설치 직전에 다른 디스크로 바뀌어도 이름만 같으면 지웠어요 → 계획에 디스크 id(크기+시리얼+WWN)와 파티션 PARTUUID를 넣어 설치 직전에 같은지 확인 ④ 라이브 USB를 한 단계만 따라가서 Ventoy(`/dev/mapper/ventoy`)로 켠 USB 자체가 설치 대상에 보였어요(이전부터 있던 문제) → 디스크가 나올 때까지 올라가요 ⑤ OEM 복구 파티션 → GPT 속성(숨김·읽기 전용·필수)이 있으면 막아요 ⑥ 다른 디스크의 BitLocker 윈도우는 복구 키 확인 대상이 아니었어요 → 남는 디스크 어디든 BitLocker면 모든 방식에서 확인 ⑦ VM 테스트가 화면의 안전 흐름을 안 지나갔어요 → `qs ipc call shell installerState`(비밀번호 없는 상태 JSON)로 키보드로 몰아서 확인 단계에서 지울 파티션을 체크하기 전에는 못 가고 체크하면 갈 수 있는지 확인(`drive_installer`) ⑧ 계획의 타입 검사. 이것들은 모두 단위 테스트로 막혀 있어요(87개)
- 검증(2026-10-13): `verify -Installer windows` 통과(부팅 88장면·판정 15개 PASS, 설치 5단계 통과, 화면 스크린샷 확인), 디스크 전체 설치(`-Installer robinos`)도 같은 백엔드로 5단계 통과. VM 테스트가 잡은 버그 둘: 설치 진행률이 12%에 머물던 것(pacman이 파이프에서는 `installing 이름...`만 말해요), 윈도우 디스크 관리가 만든 NTFS 파티션에 설치하면 `btrfs subvolume create`가 실패하던 것(예전 NTFS 흔적을 `wipefs`로 지우고 `mount -t btrfs`로 지정). 남은 것: 파티션 목록이 길면 "설치하면" 막대가 아래로 밀려 스크롤해야 해요(설치 창 높이를 키우기), 실제 윈도우 PC에서는 아직 해 보지 않았어요
- 테스트: `test-robin-install.py`(진행률, 디스크 그림, 이전 파티션 다시 쓰기와 거절, 다른 디스크의 윈도우, 시간대 경로), 설치 테스트(진행률 43~69% 줄, `/etc/issue`, zram, windows 모드는 멈춘 설치의 파티션을 만든 뒤 `replace`로 설치), 부팅 테스트 `installer-user`, `installer-timezone` 장면
- 남은 것: 별도 `/home`·수동 파티션 전체, 설치기 안에서 윈도우 C: 줄이기(ntfsresize, BitLocker·빠른 시작이면 막기), 디스크 암호화(T-163), 언어 고르기, (설치 화면이 끝까지 설치하는 것은 2026-10-14에 윈도우 설치 테스트에 넣어 통과했어요: 진행 막대 2%에서 100%), 비밀번호 강도(2026-10-14: 짧거나 사용자 이름과 같으면 안내만 보여 줘요. 막지는 않아요), 재설치할 때 `/home` 지키기, 설치 중 전원이 꺼졌을 때 시험. 전체 목록은 [unfinished.md](unfinished.md)
- 코드 검토(2026-10-15 클라우드 세션)에서 고친 것: ① 윈도우 옆 설치가 `grub-install` 뒤(설치 후 설정 중 인터넷이 끊기는 등)에서 멈추면 펌웨어가 GRUB를 먼저 켜는데 메뉴에 윈도우가 없었어요 → 멈출 때도 `grub_mkconfig_with_udev`로 윈도우를 넣어요 ② `games`, `video`, `http`, `nobody` 같은 시스템 이름은 패키지를 다 받은 72%에서야 `useradd`가 실패했어요 → 시작할 때 거절(라이브의 id 1000 미만 계정·그룹) ③ 비밀번호의 줄바꿈이 `chpasswd`에 다른 계정 줄로 들어갔어요 → 제어 문자 거절 ④ 디스크 전체 설치가 쓰는 중인 디스크(마운트, 스왑, 열린 암호화)를 지우다 `partprobe`에서 멈췄어요 → 지우기 전에 거절. 실패 메시지가 `arch-chroot` 대신 안의 명령 이름을 말해요. 시험 20개
- 코드 검토에서 남긴 것: 파티션 표가 없는 디스크(디스크 전체가 NTFS·ext4·LVM·LUKS)가 그림에 빈 공간으로 보여요, 같은 디스크의 exFAT·FAT 데이터 파티션만으로도 `dual_boot`가 켜져요(시계가 지역 시간, os-prober), 내 파일이 든 NTFS 데이터 파티션도 "만들어 둔 파티션"으로 고를 수 있어요(지우기 확인은 받아요), `RobinOS` 이름의 파티션은 형식 검사를 건너뛰어요(LUKS·LVM), `copytoram`이나 파일로 부팅하면 라이브 USB 디스크를 목록에서 못 빼요, 화면(`Installer.qml`)의 사용자 이름 검사는 시스템 이름을 몰라요(백엔드가 시작할 때 거절해요)
- 완료 기준: `verify`와 `install-test -Installer windows` 통과, 설치 화면 스크린샷 확인

### T-170 랜딩 페이지와 GitHub Pages
- 상태: 완료 (2026-11-24 T-176 정리: 페이지가 열리고 휴대폰 폭에서도 넘치지 않아요. 새 화면 사진과 영상은 T-180 ②(v0.4 때), "미리 보기" 안내는 실기기 확인(T-167) 뒤)
- 출처: 사용자(2026-10-13) "우리 OS 랜딩페이지도 만들어줘 그리고 웹사이트도 깃허브 이용해서 무료로 만들 수 있지 않아?"
- 한 것(2026-10-13): `site/`에 한 장짜리 랜딩 페이지(약속 "RobinOS로 시작하는 첫 리눅스", 윈도우 이름 표, 터미널 힌트가 타이핑되는 데모, 미션, 스냅샷 되돌리기, 매일 쓰는 기능, 써 보는 순서, "지금은 미리 보기" 안내). 글꼴은 Geist·Pretendard, 색은 brand.md. 움직임 줄이기를 켜면 움직이지 않아요. `scripts/publish-site.sh`가 `site/`를 `gh-pages` 브랜치로 올려요(GitHub Actions 없이 Pages의 "브랜치에서 배포")
- 공개(2026-10-13, 사용자 "웹사이트 공개해 줘"): `gh-pages` 브랜치를 올리자 GitHub가 Pages를 저절로 켰어요(브랜치에서 배포, legacy 빌드). README에 주소
- 다시 만들기(2026-10-13, 사용자 "taste-skill 이용해서 랜딩페이지 만들어"): taste-skill 기준으로 점검해 고쳤어요. 왼쪽 글·오른쪽 실제 화면의 첫 화면, 크기가 다른 네 칸(실제 스크린샷), div로 그린 가짜 터미널 대신 `hints.json`으로 실제 힌트를 돌려주는 입력 칸, 부팅 메뉴의 실제 스냅샷 목록, 겹친 설정 화면, 라이트·다크, 글꼴 직접 올리기(Pretendard는 쓰인 글자만 남겨 1MB→120KB), 사진은 WebP(합쳐서 170KB), 404 페이지, 본문 건너뛰기
- 더 화려하게(2026-10-13, 사용자 "더 예쁘고 화려하게"): 다이얼을 변화 8, 움직임 8로. 제목이 줄마다 떠오르고, 실제 데스크톱이 뒤로 기울어져 있다가 스크롤하면 펴지고(CSS 스크롤 타임라인), 마우스를 따라 살짝 기울어요. 뒤에는 빨강·주황 빛이 천천히 움직여요. 윈도우 이름 → RobinOS 이름이 두 줄로 흐르는 띠, 마우스를 따라 테두리가 빛나는 칸, 터미널은 명령을 타이핑하고 답을 한 줄씩, 되돌리기는 화면이 고정된 채 설치 테스트의 실제 부팅 메뉴 세 장이 단계마다 바뀌어요. 겹친 설정 화면은 스크롤에 따라 벌어지고, 마지막에 소개 영상의 빛의 고리와 내려받기. 움직임 줄이기면 모두 멈추고, 스크롤 이벤트는 쓰지 않아요(IntersectionObserver, 포인터 이벤트, CSS 스크롤 타임라인)
- ChatGPT 여섯 번째 검토(2026-10-13): 페이지가 소개하는 기능이 공개 ISO(v0.2, 10월 10일)에 없다는 지적이 가장 컸어요(v0.2 뒤 커밋 86개). 사용자가 "새 미리 보기 v0.3 공개"를 골랐어요. 페이지에는 첫 화면의 "설치 전에 알아 둘 것", 확인한 것과 아직 못 한 것 표, 자주 묻는 질문(윈도우가 지워지나요, 보안 부팅과 BitLocker, 카카오톡·HWP·은행·게임, 스냅샷과 내 파일, 사양, 다른 리눅스와 차이), 움직임 멈추기 단추(WCAG 2.2.2), 움직임 줄이기를 바로 따라가기, 칸의 빛도 움직임 줄이기를 지키기, 터미널은 다 쓴 답만 화면 읽기 프로그램에, main.js를 못 불러오면 내용을 보이기, 키 낮은 창에서는 되돌리기 장면을 고정하지 않기. 마우스 기울기는 스크롤 펴기와 겹쳐서 뺐고, 과하게 약속하던 문구("윈도우 옆에도 설치돼요", "대부분 드라이버 없이", "winget → pacman -S")를 고쳤어요. USB 없이 파티션으로 켜기는 페이지에서 빼고 install.md에만
- v0.3 프리뷰 공개(2026-10-13, 사용자 "새 미리 보기 v0.3 공개"): main `8698053`로 xz ISO 2,103,541,760바이트(한도까지 약 42MiB), 서명한 SHA256SUMS, https://github.com/Yoon-robin/RobinOS/releases/tag/v0.3.0 (프리릴리스). 업데이트 저장소 `repo`도 `robinos 0.3.0.r475`로 올리고 받아 설치 확인. 페이지의 내려받기는 이 태그로
- 설명 줄이기와 모션그래픽(2026-10-13, 사용자 "쓸데없는 설명 줄여주고 좀더 모션그래픽처럼"): 구역마다 제목 한 줄과 화면만 남기고 칸 설명·긴 답을 줄였어요. 제목 낱말이 흐림에서 하나씩 떠오르고, 화면은 위에서부터 열리고, 숫자 띠(학습 미션 45, 명령 힌트 75, 확인하는 화면 86)가 0부터 올라가요. 움직임 줄이기면 모두 그 자리에
- 애플처럼 단순하게(2026-10-13, 사용자 "너무 cringe인 설명이 너무 많아… 비주얼적으로만 This is RobinOS 이런 식으로, 애플처럼 심플하게"): 페이지를 다시 짰어요. 큰 "RobinOS"와 약속 한 줄, 내려받기, 기울어져 있다가 일어서는 환영 화면 → 옆으로 넘기는 실제 화면 여섯 장(캡션은 기능 이름만) → 터미널 힌트 세 줄(`ipconfig`→`ip a` 등, 윈도우 명령에 줄이 그어지고 리눅스 명령이 들어와요) → 학습 센터 → 다크와 라이트(고정된 빠른 설정이 스크롤에 따라 다크에서 라이트로) → 스냅샷 부팅 메뉴 → 끝의 이름과 내려받기. 흐르는 띠, 숫자 띠, 칸 설명, 자주 묻는 질문, 단계, 빛의 고리, 움직임 멈추기 단추(반복되는 움직임이 없어져서)를 뺐어요. "실제 PC에서는 아직 켜 보지 못했어요"와 릴리스 노트 링크는 끝에 남겼어요. `hints.json` 대신 `build-site.py`가 페이지의 명령 짝을 힌트 스크립트와 맞춰 봐요
- 개선(2026-10-13, 사용자 "개선점 더 찾아줘"): 게시된 페이지를 재 보니 첫 로드 267KB(글꼴 235KB), 레이아웃 흔들림 0, 링크 모두 열림. 고친 것: 푸터·상단 링크 높이를 24px 이상으로(WCAG 2.2), canonical·robots·sitemap·JSON-LD, 링크 미리 보기 그림에서 상단바 글자 빼기(`scripts/make-og.py`), 첫 화면의 둘째 링크를 "설치 안내"로, 끝에 "약 2GB · 64비트 UEFI PC", 휴대폰에서 줄 끝에 글자 하나 남는 것, 내려받기 릴리스 태그 확인(`publish-site.sh`). 남은 것: 첫 화면 그림이 어두워 눈길이 약함(앱 여러 개가 열린 장면이나 GPU 유리 질감, 짧은 화면 녹화), 영어 페이지, Firefox·Safari에서 스크롤 효과 확인
- 첫 화면 그림(2026-10-14, 사용자 "알아서 해줘"): 어둡던 환영 화면 대신 부팅 테스트의 `showcase` 장면(터미널에 `ipconfig`를 치면 `ip a` 힌트가 뜨고, 런처에 `taskmgr`를 치면 미션 센터가 나와요)으로 바꿨어요. 글꼴 부분 집합과 링크 미리 보기 그림(`og.jpg`)도 다시 만들어 `45f2f85`로 게시
- 할 것: 소개 영상 넣기, 스크린샷을 GPU로 켠 화면(유리·블러가 보이는)으로 바꾸기(T-152), 실제 PC 확인 뒤 "미리 보기" 안내 고치기
- 완료 기준: https://yoon-robin.github.io/RobinOS/ 가 열리고 휴대폰 폭에서도 가로로 넘치지 않아요

### T-169 평소 쓰다가 다음 리눅스 개념으로 (윈도우 습관에서 리눅스로)
- 상태: 완료 (2026-11-24 T-176 정리: 완료 기준인 부팅 테스트 `launcher-windows-mission` 장면과 힌트의 미션 번호가 있어요. 연결표를 한 곳으로 모으기와 미션을 끝낸 뒤 다음 일상 동작은 T-011 후보로)
- 출처: 컨셉 결정(2026-10-13, [design.md](design.md) "컨셉 결정"), ChatGPT 다섯 번째 검토: "미션이 45개라는 사실보다 평소 사용 중에 다음 리눅스 개념을 알게 되는지가 차별점. 미션이 별도 메뉴에만 있으면 약해요"
- 한 것(2026-10-13): 터미널 힌트 아래 "직접 해 보기: 학습 미션 N → robinctl learn show N"(윈도우 명령 30여 개, `__robinos_hint_mission`), 런처의 윈도우 이름(작업 관리자, 파일 탐색기, 명령 프롬프트, 네트워크, 저장소, 디스크 관리, 이벤트 뷰어, 서비스)에 "터미널: 명령"과 학습 미션 항목, 환영 마법사의 마지막 안내와 "리눅스 기초" 설명. 테스트: 미션이 붙은 명령마다 힌트가 있고 번호가 45개 안인지(`test-robinctl.sh`), 부팅 테스트 `launcher-windows-mission` 장면. 남은 것: 연결표를 한 곳으로 모으기(지금은 힌트 스크립트와 런처 두 곳), 미션을 끝냈을 때 다음 일상 동작 알려 주기
- 할 것: 처음 10~15분 안에 "윈도우 이름으로 찾기 → 리눅스 이름과 명령 → 그 개념의 미션"을 겪게 하기. 런처에서 윈도우 이름(작업 관리자, 서비스, 이벤트 뷰어 등)으로 찾으면 결과에 "터미널로는 `top`" 같은 명령과 해당 미션으로 가는 길, 터미널 힌트(`ipconfig` → `ip a`)가 나오면 관련 미션 번호, 환영 마법사 끝에서 첫 미션 세 개. 연결표는 한 곳(윈도우 이름 ↔ 리눅스 명령 ↔ 미션)에 두고 런처·힌트·학습 센터가 같이 써요
- 완료 기준: 부팅 테스트에서 "작업 관리자" 검색 결과에 명령과 미션이 보이고, `ipconfig` 힌트가 미션을 알려 줘요

### T-157 방화벽 켜기
- 상태: 완료 (2026-11-24 T-176 정리: 설치본에서 ufw 켜짐과 mDNS 규칙 확인. 웹 보안 랩과 함께 되는지는 [unfinished.md](unfinished.md) 7번 표, 방화벽 미션은 T-011 후보로)
- 한 것(2026-10-13 집 PC): ufw를 골랐어요(`ufw status`, `ufw allow 22`처럼 명령이 말에 가까워서 미션에서 설명하기 쉬워요). `packages/core.txt`에 `ufw`, `post-install.sh`가 `/etc/ufw/ufw.conf`의 `ENABLED=yes`와 `ufw.service`로 켜요(설치기 chroot에서 `ufw enable`을 하면 라이브 커널에 규칙이 들어가서요). 기본값이 들어오는 연결은 막고 나가는 연결은 그대로, ufw의 before.rules가 DHCP·ping·mDNS(프린터 찾기)를 열어 둬요. `robinctl audit`은 설치본에서 방화벽이 꺼져 있으면 경고(라이브는 괜찮다고). 설치 테스트에서 `ufw` 켜짐과 mDNS 규칙 확인
- 2026-10-13 묶음 검증 통과(설치본에서 ufw 켜짐, mDNS 규칙)
- 남은 것: 보안 기초 미션에 "방화벽 규칙 보기". 웹 보안 랩(Docker)이 그대로 되는지 실제로 띄워 보기
- 출처: 다른 OS와 비교(2026-10-12). Fedora는 firewalld가 켜져 있고, Mint는 환영 화면 체크리스트에서 방화벽을 켜게 해요. RobinOS는 방화벽이 꺼져 있는데 `robinctl audit`은 괜찮다고 해요
- 할 것: 들어오는 연결은 막고 나가는 연결은 그대로 두는 기본값(ufw나 firewalld 중 하나, 학습 미션에서 설명하기 쉬운 쪽). 프린터 찾기(mDNS)는 열어 두기. `robinctl audit`이 방화벽이 꺼져 있으면 알려 주기. 보안 기초 미션에 "방화벽 규칙 보기" 하나
- ChatGPT 네 번째 검토(2026-10-12): firewalld를 추천했어요(NetworkManager 연결마다 집/공공 구역, 공공 Wi-Fi에서는 mDNS도 막기). 지금은 설명하기 쉽고 이미 검증 중인 ufw로 두고, 연결마다 다른 규칙이 필요해지면 firewalld로 옮겨요. Docker 랩은 포트를 127.0.0.1에만 열어서 밖으로 새지 않아요
- 완료 기준: 설치 테스트에서 방화벽이 켜져 있고, 네트워크 프린터 찾기와 웹 보안 랩이 그대로 동작

### T-161 접근성: 확대, 큰 글씨, 고대비, 움직임 줄이기
- 상태: 완료 (2026-11-24 T-176 정리: 화면 확대·움직임 줄이기·앱 글자 크게가 설정에 있고 다시 켜도 유지돼요. 고대비와 셸 글자 크기는 T-185로 떼어 냈어요)
- 한 것(2026-10-13 집 PC): 화면 확대는 윈도우 돋보기와 같은 `Win+=`·`Win+-`·`Win+Esc`(Hyprland `cursor:zoom_factor`, 0.5배씩 1~5배), 설정 창의 "손쉬운 사용"에 "움직임 줄이기"(셸 애니메이션 시간 0, Hyprland 애니메이션 끔, GTK `enable-animations`)와 "앱 글자 크게"(GTK `text-scaling-factor` 1.25). 저장은 `appearance.json`이라 다시 켜도 유지. 부팅 테스트 `zoomed`·`unzoomed`
- 2026-10-13 묶음 검증 통과(확대 2배와 되돌리기). 움직임 줄이기·앱 글자 크게는 아직 VM에서 켜 보지 않음
- 남은 것: 고대비 색, 셸 자체의 글자 크기(지금은 화면 배율로), 움직임 줄이기·글자 크게를 부팅 테스트 장면으로
- 출처: 다른 OS와 비교(2026-10-12). GNOME 계열(Ubuntu, Fedora, Zorin)은 Orca, 화면 확대, 움직임 줄이기가 기본이에요. RobinOS는 투명도 줄이기만 있고 Orca는 막혀 있어요(T-040)
- 할 것: 설정 앱(T-149)에 "손쉬운 사용" 쪽. 화면 확대는 Hyprland `cursor:zoom_factor`로(단축키 Win+더하기/빼기), 글자 크기(셸과 GTK 배율), 고대비 색, 움직임 줄이기(Theme의 시간 값을 0으로)
- 완료 기준: 네 가지가 설정에서 켜지고 다시 켜도 유지돼요

### T-165 휴대폰 연결과 스캐너
- 상태: 완료 (2026-11-24 T-176 정리: 스캐너는 설치본에 들어갔어요. 휴대폰 연결은 T-186으로 떼어 냈어요)
- 한 것(2026-10-13 집 PC): 스캐너. `sane`, `sane-airscan`(드라이버 없이 네트워크·요즘 USB 스캐너), `simple-scan`을 `packages/apps.txt`에, 런처에서 "팩스 및 스캔"(윈도우 이름)으로 찾기, 설치 테스트에서 패키지와 데스크톱 파일 확인
- 2026-10-13 묶음 검증 통과(설치본에 스캔 패키지와 데스크톱 파일)
- 남은 것: 휴대폰 연결(KDE Connect와 LocalSend 중 고르기)
- 출처: 다른 OS와 비교(2026-10-12). Zorin Connect(알림, 문자, 파일), Mint Warpinator(아이폰 앱도 있음), 윈도우 "휴대폰과 연결". 스캐너는 대부분 기본으로 돼요
- 할 것: 휴대폰은 KDE Connect(크기 큼)와 LocalSend(Flathub, 아이폰도 됨) 중 고르기. 스캐너는 `sane`과 `simple-scan`을 `packages/apps.txt`에 넣고 런처에서 "팩스 및 스캔"으로
- ChatGPT 네 번째 검토: 휴대폰은 LocalSend(Flathub)가 먼저, KDE Connect는 권한과 방화벽 규칙까지 생각해야 해서 나중
- 완료 기준: 고른 것을 설치본에 넣고 런처에서 열려요

### T-151 정체성 문구를 화면에
- 상태: 완료 (2026-11-24 T-176 정리: 화면 문구는 묶음 73에서 검증, README 스크린샷은 2026-11-24 새 화면으로 바꿈. 남은 소개 영상 다시 찍기는 T-180 ①로 옮겼어요)
- 출처: 설계 점검(2026-10-10) "정체성 문구". 2026-10-12에 목적을 "처음 쓰는 리눅스"로 정해서(design.md "목적 결정") 화면에 넣을 말이 생겼어요
- 한 것(2026-10-12): 로고 한 줄 소개와 SVG(푸시함), 환영 마법사 첫 화면. 사용자 요청("T-151 남은 화면 문구도 바꿔줘")으로 나머지도 바꿨어요: 로그인 화면(SDDM, 방패 아이콘 → 터미널 아이콘)과 잠금 화면(hyprlock)의 "허가받은 환경에서만 쓰는 보안 학습용 시스템이에요", 설치본 부팅 메뉴의 "Security Learning Workstation" → 한 줄 소개(Unifont라 한글이 나와야 해요)와 윤리 안내 줄 빼기, 라이브 부팅 메뉴·콘솔·ISO 이름 "RobinOS Security Learning Live" → "RobinOS Live"(영어로 둔 건 syslinux와 리눅스 콘솔이 한글을 못 그려서예요), 터미널 인사 "RobinOS 보안 학습 환경" → "RobinOS · 쓰다 보면 리눅스를 알게 되는 OS", `robinctl` 도움말의 "허가받은 환경에서 보안을 배우는 시스템이에요" 줄 빼기(실습 안내 줄은 그대로), 기본 배경화면 그림(`robinos-default.svg`)의 글, `config.toml`의 `purpose`(읽는 코드 없음)를 `learn-linux`로. 윤리 안내는 motd, 학습 센터, 랩, ethics.md에 그대로예요
- 한 줄 소개 다시(2026-10-12, 사용자: "쓰다 보면 리눅스를 알게 되는 OS 이거 살짝 cringe야" → "화면엔 이름만"): 부팅 메뉴(설치본 GRUB, 라이브 BIOS 스플래시), 로그인·잠금 화면, 기본 배경화면 그림, 터미널 인사에서 소개 줄을 빼고 이름만 뒀어요. 환영 마법사 첫 화면도 소개 문장을 뺐어요. 로고 아래와 README, 소개 영상 끝에만 "처음 쓰는 리눅스"를 써요(`work/batch74`)
- 남은 것: 묶음 검증(`verify -Installer robinos`)으로 확인하기. 특히 설치 테스트의 부팅 메뉴 스크린샷에서 한글 한 줄 소개가 네모로 깨지지 않는지. 통과하면 README 학습 센터 스크린샷("1 / 40")과 소개 영상의 부팅 메뉴·로그인 화면을 새 스크린샷으로 바꾸고, 영상에서 가린 부분을 없애기
- 완료 기준: 부팅 테스트의 SDDM·잠금 화면 장면, 설치 테스트의 부팅 메뉴 스크린샷, README 로고

### T-182 코드 검토에서 남은 것 (2026-11-24)
- 상태: 완료 (2026-11-24 묶음 검증에서 `default-apps` 판정과 `test-robin-install.py`의 exFAT 경우 통과. ①② 2026-11-24 새벽 고침: ① 디스크의 `windows`를 NTFS·BitLocker나 윈도우 예약·복구 파티션으로만 정해요. Basic data 형식만으로는 안 세요(시험: exFAT·FAT 공유 파티션). 설치 창의 `dualBoot`도 이 값을 써요)
- 출처: 다른 PC 코드를 합친 뒤의 코드 검토(품질 점검 기록 "코드 검토")
- 할 것: ① `robin-install`의 `dual_boot`: 디스크에 NTFS나 Basic data 형식 파티션이 하나라도 있으면 윈도우로 봐서, 윈도우 없이 exFAT 공유 파티션만 있는 디스크에도 `hwclock --localtime`과 os-prober가 켜져요. 이미 계산한 `windows_inside`(또는 BitLocker)로 정하고, partition 모드에서는 고른 파티션을 빼요. `Installer.qml`의 `dualBoot`도 같은 필드로 ② ~~설정 "기본 앱": 앞의 실행이 끝나기 전에 다시 고르면 두 번째가 버려져요~~ (2026-11-24 고침: 대기열 `pendingApps`, `onExited`에서 다음 것)
- 완료 기준: `test-robin-install.py`에 exFAT만 있는 디스크 경우, 부팅 테스트 `default-apps` 판정

### T-183 터미널의 한글 글자 사이가 벌어져요
- 상태: 완료 (2026-11-24 새벽 고침: `56-robinos-fonts.conf`에서 Noto Sans Mono CJK KR만 1.15배로 그려요. foot.ini는 같은 크기(`size=11`)로 바꿔 두 번 키우지 않아요. 묶음 검증 `31-terminal-learn.png`에서 한글이 붙어 보이고 영어는 Cascadia 그대로. 한국어 로캘에서는 VTE가 줄 높이를 한글로 재서 줄 간격도 1.15배쯤 넓어졌어요. 답답해 보이면 Ptyxis의 줄 간격(`cell-height-scale`)으로 줄여 볼 수 있어요)
- 출처: 2026-11-24 묶음 검증의 부팅 테스트 `31-terminal-learn.png`. 미션 안내가 "미 션 1 · 폴 더"처럼 한 글자씩 떨어져 보여요
- 까닭: 코드 글꼴 Cascadia Mono에는 한글이 없어서 fontconfig가 Noto Sans Mono CJK KR로 대신 그려요. 한글은 두 칸을 쓰는데, Cascadia 두 칸(1.2em)이 Noto 한글(1em)보다 넓어서 남는 자리가 생겨요
- 비교(VM 없이, WSL의 화면 없는 sway에서 VTE 창을 띄워 `grim`으로): 그대로는 벌어지고, 1.15배·1.2배는 붙어 보이고 잘리지 않아요. 1.15배를 골랐어요(라틴 글자처럼 옆 여백이 조금 남아요). foot는 원래 `size=12.5`로 키우고 있어서, 그대로 두면 두 번 커져 글자 위가 잘려요. Qt(셸)는 이 규칙을 안 따라서 셸 화면은 그대로예요
- 완료 기준: 부팅 테스트 터미널 장면(`31-terminal-learn.png`)에서 한글이 붙어 보이고, 영어 코드는 Cascadia 그대로

### T-155 부팅 테스트에 성공 조건 넣기
- 상태: 완료 (2026-11-24: 망가진 ISO에서 실패하는 것을 실제 회귀로 확인했어요. 묶음 검증에서 hypridle이 잠금을 물려받아 전원 선택이 안 먹던 ISO가 `power-changed`·`power-default` FAIL로 테스트 전체를 실패시켰고, 고친 뒤 통과)
- 출처: ChatGPT 세 번째 검토(2026-10-12). 묶음 77이 "통과"로 나왔는데 라이브 ISO에서 터미널이 하나도 안 열렸어요. 스크린샷만 찍는 테스트는 화면이 틀려도 통과해요
- 한 것(2026-10-12): 멈춘 시나리오는 실패(종료 코드 1, WHPX·TCG 실행기 둘 다), 터미널을 연 뒤 "활성 창이 Ptyxis"일 때만 남는 `logger` 표시를 시리얼 로그에서 확인(`expect_serial`), 안 열리면 tty3 진단, 키·포인터 QMP 명령이 오류로 답하면 실패(`Qmp.act`), `build-iso.sh`가 빌드한 airootfs의 `/usr/share/robinos/bin`과 `/usr/local/bin`이 모두 실행 가능한지 확인
- 한 것(2026-10-13 집 PC): `scripts/e2e-check.sh`(ISO의 `/opt/robinos/scripts`)가 장면마다 VM 안에서 상태를 확인해 `robinos-e2e: scenario=<이름> status=PASS|FAIL <근거>`를 저널에 남기고, `boot-test-qmp.py`의 `check_scene`이 시리얼 로그에서 결과를 모아 하나라도 실패면 끝에 실패. 장면: 터미널(Ptyxis), 미션 1, 최대화(`fullscreen` 1, 바 아래·독 위, 화면 70% 넘게)와 되돌리기, 새 터미널이 창 하나만 늘리기, 셸 다시 띄우기(새 `qs`와 IPC 응답), 라이트·다크(저장된 값과 GTK `color-scheme`). 가짜 hyprctl로 판정 시험. [testing.md](testing.md) "상태로 판정하는 장면"
- 2026-10-13 묶음 검증(`a2c513a`): 열 장면 모두 PASS(최대화 y=37·높이 792/900, 되돌린 높이 673, Ptyxis 1→2, 녹화 4초, 새 qs, 라이트·다크 저장값과 GTK)
- 한 것(2026-10-13 두 번째): 같은 장면을 여러 번 확인할 수 있게(`label`, 입력한 뒤의 시리얼 로그만 봐요), 학습 센터에서 연 미션 터미널(`mission-terminal`), 결과 줄의 색 코드 빼기
- 남은 것: 일부러 망가뜨린 ISO로 실패하는 것 확인
- 처음 할 것(기록): 장면마다 게스트 안에서 확인하고 통과했을 때만 `logger -t robinos-e2e "scenario=<이름> status=PASS"`를 남기기. 후보: 최대화(`hyprctl clients -j`의 fullscreen, at, size가 바·독 사이), 학습 미션 터미널의 출력, 테마 바꾸기(저장된 값과 GTK 설정), 셸 재시작(새 Quickshell과 IPC 응답), 새 터미널을 열 때 창이 하나만 늘어나는지. 결과를 장면별로 모아 하나라도 실패면 전체 실패
- 흔들림(2026-10-13): 셸을 다시 시작한 뒤 IPC `learnCenter`로 학습 센터를 열었는데 창이 안 떠서 `mission-terminal`, `dark`가 실패했어요(설치 테스트는 통과). 같은 HEAD로 부팅 테스트만 다시 돌리니 14장면 모두 통과했어요. 다시 나오면 열리기를 기다렸다가 다시 부르는 확인을 넣어요
- 다시 나옴(2026-10-15, 학교 PC의 올인원 검증): 이번엔 학습 센터는 떴는데 미션 줄을 누르고 4초 안에 Ptyxis가 안 떠서, 판정 명령이 학습 센터에 들어가고 그 뒤 판정 8개가 모두 `missing`이었어요(`80-learn-center-mission`에 터미널 없음). 설치 테스트 VM이 옆에서 도는 동안이라 느렸어요. 기다림을 10초로 늘렸어요(작업 브랜치). 그래도 나오면 판정 전에 Ptyxis 창이 늘었는지 QMP 쪽에서 기다리는 방법을 넣어요
- 원인(2026-10-16, 올인원 3차): 흔들림이 아니라 매번이었어요. 1차와 3차 모두 `79-light-learn-center`에 학습 센터가 아직 없고 `80`에서야 보여요. VM 두 대가 함께 돌아 느린 동안 학습 센터가 IPC 뒤 3초 안에 안 떠서, 미션 줄 클릭이 터미널에 떨어졌어요. 그 뒤 Alt+F4가 학습 센터를, 닫기 클릭이 터미널을 닫아 이후 판정 7개(`default-apps`부터 `report`까지)가 모두 `missing`이었어요. 이제 화면(QEMU PPM 스크린샷)에서 학습 센터의 빨간 아이콘이 보일 때까지 기다린 뒤 누르고(최대 60초), 미션 터미널이 안 열렸으면 학습 센터를 다시 열어 뒤 장면이 터미널을 닫지 않게 했어요(작업 브랜치)
- 완료 기준: 위 장면이 화면이 아니라 상태로 판정되고, 일부러 망가뜨린 ISO(실행 권한 빼기 등)에서 테스트가 실패하는 것을 한 번 확인

### T-156 설치본 펌웨어와 펌웨어 업데이트
- 상태: 완료 (2026-10-13 묶음 검증에서 설치본의 `pacman -Q sof-firmware fwupd` 확인. 실제 PC의 GNOME Software 펌웨어 목록은 실기기 확인 때 같이 봐요)
- 출처: 다른 OS와 비교(2026-10-12). `sof-firmware`, `linux-firmware-marvell`, `wireless-regdb`가 라이브 ISO(`archiso/packages.x86_64`)에만 있고 설치본 목록에는 없었어요. 라이브에서는 소리가 나던 요즘 인텔·AMD 노트북이 설치하고 나면 소리가 안 날 수 있어요. 펌웨어 업데이트(fwupd)는 Fedora, elementary, Ubuntu에 다 있는데 RobinOS에는 없었어요
- 한 것: 세 펌웨어를 `packages/core.txt`에, `fwupd`를 `packages/apps.txt`에 넣었어요. GNOME Software는 fwupd가 있으면 업데이트 목록에 펌웨어도 보여 줘요
- 완료 기준: 설치 테스트에서 설치본에 `pacman -Q sof-firmware fwupd`가 나오고, 실제 PC에서 GNOME Software 업데이트에 펌웨어가 보이는지 확인(실기기 확인은 사용자)

### T-158 개인 파일 백업
- 상태: 완료 (2026-10-13 묶음 검증. USB 디스크에 백업하고 되살리기는 실기기 확인 때 같이 봐요)
- 한 것(2026-10-12 집 PC): `deja-dup`을 `packages/apps.txt`에, 런처에서 "백업", "파일 히스토리", "Time Machine"으로 찾으면 Déjà Dup(윈도우의 파일 히스토리에 해당), [recovery.md](recovery.md) "스냅샷과 백업", 설치 테스트에서 `pacman -Q deja-dup`과 데스크톱 파일 확인
- 출처: 다른 OS와 비교(2026-10-12). 스냅샷은 시스템만 되돌리고 개인 파일은 지켜 주지 않아요. Mint는 백업 도구, GNOME 계열은 Déjà Dup, 윈도우는 "Windows 백업", macOS는 Time Machine이 있어요
- 할 것: Déjà Dup(`deja-dup`)을 `packages/apps.txt`에 넣고 런처에서 "백업", "파일 히스토리", "Time Machine"으로 찾게 하기. 환영 화면이나 [recovery.md](recovery.md)에 스냅샷과 백업의 차이를 한 줄로
- ChatGPT 네 번째 검토: 앱을 넣는 것으로 끝내지 말고 외장 디스크에 백업한 뒤 파일 하나를 지우고 되살리기까지 확인. 같은 디스크에만 백업하면 디스크 고장에는 소용없다고 안내
- 완료 기준: 설치본에서 런처로 백업 앱이 열리고, USB 디스크에 백업하고 파일 하나를 되살리는 것을 확인

### T-159 윈도우 프로그램(.exe)을 열면 안내
- 상태: 완료 (2026-11-24 T-176 정리: 완료 기준은 2026-10-13 묶음의 `windows-app` 장면, 그 뒤 묶음마다 PASS. 남은 것은 T-184로)
- 확장(2026-10-14, 사용자 "알아서 해줘"; 참고: Zorin이 240개 넘게 알아봐요, [references.md](references.md)): 알아보는 프로그램을 17개에서 55개로. 브라우저(Firefox·Edge·Brave·Opera), 메일(Thunderbird), 채팅과 협업(Slack·Signal·WhatsApp·Teams·Notion·Obsidian), 클라우드(Dropbox·OneDrive·Google Drive), Adobe 계열(GIMP·Krita·Inkscape·Kdenlive로), PDF, 사진 보기(알씨), 화면 녹화(반디캠 등 → RobinOS의 Win+Alt+R와 OBS), 토렌트, 게임 런처(Epic·GOG → Heroic, Battle.net → Lutris, Minecraft → Prism), 개발·원격 도구, Rufus(→ 디스크 앱), 백신(알약·V3 → 방화벽은 기본으로 켜져 있다고), 은행·공공기관 보안 프로그램(nProtect·TouchEn·Veraport 등 → 윈도우 전용이라 안 된다고 솔직히). Flathub ID는 모두 Flathub API로 있는지 확인했어요(TeamViewer만 ID가 달라 홈페이지 링크로). `check-desktop.sh`가 파일 이름 맞추기를 시험해요(Steam이 Teams로 잘못 잡히지 않는지, `cooperate_setup.exe`가 Opera로 잡히지 않는지 같은 경우 포함)
- 한 것(2026-10-13 집 PC): `.exe`·`.msi`·`.lnk`의 기본 앱을 `robinos-windows-app`(숨은 데스크톱 파일)으로, 이게 셸의 "윈도우 프로그램" 창(`WindowsApp.qml`)을 열어요. 파일 이름으로 알려진 프로그램 열일곱 가지(카카오톡, Chrome, 웨일, 한글, Office, 반디집·7-Zip, 곰플레이어·팟플레이어, Discord, Steam, VS Code, Zoom, Spotify, Telegram, OBS, Notepad++, Python, Git)를 알아보고 대신 쓸 것(RobinOS에 있는 앱, 앱 스토어의 Flathub 앱, 웹 버전)을 단추로. 모르는 파일은 "리눅스에서는 그대로 열리지 않아요"와 Bottles 설치 단추. 이름 표는 `windowsapps.js`, `check-desktop.sh`가 파일 이름 열여섯 개로 확인("DigitalClock.exe"가 Git으로 잡히지 않게 짧은 이름은 그대로만). 부팅 테스트 `windows-app` 장면과 상태 확인
- 2026-10-13 묶음 검증 통과(`windows-app` 장면). 제목의 조사("카카오톡는")를 "카카오톡 윈도우용 설치 파일이에요"로
- 남은 것: 학습 미션 쪽 설명(실행 파일 형식이 다른 이유), 설치본에서 Flathub 단추가 앱 스토어의 그 앱을 여는지
- 출처: 다른 OS와 비교(2026-10-12). Zorin은 `.exe`를 열면 170개 넘는 설치 파일을 알아보고 리눅스판, 웹 앱, Wine 중 무엇을 쓰면 되는지 알려 줘요. 처음 쓰는 사람이 가장 먼저 부딪히는 곳이에요
- 할 것: `.exe`·`.msi`의 기본 앱을 RobinOS 안내 창으로. 파일 이름으로 잘 알려진 프로그램(카카오톡, 크롬, 한글, 반디집, 곰플레이어 등)을 알아보고 대신 쓸 것(Flathub 앱, 웹 버전, 기본 앱)을 보여 주기. 모르는 파일이면 "리눅스에서는 바로 실행되지 않아요"와 Bottles(Flathub) 설치 단추. 학습 미션 쪽 설명(실행 파일 형식이 다른 이유)으로 이어지게
- ChatGPT 네 번째 검토의 안전 규칙: 파일을 열자마자 실행하지 않기, Wine·Bottles를 자동으로 설치하거나 관리자 권한으로 돌리지 않기, Bottles를 "안전한 상자"라고 하지 않기(호환 환경이지 격리가 아니에요), 파일 이름이 `KakaoTalk_Setup.exe`여도 진짜라는 보장이 없다고 쓰기, 공식 리눅스판이 있으면 그것부터, 대체 앱 목록에는 확인한 날짜, 모르는 파일은 "모르겠어요"라고. 첫 단계는 추천 목록보다 안내 창과 앱 스토어 연결
- 완료 기준: 부팅 테스트에서 `.exe`를 열면 안내 창이 뜨고 알려진 이름 하나는 대신 쓸 앱을 보여 줘요

### T-160 화면 녹화
- 상태: 완료 (2026-10-13 묶음 검증: `recorded` PASS, 4초 mp4, 바의 "녹화 중" 스크린샷)
- 한 것(2026-10-13 집 PC): `robinos-screenshot record`가 `wf-recorder`로 지금 화면을 `~/비디오/Screencasts/날짜.mp4`에 녹화하고, 한 번 더 부르면 멈추고 "열기·폴더 열기" 알림. `Win+Alt+R`(Hyprland), 런처 "화면 녹화"(윈도우 이름 "Xbox Game Bar"), 녹화 중에는 바에 빨간 점 "녹화 중"(누르면 멈춤, 셸 IPC `setRecording`). `wf-recorder`는 `packages/desktop.txt`와 라이브 목록에. 부팅 테스트 `recording` 장면과 `recorded` 상태 확인(1초 넘는 mp4)
- 나중에 할 수 있는 것: 소리 함께 녹화, 영역 녹화
- 출처: 다른 OS와 비교(2026-10-12). 윈도우(Win+Alt+R, 캡처 도구), macOS(Cmd+Shift+5), GNOME 기본 녹화가 있는데 RobinOS는 스크린샷만 있어요
- 할 것: `robinos-screenshot`에 녹화 추가(`wf-recorder`나 `gpu-screen-recorder`), 녹화 중에는 바에 빨간 점과 멈춤 단추, 파일은 `~/동영상`에. 단축키는 Win+Alt+R
- 완료 기준: 부팅 테스트에서 몇 초 녹화한 파일이 생기고 재생돼요

### T-162 업데이트 화면
- 상태: 완료 (2026-11-24 새벽: 설치 테스트가 `robinctl update` 출력에서 "업데이트 1개, 받을 크기 1MB"와 "업데이트 직전에 스냅샷 2번을 찍어요. 문제가 생기면: sudo robinctl snapshot rollback 2"를 확인해요(`5ba9256`, 다섯 단계 통과). 커널 줄은 커널 업데이트가 있을 때만이라 시험 대상에서 뺐어요)
- 한 것(2026-10-13 집 PC): `robinctl update`가 pacman을 부르기 전에 "업데이트 N개, 받을 크기 X MB", 커널이 바뀌면 "끝나면 다시 시작", "업데이트 직전에 스냅샷 N번을 찍어요(되돌리기 명령)"를 보여 줘요. 데이터 요금 연결(NetworkManager `Metered` 1·3)이면 알리고 받을지 물어요. 목록은 `checkupdates`의 임시 데이터베이스로 봐서, 여기서 멈춰도 시스템의 패키지 데이터베이스는 그대로예요(부분 업데이트 없음). `robinctl update --preview`(root 없이 미리 보기)와 가짜 checkupdates·pacman·busctl 테스트 여덟 개
- 2026-10-13 묶음 검증 통과(빠른 테스트만, VM에서 실제 업데이트는 아직). 2026-11-24 묶음 검증도 통과(`a7a1cb9`, 빠른 설정의 "끝나면 다시 시작")
- 한 것(2026-10-13 두 번째): 빠른 설정의 "업데이트 N개가 있어요"에 커널이 들어 있으면 " · 끝나면 다시 시작". 셸은 업데이트를 알림으로 띄우지 않고 바의 점만 보여 줘서 데이터 요금 연결에서 따로 막을 것은 없어요(`checkupdates`는 목록만 받아요)
- 남은 것: 설치 테스트에서 업데이트가 있을 때 미리 보기 세 줄 확인(완료 기준)
- 출처: 다른 OS와 비교(2026-10-12). Mint는 보안·커널 업데이트를 먼저 보여 주고, elementary는 받을 크기를 보여 주고 데이터 요금 연결에서는 받지 않아요. RobinOS는 업데이트 전에 스냅샷을 자동으로 찍어서(snap-pac) Omarchy와 같은 장점이 있는데 화면에서는 보이지 않아요
- 할 것: 업데이트 창에 받을 크기, 커널이 바뀌는지(다시 시작 필요), "업데이트 전에 스냅샷 N번을 찍어요". 데이터 요금 연결(NetworkManager metered)에서는 알림만
- ChatGPT 네 번째 검토: 오래 업데이트하지 않은 시스템, 디스크 공간 부족, 업데이트 실패 때 무엇을 하면 되는지(스냅샷 번호와 되돌리는 법)도 같은 화면에서
- 완료 기준: 부팅 테스트나 설치 테스트에서 업데이트 창의 세 줄이 맞게 나와요

### T-163 디스크 암호화 (조사)
- 상태: 완료 (2026-10-13 집 PC: [design.md](design.md) "디스크 암호화"에 방식을 정하고 T-178, T-179로 나눴어요. GRUB 2.16의 `luks2.mod`·`argon2.mod`를 WSL에서 확인)
- 출처: 다른 OS와 비교(2026-10-12). Ubuntu는 TPM 암호화와 복구 키, Pop!_OS는 기본으로 켜져 있고, Omarchy는 필수예요. 노트북을 잃어버리면 지금은 파일을 그대로 읽을 수 있어요
- 할 것: 설치 프로그램에 "디스크 암호화" 선택을 넣을 수 있는지 조사. GRUB이 LUKS2(argon2)를 못 여는 문제, grub-btrfs 스냅샷 부팅과 함께 쓰는 방법, 비밀번호 입력 화면(T-150 Plymouth), 복구 키를 사람에게 어떻게 보여 줄지
- ChatGPT 네 번째 검토: 실험 두 개를 별도 브랜치에서. A) GRUB + LUKS2(PBKDF2) + 암호화된 /boot: 지금의 grub-btrfs 스냅샷 부팅이 그대로 되는지. B) GRUB + 암호화하지 않은 /boot + LUKS2(Argon2id): 설치, 부팅, 라이브 USB에서 되돌리기. LUKS1은 새 설치 기본값으로 쓰지 않아요. 복구 키를 암호화 안 된 곳에 평문으로 두지 않기, 부팅 때 비밀번호 입력은 한글이 아니라 영문 배열이라는 것을 설치 때 알려 주기. systemd-boot + UKI는 보안 부팅과 함께 나중에
- 완료 기준: 방식 하나를 정해 [design.md](design.md)에 쓰고 구현 작업으로 나누기

### T-178 설치기에 디스크 암호화 선택
- 상태: 완료 (2026-11-24 집 PC: `install-test -Installer encrypted` 다섯 단계 통과)
- 한 것(2026-10-13 집 PC): 백엔드 `"encrypt": true` → `cryptsetup luksFormat`(LUKS2, argon2id, 메모리 256MiB, 사용자 비밀번호), Btrfs는 `/dev/mapper/cryptroot` 위에. initramfs 키 파일(`/etc/cryptsetup-keys.d/cryptroot.key`, 빠른 PBKDF), `encrypt` 훅, `GRUB_ENABLE_CRYPTODISK=y`와 `cryptdevice=`·`cryptkey=`. 복구 키(6자리 숫자 여덟 묶음)를 세 번째 키 슬롯에 넣고 `@@ recovery-key` 줄로 화면에만(로그 파일에는 안 남겨요). 설치기 화면: 사용자 단계에 "디스크 암호화" 스위치(설명: 잊으면 되살릴 수 없음), 확인 단계 요약, 끝 화면에 복구 키 상자. GRUB의 `luks2` 모듈이 `argon2`에 의존해서 같이 들어가요(moddep.lst 확인). 같이 고친 것: 화면이 계획에 `bitlocker_key_saved`를 안 보내던 것(T-147 때 패치 하나가 조용히 빠짐) → `test-robin-install.py`가 백엔드가 읽는 계획 항목을 화면이 모두 보내는지 확인
- 출처: T-163 조사([design.md](design.md) "디스크 암호화")
- 할 것: 설치기 확인 단계 앞에 "디스크 암호화" 선택(기본 꺼짐, 비밀번호를 잊으면 되살릴 수 없다는 설명), 백엔드가 LUKS2(argon2id, GRUB이 견딜 메모리 비용)로 Btrfs 파티션을 잠그고 `GRUB_ENABLE_CRYPTODISK=y`, initramfs에 키 파일과 `encrypt` 훅, `systemd-cryptenroll --recovery-key`로 복구 키를 만들어 마지막 화면에 보여 주기. `robinctl audit`의 "디스크 암호화" 줄은 그대로 동작
- 완료 기준: T-179의 설치 테스트 통과

### T-179 설치 테스트에 암호화 설치
- 상태: 완료 (2026-11-24 집 PC: 다섯 단계 통과. GRUB이 비밀번호 뒤 4~7초 만에 디스크를 열었어요(argon2id 256MiB, WHPX). 스냅샷 단계는 비밀번호 대신 복구 키로 열었어요)
- 한 것(2026-10-13): `install-test -Installer encrypted`(`wsl-build.ps1`, `install-test.sh`), GRUB 비밀번호는 QMP로(`wait_menu`), 두 번째 부팅은 복구 키로, 잠금 해제 시간 로그
- 나중에 볼 것: 비밀번호를 묻는 화면이 펌웨어 글자 위의 GRUB 영어 한 줄("Enter passphrase for hd0,gpt2 (UUID):")이에요. GRUB이 정한 문구라 바꿀 수 없어요. 한글 화면으로 물으려면 `/boot`를 암호화 밖에 두고 initramfs(Plymouth, T-150)에서 물어야 하는데, 그러면 스냅샷 부팅(grub-btrfs)이 커널을 스냅샷 안에서 못 읽어요. 키트 화면에 맞출지는 T-150과 같이 정해요
- 출처: T-163
- 할 것: `install-test.py`에 암호화 계획(`"encrypt": true`)으로 설치하고, GRUB 비밀번호 화면에 QMP로 비밀번호를 입력해 부팅, 스냅샷으로 부팅·되돌리기까지 지금처럼 확인. 복구 키로도 한 번 열기. GRUB의 argon2 잠금 해제 시간 재기
- 완료 기준: 다섯 단계 통과, 잠금 해제 시간 기록

## 완료

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
- 2026-10-16 작업 브랜치 `claude/eoseohae-7nleia`를 main에 합침(`dc373ec`, 학교 PC 올인원 4차: 빠른 검사 0.8분, verify 25.3분, 설치 테스트 다섯 단계 통과, 부팅 테스트 96장·판정 20개 PASS)
  - 설치기 코드 검토 고침(`51d9fc3`), robinctl·데스크톱 스크립트 코드 검토 고침(`c2878a0`, `fd57e55`), 깃허브가 안 될 때 Arch 업데이트(T-177 ①), 부족한 점을 [unfinished.md](unfinished.md) 한 곳으로, VMware 확인 목록
  - 처음 쓰는 PC용 `scripts/verify-all-in-one.ps1`과 1~3차가 찾은 것: UPower 기본값 `Auto`, 기본 앱 시험, 빠른 검사가 키 입력을 기다리며 몇 시간 멈춤(`robinctl update --preview`), 창에 출력이 안 나오던 것, `scripts/check.sh`, 두 단계 업데이트의 snap-pac 판정, QMP 2분 제한, 학습 센터가 뜰 때까지 기다리기
- 2026-10-10 묶음 64 검증(`f96dd13`, verify 빌드 3.5분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-139 라이브 ISO 부팅이 NTP를 기다리지 않게(`f96dd13`): 시리얼 로그 `Startup finished ... = 13.993s`(전에는 83.7초), pacman 열쇠 준비 13.8초, 전원 모드 데몬 14.0초, 시계 동기화 대기 없음. `verify-boot.log`에 `Startup finished` 줄이 남음
- 2026-10-10 묶음 63 검증(`a31a8f8`, verify 빌드 3.4분 + 테스트 14.4분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-138 텍스트 다루기 미션 41~45(`a31a8f8`): robinctl 테스트가 다섯 미션을 틀린 답과 맞는 답으로 채점(목록에 "텍스트 다루기", 45/45). `72-light-learn-center`에 1/45, `74-learn-center-ctf`는 휠 60번으로 목록 끝의 입문 CTF까지. 설치 테스트에 `/usr/bin/diff`
- 2026-10-10 묶음 62 검증(`eab6589`, verify 빌드 3.4분 + 테스트 14.2분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-137 VMware가 아닌 VM의 VMware 도구(`eab6589`): QEMU(WHPX) 테스트 VM은 여전히 `vmware`로 감지되지만, 라이브 단계 vmtoolsd가 `ExecCondition`(vmware-checkvm)으로 건너뛰어 `ConditionResult=no`, 실패한 서비스 없음. 설치본에는 `open-vm-tools`가 깔리지 않고 실패한 서비스 없음. `30-failed-units`에 0 loaded units, networkd inactive, NetworkManager active
- 2026-10-10 묶음 61 검증(`b1319d5`, verify 빌드 3.6분 + 테스트 14.3분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-137 원인 찾기(`b1319d5`): 설치 테스트 로그에서 QEMU(WHPX) 테스트 VM을 systemd가 라이브·설치본 모두 `vmware`로 감지(`ConditionResult=yes`), 설치기가 `open-vm-tools`를 깔고 설치본에서도 vmtoolsd가 실패. 고침은 다음 묶음
- 2026-10-10 묶음 60 검증(`0d7c3bf`, verify 빌드 3.3분 + 테스트 14.2분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-137 테스트 VM의 vmtoolsd(`0d7c3bf`): `vmport=off`로도 라이브 세션의 vmtoolsd가 그대로 시작해서 원인이 아니었어요. `30-failed-units`는 명령 결과가 나오기 전에 찍혀 `systemd-detect-virt` 값을 못 봤어요. 다음 묶음에서 설치 테스트 로그로 가려요
- 2026-10-10 묶음 59 검증(`8f96fba`, verify 빌드 3.4분 + 테스트 14.1분, 설치 테스트 다섯 단계 통과, 부팅 테스트 79장)
  - T-134 런처 계산·웹 검색(`cce5c5f`): `16-launcher-calc`에 `(12+3)*4` = 60, `17-launcher-web`에 "웹에서 'arch wiki hyprland' 찾기" 항목만
  - T-135 런처 오른쪽 클릭 메뉴(`27c7d29`): `64-launcher-menu`에 열기·독에 고정·제거, `65-launcher-pin`에 고정 알림과 열린 채인 런처, 그 뒤 `66-app-remove-kept`는 전과 같음. 같은 메뉴 카드를 쓰는 `quick-links`, `desktop-menu`, `dock-menu`도 전과 같음
  - T-136 라이브 ISO 서비스(`8f96fba`): `30-failed-units`에 `systemd-networkd` inactive, `NetworkManager` active. `29-event-viewer`에서 networkd 다툼, resolved `LinkBusy`, preset `unresolvable alias` 경고가 사라짐. `vmtoolsd`는 여전히 실패해서 따로 봐요(T-137)
- 2026-10-10 묶음 58 검증(`d335d16`, verify 빌드 3.7분 + 테스트 13.7분, 설치 테스트 다섯 단계 통과, 부팅 테스트 75장)
  - T-131 바탕 화면 오른쪽 클릭 메뉴(`3fa1f07`): `38-desktop-menu`에 클릭한 자리에서 터미널 열기, 파일 탐색기, 배경화면 바꾸기, 디스플레이 설정, 단축키 보기. `12-quick-links`(같은 메뉴 코드로 바꾼 Win+X)는 전과 같음
  - T-132 독 오른쪽 클릭 메뉴(`f2dbcba`): `56-dock-menu`에 계산기의 새 창·독에 고정·창 닫기, 아래 화살표·Enter로 `57-dock-pinned`("독에 고정했어요" 알림)
  - T-133 이벤트 뷰어·rtkit(`d335d16`): `27-event-viewer`의 맨 위와 끝에 `journalctl` 명령, RTKit 오류 줄이 없어짐. 설치 테스트에 `rtkit 0.14-1`. 남은 경고에서 라이브 ISO의 systemd-networkd와 NetworkManager가 같은 장치를 다투는 것, QEMU에서 실패하는 `vmtoolsd`를 찾음 → T-136
- 2026-10-10 묶음 57 검증(`f6fea5a`, verify 빌드 4.4분 + 테스트 13.6분, 설치 테스트 다섯 단계 통과, 부팅 테스트 73장)
  - T-128 런처의 윈도우 관리 도구 이름(`4cf800f`): `27-event-viewer`에 런처에서 `eventvwr`로 연 새 터미널과 `journalctl` 경고 기록. 설치 테스트에서 `/usr/bin/lspci`, `/usr/bin/lsusb`. 기록이 길어 맨 위의 명령 줄은 화면 밖으로 밀려서, 명령을 끝에도 보여 주게 다음 묶음에서 고쳐요(T-133)
  - T-129 문서와 코드 맞추기(`c55db71`): robinctl 테스트에서 CTF 9번 서버가 답한 뒤 시간이 되면 스스로 꺼짐
  - T-130 Win+Ctrl+D·F4(`f6fea5a`): `35-workspace-new`에 작업 공간 2의 새 터미널, `36-workspace-closed`에 그 터미널이 작업 공간 1로 옮겨짐
- 2026-10-10 묶음 56 검증(`5544db7`, verify 빌드 3.4분 + 테스트 13.1분, 설치 테스트 다섯 단계 통과, 부팅 테스트 70장)
  - T-126 알림 센터의 지난 알림 누르면 열기(`5b7e3c9`): `43-notification-opened`에서 알림 센터의 스크린샷 알림(토스트는 이미 사라짐)을 누르니 이미지 뷰어가 그 사진(`20261010-061249.png`)을 열었고, `Ctrl+W`로 닫은 뒤 `44-connect-bluetooth`는 터미널 그대로
  - T-127 야간 모드 아이콘(`5544db7`): `18-quick-settings`, `66-light-quick-settings`의 아이콘이 해 지는 모양(반원, 빛살, 아래 화살표)
- 2026-10-10 묶음 55 검증(`030455d`, verify 빌드 3.7분 + 테스트 13.1분, 설치 테스트 다섯 단계 통과, 부팅 테스트 69장)
  - T-124 닫힌 창의 독 미리보기(`030455d`): `55-launcher-pin`, `56-app-remove-kept`에 빈 미리보기가 없음
  - T-125 사라지는 창의 키보드(`030455d`): `56-app-remove-kept`의 안내 창이 포커스를 받아 Enter로 닫히고, `57-shell-restarted`에 셸 다시 띄우기 기록이 그대로 보임
- 2026-10-10 묶음 54 검증(`c082c42`, verify 빌드 3.5분 + 테스트 13.0분, 설치 테스트 다섯 단계 통과, 부팅 테스트 69장)
  - T-122 런처 앱 제거(`c082c42`): `56-app-remove-kept`에 "gnome-calculator는 RobinOS 기본 구성에 들어 있는 앱이라 지우지 않아요". robinctl 테스트로 지울 수 있는 앱의 pacman 명령
  - T-123 설치 테스트 UDP 확인(`c082c42`): 라이브 단계 `ss -Huln`에 127.0.0.53%lo:53, 127.0.0.54:53만(5355 없음)
  - 같이 찾은 것: 닫힌 창의 독 미리보기가 남고(55·56번 장면), 런처에서 바로 뜬 터미널이 포커스를 못 받음 → T-124, T-125
- 2026-10-10 묶음 53 검증(`8bb934d`, verify 빌드 3.2분 + 테스트 12.9분, 설치 테스트 다섯 단계 통과, 부팅 테스트 68장)
  - T-121 라이브 ISO의 LLMNR 끄기(`8bb934d`): `26-security-audit`에 "다른 컴퓨터가 접속할 수 있는 서비스가 없어요"(전에는 5355가 있었음). 설치 테스트에 넣은 `ss -Hun`은 듣는 UDP 소켓을 보지 않는 명령이라 다음 묶음에서 `ss -Huln`으로 고쳐요
- 2026-10-10 묶음 52 검증(`95eee50`, verify 빌드 3.2분 + 테스트 12.9분, 설치 테스트 다섯 단계 통과, 부팅 테스트 68장)
  - T-120 robinctl audit(`95eee50`): `26-security-audit`에 항목별 결과. 라이브 세션에서 UDP 5355(systemd-resolved의 LLMNR)가 모든 주소에 열린 것을 찾음 → T-121
- 2026-10-10 묶음 51 검증(`d3cf56f`, verify 빌드 3.2분 + 테스트 12.8분, 설치 테스트 다섯 단계 통과, 부팅 테스트 67장)
  - T-119 Win+X 빠른 메뉴(`902267a`): `12-quick-links`에 런처 단추 위로 터미널(선택)·작업 관리자·파일 탐색기·설정·네트워크 연결·소리·시스템 점검·이벤트 뷰어·화면 잠금·종료 또는 로그아웃(라이브라 디스크 관리·저장소는 빠짐). robinctl 테스트의 웹 연습 서버 대기도 들어감
- 2026-10-10 묶음 49 검증(`5854ae4`, verify 빌드 3.2분 + 테스트 12.7분, 설치 테스트 다섯 단계 통과, 부팅 테스트 66장)
  - T-117 런처 최근 파일(`526d810`, `0e7cc16`, `aec719b`, `5854ae4`): `57-light-launcher`에 "최근 파일 · hello.txt ~/practice". 묶음 46~48에서 안 보인 건 테스트 입력 표에 `%`가 없어 xbel이 안 써진 탓이었어요(묶음 48의 `recent-file-written`으로 찾음)
- 2026-10-10 묶음 46 검증(`526d810`, verify 빌드 4.4분 + 테스트 12.6분, 설치 테스트 다섯 단계 통과, 부팅 테스트 65장)
  - T-118 디스크 사용량 분석(`526d810`): 설치 테스트에서 `command -v baobab` → `/usr/bin/baobab`, robinctl 테스트의 힌트 앱 확인
  - T-117 런처 최근 파일은 `56-light-launcher`에 안 보여서 묶음 47에서 다시 봐요
- 2026-10-10 묶음 44 검증(`c06c9e9`, verify 빌드 2.9분 + 테스트 12.1분, 설치 테스트 다섯 단계 통과, 부팅 테스트 65장)
  - T-116 설치 테스트의 명령 확인(`90a0f1d`): 설치본에서 `command -v which ssh-keygen gpg wtype` 통과(`/usr/bin/ssh-keygen`)
- 2026-10-10 T-115 공개용 ISO 크기: `3db2e72`를 `wsl-build.ps1 build`(xz)로 빌드하니 2,101,510,144바이트(2004MiB). 깃허브 한도 2,147,483,648바이트까지 약 44MiB 남아서 v0.2는 올릴 수 있어요(v0.1은 2,097,446,912바이트). 라이브 ISO에 패키지를 더 넣을 때는 release.md대로 크기부터 봐요
- 2026-10-10 묶음 43 검증(`0a12910`, verify 빌드 3.2분 + 테스트 12.1분, 설치 테스트 다섯 단계 통과, 부팅 테스트 65장)
  - T-113 미션 묶음 완료 알림(`0a12910`): robinctl 테스트가 가짜 notify-send로 5번의 "리눅스 기초를 끝냈어요|다음은 네트워크 기초예요" 알림이 한 번만 가는 것을 확인
  - T-114 코드 검토(`0a12910`): 이모지 입력 여유 0.4초로, `38-emoji-typed`에 터미널에 들어간 이모지
- 2026-10-10 묶음 42 검증(`d7b3a14`, verify 빌드 3.2분 + 테스트 12.0분, 설치 테스트 다섯 단계 통과, 부팅 테스트 65장)
  - T-111 바탕 화면 Alt+F4 전원 메뉴(`d7b3a14`): `11-power-menu`에 빠른 설정이 로그아웃·다시 시작·전원 끄기가 펼쳐진 채로, Esc 뒤 `12-launcher`도 그대로
  - T-110 동기화 검사(`91c3a2e`): `ready.ps1 -Check`에 "ISO sync (sync-archiso-files.sh): ok". T-112 Win+PrtSc(`d7b3a14`): Hyprland 설정 검사
- 2026-10-10 묶음 40 검증(`25c84b2`, 두 번째 verify 빌드 3.5분 + 테스트 11.9분, 설치 테스트 다섯 단계 통과, 부팅 테스트 64장)
  - T-108 윈도우 명령 힌트(`143361b`): robinctl 테스트가 certutil·cipher·runas·netsh·sc 힌트 확인, 부팅 테스트 `ipconfig` 힌트 그대로
  - T-109 README 화면 사진(`143361b`, `25c84b2`): 첫 verify는 WSL 동기화의 `install docs/*`가 `docs/screenshots` 폴더에서 멈춰 빌드 실패 → `docs/*.md`만 복사하게 고쳐 통과. ISO에는 사진이 없음
- 2026-10-10 묶음 39 검증(`9cf13c1`, verify 빌드 3.3분 + 테스트 11.9분, 설치 테스트 다섯 단계 통과, 부팅 테스트 64장)
  - T-107 학습 센터 CTF 목록(`9cf13c1`): `59-learn-center-ctf`에 휠로 내린 목록 끝의 입문 CTF 묶음(바꿔치기된 파일 · 무결성 … 사진 속 압축 파일 · 포렌식)
- 2026-10-10 묶음 38 검증(`1040c3f`, verify 빌드 3.3분 + 테스트 11.7분, 설치 테스트 다섯 단계 통과, 부팅 테스트 63장)
  - T-105 독 창 미리보기(`2bf5b8a`, `1040c3f`): `45-dock-preview`에 독의 터미널 위로 터미널 창 미리보기, `48-dock-pinned`에서도 계산기 위에 머문 마우스로 계산기 미리보기. 뒤의 Alt+Tab·작업 보기 장면도 그대로
- 2026-10-10 묶음 37 검증(`2bf5b8a`, verify 빌드 3.3분 + 테스트 11.7분, 설치 테스트 다섯 단계 통과, 부팅 테스트 63장)
  - T-106 연결·소리 창 키보드(`2bf5b8a`): `42-sound-keyboard`에 Tab으로 옮긴 첫 출력 장치 줄의 포커스 테두리
  - T-105 독 창 미리보기는 `45-dock-preview`에 툴팁만 보여서 묶음 38에서 다시 봐요
- 2026-10-10 묶음 36 검증(`24c7b6e`, verify 빌드 3.7분 + 테스트 11.6분, 설치 테스트 다섯 단계 통과, 부팅 테스트 61장)
  - T-102 입문 CTF 6~10(`5e4d63f`): robinctl 테스트가 다섯 문제를 힌트대로 풀어 봄(9번은 127.0.0.1의 포트를 찾아 접속, 서버는 한 번만 뜨고 남지 않음). `53-light-launcher`에 "플래그 10개 찾기"
  - T-103 달력 공휴일(`24c7b6e`): `20-calendar`(2026년 10월)에 3·5·9일이 빨간 날, 아래에 "10월 3일 토요일 · 개천절", "10월 5일 월요일 · 대체공휴일", "10월 9일 금요일 · 한글날"
- 2026-10-10 묶음 35 검증(`f9660cc`, verify 빌드 3.3분 + 테스트 11.6분, 설치 테스트 다섯 단계 통과, 부팅 테스트 61장)
  - T-100 Win+Tab 작업 보기(`f9660cc`): `49-task-view`에 "작업 공간 1 · 지금 화면"과 계산기(선택)·터미널 미리보기, "새 작업 공간" 단추
  - T-101 클립보드 이미지 항목(`f9660cc`): `35-clipboard`에 "이미지 · PNG 1600x900 40 KiB"와 사진 아이콘
  - T-099 문서와 코드 맞추기(`205bcf6`): `08-welcome-tour`에 Win+←/→ 창을 화면 반쪽에, Win+. 이모지가 잘리지 않고 보임
- 2026-10-09 묶음 34 검증(`522a95b`, verify 빌드 4.4분 + 테스트 11.5분, 설치 테스트 다섯 단계 통과, 부팅 테스트 60장)
  - T-094 Alt+Tab 창 전환 화면(`dfca88a`, `522a95b`): `47-alt-tab`에 계산기·터미널 미리보기, Alt를 놓으니 `48-alt-tab-switched`에 터미널이 앞(전환 화면 닫힘)
  - T-093 바에서 휠로 음량(`18a5eee`, `522a95b`): `43-volume-wheel`에 네 칸 내려 20이 된 음량 표시
  - T-096 코드 검토(`56e0633`): Alt+Tab의 닫힌 창 처리. T-097 스크린샷 알림(`56e0633`): `34-screenshot-toast`에 "클립보드에도 복사했어요"와 "폴더 열기" 단추
  - T-098 Win+. 이모지(`cb74172`): `36-emoji`에 `heart`로 찾은 하트 이모지 목록, Enter로 `37-emoji-typed`의 터미널에 😍(첫 항목)가 들어감
- 2026-10-09 묶음 33 검증(`62c4a29`, verify 빌드 5.1분 + 테스트 11.5분, 설치 테스트 다섯 단계 통과, 부팅 테스트 57장)
  - T-091 바의 트레이 아이콘(`fce1443`, `de08af7`): `39-tray`에 한/A 왼쪽 터미널 아이콘(테스트 도우미), 누르니 터미널에 `Activate`
  - T-095 보안 기초 미션 36~40(`84a5b7c`): `49-light-launcher`에 "1/40 완료"와 `robinctl learn` 목록의 보안 기초 36~40, `51-light-learn-center`에 1/40. robinctl 테스트가 36~40을 실제로 풀어 봄
  - T-094 Alt+Tab은 전환 화면(`44-alt-tab`, 계산기·터미널 미리보기, 터미널 선택)까지 됐지만 Alt를 놓아도 안 바뀜, T-093 휠 음량은 안 바뀜 → 묶음 34에서 고쳐 다시 봐요
- 2026-10-09 묶음 32 검증(`c09b8bd`, verify 빌드 4.5분 + 테스트 11.8분, 설치 테스트 다섯 단계 통과, 부팅 테스트 55장)
  - T-092 Win+방향키 창 붙이기(`fce1443`): `27-snap-left`에 터미널이 바와 독을 뺀 왼쪽 절반, `28-snap-maximized`, `29-snap-restored`에 처음 크기와 자리, `30-workspace-next`에 빈 작업 공간 2
  - T-091 트레이와 T-093 휠 음량은 이번에 확인하지 못함: 압축 파이썬을 빠르게 입력하다 Shift가 눌린 채 남아서 도우미가 안 뜨고 휠이 가로 스크롤이 됨. 테스트를 고쳐(`de08af7`) 묶음 33에서 다시 봐요
- 2026-10-09 묶음 31 검증(`2f2af34`, verify 빌드 4.2분 + 테스트 11.0분 통과, 부팅 테스트 49장)
  - T-089 Wi-Fi·블루투스 연결 창(`cd42b83`): `19-connect-wifi`에 "Wi-Fi 장치가 없어요. 지금은 유선으로 연결돼 있어요."와 nmtui 고급 설정, `33-connect-bluetooth`에 "블루투스 장치가 없어요.", 창 밖 클릭으로 닫힘
  - T-090 소리 창(`6eb0022`, `72387bc`): 런처에서 `mixer`로 연 `34-sound`에 출력·입력 장치 "내장 오디오 아날로그 스테레오"(체크), 마이크 음량, 앱별 음량 `pw-play`. 빠른 설정 음량 막대가 VM 사운드 카드로 0이 아니게 됨
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
- 2026-10-09 묶음 22 검증(`6cf0903`, verify 빌드 3.4분 + 테스트 9.2분 통과)
  - T-080 단축키 보기(`ee37a35`): `19-shortcuts`에 창, 앱과 시스템, 터미널(복사 Ctrl+Shift+C 등) 세 묶음, 글자 잘림 없음
- 2026-10-09 묶음 21 검증(`5eaaba1`, verify 빌드 3.5분 + 테스트 9.7분 통과)
  - T-079 셸 기초 미션 26~30(`837e5c5`): robinctl 테스트가 다섯 미션을 틀린 답과 맞는 답으로 채점, `34-light-learn-center`에 "1 / 30 완료". 설치본에 `which`(설치 테스트 `command -v which`)
- 2026-10-09 묶음 20 검증(`79193eb`, verify 빌드 3.4분 + 테스트 9.2분 통과)
  - T-078 윈도우 명령 힌트 13개(`aacd206`): robinctl 테스트에서 start·clip·powercfg·ncpa.cpl·doskey 힌트와 안내하는 패키지 확인, 부팅 테스트 `terminal-windows-hint` 그대로
- 2026-10-09 묶음 19 검증(`dba3ff4`, verify 빌드 3.5분 + 테스트 9.2분 통과)
  - T-077 코드 검토(`b9bd1d9`), 야간 모드 VM 안내(`217c99e`): `37-night-light`에 `/usr/bin/hyprsunset --temperature 4500` 실행 중, `16-quick-settings`의 야간 모드 타일에 "VM에서는 안 돼요"
- 2026-10-09 묶음 18 검증(`cb58a49`, verify 빌드 4.2분 + 테스트 9.7분 통과)
  - T-076 야간 모드·비행기 모드(`e2bf66e`): `16-quick-settings`에 두 타일. `37-night-light`에서 색은 안 바뀜: Hyprland는 드라이버의 KMS CTM으로만 색을 바꾸는데 VM의 bochs-drm에 없음. VM 안내와 실행 확인은 묶음 19에서
- 2026-10-09 묶음 17 검증(`79b7b6e`, verify 빌드 3.5분 + 테스트 9.2분 통과)
  - T-075 배율과 떠 있는 창(`a87a491`): `36-scale-125`에서 터미널이 화면 안 가운데로 옴(위쪽은 바에 조금 걸림)
- 2026-10-09 묶음 15·16 검증(`b0e1c63`, 묶음 16 verify 빌드 3.5분 + 테스트 9.7분 통과, 부팅 테스트 37장)
  - T-073 "배경으로 설정"(`f6c02c0`, `b746b0a`): 묶음 15에서는 포털 앞단의 GTK 허락 창 때문에 배경이 안 바뀜(시리얼 로그, 독의 톱니바퀴 창). WSL에서 앞단을 돌려 Access 백엔드와 허락 규칙을 확인하고, 샌드박스 밖 앱에 허락을 미리 넣음. 묶음 16 `29-wallpaper`에 로고 배경, `30-wallpaper-reset`에 기본 배경(허락 창 없음). 포털 설정을 적은 뒤에도 설정 포털(`button-layout`)은 그대로
  - T-074 화면 배율(`0677483`): 빠른 설정에 "화면 배율 100%~200%"(100% 선택), `36-scale-125`에 커진 화면과 저장 파일 `Virtual-1 1.25`. 배율을 바꾸면 떠 있는 창이 화면 밖으로 조금 나가는 것은 남음
- 2026-10-09 묶음 14 검증(`8f81c47`, verify 빌드 3.7분 + 테스트 9.2분 통과)
  - T-070 배터리 부족 알림(`7aae470`): 셸이 뜨고 시리얼 로그에 QML 오류 없음. VM에는 배터리가 없어 알림 자체는 실기기 확인(사용자 확인 필요)
  - T-072 바의 "터미널"(`0708ecc`): `28-notification`의 바에 "터미널". 런처에서 웹캠 시험 도구 숨김(`135971d`): 설치본 "video" 검색에 동영상 재생 앱만. T-071 문서 맞추기(`e5d3089`)
- 2026-10-09 묶음 13 검증(`f05489a`, verify 빌드 3.6분 + 테스트 9.1분 통과, 부팅 테스트 35장)
  - T-066 Steam(`228f0e0`): 설치본 런처 "steam" 검색에 "Steam 설치하기 · 앱 스토어에서 Flathub의 Steam을 받아요"
  - T-067 알림(`1eb4b43`): `28-notification`에 한국어 토스트(알림 / 오른쪽 아래에 떠요)
  - T-068 동영상·음악(`b2b9ac6`): 설치본에 showtime·decibels·gst-libav, gio 기본 앱(MP4, MP3, PDF) 확인, 런처 "video"에 "동영상 재생 앱 · 윈도우의 미디어 플레이어에 해당해요"
  - T-069 독(`c7535a3`)과 학습 센터 묶음 이름(`a12d8cc`): `32-light-learn-center`에 "다음 미션 · 리눅스 기초", 독에 학사모 아이콘(설치기 아이콘은 열림 표시 없음)
- 2026-10-09 묶음 12 검증(`acebc64`, verify 빌드 3.6분 + 테스트 9.7분 통과)
  - T-063 학습 센터(`c2cddbd`): 환영 마법사 뒤 `09-welcome-done`에 학습 센터(0/25, 다음 미션 1), Alt+F4로 닫았다가 IPC로 다시 연 `31-light-learn-center`에 미션 1 체크와 1/25. 이 장면에서 찾은 두 가지(다음 미션 카드의 빈 묶음 이름, 독의 설치기 아이콘이 열림으로 보이는 것)는 묶음 13에서 고침
  - T-064 윈도우 단축키(`f390e8f`): 단축키 안내에 작업 관리자(Ctrl+Shift+Esc)와 클립보드 기록 줄, Hyprland 설정 검사 통과. taskmgr 힌트가 `missioncenter`를 알려 줌
  - T-065 런처(`2baa1f1`): 추천에 "Foot · 터미널"
  - start-hyprland를 쓰지 않는 이유(`7015451`), README(`397ab52`)
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
- 2026-10-08 묶음 2 검증(`c4e62d5`, ISO 빌드 → 부팅 테스트 33장 → 설치 테스트 robinos 다섯 단계 통과)
  - T-041 doctor가 NVIDIA 드라이버 상태와 인쇄 서비스를 알려 줌(`9dcad3a`, robinctl 테스트 8개)
  - T-042 Firefox 정책으로 원격 측정·실험·기본 브라우저 묻기 끔(`9dcad3a`, 설치본에서 파일 확인)
  - T-043 런처 학습 진행도(`76dbc84`): 라이트 모드 런처에 "1/20 완료 · 이어서 풀어요"
  - T-044 환영 마법사 단축키 안내에 Win+D, Win+Shift+S(`ade8743`, `welcome-tour` 장면)
  - T-045 클립보드 기록 Win+V(`4586424`): `clipboard` 장면에 복사한 글, 로그아웃하면 사라지는 곳에 50개, 민감한 복사는 남기지 않음
- 2026-10-08 묶음 1 검증(`865b09d`, ISO 빌드 → 부팅 테스트 31장 → 설치 테스트 robinos 다섯 단계 통과)
  - T-035 설치본 런처 장면(`22dde2a`): `word` → 텍스트 편집기(워드패드)와 LibreOffice Writer, `store` → 소프트웨어, `printer` → 인쇄 설정이 "윈도우의 …에 해당해요"로 나옴
  - T-037 윈도우 이름 넓히기(`22dde2a`): 명령 힌트 8개, 런처 계산기·디스크 관리, `gnome-disk-utility`
  - T-038 기본 설치의 네트워크(`e9bab85`): 설치본 `ss -Htuln`이 5353/udp(Avahi)와 127.0.0.1·::1의 631(CUPS)뿐, sshd 꺼짐. ethics.md에 적은 그대로
  - T-039 캡처 도구(`e9bab85`): `snipping` 장면에 slurp의 어두운 덮개, Esc 뒤 정상
  - T-040 화면 읽기 조사(`865b09d`): 막힘으로 남김
- 2026-10-08 T-034 리버싱 기초 미션 5개(`9707f73`): 직접 만든 무해한 C 연습 프로그램(`practice/reversing`, 압축해서 robinctl에 14KB)으로 `readelf`(NEEDED), `strings`(비밀번호), `ltrace`(strcmp 비교값), `strace`(찾는 파일 경로), `objdump`(`cmp $0x539` → 1337)를 연습해요. 정답 코드는 XOR로 숨겨 strings에 안 보임. robinctl 테스트에 미션 흐름과 실제 도구 결과(WSL에 gcc·ltrace·strace 설치), 부팅 테스트에서 미션 목록 20개(네 묶음)와 런처 설명 확인. 같이: 문서와 코드 맞추기(`630f101`), 루프 절차에 느린 검증 모아 하기(`e83c5d8`, 사용자 요청)
- 2026-10-08 매일 쓰는 앱 세 가지(design.md 요구사항 표에서 빠져 있던 것): 라이브 ISO에 넣지 않는 설치본 전용 목록 `packages/apps.txt`를 새로 만듦(ISO가 2GiB 한도에 48MB 남음). 설치 테스트 robinos 다섯 단계 통과, 걸린 시간 6.3분 → 6.4분
  - T-031 프린터(`e1a537b`): `cups`, `nss-mdns`, `system-config-printer`. `cups.socket`, `avahi-daemon.service`, nsswitch에 `mdns_minimal`. 설치본에서 `lpstat -r` → "scheduler is running". cups-browsed는 넣지 않음. 런처 "장치 및 프린터"
  - T-032 오피스(`c5db7ca`): `libreoffice-still`(26.2)과 `-ko`. 런처 Word, Excel, PowerPoint. hwp는 97 형식만 열린다고 desktop.md에 적음
  - T-033 앱 스토어(`fff598a`): `gnome-software`(51), PackageKit 없음 확인, `flatpak remotes --system`에 flathub. 런처 "Microsoft Store". `robinctl update`가 시스템 Flatpak 앱도 올림(robinctl 테스트 5개)
  - 첫 설치 테스트는 실패로 나왔는데, 테스트가 도는 중에 `install-test.py`를 고쳐서 단계마다 다시 읽힌 탓이었어요(CLAUDE.md의 주의 그대로). 제품 문제는 아니었어요
- 2026-10-08 T-030 NVIDIA 그래픽 카드 드라이버(`844712d`): 설치기가 `/sys/bus/pci/devices`에서 NVIDIA 화면 장치(VGA, 노트북의 3D 컨트롤러)를 찾고, 장치 번호 `0x1e00` 이상(Turing, GTX 16·RTX 20 이후)이면 `nvidia-open`을 설치하고 initramfs에서 `kms` 훅을 빼요. 오래된 카드는 nouveau 그대로(Arch 공식 저장소에 드라이버 없음). nvidia-utils 615가 nouveau 차단과 절전(커널 suspend notifier)을 스스로 해서 켤 서비스는 없음(패키지를 받아 확인). 설치기 테스트 `scripts/test-robin-install.py`(11개)를 `check`에 넣음. 설치 테스트 robinos 다섯 단계 통과. 실제 NVIDIA PC는 "사용자 확인 필요"
- 2026-10-08 코드 검토로 고친 것 두 가지: 라이브 ISO와 새 설치본의 독에 설치 안 된 Wireshark가 고정돼 눌러도 반응 없던 것(`6faf853`, 부팅·설치 테스트에서 확인), Docker 없이 랩을 켜면 설치 방법을 알려 주지 않던 것(`dfcb5fd`, robinctl 테스트에 Docker 없는 경우를 더함)
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

## 지난 정기 점검

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-11-24 (오전 10시 반) | `c430a5f` 테스트 ISO | robin PC에서 `verify -Installer robinos`(빌드 2.6분, 테스트 22.6분) | 통과. 판정 모두 PASS. 새 장면 `17-launcher-localsend`: 라이브에는 GNOME 소프트웨어가 없어 "LocalSend 설치하기"는 숨고 "휴대폰에서 받기 허용"만 나와요(설계대로, 설치본 장면은 batch79에서 더함). 설치 테스트 다섯 단계 |
| 2026-11-24 (새벽 3시 반) | `f2a6996` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 4.1분, 테스트 22.6분) | 통과. 판정 21개 모두 PASS. `31-terminal-learn.png`에서 터미널 한글이 붙어 보여요(T-183). 설치 테스트 다섯 단계 |
| 2026-11-24 (새벽 3시) | `0451fd4` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.8분, 테스트 22.6분) | 통과. 판정 21개 모두 PASS. 앞의 묶음에서 실패한 `power-changed`(60 120 300)·`power-default`(240 300 600 900)가 잠금 fd 수정 뒤 통과, `default-apps`·`terminal`도 PASS. 설치 테스트 다섯 단계 |
| 2026-11-24 (새벽 1시) | `ddcb219` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 4.4분, 테스트 17.7분), 이어서 `install-test -Installer encrypted` | 통과. 장면 판정 열다섯 개 모두 PASS, 키트 토큰의 다크·라이트 스크린샷(바탕 화면, 빠른 설정, 잠금 화면, 학습 센터) 확인. 설치 테스트 다섯 단계. 암호화 설치도 다섯 단계 모두 통과: 단계마다 GRUB이 비밀번호를 묻고(`*-grub-password.png`) 풀린 뒤 설치본·스냅샷 부팅·되돌리기까지 |
| 2026-10-13 (새벽 3시) | `b2a3624` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.4분, 테스트 17.7분) | 통과. 장면 판정 열다섯 개 모두 PASS, 새 `zoomed`(zoom_factor 2)·`unzoomed`(1), 확대 스크린샷 확인. 설치 테스트 다섯 단계 |
| 2026-10-13 (새벽 2시) | `6e4cc12` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.9분, 테스트 16.8분) | 통과. 장면 판정 열두 개 모두 PASS(학습 센터에서 연 미션 터미널 포함), 설치본에 `sane-airscan` 등 스캔 패키지, 설치 테스트 다섯 단계. 업데이트 미리 보기(T-162)는 VM에서 돌리지 않았고 `test-robinctl.sh`의 가짜 도구 테스트만 |
| 2026-10-13 (새벽 1시 반) | `a2c513a` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.3분, 테스트 16.5분) | 통과. 부팅 테스트가 처음으로 상태로 판정: `e2e-check.sh` 열 장면 모두 PASS(T-155), 화면 녹화 4초 mp4와 바의 "녹화 중"(T-160), 설치 테스트 다섯 단계 |
| 2026-10-13 (새벽 1시) | `57b40e4` 테스트 ISO | 집 PC에서 `verify -Installer robinos`(빌드 3.4분, 테스트 15.0분) | 통과. 설치본에 `ufw` 켜짐(`Status: active`, mDNS 5353 규칙), `deja-dup`과 데스크톱 파일, 설치 테스트 다섯 단계, 부팅 테스트 82장. 라이브의 보안 점검이 "라이브 세션이라 방화벽은 꺼져 있어요"(스크린샷 확인). BitLocker 확인은 정적 검사(`test-robin-install.py`)뿐이고 설치 테스트 robinos의 지우기 확인 상자(같은 `ConfirmBox`)는 그대로 통과 |
| 2026-10-13 (새벽) | `b80f5d0` 테스트 ISO | 집 PC(Blitz)에서 `verify -Installer robinos`(빌드 5.7분, 테스트 15.4분) | 통과. 학교에서 한 커밋들: 설치본에 `sof-firmware 2026.09.2`, `fwupd 2.1.8`(T-156), 터미널 한글 폭 규칙 뺀 뒤 Ptyxis 터미널 장면(`terminal-ptyxis` 시리얼 확인), 설치 테스트 다섯 단계, 부팅 테스트 82장 |
| 2026-10-12 (오후 4시) | `3b08949` 테스트 ISO | robin PC에서 `verify -Installer robinos`(빌드 2.7분, 테스트 14.9분) | 통과. 묶음 77·78: Ptyxis 터미널, 스냅샷 알림과 바의 "스냅샷 N · 임시", 패널 스프링. 처음 두 번은 "통과"였지만 터미널 장면에 창이 없었어요: 새 스크립트가 profiledef.sh의 file_permissions에 없어 라이브에서 644였고, boot-test-qmp.py가 멈춰도 0으로 끝나서 검증이 실패를 못 봤어요. 둘 다 고치고(정적 검증이 권한 목록 확인, 멈춘 시나리오는 실패, 터미널이 안 열리면 tty3 진단) 미션 터미널의 빈 창 하나(--new-window와 명령을 같이 줌)도 고친 뒤 통과. 스크린샷에서 Ptyxis 창과 미션 내용 확인 |
| 2026-10-12 (오후 3시) | `5b1facd` 테스트 ISO | robin PC에서 `verify -Installer robinos` | 통과. 묶음 76: Spotlight 같은 런처, 제어 센터 같은 빠른 설정, 환영 화면 "망가져도 되돌리기", 디자인 문서, 설정 창(`light-settings`, `light-settings-about`: Win+I로 열리고 정보 페이지에 버전·CPU·메모리) |
| 2026-10-12 (오후 2시 반) | `3ab6a33` 테스트 ISO | robin PC에서 `verify -Installer robinos` | 통과. 묶음 75: T-152 ①②(유리, 배경화면 빛), 부팅·로그인·잠금 화면은 이름만, 라이브 하드웨어 시계 LOCAL. 설치본 부팅 메뉴는 "RobinOS"만, 로그인 화면 아래 줄 없음, 환영 화면 뒤에 빨강 빛. VMware(GPU) 라이브에서 시계가 바로 맞는 것도 확인 |
| 2026-10-12 (오후 2시) | `cc7ea3b` 테스트 ISO | robin PC에서 `verify -Installer robinos`(빌드 2.7분, 테스트 14.4분) | 통과. 묶음 74: 라이브 BIOS 부팅 메뉴의 RobinOS 스플래시와 색. VMware와 QEMU(BIOS)로 직접 켜서 메뉴 화면도 확인했어요 |
| 2026-10-12 (오후) | `6113f35` 테스트 ISO | robin PC에서 `verify -Installer robinos`(빌드 2.8분, 테스트 14.5분) | 통과. 부팅 테스트 79장, 설치 테스트 다섯 단계. 묶음 73: 환영 마법사 첫 화면과 T-151 화면 문구. 설치본 부팅 메뉴의 한글 한 줄 소개가 Unifont로 깨지지 않고 나오고(`installed-01-grub-first-boot.png`), 로그인 화면 아래 줄도 새 문구예요(`rollback-02-sddm.png`) |
| 2026-10-12 | `8be98ca` 테스트 ISO | robin PC에서 `verify -Installer robinos`(빌드 3.5분, 테스트 14.7분) | 통과. 부팅 테스트 70장, 설치 테스트 다섯 단계. 집에서 쌓인 290개 커밋을 받고, WSL `setup`으로 Quickshell 0.3.2와 `which`를 맞춘 뒤 처음 돈 묶음 검증이에요. 부팅 테스트 화면은 소개 영상(`promo/intro/`)에도 썼어요 |
| 2026-10-10 (아침) | `030455d` 테스트 ISO | 설치 테스트 windows(9.1분) | 다섯 단계 통과. 윈도우 파티션, EFI 파일, C: 그대로, GRUB 메뉴에 Windows Boot Manager. 새벽 뒤로 바뀐 것(LLMNR 끄기, 앱 제거, 설치 테스트의 UDP 확인)이 윈도우 옆 설치 경로에서도 문제없음 |
| 2026-10-10 (새벽) | `857383b` 테스트 ISO | 설치 테스트 archinstall(11.4분) | 다섯 단계 통과. 어제 저녁 뒤로 바뀐 설치 코드(openssh, baobab, wtype, 힌트)가 archinstall+post-install 경로에서도 문제없음(`ssh-keygen`, `baobab` 확인) |
| 2026-10-08 | `933ca31` ISO, `e038f2a` 테스트 | ISO 빌드, 부팅 테스트(WHPX, 29장, 새 장면 `shell-restarted`), 설치 테스트 robinos(다섯 단계) | 통과. 셸을 끄면 1초 뒤 다시 뜸(`exited with 143` → `starting the shell`). 환영 마법사 단축키가 `Win`으로, 윈도우 명령 힌트가 새 문구로 나옴. 설치기 마무리가 "설치가 끝났어요"까지 감. 테스트 도중 WSL에 `cmp`가 없어 ISO를 매번 복사하던 것을 고침(`e038f2a`) |
| 2026-10-08 | `5de4149` | 두 번째 PC(사용자 `robin`, 한글 경로)에서 처음 검증: ISO 빌드(처음부터, 6분, Qt 6.12), 부팅 테스트(WHPX, 254초, 24장) | 통과. 한글 경로에서 WHPX QEMU가 파일을 못 열던 문제를 고친 뒤 통과. 스크린샷 24장 모두 정상(라이트 모드, 잠금 화면 포함) |
| 2026-10-08 | `4fbb2c6` | ISO 빌드(처음부터, 8분), 부팅 테스트(221초, 21장), 설치 테스트 windows(8분, 다섯 단계) | 통과. 같은 날 archinstall·robinos 설치 테스트도 각각 통과 |
| 2026-10-08 | `7a000b9` | ISO 빌드(처음부터, 9분), 부팅 테스트(WHPX, 207초) | 통과. 스크린샷 18장 모두 정상 |
| 2026-10-07 | `16d652f` | ISO 빌드, 부팅 테스트 | 빌드 성공. 부팅 테스트에서 마법사 키 반복 문제(고침), 런처 검색 미확인 (T-001) |

## 정기 점검 기록

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-10-09 (밤) | `71333c8` 테스트 ISO | 설치 테스트 windows(9.1분) | 다섯 단계 통과. 윈도우 파티션, EFI 파일, C: 그대로. 오늘 바뀐 post-install이 윈도우 옆 설치 경로에서도 문제없음 |
| 2026-10-09 (저녁) | `a39b6b8` 테스트 ISO | 설치 테스트 archinstall | 다섯 단계 통과. 오늘 바뀐 post-install(사용자 `.bashrc`의 RobinOS 설정, os-release와 pacman 훅, 기본 앱, 동영상·음악 앱, `which`)이 archinstall 경로에서도 문제없음 |
| 2026-10-09 | `ba358cb` 테스트 ISO | 설치 테스트 windows(6.7분), archinstall(10.1분) | 둘 다 다섯 단계 통과. 오늘 고친 설치 코드(`apps.txt`, 서비스, nsswitch, NVIDIA 감지, 전원 모드)가 윈도우 옆 설치와 archinstall+post-install 경로에서도 문제없음 |
| 2026-10-08 | `968795d` ISO | 집 PC(Blitz)에서 ISO 빌드, 부팅 테스트(WHPX, 30장, 새 장면 `button-layout`), 설치 테스트 robinos(다섯 단계) | 통과. 설치기에 Qt 제목 표시줄(최대화, 닫기), 라이브 독에 Wireshark 없음, 설치본 독은 터미널·파일·브라우저 |
