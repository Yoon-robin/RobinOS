# RobinOS 데스크톱

RobinOS는 Hyprland 위에 직접 만든 Quickshell 셸을 얹어 써요. 디자인은 shadcn/ui의 zinc 팔레트를 따르고, 기본값은 윈도우에서 넘어온 사용자에게 맞췄어요. 왜 이렇게 만들었는지는 `docs/design.md`에 있어요.

## 구성 요소

| 부분 | 프로그램 | 저장소 안 위치 |
|---|---|---|
| 컴포지터 | Hyprland 0.56+ (Lua 설정) | `desktop/hypr/robinos.lua` |
| 셸: 상단 바(트레이 포함), 독, 런처, Alt+Tab 창 전환, 작업 보기, 빠른 설정, Wi-Fi·블루투스 연결 창, 소리 창, 알림, 볼륨 표시, 배경화면, 환영 마법사, 달력, 학습 센터, 단축키 보기, 설치기 | Quickshell 0.3 | `desktop/shell/` |
| 세션 시작, 렌더링 자동 전환 | `robinos-session` | `desktop/bin/robinos-session` |
| 셸 다시 띄우기, 셸 렌더링 전환 | `robinos-shell` | `desktop/bin/robinos-shell` |
| VM 화면을 창 크기에 맞추기 | `robinos-vm-display` | `desktop/bin/robinos-vm-display` |
| 화면 캡처 | `robinos-screenshot` (grim, slurp) | `desktop/bin/robinos-screenshot` |
| "배경으로 설정" (Wallpaper 포털) | `robinos-wallpaper-portal` | `desktop/bin/robinos-wallpaper-portal`, `desktop/portal/` |
| 시스템 이름 (os-release) | `robinos-os-release`, pacman 훅 | `desktop/bin/robinos-os-release`, `desktop/pacman/` |
| 터미널 프롬프트와 윈도우 명령 힌트 | bash | `desktop/bash/` |
| 야간 모드 | hyprsunset | - |
| 이모지 넣기 (`Win+.`) | 런처의 이모지 모드, wtype | `desktop/shell/emoji.js` |
| 트레이 아이콘 | StatusNotifierItem (Quickshell `SystemTray`) | `desktop/shell/Bar.qml` |
| 로그인 화면 | SDDM (Qt 6 테마) | `themes/sddm/robinos/` |
| 잠금 화면과 대기 | hyprlock, hypridle | `desktop/hypr/hyprlock.conf`, `hypridle.conf` |
| 터미널 | foot | `desktop/foot/foot.ini` |
| 파일, 브라우저 | Nautilus, Firefox (원격 측정과 실험 기능은 꺼 둬요: `/etc/firefox/policies/policies.json`) | `desktop/firefox/` |
| 파일을 여는 기본 앱 | `/etc/xdg/mimeapps.list` | `desktop/mime/` |
| fastfetch 요약과 울새 그림 | fastfetch | `desktop/fastfetch/` |
| GTK, libadwaita 앱 | adw-gtk3, dconf 기본값 | `desktop/dconf/` |
| Qt 앱 | qt6ct 팔레트 | `desktop/qt6ct/` |
| 한글 입력 | fcitx5-hangul | `desktop/fcitx5/` |
| 글꼴 | Geist, Geist Mono, Pretendard | `desktop/fontconfig/`, `scripts/fetch-fonts.sh` |

디자인 토큰은 `desktop/shell/Theme.qml`에 있어요. foot, hyprlock, qt6ct 팔레트, SDDM 테마도 같은 값을 써요.

## 설치 위치

`desktop/install-map.txt`에 모든 파일과 각 파일이 들어갈 위치가 적혀 있어요. 아래 스크립트는 모두 이 파일 하나만 보고 움직여요.

- `scripts/install-desktop.sh` (설치된 시스템용. 다른 루트 경로에 설치할 때는 `--root`)
- `scripts/sync-archiso-files.sh`, `scripts/sync-archiso-files.ps1` (라이브 ISO 오버레이)

주요 위치:

```text
/usr/share/robinos/shell/                Quickshell config (qs -p /usr/share/robinos/shell)
/usr/share/robinos/hypr/robinos.lua      Hyprland defaults
/etc/xdg/hypr/hyprland.lua               System entry point, used when ~/.config/hypr/hyprland.lua is missing
/usr/share/wayland-sessions/robinos.desktop
/usr/share/robinos/bin/robinos-session
/usr/share/robinos/bin/robinos-shell
/usr/share/robinos/bin/robinos-vm-display
/usr/share/robinos/bin/robinos-screenshot
/usr/share/robinos/bin/robinos-wallpaper-portal
/usr/share/robinos/bin/robinos-os-release
/usr/share/robinos/bash/robinos-bashrc.sh   Prompt, Windows command hints, greeting (~/.bashrc sources it)
/etc/xdg/xdg-desktop-portal/hyprland-portals.conf
/etc/xdg/mimeapps.list
```

Geist와 Pretendard는 Arch 저장소에 없어요. `scripts/fetch-fonts.sh`가 버전을 고정해 둔 릴리스를 내려받아 SHA-256 체크섬을 확인하고 `/usr/share/fonts/robinos`에 설치해요. ISO를 만들 때는 `scripts/prepare-archiso.sh`가, 설치된 시스템에서는 `scripts/post-install.sh`가 이 스크립트를 실행해요.

