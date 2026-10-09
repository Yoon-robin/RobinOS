# RobinOS 설계

> 확정: 2026-10-07 · 기반 Arch Linux + Hyprland + Quickshell

## 한 줄 정의

**윈도우에서 넘어와 매일 쓰는 컴퓨터. 쓰다 보면 리눅스와 보안 실력이 느는 OS.**

## 대상

- 리눅스를 처음 써 보는 윈도우 사용자
- 보안(CTF, 웹 보안, 포렌식, 리버싱)을 배우고 싶은 학생과 입문자
- 한국어 사용자가 기본. 첫 부팅부터 한국어 화면과 한글 입력이 돼요.

학습용이면서 **매일 쓰는 컴퓨터**라는 걸 전제로 해요. 실습 때문에 일상 사용이 불안해지면 안 돼요.

## 설계 원칙

1. **익숙하게 시작**: 윈도우 사용자가 설명 없이 쓸 수 있어야 해요. 창은 기본으로 자유롭게 띄우고, 하단 작업 표시줄과 윈도우 단축키를 그대로 써요.
2. **조금씩 리눅스로**: 화면에서 한 동작을 터미널로는 어떻게 하는지 보여 줘요. 윈도우 용어로 검색해도 찾아지고, 터미널에 윈도우 명령을 치면 리눅스 명령을 알려 줘요.
3. **망가뜨려도 괜찮게**: 업데이트 전에 자동으로 스냅샷을 만들고, 부팅 메뉴에서 이전 상태로 되돌릴 수 있어요.
4. **배우는 순서가 보이게**: 학습 센터가 미션 단위로 다음에 배울 것을 알려 주고, 결과를 자동으로 확인해요.
5. **허가받은 곳에서만**: 실습 대상은 내 컴퓨터 안에서만 열려요(`127.0.0.1`, 컨테이너). 실제 대상을 공격하는 기능은 기본으로 넣지 않아요. 자세한 기준은 [ethics.md](ethics.md)에 있어요.

## 일상 공간과 실습 공간

| | 일상 공간 | 실습 공간 |
|---|---|---|
| 용도 | 브라우저, 문서, 파일, 메신저 | 보안 도구, 취약한 실습 대상 |
| 실행 위치 | 호스트 시스템 | 컨테이너(Docker), 필요하면 VM |
| 네트워크 | 일반 | 실습 대상은 `127.0.0.1`에만 노출 |
| 실패했을 때 | 스냅샷으로 되돌리기 | 랩을 지우고 다시 만들기 |

보안 도구는 처음부터 전부 깔지 않아요. 학습 단계에 맞춰 `robinctl profile`로 필요한 묶음만 설치해서 일상 시스템을 가볍게 유지해요. 묶음은 `network`, `web`, `forensics`, `reversing`, `passwords`, `wireless`, `vm`이고(`security`는 전부), 목록은 `packages/security-baseline.txt`의 `# profile:` 구역이에요.

## 실사용 요구사항

| 영역 | 요구사항 | 구현 |
|---|---|---|
| 설치 | 윈도우를 지우지 않고 나란히 설치, 부팅할 때 선택 | 자체 설치기(아래 "설치기"), GRUB + os-prober |
| 업데이트 | 업데이트로 망가져도 복구 가능 | `snapper` + `snap-pac`(pacman 전후 자동 스냅샷) + `grub-btrfs`(부팅 메뉴에서 스냅샷 부팅) |
| 앱 | 앱 스토어, 브라우저, 오피스, 동영상·음악, 게임 | Flatpak + Flathub(GNOME 소프트웨어), Firefox, LibreOffice, Showtime·Decibels(동영상·음악), Steam(Flathub판, 런처의 "Steam 설치하기") |
| 하드웨어 | Wi-Fi, 블루투스, 프린터, 노트북 전원, NVIDIA | NetworkManager, BlueZ, CUPS, UPower, `nvidia-open` |
| 파일 | 윈도우 파티션과 USB 읽기/쓰기 | `ntfs-3g`, `exfatprogs` |
| 한국어 | 한국어 화면, 한글 입력, 한글 글꼴 | `ko_KR.UTF-8`, fcitx5-hangul(오른쪽 Alt = 한/영), Pretendard |

**알려진 한계**: 윈도우 전용 보안 프로그램을 요구하는 은행·공공기관 사이트는 리눅스에서 안 되는 경우가 많아요. 그래서 윈도우 듀얼 부팅을 기본 시나리오로 잡아요.

## 학습 설계

