# RobinOS 브랜드

RobinOS는 윈도우에서 넘어오는 사람을 위한 한국어 리눅스예요([design.md](design.md)의 "정체성 다시 정하기 ②", 2026-11-24). 모든 화면은 robin-ui V5 키트 하나를 따라요. 키트는 `assets/brand/robin-ui/`에 있고, 견본은 그 폴더의 `index.html`을 브라우저로 열면 돼요.

## 로고 파일

- `assets/brand/robinos-mark.svg`: 정사각형 앱·아이콘 마크. 키트의 마크(`.rk-mark`)와 같은 문법이에요: 거의 검은 네모(`#060a14`, 모서리는 한 변의 7/30) 위에 하얀 울새, 그 둘레에 파란(`#4b7dfe`) 번짐
- `assets/brand/robinos-logo.svg`: 전체 로고 락업 (마크와 이름)
- `assets/brand/robinos-logo-horizontal.svg`: 헤더에 쓰기 좋은 가로형 로고 (README 맨 위)
- `assets/brand/robinos-glyph.svg`: 아주 작은 곳(셸의 바, 런처, 설치기, 로그인 화면)에 쓰는 하얀 울새 실루엣. 키트의 마크처럼 거의 검은 네모(`#060a14`) 위에 올리고, 셸에서는 파란 번짐을 둘러요(`Mark.qml`)
- `assets/brand/robinos-boot-splash.svg`: 라이브 BIOS 메뉴 배경(`themes/syslinux/splash.png`)의 원본
- `assets/brand/build-logo.py`: 위 다섯 파일을 만드는 스크립트. 이름은 글꼴을 윤곽선으로 바꿔 넣어서 글꼴이 없는 곳에서도 똑같이 보여요
- `desktop/fastfetch/robinos-logo.ansi`: 터미널을 열면 fastfetch 옆에 나오는 울새 그림(31×11칸). 글리프를 고치면 `python3 assets/brand/build-terminal-logo.py desktop/fastfetch/robinos-logo.ansi`로 다시 만들고, 알려 주는 크기를 `desktop/fastfetch/config.jsonc`에 적어요(`check-desktop.sh`가 맞는지 봐요)

로고는 키트 색(바탕은 옆 기둥 `#0a0e11`, 마크 네모 `#060a14`, 울새와 이름 `#ffffff`, 번짐만 파랑 `#4b7dfe`)이고, 이름은 Pretendard 650이에요. 한 줄 소개는 없어요(2026-11-24). 다시 만들 때는 `scripts/fetch-fonts.sh /tmp/robinfonts` 뒤에 `python3 assets/brand/build-logo.py /tmp/robinfonts assets/brand`, 라이브 BIOS 메뉴 배경은 `rsvg-convert -w 640 -h 480 assets/brand/robinos-boot-splash.svg -o themes/syslinux/splash.png`예요.

## 콘셉트

**어두운 네모 위에서 파랗게 빛나는 하얀 울새(Robin)** 예요(2026-11-24). 키트의 마크 문법 그대로, 셸의 바·런처·설치기에 있는 작은 마크(`Mark.qml`)와 앱 아이콘, README 로고가 모두 같은 모양이에요.

- 울새: 이름 그대로의 RobinOS. 원 두 개와 부리·꼬리로 만든 둥글고 차분한 실루엣이고, 눈은 뚫려 있어서 파란 번짐이 비쳐요
- 색: 흰 울새와 파란 번짐 둘뿐이에요. 강조색은 파랑(`#4b7dfe`) 하나예요
- 예전 모양(2026-10-09~11-24): 터미널 프롬프트 `> _`의 커서 위에 앉은 회색 부리의 울새. 키트의 마크와 달라서 셸의 작은 마크와 로고가 서로 다른 모양이었어요. 사용자 요청("로고도 키트 스타일로", 2026-11-24)으로 바꿨어요
- 한 줄 소개: 화면에는 이름만 둬요. 키트가 설명 문장을 쓰지 않아서, 로고 아래에도 소개를 넣지 않아요. 정체성("윈도우에서 넘어오는 사람을 위한 한국어 리눅스")은 README와 소개 영상처럼 설명이 필요한 곳에만 써요

## 키트: robin-ui V5

