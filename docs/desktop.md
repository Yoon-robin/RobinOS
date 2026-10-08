# RobinOS 데스크톱

RobinOS는 Hyprland 위에 직접 만든 Quickshell 셸을 얹어 써요. 디자인은 shadcn/ui의 zinc 팔레트를 따르고, 기본값은 윈도우에서 넘어온 사용자에게 맞췄어요. 왜 이렇게 만들었는지는 `docs/design.md`에 있어요.

## 구성 요소

| 부분 | 프로그램 | 저장소 안 위치 |
|---|---|---|
| 컴포지터 | Hyprland 0.56+ (Lua 설정) | `desktop/hypr/robinos.lua` |
| 셸: 상단 바, 독, 런처, 빠른 설정, 알림, 볼륨 표시, 배경화면, 환영 마법사 | Quickshell 0.3 | `desktop/shell/` |
| 세션 시작, 렌더링 자동 전환 | `robinos-session` | `desktop/bin/robinos-session` |
| 셸 다시 띄우기, 셸 렌더링 전환 | `robinos-shell` | `desktop/bin/robinos-shell` |
| VM 화면을 창 크기에 맞추기 | `robinos-vm-display` | `desktop/bin/robinos-vm-display` |
| 로그인 화면 | SDDM (Qt 6 테마) | `themes/sddm/robinos/` |
| 잠금 화면과 대기 | hyprlock, hypridle | `desktop/hypr/hyprlock.conf`, `hypridle.conf` |
| 터미널 | foot | `desktop/foot/foot.ini` |
| 파일, 브라우저 | Nautilus, Firefox | - |
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
| `Super+S` | 빠른 설정 |
| `Super+N` | 알림 지우기 |
| `Super+Return` | 터미널 |
| `Super+E` | 파일 |
| `Super+B` | 브라우저 |
| `Super+L` | 화면 잠금 |
| `Alt+Tab`, `Alt+Shift+Tab` | 다음 창 / 이전 창 |
| `Alt+F4` 또는 `Super+Q` | 창 닫기 |
| `Super+D` | 바탕 화면 보기 (지금 작업 공간의 창을 모두 숨기고, 다시 누르면 돌아와요) |
| `Super+T` | 창을 자유 배치와 타일 배치 사이에서 전환 |
| `Super+F`, `Super+M` | 전체 화면, 최대화 |
| `Super+1`...`Super+9` | 작업 공간 전환 (`Shift`를 같이 누르면 창을 옮겨요) |
| `Super+방향키` | 그쪽 창으로 포커스 이동 (`Shift`를 같이 누르면 창을 옮겨요) |
| `Super+마우스 휠` | 이웃 작업 공간으로 |
| `Super+drag` | 창 이동(왼쪽 버튼), 크기 조절(오른쪽 버튼) |
| `Print`, `Shift+Print` | 영역 또는 전체 화면을 찍어 `~/Pictures/Screenshots`와 클립보드에 저장 |
| `Right Alt` | 한/영 전환 (`Right Ctrl`은 한자) |
| `Super+Shift+Escape` | 로그아웃 |

새 창은 윈도우처럼 자유 배치로 떠요. 빠른 설정에서 "창 자동 정렬" 스위치를 켜면 새 창이 타일로 배치돼요.

독의 앱 아이콘은 윈도우 작업 표시줄처럼 동작해요. 앱이 꺼져 있으면 열고, 창이 뒤에 있으면 앞으로 가져오고, 이미 앞에 있으면 최소화하고, 최소화돼 있으면 원래 작업 공간으로 되돌려요. 창이 여러 개면 차례로 앞으로 가져와요. 최소화한 창은 숨은 작업 공간(`special:minimized`)에 있고, 독에는 계속 실행 중(점)으로 보여요. 셸 IPC로도 같은 동작을 할 수 있어요: `qs ipc -p /usr/share/robinos/shell call shell toggleApp foot`.