## VM 렌더링

`robinos-session`이 Hyprland를 어떤 방식으로 시작할지 정해요.

1. 3D 가속이 없는 그래픽 드라이버(`hyperv_drm`, `bochs`, `simpledrm`, `qxl` 등)를 쓰거나 DRM 렌더 노드가 없으면 소프트웨어 렌더링으로 시작해요.
2. 그 밖에는 GPU 가속으로 Hyprland를 시작해요. 8초 안에 종료되면 세션이 소프트웨어 렌더링으로 다시 시작해요.
3. `ROBINOS_RENDER=software`에서는 Hyprland의 블러와 그림자를 끄고, 셸도 그림자 효과를 그리지 않아요.

로그는 `~/.local/state/robinos/session.log`에 남아요. 렌더링 방식을 직접 정하고 싶으면 `~/.bash_profile`에서 `ROBINOS_RENDER=software`나 `ROBINOS_RENDER=hardware`를 export하면 돼요.

셸은 Hyprland가 바로 띄우지 않고 `robinos-shell`을 거쳐 떠요.

- Hyprland는 GPU로 잘 그리는데 셸(Qt)만 GPU 화면을 못 얻는 드라이버가 있어요. VMware의 `vmwgfx`가 그래요. 이때 셸은 떠 있어도 화면에 아무것도 안 보여요. `robinos-shell`은 셸 로그에서 `Could not create EGL surface`를 보면 셸만 소프트웨어 렌더링(`LIBGL_ALWAYS_SOFTWARE=1`)으로 다시 띄워요. Hyprland는 계속 GPU를 써요.
- 셸이 죽으면 1초 뒤에 다시 띄워요. 2분 안에 5번 죽으면 멈추고, 화면에 복구 방법을 띄워요.
- 로그는 `~/.local/state/robinos/shell.log`에 있어요. 셸을 처음부터 소프트웨어로 그리려면 `~/.bash_profile`에서 `ROBINOS_SHELL_RENDER=software`를 export하세요.

QEMU에서 GPU 가속으로 테스트하려면 `scripts/run-vm.sh --gl`을 실행하세요.

## VM 화면 크기

VM 화면은 물리 크기를 알려 주지 않아서, Hyprland의 자동 배율이 2배를 고르곤 해요. 그러면 1280×800 창이 640×400짜리 바탕 화면이 돼요. 그래서 VM 화면(`Virtual-1` 같은 이름)은 배율 1로 시작해요.

VM 창 크기를 바꾸면 VMware(`vmtoolsd`)나 QEMU(`virtio-gpu`)가 새 크기를 커널에 알려 줘요. Hyprland는 처음 고른 해상도를 그대로 쓰기 때문에, `robinos-vm-display`가 이 신호를 보고 화면을 창 크기에 맞춰요. 가로 3200픽셀 이상이면 배율 2를 써요. 실제 PC에서는 바로 끝나요.

- VMware에서는 보기 메뉴의 "Autofit Guest"가 켜져 있어야 해요. 끄면 마지막 크기가 유지돼요.
- 설치기는 VMware에서 설치하면 `open-vm-tools`를 같이 설치하고 `vmtoolsd`를 켜요. QEMU/KVM에서는 `qemu-guest-agent`를 설치해요.

## 단축키

`Super`는 키보드의 윈도우 키예요. 리눅스에서 부르는 이름이고, 화면(환영 마법사, 런처, 안내 문구)에는 윈도우 사용자에게 익숙한 `Win`으로 보여요.