출처: 모양과 값은 Figma Community의 "Recurrence Design"(Jellyx Design, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/))에서 잰 것이에요. 키트를 공개하는 곳(README, 릴리스 노트)에는 이 출처를 같이 적어요. 원래 제품의 이름·로고·그림은 쓰지 않아요.

### 두 가지 문법

화면의 모든 것은 둘 중 하나예요. 만들기 전에 어느 쪽인지 먼저 정해요.

| | 메뉴 | 표시기 |
|---|---|---|
| 무엇 | 면 위에 놓인 것: 창, 옆 기둥, 카드, 줄, 컨트롤 | 떠 있는 것: 상태 칩, 토스트, 알림, 독, 떠 있는 패널 |
| 면 | 푸른 검정 셋: 기둥 `#0a0e11` < 판 `#0e1012` < 카드 `#0f1115`, 1px 선으로 나눠요 | 짙은 면 `#08090b` + 1px 선 + 둘레 그림자 |
| 모서리 | 컨트롤 7, 칩 6, 카드 12, 창 14 | 알약(칩), 토스트 10, 알림 14 |
| 색 | 파랑 하나: 켜짐·고름·링크 | 왼쪽의 짧은 막대가 뜻: 보통·파랑·살구색·빨강 |

### 팔레트

원본은 `assets/brand/robin-ui/robin-ui.css`(그리고 같은 값의 `tokens.json`)이고, 셸은 `desktop/shell/Theme.qml`이 같은 값을 들고 있어요. 고대비(`data-contrast="high"`, 셸은 `Theme.highContrast`)는 면·파란색·알림 색을 그대로 두고 선과 흐린 글자만 진하게 바꾼 토큰 한 벌이에요(선은 모든 면에 3:1, 흐린 글자는 7:1 넘게).

| 키트 토큰 | Theme.qml | 다크 (기본) | 라이트 |
|---|---|---|---|
| side (옆 기둥, 바) | `side`, `barBg` | `#0a0e11` | `#f4f5f7` |
| page (판) | `bg` | `#0e1012` | `#ffffff` |
| card (카드) | `surface` | `#0f1115` | `#f8f8f9` |
| control (단추·입력·타일) | `secondary`, `raised`, `tile` | `#14151c` | `#f1f1f2` |
| chosen (고른 것) | `chosen` | `#222629` | `#dfe3e9` |
| line (선) | `border` | `#181a1d` | `#e3e6eb` |
| control-line | `borderStrong`, `input` | `#26272d` | `#dedee3` |
| head (제목) | `head` | `#f0f0f0` | `#000000` |
| text (글) | `fg` | `#e6e7e9` | `#1a1a1a` |
| soft | `muted` | `#8a8e94` | `#616161` |
| faint | `subtle` | `#7d8187` | `#727272` |
| accent (파랑) | `accent`, `success` | `#4b7dfe` | `#3566e8` |
| accent-fill (파란 채움) | `primary` | `#3d6af0` | `#3566e8` |
| note (살구색, 주의) | `note` | `#c27463` | `#a4523f` |
| alarm (빨강, 실패) | `destructiveSolid` | `#d52236` | `#c0263a` |
| alarm-text | `destructive` | `#e5475a` | `#c0263a` |
| hud (표시기 면) | `panel`, `dockBg` | `#08090b` | `#ffffff` |
| hud-line | `panelBorder` | `#1c1e22` | `#dedee3` |

**초록과 노랑은 쓰지 않아요.** 성공은 파랑, 주의는 살구색, 실패는 빨강이에요. 강조색을 고르는 곳도 없어요(파랑 하나).

### 글꼴과 모양

- 인터페이스: Pretendard(`Pretendard Variable`), 굵기 450 / 550 / 650(`Theme.weight`, `weightStrong`, `weightHead`). 가늘게 바꾸지 않아요
- 코드와 터미널: 키트의 코드 글꼴인 Cascadia예요. 합자(`->`가 화살표 하나로 붙는 것)가 없는 Cascadia Mono를 써요(`ttf-cascadia-code`). 미션 명령의 `>>`, `->`가 친 그대로 보여야 해서예요. 한글은 Noto Sans Mono CJK KR로 이어 그리고, 두 칸을 채우도록 1.15배로 그려요(`56-robinos-fonts.conf`, 터미널에서 "윈 도 우"처럼 벌어지지 않게)
- 모서리: 칩 6, 컨트롤 7, 토스트 10, 카드 12, 창·떠 있는 패널 14. 알약 모양은 표시기에만
- 아이콘: 키트의 선 아이콘(`icons.svg`, 24 칸, 선 1.8, 둥근 끝, 채우지 않음). 셸은 아직 Lucide예요(모양이 거의 같아요). 이모지나 글자 기호로 대신하지 않아요