1. **학습 센터 앱**: 리눅스 기초 → 네트워크 → 웹 보안 → 포렌식 → 리버싱 순서의 미션. 미션은 실제 터미널에서 풀고, `robinctl`이 결과를 확인해 진행도를 저장해요. 셸 기초(환경 변수, PATH, 별명, 스크립트 인자, 종료 코드)와 시스템 기초(작업 관리자·서비스·이벤트 뷰어에 해당하는 프로세스, 디스크, 서비스, 시스템 기록)는 리눅스 기초의 다음 단계지만 26~35번으로 붙였어요(2026-10-09). 보안 기초(사용자와 그룹, 파일 권한, SSH 열쇠, 내려받은 파일 검사, 암호화)는 웹 보안 랩 전에 알아야 할 방어 쪽 기본기라 36~40번이에요. 이미 푼 사람의 진행도 번호가 바뀌지 않게 하려고요.
2. **윈도우 → 리눅스 번역**
   - 런처에서 윈도우 용어로 검색: "제어판" → 설정, "작업 관리자" → 시스템 모니터, "메모장" → 텍스트 편집기
   - 터미널에서 윈도우 명령 입력: `ipconfig` → "리눅스에서는 `ip a`예요"
3. **실습 랩**: 웹 랩(Juice Shop, DVWA)부터 시작해서 네트워크 스캔 랩, 로컬 CTF 문제, 포렌식 샘플로 늘려요. 입문 CTF 10문제(`robinctl ctf`, 2026-10-10에 5문제에서 늘림), 네트워크 스캔 랩(`robinctl lab start net`), 포렌식·리버싱 연습 파일은 들어갔어요(2026-10-09).
4. **환영 마법사**: 첫 로그인 때 테마, 한/영 키, 학습 목표를 고르고 짧은 투어를 해요. 고른 학습 목표는 마지막에 바로 열려요(리눅스 기초 미션 또는 웹 랩 안내).

## 기술 결정

### 기반: Arch Linux

- Hyprland와 Quickshell 최신판이 공식 저장소에 있어요(2026-10 기준 Hyprland 0.56.2, Quickshell 0.3.2). Hyprland는 버전마다 설정 문법이 바뀔 만큼 빠르게 변해서 최신 패키지가 중요해요.
- 공식 ISO 도구(`archiso`)가 있어요.
- 보안 도구가 최신이고, 필요하면 BlackArch 저장소를 붙일 수 있어요.
- Debian 기반인 Kali의 변형으로 보이지 않아요.
- 단점은 롤링 업데이트의 위험이에요. 자동 스냅샷과 부팅 메뉴 되돌리기를 v0.1 필수 기능으로 둬서 보완해요.

검토한 대안: Debian 안정판은 Hyprland와 Quickshell이 한 단계씩 뒤처져요. Ubuntu LTS와 Fedora는 둘 중 하나가 없거나 구버전이에요. NixOS는 파일 구조가 일반 리눅스와 달라 학습용으로 맞지 않아요. openSUSE Tumbleweed가 차선이지만 Quickshell을 직접 패키징해야 해요.

시스템 이름(2026-10-09 결정): `/usr/lib/os-release`를 `NAME="RobinOS"`, `ID=robinos`, `ID_LIKE=arch`로 적어요(`desktop/bin/robinos-os-release`). fastfetch, `hostnamectl`, 다른 배포판의 부팅 메뉴(os-prober)에 RobinOS로 나오고, Arch를 찾는 도구는 `ID_LIKE`로 알아봐요. EndeavourOS 같은 Arch 기반 배포판과 같은 방식이에요. archinstall 4.5는 os-release를 읽지 않는 것을 패키지에서 확인했어요. 이 파일은 `filesystem` 패키지 것이라 업그레이드 때마다 Arch 것으로 돌아가서, pacman 훅이 다시 적어요. `robinctl doctor`는 "RobinOS (Arch Linux 기반)"으로 보여 줘요. 문제를 검색할 때는 Arch 위키가 가장 잘 맞기 때문이에요.

### 데스크톱: Hyprland + Quickshell

- **Hyprland**: 창 관리(컴포지터). 설정은 Lua(`desktop/hypr/robinos.lua`).
- **Quickshell**: 상단 바, 작업 표시줄(독), 런처, 빠른 설정, 알림, 볼륨 표시, 배경화면을 QML로 직접 그려요(`desktop/shell/`).
- **hyprlock / hypridle**: 잠금 화면과 대기 정책
- **foot**: 터미널. **Nautilus**: 파일. **Firefox**: 브라우저.

### 윈도우 사용자 배려

