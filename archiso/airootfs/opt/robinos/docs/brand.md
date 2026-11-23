# RobinOS 브랜드

RobinOS는 예쁜 UI를 가진 OS예요([design.md](design.md)의 "정체성 다시 정하기", 2026-11-24). 모든 화면은 robin-ui V5 키트 하나를 따라요. 키트는 `assets/brand/robin-ui/`에 있고, 견본은 그 폴더의 `index.html`을 브라우저로 열면 돼요.

## 로고 파일

- `assets/brand/robinos-mark.svg`: 정사각형 앱·아이콘 마크
- `assets/brand/robinos-logo.svg`: 전체 로고 락업 (마크와 이름)
- `assets/brand/robinos-logo-horizontal.svg`: 헤더에 쓰기 좋은 가로형 로고 (README 맨 위)
- `assets/brand/robinos-glyph.svg`: 아주 작은 곳(셸의 바, 런처, 설치기, 로그인 화면)에 쓰는 하얀 울새 실루엣. 키트의 마크처럼 거의 검은 네모(`#060a14`) 위에 올리고, 셸에서는 파란 번짐을 둘러요(`Mark.qml`)
- `assets/brand/build-logo.py`: 위 네 파일을 만드는 스크립트. 이름과 한 줄 소개는 글꼴을 윤곽선으로 바꿔 넣어서 글꼴이 없는 곳에서도 똑같이 보여요
- `desktop/fastfetch/robinos-logo.ansi`: 터미널을 열면 fastfetch 옆에 나오는 울새 그림(31×15칸). 마크를 고치면 `python3 assets/brand/build-terminal-logo.py desktop/fastfetch/robinos-logo.ansi`로 다시 만들고, 알려 주는 크기를 `desktop/fastfetch/config.jsonc`에 적어요(`check-desktop.sh`가 맞는지 봐요)

로고는 키트 색(기둥 `#0a0e11`, 울새 `#f0f0f0`, 날개 `#e6e7e9`, 부리·꼬리·다리 `#8a8e94`, 프롬프트 `>`만 파랑 `#4b7dfe`)이고, 이름은 Pretendard 650이에요. 한 줄 소개는 없어요(2026-11-24). 다시 만들 때는 `scripts/fetch-fonts.sh /tmp/robinfonts` 뒤에 `python3 assets/brand/build-logo.py /tmp/robinfonts assets/brand`, 라이브 BIOS 메뉴 배경은 `rsvg-convert -w 640 -h 480 assets/brand/robinos-boot-splash.svg -o themes/syslinux/splash.png`예요.

## 콘셉트

**프롬프트의 커서 위에 앉은 울새(Robin)** 예요(2026-10-09). 원 두 개로 만든 하얀 울새가 터미널 프롬프트 `> _`의 커서 위에 앉아 있어요.

- 울새: 이름 그대로의 RobinOS. 둥글고 차분한 모양
- 터미널 프롬프트 `>`와 커서 `_`: 직접 만든 도구로 손수 다루는 컴퓨터
- 색: 프롬프트의 `>`만 강조색이에요. 2026-11-24부터 강조색은 파랑(`#4b7dfe`)이에요
- 한 줄 소개: 화면에는 이름만 둬요. 키트가 설명 문장을 쓰지 않아서, 로고 아래에도 소개를 넣지 않아요. 정체성("예쁜 UI를 가진 OS")은 README와 소개 영상처럼 설명이 필요한 곳에만 써요

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

원본은 `assets/brand/robin-ui/robin-ui.css`(그리고 같은 값의 `tokens.json`)이고, 셸은 `desktop/shell/Theme.qml`이 같은 값을 들고 있어요.

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
- 코드와 터미널: 키트의 코드 글꼴인 Cascadia예요. 합자(`->`가 화살표 하나로 붙는 것)가 없는 Cascadia Mono를 써요(`ttf-cascadia-code`). 미션 명령의 `>>`, `->`가 친 그대로 보여야 해서예요. 한글은 Noto Sans Mono CJK KR로 이어 그려요
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

쓸 곳:

- 부팅 스플래시(T-150): 정사각형 마크
- 웹사이트와 파비콘, 릴리스 노트 머리 그림: 가로형 로고나 전체 로고 락업. 웹은 `robin-ui.css`를 그대로 써요

## 부팅 브랜딩

1차 부팅 브랜딩에 들어간 파일이에요. 아직 예전 팔레트라 키트 값으로 옮겨요(T-168).

- `themes/grub/robinos`: GRUB 부팅 메뉴 테마
- `themes/sddm/robinos`: SDDM 로그인 테마
- `themes/syslinux/colors.cfg`: 라이브 ISO의 BIOS 부팅 메뉴
- `assets/wallpapers/robinos-default.svg`: 데스크톱 배경화면 그림(셸은 `Wallpaper.qml`이 그려요)
- `assets/wallpapers/robinos-lock.svg`: 로그인·잠금 화면 배경화면