| 단축키 | 동작 |
|---|---|
| `Super+Space` 또는 `Super+A` | 런처 (앱, 학습 미션, 랩, 시스템 명령) |
| `Super+S` 또는 `Super+I` | 빠른 설정 (윈도우의 설정 `Win+I`) |
| `Super+R` | 런처 (윈도우의 실행 `Win+R`) |
| 바의 상태 아이콘(네트워크, 스피커) 위에서 마우스 휠 | 음량 5%씩 (윈도우의 스피커 아이콘과 같아요) |
| `Super+N` 또는 바의 종 아이콘 | 알림 센터: 로그인한 뒤 온 알림, 모두 지우기, 방해 금지 (윈도우 11의 `Win+N`과 같아요) |
| `Super+Return` | 터미널 |
| `Super+E` | 파일 |
| `Super+B` | 브라우저 |
| `Super+L` | 화면 잠금 |
| `Ctrl+Shift+Escape` | 작업 관리자 (Mission Center) |
| `Alt+Tab`, `Alt+Shift+Tab` | 창 전환: `Alt`를 누르고 있는 동안 지금 작업 공간의 창이 미리보기 그림과 함께 최근에 쓴 순서로 나와요(최소화한 창도). `Tab`으로 다음, `Shift+Tab`으로 이전 창을 고르고, `Alt`를 놓으면 그 창으로 가요. 마우스로 눌러도 돼요 (윈도우와 같아요) |
| `Alt+F4` 또는 `Super+Q` | 창 닫기. 창이 없는 바탕 화면에서 `Alt+F4`를 누르면 전원 메뉴(로그아웃, 다시 시작, 전원 끄기)가 떠요 (윈도우의 "Windows 종료"와 같아요) |
| `Super+D` | 바탕 화면 보기 (지금 작업 공간의 창을 모두 숨기고, 다시 누르면 돌아와요) |
| `Super+T` | 창을 자유 배치와 타일 배치 사이에서 전환 |
| `Super+F`, `Super+M` 또는 `Super+↑` | 전체 화면, 최대화 |
| `Super+1`...`Super+9` | 작업 공간 전환 (`Shift`를 같이 누르면 창을 옮겨요) |
| `Super+←`, `Super+→` | 창을 화면 왼쪽·오른쪽 절반에 붙여요 (윈도우의 창 끌어 놓기와 같아요). 타일 배치에서는 그쪽 창과 자리를 바꿔요 |
| `Super+↓` | 최대화나 반쪽에 붙인 창을 원래 크기와 자리로 되돌리고, 다시 누르면 최소화 (독에서 다시 열어요) |
| `Super+Tab` | 작업 보기: 모든 작업 공간의 창을 미리보기와 함께 작업 공간별로 보여 줘요(최소화한 창도). 누르거나 화살표·`Enter`로 그 창으로 가고, "새 작업 공간"은 빈 작업 공간을 열어요. `Esc`로 닫아요 (윈도우의 `Win+Tab`과 같아요) |
| `Super+Ctrl+←`, `Super+Ctrl+→` | 이전·다음 작업 공간 (윈도우의 가상 데스크톱 전환과 같아요) |
| `Super+Shift+방향키` | 창을 그쪽으로 옮겨요 |
| `Super+마우스 휠` | 이웃 작업 공간으로 |
| `Super+drag` | 창 이동(왼쪽 버튼), 크기 조절(오른쪽 버튼) |
| `Print`, `Shift+Print` 또는 `Super+Print` | 영역 또는 전체 화면을 찍어 `~/Pictures/Screenshots`와 클립보드에 저장. 알림을 누르면 사진이 열리고, "폴더 열기" 단추로 폴더를 열어요 |
| `Super+Shift+S` | 영역 스크린샷 (윈도우의 캡처 도구 `Win+Shift+S`와 같아요) |
| `Super+.` 또는 `Super+;` | 이모지: 런처에서 이모지를 찾아(하트, 웃음, ok처럼 한국어·영어로) `Enter`를 누르면 원래 창에 들어가고 클립보드에도 복사돼요 (윈도우의 `Win+.`와 같아요) |
| `Super+V` | 클립보드 기록 (윈도우의 `Win+V`처럼 복사한 것 50개, 로그아웃하면 지워져요) |
| `Super+Alt+D` 또는 바의 시계 클릭 | 달력 (←, → 로 달 바꾸기, Home은 이번 달). 일요일과 공휴일(설날·추석·대체공휴일·선거일 포함)은 빨간색이고, 그달의 공휴일 이름이 아래에 나와요. 음력 공휴일과 대체공휴일은 `desktop/shell/holidays.js`의 표에 있어서 해마다 다음 해를 넣어요(지금 2026~2028년) |
| `Super+F1` 또는 런처의 "단축키 보기" | 모든 단축키를 한 화면에 (터미널의 복사 `Ctrl+Shift+C`, 붙여 넣기 `Ctrl+Shift+V`, 멈추기 `Ctrl+C`도 있어요) |
| `Right Alt` | 한/영 전환 (`Right Ctrl`은 한자) |
| `Super+Shift+Escape` | 로그아웃 |

새 창은 윈도우처럼 자유 배치로 떠요. 빠른 설정에서 "창 자동 정렬" 스위치를 켜면 새 창이 타일로 배치돼요.

독의 앱 아이콘은 윈도우 작업 표시줄처럼 동작해요. 앱이 꺼져 있으면 열고, 창이 뒤에 있으면 앞으로 가져오고, 이미 앞에 있으면 최소화하고, 최소화돼 있으면 원래 작업 공간으로 되돌려요. 창이 여러 개면 차례로 앞으로 가져와요. 최소화한 창은 숨은 작업 공간(`special:minimized`)에 있고, 독에는 계속 실행 중(점)으로 보여요. 셸 IPC로도 같은 동작을 할 수 있어요: `qs ipc -p /usr/share/robinos/shell call shell toggleApp foot`. 독에 고정된 앱은 터미널, 파일, 브라우저이고, Wireshark는 network 프로필로 설치한 뒤에 나타나요(`sudo robinctl profile network`). 실행 중인 다른 앱도 윈도우 작업 표시줄처럼 고정할 수 있어요. 독에서 그 앱을 오른쪽 버튼으로 누르면 고정되고, 내가 고정한 앱을 다시 오른쪽 버튼으로 누르면 풀려요(알림으로 알려 줘요). 런처에서 앱을 오른쪽 버튼으로 눌러도 고정하거나 풀어요(시작 메뉴의 "작업 표시줄에 고정"과 같아요). 고정한 앱은 셸 상태 폴더의 `desktop.json`에 남아서 다음 로그인에도 그대로예요. 켜져 있는 앱 아이콘 위에 마우스를 0.5초 올려 두면 그 앱의 창(4개까지)이 미리보기로 독 위에 떠요. 미리보기를 누르면 그 창으로 가요.