| 윈도우 | RobinOS |
|---|---|
| 창을 자유롭게 띄움 | 기본은 자유 배치. 빠른 설정의 "창 자동 정렬"을 켜면 Hyprland 타일링을 배울 수 있어요. |
| 작업 표시줄 | 하단 독: 시작(런처), 고정 앱, 실행 중인 앱. 아이콘을 누르면 열기, 앞으로 가져오기, 최소화, 되돌리기 |
| `Win+D` (바탕 화면 보기) | `Super+D`, 다시 누르면 창이 돌아와요 |
| 시작 메뉴 (Win) | `Super+Space` 또는 독의 런처 버튼 |
| `Alt+Tab`, `Alt+F4` | 그대로 동작 |
| `Win+E`, `Win+L` | 파일, 화면 잠금 |
| `PrtSc`, `Win+Shift+S` (캡처 도구) | 영역 스크린샷(클립보드 + 사진 폴더) |
| `Win+V` (클립보드 기록) | `Super+V`, 런처에 최근 복사한 것이 보여요(로그아웃하면 지워져요) |
| 작업 표시줄 시계 클릭 (달력) | 바의 시계 클릭 또는 `Super+Alt+D` |

화면에 단축키를 보여 줄 때는 윈도우 키를 `Win`이라고 적어요(`Win+S`, `Win+Enter`). 리눅스 이름인 `Super`는 환영 마법사에서 한 번 알려 주고, 기술 문서와 설정 파일에서만 써요.

### 디자인: shadcn/ui와 일치

디자인 기준은 shadcn/ui의 zinc 팔레트예요. 토큰은 `desktop/shell/Theme.qml`이 원본이고, 같은 값을 [brand.md](brand.md), foot, hyprlock, qt6ct 팔레트, SDDM 테마가 따라요.

| 영역 | 일치 수준 | 방법 |
|---|---|---|
| RobinOS가 만드는 독립 앱 (아직 없음) | 동일 | 진짜 shadcn/ui 코드(React + Tailwind)를 Tauri로 감싸요 |
| 데스크톱 셸 (환영 마법사, 설치기, 학습 센터 포함) | 수치 일치 | QML로 같은 색, 간격, 모서리, 글꼴(Geist), 아이콘(Lucide) 재현 |
| 외부 앱 (Firefox, Nautilus, Qt 앱) | 색과 글꼴 | GTK(adw-gtk3, libadwaita), qt6ct 팔레트, 글꼴 설정 |

환영 마법사는 셸 안에 QML로 만들었어요(`desktop/shell/Welcome.qml`, 2026-10 결정). 테마와 한/영 키를 셸의 `Theme`, `ShellState`로 바로 적용할 수 있고, 첫 로그인 직후 셸과 함께 떠야 하며, Tauri 빌드 도구(Rust, Node)를 ISO 빌드에 들이지 않아도 되기 때문이에요.

학습 센터도 처음 계획(Tauri 앱)과 달리 셸 안의 QML 창으로 만들었어요(`desktop/shell/LearnCenter.qml`, 2026-10-09 결정). 환영 마법사와 같은 이유에 더해, 미션을 푸는 터미널 옆에서 진행도가 바로 바뀌어야 해서예요. 셸은 이미 `robinctl`의 진행도 파일을 지켜보고 있고, 미션 목록은 `robinctl learn tsv`에서 읽어서 미션 제목이 `robinctl` 한곳에만 있어요.

다크/라이트와 강조 색상을 바꾸면 셸이 GTK, libadwaita, foot, qt6ct, Hyprland 창 테두리에 한꺼번에 적용해요.

### 설치기: 직접 만든 Quickshell 화면 + Python 백엔드

2026-10 결정. 화면은 셸 안의 `desktop/shell/Installer.qml`이고, 실제 설치는 `installer/robin-install`이 `sgdisk`, `mkfs.btrfs`, `pacstrap`, `grub-install`로 해요. 화면은 계획(디스크, 방식, 사용자)을 표준 입력으로 넘기고, 백엔드의 `@@ <퍼센트> <메시지>` 줄로 진행률을 그려요. 설치 방법은 [install.md](install.md)에 있어요.

Calamares를 쓰지 않은 이유예요.

- Arch 공식 저장소에 없어요. AUR에서 빌드해 RobinOS 전용 저장소를 운영해야 하고, 그 저장소의 서명과 갱신까지 맡아야 해요.
- Qt Widgets 기반이라 shadcn/ui 기준의 셸과 모양을 맞추기 어려워요. 자체 화면은 셸의 `Theme`, 버튼, 입력 칸을 그대로 써요.
- RobinOS에 필요한 설치는 하나로 정해져 있어요(GPT, Btrfs 하위 볼륨, `/efi`, GRUB, 스냅샷 설정). 백엔드는 400줄 남짓이고, VM 설치 테스트(`wsl-build.ps1 install-test -Installer robinos`)가 설치부터 스냅샷 되돌리기까지 확인해요.

