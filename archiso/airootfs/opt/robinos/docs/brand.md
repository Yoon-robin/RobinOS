# RobinOS 브랜드

RobinOS의 정체성은 차분한 보안 워크스테이션이에요. 기술적이고, 믿음직하고, 학습을 우선해요.

## 로고 파일

- `assets/brand/robinos-mark.svg`: 정사각형 앱·아이콘 마크
- `assets/brand/robinos-logo.svg`: 전체 로고 락업 (마크, 이름, 한 줄 소개)
- `assets/brand/robinos-logo-horizontal.svg`: 헤더에 쓰기 좋은 가로형 로고 (README 맨 위)
- `assets/brand/robinos-glyph.svg`: 아주 작은 곳(셸의 바, 런처, 설치기, 로그인 화면)에 쓰는 하얀 울새 실루엣. 강조색 네모 위에 올려요
- `assets/brand/build-logo.py`: 위 네 파일을 만드는 스크립트. 이름과 한 줄 소개는 Geist·Pretendard를 윤곽선으로 바꿔 넣어서 글꼴이 없는 곳에서도 똑같이 보여요
- `desktop/fastfetch/robinos-logo.ansi`: 터미널을 열면 fastfetch 옆에 나오는 울새 그림(31×15칸). 반 칸 블록 문자 하나에 점 두 개를 그려요. 하얀 부분은 터미널 글자색을 써서 라이트 모드에서는 검은 울새가 돼요. 마크를 고치면 `python3 assets/brand/build-terminal-logo.py desktop/fastfetch/robinos-logo.ansi`로 다시 만들고, 알려 주는 크기를 `desktop/fastfetch/config.jsonc`에 적어요(`check-desktop.sh`가 맞는지 봐요)

## 콘셉트

**프롬프트의 커서 위에 앉은 울새(Robin)** 예요(2026-10-09). 원 두 개로 만든 하얀 울새가 터미널 프롬프트 `> _`의 커서 위에 앉아 있어요.

- 울새: 이름 그대로의 RobinOS. 둥글고 차분한 모양으로, 윈도우에서 넘어온 사람이 겁먹지 않는 친근한 학습 OS를 뜻해요
- 터미널 프롬프트 `>`와 커서 `_`: 매일 쓰면서 직접 손으로 하는 리눅스·보안 실습
- 빨간 강조색: 프롬프트의 `>`에만 써요. 울새 가슴에 빨강을 칠한 안도 그려 봤지만 덩어리처럼 어색해서 뺐어요
- 한 줄 소개: "매일 쓰면서 배우는 보안 학습 OS"

예전 마크(방패, 말풍선, 날개를 겹친 모양)는 작게 보면 무엇인지 읽히지 않고 셸의 `>_` 마크와도 달라서 바꿨어요.

## 팔레트

RobinOS는 shadcn/ui의 zinc 팔레트를 따르고, 강조색은 Robin red 하나만 써요. 원본은 `desktop/shell/Theme.qml`이에요.

| 토큰 | 다크 (기본) | 라이트 |
|---|---|---|
| background | `#09090b` | `#ffffff` |
| surface | `#121214` | `#ffffff` |
| secondary | `#27272a` | `#f4f4f5` |
| foreground | `#fafafa` | `#09090b` |
| muted foreground | `#a1a1aa` | `#71717a` |
| border | 흰색 10% | `#e4e4e7` |
| primary | `#fafafa` | `#18181b` |
| accent (Robin red) | `#e5484d` | `#e5484d` |
| destructive | `#f87171` | `#dc2626` |
| success | `#4ade80` | `#16a34a` |

사용자는 다른 강조색도 고를 수 있어요. 주황 `#f76b15`, 초록 `#30a46c`, 파랑 `#3e63dd`, 보라 `#8e4ec6`, 무채색 `#a1a1aa`.

## 글꼴과 모양

- 인터페이스: Geist, 한글은 Pretendard
- 코드와 터미널: Geist Mono, 한글은 Noto Sans Mono CJK KR
- 모서리 반경: 6 (작은 요소), 8 (입력창, 버튼), 10 (카드), 14 (창, 팝오버), 18 (독)
- 아이콘: Lucide 선 아이콘, 24px 그리드에 2px 선

로고 파일(`assets/brand/*.svg`)도 이 팔레트를 따라요. 배경은 zinc-950(`#09090b`), 울새와 커서는 `#fafafa`, 날개는 `#e4e4e7`, 부리·꼬리·다리와 한 줄 소개는 `#a1a1aa`이고, 프롬프트 `>`만 Robin red예요. 배경화면 SVG(`assets/wallpapers/`)와 GRUB 테마(`themes/grub/robinos`)도 같은 팔레트예요. GRUB 메뉴는 고른 항목만 Robin red예요.

## 사용처

정사각형 마크를 쓰는 곳:

- 앱 아이콘
- 부팅 스플래시
- SDDM 아바타나 배지
- 파비콘

가로형 로고를 쓰는 곳:

- 문서 헤더
- 웹사이트 내비게이션
- 설치기 헤더

전체 로고 락업을 쓰는 곳:

- README 대표 이미지
- 릴리스 노트
- ISO 스플래시 화면

## 부팅 브랜딩

1차 부팅 브랜딩에 들어간 파일:

- `themes/grub/robinos`: GRUB 부팅 메뉴 테마
- `themes/sddm/robinos`: SDDM 로그인 테마
- `assets/wallpapers/robinos-default.svg`: 데스크톱 배경화면
- `assets/wallpapers/robinos-lock.svg`: 로그인·잠금 화면 배경화면