GTK 앱, Firefox, Qt 앱(설치기, Wireshark 등)은 창 위에 제목 표시줄이 있어요. 단추는 최대화와 닫기 두 개예요. Hyprland가 앱의 최소화 요청을 아직 처리하지 않아서 최소화는 독에서 해요. 터미널(foot)에는 제목 표시줄이 없어요. `Alt+F4`나 `Super+Q`로 닫아요.

마우스 없이도 쓸 수 있어요. 런처, 빠른 설정, 환영 마법사, 설치기에서 `Tab`으로 버튼과 선택지를 옮겨 다니고(포커스가 테두리로 보여요), `Enter`나 `Space`로 눌러요. 볼륨 같은 슬라이더는 화살표 키로 5%씩, `Home`과 `End`로 끝까지 움직여요.

## 터미널 프롬프트

터미널의 프롬프트는 이렇게 생겼어요. 윈도우 PowerShell의 `PS C:\Users\robin>`처럼 지금 있는 폴더 뒤에 `>`가 와요.

```text
robin@robinos ~/practice >
```

- 흐린 글자는 사용자 이름과 컴퓨터 이름, 굵은 글자는 지금 있는 폴더예요(`~`는 내 홈 폴더). 경로가 길면 마지막 세 단계만 보여요
- `>`는 RobinOS의 빨간 강조색이에요. 관리자(root) 셸에서는 리눅스의 관례대로 `#`가 돼요
- 바로 앞 명령이 실패하면 `>` 앞에 종료 코드가 빨갛게 나와요. `robin@robinos ~ 127 >`는 명령을 찾지 못했다는 뜻이에요. 0이 아닌 종료 코드는 실패예요
- 창 제목도 `robin@robinos: ~/practice`처럼 지금 있는 곳으로 바뀌어요(셸의 바는 창 제목 대신 앱 이름 "터미널"을 보여 줘요)

프롬프트, 윈도우 명령 힌트, 첫 인사(fastfetch)는 `desktop/bash/robinos-bashrc.sh`(설치 위치 `/usr/share/robinos/bash/robinos-bashrc.sh`)에 모여 있고, `~/.bashrc`는 이 파일을 불러오기만 해요. 그래서 RobinOS가 업데이트되면 이미 있는 사용자에게도 바뀐 것이 들어가요. 내 설정은 `~/.bashrc`의 그 줄 아래에 적어요. 새로 만드는 사용자는 `/etc/skel/.bashrc`로 바로 쓸 수 있고, 설치하는 사용자의 `~/.bashrc`에는 `scripts/post-install.sh`가 그 줄을 넣어 줘요.

## 윈도우 명령 힌트

`desktop/bash/robinos-hints.sh`가 맡아요. 터미널에 윈도우 명령을 치면 같은 일을 하는 리눅스 명령을 알려 줘요.

```text
robin@robinos ~ > ipconfig
ipconfig 명령은 윈도우용이에요. 리눅스에서는
  ip a  IP 주소와 네트워크 장치를 보여 줘요
```

명령 70개 넘게 알아들어요(`dir`, `cls`, `cd..`, `copy`, `del`, `tasklist`, `tracert`, `netstat`, `findstr`, `notepad`, `calc`, `start`, `clip`, `powercfg`, `eventvwr`, `services.msc`, `devmgmt.msc`, `diskmgmt.msc`, `ncpa.cpl`, `appwiz.cpl`, `getmac`, 보안 미션과 이어지는 `certutil`·`cipher`·`runas`·`cacls` 등). `nslookup`처럼 리눅스에도 있지만 처음에는 설치돼 있지 않은 명령은 지금 쓸 수 있는 명령(`getent hosts`)과 설치할 프로필을 알려 줘요.

## 환영 마법사

처음 로그인하면 환영 마법사가 떠요(`desktop/shell/Welcome.qml`). 다섯 단계예요.

1. RobinOS 소개
2. 다크/라이트와 강조 색상. 고르는 즉시 화면에 적용돼요.
3. 한/영 전환 단축키. 한/영 키와 오른쪽 Alt는 항상 되고, Ctrl+Space(기본), Shift+Space, 없음 중에서 하나를 더 골라요. `~/.config/fcitx5/config`를 다시 쓰고 `fcitx5-remote -r`로 바로 적용해요. 입력 칸에서 직접 바꿔 볼 수 있어요.
4. 학습 목표: 리눅스 기초, 웹 보안, 먼저 둘러보기
5. 단축키 안내(런처, 빠른 설정, 창 전환·닫기, 파일, 터미널, 바탕 화면 보기, 화면 캡처, 한/영, 잠금, 작업 관리자, 클립보드 기록, 창 반쪽 붙이기, 이모지). 마지막 단추를 누르면 고른 목표가 열려요. 리눅스 기초는 학습 센터, 웹 보안은 터미널의 웹 랩 안내예요.

Enter는 다음, Esc는 건너뛰기예요. 끝내거나 건너뛰면 `~/.local/state/quickshell/` 아래 `welcome.json`에 기록돼서 다시 뜨지 않아요. 라이브 ISO는 부팅할 때마다 새로 시작하니 매번 떠요. 다시 보려면 런처에서 "환영 마법사"를 고르거나 이렇게 실행하세요.

