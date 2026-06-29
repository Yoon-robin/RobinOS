# Changelog

## [Unreleased]

### Added
- 초기 프로젝트 골격 (Arch `releng` 위에 RobinOS 레이어를 얹는 방식).
- Hyprland 데스크톱 기본 설정: waybar, wofi, swaync, kitty, hyprpaper, 한글 입력(fcitx5).
- RobinOS 브랜딩: os-release, 배경화면(SVG → 빌드 시 PNG 렌더), 부트 메뉴 텍스트.
- 빌드 파이프라인: `build/build.sh`, 로컬 Docker 빌드, GitHub Actions ISO 빌드.
- QEMU 부팅 테스트 스크립트.
- **Robin 비서** (시그니처): 내장 CLI `robin` — 오프라인 명령 파서(볼륨/밝기/앱실행/
  네트워크/잠금/웹검색/상태) + 선택적 Ollama LLM 폴백. 터미널 환영(`robin welcome`),
  waybar Robin 버튼, SUPER+A 단축키. 파서 회귀 테스트 20케이스 + CI 검증.

### Fixed
- 터미널 환영을 `/etc/zsh/zshrc.local`로 이동 — `/etc/skel/.zshrc`가 `grml-zsh-config`
  와 충돌(`exists in filesystem`)하던 문제 해결.