### VM 대응: 렌더링 자동 전환

학습자는 VM에서 먼저 써 보는 경우가 많아요. `robinos-session`이 그래픽 환경을 보고 렌더링 방식을 정해요.

1. 3D 가속이 없는 그래픽 드라이버(Hyper-V, QEMU 기본 그래픽 등)는 처음부터 소프트웨어 렌더링으로 시작해요.
2. 그 밖에는 GPU 가속으로 먼저 시작하고, Hyprland가 곧바로 종료되면 소프트웨어 렌더링으로 다시 시작해요.
3. 소프트웨어 모드(`ROBINOS_RENDER=software`)에서는 Hyprland의 블러와 그림자, 셸의 그림자 효과를 꺼서 VM에서도 버벅이지 않게 해요.

Hyprland 0.56은 `start-hyprland`(감시 프로세스)로 띄우라고 하고, 그냥 띄우면 시작할 때 경고를 남겨요. RobinOS는 `robinos-session`이 `Hyprland`를 직접 띄워요(2026-10-09 결정). `start-hyprland`는 Hyprland가 비정상 종료하면 `--safe-mode`로 다시 띄우는데(실행 파일에서 확인), 그러면 위 2번의 "곧바로 종료되면 소프트웨어 렌더링으로" 대처가 동작하지 않아요. 경고는 무시해도 돼요.

## v0.1 범위

| # | 항목 | 상태 |
|---|---|---|
| 1 | VM과 실기기에서 부팅되는 라이브 ISO (Hyprland + RobinOS 셸) | VM 부팅 테스트로 검증(2026-10-08, 데스크톱까지 약 20초), 실기기 검증 전 |
| 2 | 윈도우와 나란히 설치되는 그래픽 설치기 | 완료, VM 설치 테스트로 검증(2026-10-08: 디스크 전체, 가짜 윈도우 디스크 옆에 설치와 부팅 메뉴의 윈도우). 실제 윈도우 PC 확인 전 |
| 3 | 업데이트 전 자동 스냅샷, 부팅 메뉴에서 되돌리기 | 완료, VM 설치 테스트로 검증 (2026-10-08: snap-pac 전후 스냅샷, GRUB 스냅샷 메뉴, `robinctl snapshot rollback`) |
| 4 | 환영 마법사, 리눅스 기초 미션 5개(네트워크·포렌식·리버싱·웹 기초 20개 더), 윈도우 명령어 번역기 | 번역기 완료 (터미널 `desktop/bash/robinos-hints.sh`, 런처 윈도우 이름 검색), 미션 완료 (`robinctl learn`, 2026-10-10 기준 45개: 셸·시스템·보안 기초, 텍스트 다루기 포함), 환영 마법사 완료 (`desktop/shell/Welcome.qml`) |
| 5 | 로컬 전용 웹 보안 랩 | 완료 (`127.0.0.1` 바인딩, 설치 테스트 -Lab으로 실제 실행 확인) |

## 미결정 사항

- **창 제목 표시줄**: Hyprland에는 기본 제목 표시줄이 없고, xdg-decoration 요청에는 언제나 "서버가 그린다"고 답해요. GTK 앱과 Firefox는 자체 단추가 있어요. Qt 앱은 그 프로토콜을 보지 않게 해서 Adwaita 제목 표시줄을 그려요(T-029). foot은 `[csd] preferred=client`로 설정했지만 Hyprland의 답을 따라서 제목 표시줄이 없어요. foot의 제목 표시줄(hyprbars 플러그인 등)은 v0.2에서 다뤄요. 제목 표시줄에는 최소화 단추를 두지 않아요(Hyprland 0.56은 앱의 최소화 요청을 처리하지 않아요). 최소화와 `Win+D`는 독과 `Super+D`로 해요(T-024).
- **화면 읽기(Orca)**: 2026-10-08 조사(T-040). Orca 51은 키 입력을 libatspi의 장치로 받는데, Wayland에서는 `org.freedesktop.a11y.Manager`의 `KeyboardMonitor`(GNOME의 Mutter가 제공)를 써요. Hyprland 0.56.2 소스에는 이 인터페이스가 없어서 Orca의 읽기 명령(Orca 키 조합, 화면 훑기)이 동작하지 않고, 앱이 보내는 포커스 변화만 읽을 수 있어요. 반쪽짜리 내레이터를 기본으로 넣지 않고, Hyprland나 별도 도구가 이 인터페이스를 제공하면 다시 봐요. 셸의 버튼에는 `Accessible.name`을 계속 붙여 둬요.