### 재질과 움직임

- **유리·흐림 없음**: 바, 독, 패널 모두 불투명한 면이에요. Hyprland도 셸에는 블러를 걸지 않아요(`robinos.lua`). 2026-10-12의 macOS 유리(T-152)는 이걸로 바뀌었어요
- **배경화면**: 판 색 위에 파랑의 옅은 번짐 하나와 옅은 점 격자(`Wallpaper.qml`). 다른 색은 없어요
- **움직임**: 짧게(150~240ms, `Theme.durFast`·`dur`·`durSpring`), 들어올 때 4px. "움직임 줄이기"를 켜면 멈춰요
- **창**: 모서리 14, 1px 테두리(다크 `#32343b`·`#181a1d`, 라이트 `#c6cad2`·`#e3e6eb`)

### 지키는 것

1. **설명 문장을 쓰지 않아요.** 제목은 이름, 아랫줄은 사실(날짜·시각·숫자). 문장은 무언가 잘못됐을 때, 켜고 끌 때 따라오는 결과, 한 번 눌러야 보이는 곳에만 둬요
2. **알약은 표시기에만.** 단추·입력 칸은 모서리 7
3. **파란 채움은 한 화면에 하나**(그 화면의 주 동작). 지우기처럼 되돌릴 수 없는 것은 빨간 테 + 빨간 글자, 채운 빨강은 확인 창의 한 단추뿐
4. **상태는 낱말로 말하고** 색은 되풀이만 해요
5. **묶음 이름표는 카드 밖**에, 작고 흐리게. 카드 안에 제목을 넣지 않아요
6. 꾸미려고 지어낸 내용(가짜 숫자, 가짜 설정)을 넣지 않아요

에이전트가 화면을 고칠 때 지킬 규칙은 `assets/brand/robin-ui/AGENTS.md`에 있어요.

## 사용처

지금 쓰는 곳:

- 글리프(`robinos-glyph.svg`, 거의 검은 네모 위의 하얀 울새): 셸의 바·런처·학습 센터·설치기(`desktop/shell/Mark.qml`), SDDM 로그인 화면
- 정사각형 마크(`robinos-mark.svg`): 앱 아이콘(`/usr/share/icons/hicolor/scalable/apps/robinos.svg`), `/usr/share/pixmaps`, SDDM 테마의 `logo.svg`
- 가로형 로고: README 맨 위
- 터미널 울새 그림: fastfetch

## GTK 앱 (파일, 텍스트 편집기, 계산기 등)

GNOME 앱은 RobinOS가 그리지 않지만 같은 면 셋과 파랑 하나를 써요(T-188). `scripts/build-gtk-theme.py`가 `Theme.qml`의 값으로 libadwaita와 adw-gtk3의 이름 붙은 색(`window_bg_color`, `accent_bg_color` 등)을 만들어요. 창·보기 면은 `bg`, 머리줄과 옆 기둥은 `side`, 카드는 `surface`, 팝오버는 `panel`, 채운 파랑은 `primary`예요. 키트에 초록·노랑이 없어서 성공은 파랑, 경고는 살구색 `note`예요. 텍스트 편집기는 창 전체를 GtkSourceView 색 구성으로 칠해서 `robinos`·`robinos-dark` 구성을 따로 만들었어요. 코드의 문법 색은 터미널의 ANSI 색처럼 프로그램의 뜻이라 Adwaita 것을 물려받아요. 모서리, 단추 모양, 글자는 libadwaita 그대로예요(글꼴은 dconf의 Pretendard).