```bash
qs ipc -p /usr/share/robinos/shell call shell welcome
```

## 설치기 (라이브 세션)

라이브 ISO에서는 런처 추천 맨 위에 "RobinOS 설치"가 나와요(`desktop/shell/Installer.qml`). 일반 창이라 설치하는 동안 다른 앱을 써도 돼요. 단계는 준비 확인, 설치 위치(디스크와 "윈도우 옆에 설치"/"디스크 전체 사용"), 사용자, 최종 확인, 진행 순서예요. 실제 설치는 `installer/robin-install`이 하고, 화면은 그 출력의 `@@ <퍼센트> <메시지>` 줄로 진행률을 보여 줘요. 설치된 시스템에서는 나오지 않아요.

```bash
qs ipc -p /usr/share/robinos/shell call shell installer
```

## 윈도우 이름으로 앱 찾기

런처에서 윈도우 앱 이름으로 검색해도 같은 일을 하는 앱이 나와요. 결과는 "윈도우에서 쓰던 이름" 아래에 "윈도우의 메모장에 해당해요"처럼 설명과 함께 보여요.

| 검색어 | 찾아 주는 것 |
|---|---|
| 메모장, `notepad` | 텍스트 편집기 |
| 작업 관리자, `taskmgr` | Mission Center |
| 파일 탐색기, 내 PC, `explorer` | 파일 (Nautilus) |
| 명령 프롬프트, `cmd`, `powershell` | 터미널 (foot) |
| Edge, 크롬, `chrome` | Firefox |
| 사진 | 이미지 뷰어 (Loupe) |
| 반디집, 알집, `7-zip` | 압축 관리자 |
| 볼륨 믹서, 소리 설정 | 소리 창 (출력 장치, 마이크, 앱별 음량) |
| 네트워크 및 인터넷, `ncpa.cpl`, 와이파이 | Wi-Fi 연결 창 |
| 블루투스 및 장치, 이어폰 | 블루투스 연결 창 |
| Acrobat, `pdf` | 문서 뷰어 (Evince) |
| 캡처 도구, `snipping tool` | 영역 스크린샷 명령 (`Super+Shift+S`) |
| 계산기, `calc` | 계산기 |
| 디스크 관리, USB 포맷 | 디스크 (GNOME 디스크, 설치본에만 있어요) |
| 워드, 엑셀, 파워포인트, 오피스 | LibreOffice Writer, Calc, Impress (설치본에만 있어요) |
| Microsoft Store, 스토어, 앱 설치 | GNOME 소프트웨어 (설치본에만 있어요) |
| 장치 및 프린터, 프린터, `printer` | 프린터 설정 (설치본에만 있어요) |
| 미디어 플레이어, 영화 및 TV, 동영상 | 동영상 재생 앱 (Showtime, 설치본에만 있어요) |
| 그루브 음악, 음악 | 오디오 재생기 (Decibels, 설치본에만 있어요) |
| 제어판, `control panel` | 빠른 설정 |

목록은 `desktop/shell/Launcher.qml`의 `windowsNames`에 있어요.

## 런처의 최근에 연 앱

런처를 열면 추천 아래에 "최근에 연 앱"이 4개까지 나와요(윈도우 시작 메뉴의 최근 항목처럼). 런처에서 연 앱만 세고, 독에 기본으로 있는 터미널·파일·브라우저는 빼요. 기록은 셸 상태 폴더의 `desktop.json`에 8개까지 남아요.

## 런처에서 파일 찾기

런처(`Win+Space`)에 두 글자 이상 치면 앱과 명령 아래에 "파일"이 나와요. 윈도우 시작 메뉴처럼 홈 폴더에서 이름에 그 글자가 들어간 파일과 폴더를 6개까지 찾아요(5단계 아래까지, `.config` 같은 숨김 폴더는 빼요). 고르면 알맞은 앱으로 열려요(폴더는 파일 앱). 치기를 멈추고 잠깐 뒤에 `find`로 찾고, 검색어는 셸을 거치지 않아요.

## 학습 미션

