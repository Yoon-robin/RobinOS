# RobinOS 데스크톱

RobinOS는 Hyprland 위에 직접 만든 Quickshell 셸을 얹어 써요. 디자인은 shadcn/ui의 zinc 팔레트를 따르고, 기본값은 윈도우에서 넘어온 사용자에게 맞췄어요. 왜 이렇게 만들었는지는 `docs/design.md`에 있어요.

## 구성 요소

| 부분 | 프로그램 | 저장소 안 위치 |
|---|---|---|
| 컴포지터 | Hyprland 0.56+ (Lua 설정) | `desktop/hypr/robinos.lua` |
| 셸: 상단 바, 독, 런처, 빠른 설정, 알림, 볼륨 표시, 배경화면, 환영 마법사 | Quickshell 0.3 | `desktop/shell/` |
| 세션 시작, 렌더링 자동 전환 | `robinos-session` | `desktop/bin/robinos-session` |
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
```

Geist와 Pretendard는 Arch 저장소에 없어요. `scripts/fetch-fonts.sh`가 버전을 고정해 둔 릴리스를 내려받아 SHA-256 체크섬을 확인하고 `/usr/share/fonts/robinos`에 설치해요. ISO를 만들 때는 `scripts/prepare-archiso.sh`가, 설치된 시스템에서는 `scripts/post-install.sh`가 이 스크립트를 실행해요.

## VM 렌더링

`robinos-session`이 Hyprland를 어떤 방식으로 시작할지 정해요.

1. 3D 가속이 없는 그래픽 드라이버(`hyperv_drm`, `bochs`, `simpledrm`, `qxl` 등)를 쓰거나 DRM 렌더 노드가 없으면 소프트웨어 렌더링으로 시작해요.
2. 그 밖에는 GPU 가속으로 Hyprland를 시작해요. 8초 안에 종료되면 세션이 소프트웨어 렌더링으로 다시 시작해요.
3. `ROBINOS_RENDER=software`에서는 Hyprland의 블러와 그림자를 끄고, 셸도 그림자 효과를 그리지 않아요.

로그는 `~/.local/state/robinos/session.log`에 남아요. 렌더링 방식을 직접 정하고 싶으면 `~/.bash_profile`에서 `ROBINOS_RENDER=software`나 `ROBINOS_RENDER=hardware`를 export하면 돼요.

QEMU에서 GPU 가속으로 테스트하려면 `scripts/run-vm.sh --gl`을 실행하세요.

## 단축키

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
| `Super+T` | 창을 자유 배치와 타일 배치 사이에서 전환 |
| `Super+F`, `Super+M` | 전체 화면, 최대화 |
| `Super+1`...`Super+9` | 작업 공간 전환 (`Shift`를 같이 누르면 창을 옮겨요) |
| `Super+drag` | 창 이동(왼쪽 버튼), 크기 조절(오른쪽 버튼) |
| `Print`, `Shift+Print` | 영역 또는 전체 화면을 찍어 `~/Pictures/Screenshots`와 클립보드에 저장 |
| `Right Alt` | 한/영 전환 (`Right Ctrl`은 한자) |
| `Super+Shift+Escape` | 로그아웃 |

새 창은 윈도우처럼 자유 배치로 떠요. 빠른 설정에서 "창 자동 정렬" 스위치를 켜면 새 창이 타일로 배치돼요.

## 윈도우 명령 힌트

`~/.bashrc`가 `desktop/bash/robinos-hints.sh`를 불러와요. 터미널에 윈도우 명령을 치면 같은 일을 하는 리눅스 명령을 알려 줘요.

```text
$ ipconfig
ipconfig은(는) 윈도우 명령이에요. 리눅스에서는
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

## 리눅스 기초 미션

런처의 "리눅스 기초 미션"을 고르면 터미널이 열리고 `robinctl learn`이 미션 목록과 진행도를 보여 줘요. 미션은 그 터미널에서 직접 풀고, `robinctl learn check`로 확인해요. 자세한 내용은 [README](../README.md#리눅스-기초-미션)에 있어요.

셸이 작업용으로 여는 터미널은 `ROBINOS_NO_GREETING=1`로 시작해서 `~/.bashrc`가 fastfetch를 띄우지 않아요.

## 라이브 세션

라이브 ISO는 `robin` 계정(비밀번호 `robin`)으로 RobinOS 세션에 자동 로그인해요. 비밀번호 없는 sudo는 라이브 ISO에만 설정돼 있어요(`/etc/sudoers.d/10-robinos-live`).

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