Firefox는 GTK 색이 아니라 자기 회색을 쓰고, 서명 없는 테마는 일반 Firefox가 받지 않아요. 그래서 Firefox의 관리자 설정 파일(autoconfig, `desktop/firefox/robinos.cfg`)이 시작할 때 `desktop/gtk/firefox.css`를 사용자 스타일 시트로 등록해요. 이 파일도 같은 생성기가 만들어요. 탭 줄은 `side`, 도구 모음과 고른 탭은 `bg`, 주소 칸은 컨트롤 면, 패널은 `panel`, 보라 강조색과 채운 단추는 파랑이에요. 시트는 Firefox 자신의 화면(`browser.xhtml`, `about:` 페이지)에만 맞아서 웹 페이지는 건드리지 않아요. autoconfig는 시트 등록 말고는 아무것도 하지 않고, 개인 정보 설정은 그대로 `policies.json`에 있어요. 새 탭의 위젯 몇 개(낱말 퍼즐, "NEW" 표시)는 자기 색을 써서 그대로예요.

Theme.qml의 색을 바꿨으면 `python3 scripts/build-gtk-theme.py`를 다시 돌려요. `check`가 어긋나면 알려 줘요.

쓸 곳:

- 부팅 스플래시(T-150): 정사각형 마크
- 릴리스 노트 머리 그림: 가로형 로고나 전체 로고 락업

## 웹 문법 (랜딩 페이지)

RobinOS 화면(셸, 설정, 로그인)은 위의 키트를 따르고, 랜딩 페이지(`site/`)는 키트를 만든 제품의 **웹사이트** 문법을 따라요(사용자 요청 "neverlose UI로", 2026-11-24). 그 제품의 웹사이트 두 곳을 브라우저에서 열어 계산값으로 쟀어요. 이름·로고·문구·그림은 가져오지 않고 모양과 값만 써요.

- 바탕: 거의 검정 `#0b0b0d`. 글자는 흰색 85%, 제목은 `#f2f2f4`, 흐린 글은 회색 80%
- 머리: 위에 떠 있는 알약 단추 줄(높이 44, 모서리 9999, 흐린 유리 `rgb(80 80 80 / 10%)` + 흐림 12, 1px 밝은 테 6.5% + 그림자 `0 8px 40px rgb(10 10 10 / 40%)`), 그 아래 흐린 유리 탭 줄(탭 높이 36, 고른 탭은 흰색 10% 면)
- 첫 화면: 왼쪽 정렬 큰 제목(48px, 650, 자간 -0.03em), 굵은 낱말 몇 개가 들어간 회색 한 줄, 파란 알약 단추(48 높이)와 유리 알약 단추, 그 아래 실제 창이 원근으로 기울어 서 있고 아래로 바탕에 녹아요
- 절: 제목(30px) + 회색 한 줄, 오른쪽에 알약 동작. 카드는 모서리 12, 1px 밝은 테 5.5% + 같은 그림자, 올리면 테가 10%로
- 코드 카드: `#0f1013` 면에 고정폭 글꼴, 프롬프트는 회색, 리눅스 명령은 파랑
- 바닥: 마크와 이름, 링크 세 단(작은 회색 머리글), 아주 흐린 작은 글
- 움직임: 들어올 때 8px·400ms(`0.22, 1, 0.36, 1`), 올림 130ms, 누름 0.98. 동작 줄이기에서 기울기와 움직임을 멈춰요
- 밝게: 흰 바탕, 흰 유리 알약, 연한 테와 그림자. 시스템 설정을 따라요
- 키트와 다른 점: 알약 모양과 흐린 유리는 웹에서만 써요. 파란 채움도 웹에서는 머리의 "내려받기"와 그 절의 주 동작에 같이 써요. 초록·노랑은 웹에서도 안 써요

화면 사진은 부팅·설치 테스트가 찍은 1600×900 화면에서 창 부분만 잘라 WebP로 넣어요(`site/assets/screens/`). 글꼴은 Pretendard 가변 글꼴을 페이지 글자만 남게 줄인 것이고(`scripts/build-site.py`), 공유 그림(`og.jpg`)은 가로형 로고예요.

## 부팅 브랜딩

1차 부팅 브랜딩에 들어간 파일이에요. 아직 예전 팔레트라 키트 값으로 옮겨요(T-180).

- `themes/grub/robinos`: GRUB 부팅 메뉴 테마
- `themes/sddm/robinos`: SDDM 로그인 테마
- `themes/syslinux/colors.cfg`: 라이브 ISO의 BIOS 부팅 메뉴
- `assets/wallpapers/robinos-default.svg`: 데스크톱 배경화면 그림(셸은 `Wallpaper.qml`이 그려요)
- `assets/wallpapers/robinos-lock.svg`: 로그인·잠금 화면 배경화면