마우스 없이도 쓸 수 있어요. 런처, 빠른 설정, 환영 마법사, 설치기에서 `Tab`으로 버튼과 선택지를 옮겨 다니고(포커스가 테두리로 보여요), `Enter`나 `Space`로 눌러요. 볼륨 같은 슬라이더는 화살표 키로 5%씩, `Home`과 `End`로 끝까지 움직여요.

## 윈도우 명령 힌트

`~/.bashrc`가 `desktop/bash/robinos-hints.sh`를 불러와요. 터미널에 윈도우 명령을 치면 같은 일을 하는 리눅스 명령을 알려 줘요.

```text
$ ipconfig
ipconfig 명령은 윈도우용이에요. 리눅스에서는
  ip a  IP 주소와 네트워크 장치를 보여 줘요
```

명령 30개쯤을 알아들어요(`dir`, `cls`, `cd..`, `copy`, `del`, `tasklist`, `tracert`, `netstat`, `findstr`, `notepad` 등). 새로 만드는 사용자는 `/etc/skel/.bashrc`로 바로 쓸 수 있고, 설치하는 사용자의 `~/.bashrc`에는 `scripts/post-install.sh`가 넣어 줘요.

## 환영 마법사

처음 로그인하면 환영 마법사가 떠요(`desktop/shell/Welcome.qml`). 다섯 단계예요.

1. RobinOS 소개
2. 다크/라이트와 강조 색상. 고르는 즉시 화면에 적용돼요.
3. 한/영 전환 단축키. 한/영 키와 오른쪽 Alt는 항상 되고, Ctrl+Space(기본), Shift+Space, 없음 중에서 하나를 더 골라요. `~/.config/fcitx5/config`를 다시 쓰고 `fcitx5-remote -r`로 바로 적용해요. 입력 칸에서 직접 바꿔 볼 수 있어요.
4. 학습 목표: 리눅스 기초, 웹 보안, 먼저 둘러보기
5. 단축키 안내. "미션 시작하기"를 누르면 고른 목표가 터미널에서 열려요.

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
| 볼륨 믹서 | 음량 조절 (pavucontrol) |
| Acrobat, `pdf` | 문서 뷰어 (Evince) |
| 제어판, `control panel` | 빠른 설정 |

목록은 `desktop/shell/Launcher.qml`의 `windowsNames`에 있어요.

## 학습 미션

런처의 "학습 미션"을 고르면 터미널이 열리고 `robinctl learn`이 미션 목록과 진행도를 보여 줘요. 미션은 그 터미널에서 직접 풀고, `robinctl learn check`로 확인해요. 리눅스 기초 5개와 네트워크 기초 5개가 있고, 자세한 내용은 [README](../README.md#학습-미션)에 있어요.

셸이 작업용으로 여는 터미널은 `ROBINOS_NO_GREETING=1`로 시작해서 `~/.bashrc`가 fastfetch를 띄우지 않아요. fastfetch는 한국어 라벨로 짧게 줄인 설정(`desktop/fastfetch/config.jsonc` → `/etc/xdg/fastfetch/config.jsonc`)을 써요.

## 라이브 세션

라이브 ISO는 `robin` 계정(비밀번호 `robin`)으로 RobinOS 세션에 자동 로그인해요. 비밀번호 없는 sudo는 라이브 ISO에만 설정돼 있어요(`/etc/sudoers.d/10-robinos-live`).

라이브 ISO에는 가벼운 보안 도구(nmap, tcpdump, netcat, dig, sqlmap, binwalk 같은 것)만 들어 있어요. Wireshark 화면 앱, john, hashcat, Docker(웹 랩), 가상 머신 도구는 크기가 커서 빠져 있고, 설치한 시스템에서 `sudo robinctl profile <이름>`으로 넣어요. 라이브 세션은 메모리 위에서 돌아서 큰 묶음이나 랩 이미지를 받을 자리가 거의 없어요.

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