런처의 "학습 미션"을 고르면 학습 센터가 열려요(`desktop/shell/LearnCenter.qml`). 맨 위에 진행도 막대와 다음 미션이 있고, 그 아래에 여덟 묶음의 미션 40개가 끝낸 것은 초록 체크, 다음 것은 강조색 동그라미로 보여요. 미션을 고르면(마우스나 `Tab`과 `Enter`) 터미널이 열리고 `robinctl learn show <번호>`가 설명을 보여 줘요. 미션은 그 터미널에서 직접 풀고, `robinctl learn check`로 확인해요. 통과하면 학습 센터의 체크가 바로 바뀌고, 묶음 하나를 다 끝내면 다음 묶음을 알려 주는 알림이 떠요. 목록 끝에는 입문 CTF 10문제가 한 묶음으로 있어서, 고르면 터미널에서 `robinctl ctf show 번호`가 열려요. 맨 아래에는 입문 CTF의 진행도와 "CTF 열기"가 있어요. 환영 마법사에서 "리눅스 기초"를 고르고 끝내도 학습 센터가 열려요. 미션 목록은 `robinctl learn tsv`에서 읽어요. 리눅스, 네트워크, 포렌식, 리버싱, 웹, 셸, 시스템, 보안 기초가 5개씩 있고(연습 파일은 `~/practice/forensics`, 연습 프로그램은 `~/practice/reversing`, 웹 연습 서버는 `~/practice/web`에 만들어요), 자세한 내용은 [README](../README.md#학습-미션)에 있어요. 미션을 하나라도 끝내면 런처의 "학습 미션"에 "3/40 완료"처럼 진행도가 보여요(`~/.local/state/robinos/learn/done`을 셸이 읽어요).

셸이 작업용으로 여는 터미널은 `ROBINOS_NO_GREETING=1`로 시작해서 `~/.bashrc`가 fastfetch를 띄우지 않아요. fastfetch는 한국어 라벨로 짧게 줄인 설정(`desktop/fastfetch/config.jsonc` → `/etc/xdg/fastfetch/config.jsonc`)을 쓰고, 왼쪽에 Arch 로고 대신 RobinOS 울새 그림(`/usr/share/robinos/fastfetch/robinos-logo.ansi`, [brand.md](brand.md))을 보여 줘요.

런처의 "입문 CTF"(보안 랩 아래)는 터미널에서 `robinctl ctf`를 열어요. 학습 미션 다음 단계로, 배운 기술을 섞어 플래그 10개를 찾아요([README](../README.md#입문-ctf)).

## 라이브 세션

라이브 ISO는 `robin` 계정(비밀번호 `robin`)으로 RobinOS 세션에 자동 로그인해요. 비밀번호 없는 sudo는 라이브 ISO에만 설정돼 있어요(`/etc/sudoers.d/10-robinos-live`). 시간대는 한국(`Asia/Seoul`)이고, 인터넷에 연결되면 `systemd-timesyncd`가 시계를 맞춰요. 설치한 시스템의 시간대는 설치기에서 정해요.

라이브 ISO에는 가벼운 보안 도구(nmap, tcpdump, netcat, dig, sqlmap, binwalk 같은 것)만 들어 있어요. Wireshark 화면 앱, john, hashcat, hydra, gdb, Docker(웹 랩), 가상 머신 도구는 크기가 커서 빠져 있고, 설치한 시스템에서 `sudo robinctl profile <이름>`으로 넣어요. 라이브 세션은 메모리 위에서 돌아서 큰 묶음이나 랩 이미지를 받을 자리가 거의 없어요. 프린터(CUPS와 프린터 설정 앱), 오피스(LibreOffice), 앱 스토어(GNOME 소프트웨어), 디스크 관리(GNOME 디스크)도 설치본에만 들어가요(`packages/apps.txt`).

## 앱 스토어

설치한 시스템에서 런처의 "소프트웨어"(검색어 "스토어", "앱 설치")를 열면 Flathub의 앱을 찾아 설치할 수 있어요. 윈도우의 Microsoft Store 자리예요. 앱은 Flatpak으로 설치돼서 시스템과 떨어져 돌아가요. 시스템 패키지(pacman)는 건드리지 않고(PackageKit을 넣지 않았어요), 설치할 때 비밀번호를 물어요. 업데이트는 `sudo robinctl update`가 시스템 다음에 함께 해요.

게임은 Steam으로 해요. 런처에서 "steam"이나 "게임"을 찾으면 "Steam 설치하기"가 나오고, 고르면 앱 스토어의 Steam(Flathub) 페이지가 열려요. Flathub판은 32비트 저장소(multilib)를 켜지 않아도 되고, 그래픽 드라이버(NVIDIA 포함)도 Flatpak이 알아서 맞춰 받아요. 설치하고 나면 "Steam 설치하기" 대신 Steam 앱이 나와요.

## 오피스

설치한 시스템에는 LibreOffice 안정판(`libreoffice-still`)이 한국어로 들어 있어요. Writer는 Word, Calc는 Excel, Impress는 PowerPoint 자리예요. `.docx`, `.xlsx`, `.pptx`를 열고 저장할 수 있지만, 복잡한 서식은 조금 달라 보일 수 있어요. 한글 문서(`.hwp`)는 오래된 형식(한글 97)만 열려요. 요즘 `.hwp`·`.hwpx` 파일은 보내는 사람에게 PDF나 `.docx`로 받는 게 가장 확실해요.

## 동영상과 음악, 기본 앱

설치한 시스템에는 GNOME의 동영상 재생 앱(Showtime)과 오디오 재생기(Decibels)가 있고, MP4(H.264/AAC)도 재생돼요(`gst-libav`). 파일에서 동영상이나 음악을 두 번 누르면 바로 재생돼요.

파일을 어떤 앱으로 여는지는 `desktop/mime/mimeapps.list`(설치 위치 `/etc/xdg/mimeapps.list`)가 정해요. 폴더는 파일, 글 파일은 텍스트 편집기, PDF는 문서 보기, 사진은 이미지 보기, 동영상과 음악은 위 두 앱, 웹 주소는 Firefox예요. 파일 앱에서 "다른 앱으로 열기"로 바꾸면 내 설정(`~/.config/mimeapps.list`)이 먼저예요.

## 화면 배율

글자와 창이 너무 작거나 크면 빠른 설정의 "화면 배율"에서 100%, 125%, 150%, 175%, 200% 중에 골라요(윈도우의 설정 > 디스플레이 > 배율과 같아요). 지금 마우스가 있는 화면에 바로 적용되고, `~/.local/state/robinos/display-scale`에 화면 이름별로 저장돼서 다음 로그인에도 그대로예요(`robinos.lua`가 읽어요). 화면이 정확히 나눠지지 않는 배율이면 Hyprland가 가장 가까운 값으로 맞춰요. 처음에는 Hyprland가 화면 크기를 보고 고른 배율이에요. VM 화면은 창 크기를 따라가는 `robinos-vm-display`가 저장된 배율을 함께 써요.

## 야간 모드와 비행기 모드

빠른 설정에 윈도우와 같은 두 타일이 있어요.

- **야간 모드**: 화면을 따뜻한 색(4500K)으로 바꿔 밤에 눈이 덜 부셔요. `hyprsunset`이 해요. 켠 상태는 다음 로그인에도 그대로예요(셸 상태 폴더의 `desktop.json`, 창 자동 정렬과 같은 곳). 색은 그래픽 드라이버의 색 변환(KMS CTM)으로 바꿔서, 인텔·AMD 같은 실제 그래픽 카드에서만 돼요. VM에서는 타일에 "VM에서는 안 돼요"라고 나와요.
- **비행기 모드**: Wi-Fi와 블루투스를 함께 꺼요. 랜선으로 연결된 인터넷은 그대로예요. 다시 누르면 둘 다 켜져요. NetworkManager와 BlueZ가 상태를 기억해서 다시 켤 때까지 유지돼요.

## Wi-Fi와 블루투스 연결

빠른 설정의 Wi-Fi 타일과 블루투스 타일 오른쪽 화살표를 누르거나 런처에서 "와이파이", "블루투스"를 찾으면 연결 창이 열려요(윈도우 11 빠른 설정의 화살표와 같아요, `desktop/shell/ConnectPanel.qml`).

- **Wi-Fi**: 주변 네트워크가 연결된 것, 저장된 것, 신호가 센 것 순서로 10개까지 나와요. 자물쇠가 있는 네트워크를 처음 고르면 그 아래에 비밀번호 칸이 열리고, 저장된 네트워크와 열린 네트워크는 누르면 바로 연결돼요. 연결된 네트워크를 누르면 끊어요. 숨긴 네트워크, VPN, 고정 IP는 맨 아래 "고급 네트워크 설정 (nmtui)"에서 해요. 창이 열려 있는 동안만 주변을 찾아요.
- **블루투스**: 주변 장치가 연결된 것, 저장된(페어링한) 것 순서로 나와요. 처음 보는 장치를 누르면 페어링하고, 저장된 장치는 누르면 연결, 연결된 장치는 누르면 끊어요. 이어폰처럼 배터리를 알려 주는 장치는 남은 배터리가 보여요. 휴지통 단추는 저장된 장치를 지워요. 창이 열려 있는 동안만 주변 장치를 찾아요.

창 위쪽 단추로 Wi-Fi나 블루투스를 켜고 꺼요. 장치가 없으면(VM이나 유선만 있는 PC) "Wi-Fi 장치가 없어요"처럼 알려 줘요. 창 밖을 누르거나 `Esc`로 닫아요.

## 소리 출력 장치와 앱별 음량

빠른 설정의 음량 막대 오른쪽 화살표를 누르거나 런처에서 "소리", "볼륨 믹서"를 찾으면 소리 창이 열려요(윈도우 11 음량 막대 옆 화살표와 볼륨 믹서를 합친 자리예요, `desktop/shell/SoundPanel.qml`).

- **출력 장치**: 스피커, 이어폰, HDMI 모니터처럼 소리가 나갈 장치를 골라요. 고른 장치에 체크가 붙고, 바와 빠른 설정의 음량도 그 장치 것이 돼요. 블루투스 이어폰은 연결하면 여기에 나와요.
- **입력 장치 (마이크)**: 쓸 마이크를 고르고, 그 아래 막대로 마이크 음량을, 마이크 아이콘으로 끄고 켜요.
- **앱별 음량**: 지금 고른 출력 장치로 소리를 내는 앱마다 음량 막대와 음소거 단추가 있어요.

고른 장치는 WirePlumber가 기억해서 다음 로그인에도 그대로예요. 소리 장치가 없으면 "소리 장치가 없어요"라고 알려 줘요.

## 알림 센터

알림은 오른쪽 아래에 잠깐 떴다가 사라지지만, 바의 종 아이콘이나 `Win+N`으로 여는 알림 센터에 로그인한 뒤 온 알림이 남아 있어요(최근 8개를 보여 주고 30개까지 기억해요). 새 알림이 오면 종 아이콘에 점이 생기고, 알림 센터를 열면 사라져요. "모두 지우기"로 비우고, 맨 아래에서 방해 금지를 켜고 꺼요. 방해 금지가 켜져 있으면 알림이 뜨지 않고 알림 센터에만 쌓여요. 로그아웃하면 기록은 사라져요.

## 트레이 아이콘

Steam, Discord처럼 백그라운드에서 도는 앱의 아이콘이 바 오른쪽(한/A 표시 왼쪽)에 나와요. 윈도우 작업 표시줄의 알림 영역과 같아요. 누르면 앱이 열리고, 오른쪽 버튼은 앱의 메뉴, 가운데 버튼은 앱이 정한 두 번째 동작이에요. 앱은 StatusNotifierItem(SNI) 방식으로 아이콘을 보내요. 입력기(fcitx5)의 아이콘은 한/A 표시와 같은 일을 해서 숨겨요.

## 배경화면

기본 배경화면은 셸이 직접 그려요(점 무늬와 위에서 비치는 빛, 다크·라이트를 따라가요). 내 사진으로 바꾸려면 파일 앱에서 사진을 오른쪽 버튼으로 누르고 "배경으로 설정…"을 골라요. 이미지 보기 앱에서는 메뉴의 "백그라운드로 설정"이에요. 런처에서 "배경화면"이나 "배경 화면"(윈도우 이름)을 찾으면 사진 폴더를 열고 방법을 알려 줘요. 되돌리려면 런처의 "기본 배경화면으로"를 골라요.

두 앱은 Wallpaper 포털에 부탁하는데, Hyprland와 GTK 포털에는 이 기능이 없어서 RobinOS가 작은 포털 백엔드(`desktop/bin/robinos-wallpaper-portal`)를 넣었어요. 고른 사진을 `~/.local/share/robinos/wallpaper/`에 복사하고 그 경로를 `~/.local/state/robinos/wallpaper`에 적으면 셸이 바로 그려요. 포털은 앱이 처음 배경화면을 바꿀 때 허락을 묻는데, 샌드박스 밖의 앱(파일, 이미지 보기)은 셸이 로그인할 때 미리 허락해 둬요. 그런 앱은 어차피 위 파일을 직접 쓸 수 있기 때문이에요. Flatpak으로 설치한 앱은 지금처럼 물어요. 어떤 포털이 어떤 일을 맡는지는 `/etc/xdg/xdg-desktop-portal/hyprland-portals.conf`에 있어요.

## 전원 모드와 배터리

빠른 설정의 "전원 모드"에서 절전, 균형, 최고 성능을 골라요(윈도우의 전원 모드와 같아요). `power-profiles-daemon`이 CPU와 화면 설정을 바꿔요. 최고 성능은 지원하는 CPU에서만 보여요(VM에는 보통 없어요).

노트북에서는 바에 배터리 아이콘과 남은 양이 보이고, 20% 아래로 내려가면 빨갛게 바뀌어요. 전원 없이 쓰다가 10%와 5%가 되면 윈도우처럼 "배터리가 10% 남았어요" 알림이 떠요(`ShellState.qml`). 이 알림은 닫을 때까지 남아 있어요. 거의 다 떨어지면 UPower가 컴퓨터를 잠재우거나 꺼서 작업을 지켜요. 전원을 연결하면 다음 방전 때 다시 알려 줘요.

## 업데이트 알림

설치한 시스템은 로그인하고 3분 뒤, 그다음엔 3시간마다 업데이트가 있는지 봐요(`checkupdates`, 패키지 DB의 사본으로 확인해서 pacman을 막지 않아요). 있으면 바의 빠른 설정 단추에 강조 색 새로 고침 아이콘이 생기고, 빠른 설정 맨 위에 "업데이트 N개가 있어요" 단추가 나와요. 누르면 터미널에서 `sudo robinctl update`가 돌아서 업데이트 전후 스냅샷과 함께 설치해요. 빠른 설정을 열 때도 10분이 지났으면 다시 봐요. 라이브 세션에서는 보지 않아요.

## 프린터

설치한 시스템에서 USB 프린터를 꽂거나 같은 네트워크의 프린터를 쓸 수 있어요. 요즘 프린터는 대부분 드라이버 없이(IPP Everywhere, AirPrint) 인쇄 창에 바로 나와요. 안 나오면 런처에서 "프린터"를 찾아 프린터 설정 앱에서 추가해요. 인쇄 서비스(CUPS)는 처음 쓸 때 켜지고, 네트워크 프린터는 Avahi로 찾아요(`printer.local` 같은 이름). Avahi는 같은 네트워크에 내 컴퓨터 이름을 알리고 5353/udp를 열어 둬요.

## 설정 바꾸기

`~/.config/hypr/hyprland.lua`를 만들고 RobinOS 기본값을 불러온 다음, 바꾸고 싶은 값을 덮어쓰세요.

```lua
require("/usr/share/robinos/hypr/robinos")

hl.config({ general = { gaps_out = 16 } })
hl.bind("SUPER + W", hl.dsp.exec_cmd("firefox"))
```

테마와 강조 색상은 빠른 설정에서 바꿔요. 고른 값은 `~/.local/state/quickshell/`에 저장되고 GTK, libadwaita, foot, qt6ct, Hyprland 창 테두리에 적용돼요.

스크립트에서는 셸 IPC를 쓸 수 있어요.

```bash
qs ipc -p /usr/share/robinos/shell call shell launcher
qs ipc -p /usr/share/robinos/shell call shell setDark false
```

## 검사

```bash
scripts/check-desktop.sh
```

Lua 문법을 확인하고 `Hyprland --verify-config`를 실행해요. 모든 QML 파일은 `qmlformat`으로 파싱해 보고, 데스크톱 스크립트는 `bash -n`으로 검사해요. `Validate` 워크플로가 Arch Linux 컨테이너에서 이 스크립트를 실행해요.
