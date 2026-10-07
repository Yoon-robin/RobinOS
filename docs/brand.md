# RobinOS 브랜드

RobinOS의 정체성은 차분한 보안 워크스테이션이에요. 기술적이고, 믿음직하고, 학습을 우선해요.

## 로고 파일

- `assets/brand/robinos-mark.svg`: 정사각형 앱·아이콘 마크
- `assets/brand/robinos-logo.svg`: 전체 로고 락업
- `assets/brand/robinos-logo-horizontal.svg`: 헤더에 쓰기 좋은 가로형 로고

## 콘셉트

마크에는 이런 요소가 들어 있어요.

- 방패: 안전한 랩 경계와 방어 학습
- 날개 모양: RobinOS의 정체성과 앞으로 나아가는 움직임
- 터미널 프롬프트: 직접 손으로 하는 리눅스·보안 실습
- 빨간 강조색: RobinOS의 대표 색

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
- 코드와 터미널: Geist Mono / GeistMono Nerd Font
- 모서리 반경: 6 (작은 요소), 8 (입력창, 버튼), 10 (카드), 14 (창, 팝오버), 18 (독)
- 아이콘: Lucide 선 아이콘, 24px 그리드에 2px 선

로고 파일(`assets/brand/*.svg`)도 이 팔레트를 따라요. 위쪽 날개와 가로줄만 Robin red이고, 방패와 아래쪽 날개, 설명 글은 zinc 색이에요. 배경화면 SVG(`assets/wallpapers/`)와 GRUB 테마(`themes/grub/robinos`)도 같아요. GRUB 메뉴는 고른 항목만 Robin red예요.

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
