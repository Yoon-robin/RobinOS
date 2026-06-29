# RobinOS

Arch Linux 기반의 개인용 OS. 실제로 USB로 부팅·설치되는 라이브 ISO를 만든다.

데스크톱은 **Hyprland**(Wayland 컴포지터)를 쓴다. 가볍고, 애니메이션·블러·둥근 모서리 같은
시각 효과가 강하며 Arch 생태계에서 가장 활발하다. 베이스는 공식 Arch 그대로 두고 그 위에
RobinOS 패키지 세트·데스크톱 설정·브랜딩만 얹는 구조라 "Arch처럼" 동작하면서도 켜자마자
완성된 데스크톱이 뜬다.

## 구조

```
RobinOS/
├─ iso/
│  ├─ packages.x86_64        # releng 패키지 위에 더할 RobinOS 패키지
│  ├─ airootfs/              # 시스템 고정 경로에 들어갈 파일 (os-release 등)
│  └─ skel/                  # 사용자 홈 dotfiles (Hyprland/waybar/kitty…)
├─ branding/                 # 배경화면·로고 (SVG → 빌드 때 PNG로 렌더)
├─ build/build.sh            # releng 복사 → RobinOS 레이어 머지 → mkarchiso
├─ scripts/
│  ├─ build-docker.sh        # 로컬 Docker로 ISO 빌드
│  └─ test-qemu.sh           # QEMU로 부팅 테스트
├─ .github/workflows/        # 푸시하면 ISO 자동 빌드 (아티팩트로 다운로드)
└─ docs/                     # BUILD.md, DESIGN.md
```

## 빌드 방법

이 빌드는 Arch 환경이 필요하다. 세 가지 중 하나:

1. **GitHub Actions (기본)** — `main`에 푸시하거나 Actions 탭에서 수동 실행하면
   Arch 컨테이너에서 ISO를 굽고 아티팩트로 올린다. Linux 환경이 따로 없어도 된다.
2. **로컬 Docker** — Docker가 깔려 있으면 `bash scripts/build-docker.sh`.
3. **로컬 Arch** — Arch에서 직접 `sudo bash build/build.sh`.

자세한 내용은 [docs/BUILD.md](docs/BUILD.md), 디자인 방향은 [docs/DESIGN.md](docs/DESIGN.md).

## 상태

**라이브 ISO 동작 확인됨** (VMware): 부팅 → 자동 로그인 → Hyprland 데스크톱(테마·waybar·
배경) + fcitx5 한글 입력 + Robin 비서까지 렌더. GPU 가속 없는 VM에선 소프트웨어 렌더링으로
자동 폴백한다.

설치는 `archinstall` 포함(전용 RobinOS 설치기는 이후 단계).

### RobinOS만의 것
- **Robin 비서** — 내장 CLI(`robin`). 한국어로 시스템 제어: 볼륨/밝기(퍼센트 지정)·앱 실행·
  네트워크·스크린샷·웹 검색·전원(확인 후)·상태. 터미널 환영·waybar 버튼·`SUPER+A`. 선택적
  로컬 LLM(Ollama) 연동.
- **시그니처 디자인** — 다크 + 블루/퍼플(`#78aaff`→`#7d5fff`), 커스텀 애니메이션 이징, 배경화면.
- **전원 메뉴** — `SUPER+Escape` (wofi).

### 다음
부트 스플래시(Plymouth)·로그인 화면 브랜딩, 전용 설치기, 비root 라이브 사용자, OSINT 에디션.
