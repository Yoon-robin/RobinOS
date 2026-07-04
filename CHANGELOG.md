# Changelog

## [Unreleased]

### Added
- **전용 설치기 `robinos-install`(베타)** — 라이브를 디스크로 rsync 미러링해 설치본==RobinOS.
  chroot에서 실제 사용자·부트로더(UEFI systemd-boot / BIOS GRUB)·initramfs 구성. VM 테스트 예정.
- 비root 라이브 사용자 `robin`(무비번 autologin, sudo) — root 대신 일반 사용자로 데스크톱 실행,
  per-user 파이프와이어로 오디오 정상화. Hyprland `--i-am-really-stupid` 불필요.
- swaync 알림센터 RobinOS 브랜딩(다크+블루, 한국어 라벨) + hypridle(유휴 시 화면 절전).
- 스크린샷을 `~/Pictures`에 저장 + 알림(`robinos-screenshot`).
- Robin 비서: 볼륨/밝기 현재값 조회, `robin config`(설정 보기), `robin ask <질문>`(LLM 강제).
- Plymouth 부트 스플래시(커스텀 테마) + hyprlock 로그인/잠금 화면(둘 다 실기기 시각확인 대기).

### Added (이전)
- 초기 프로젝트 골격 (Arch `releng` 위에 RobinOS 레이어를 얹는 방식).
- Hyprland 데스크톱 기본 설정: waybar, wofi, swaync, kitty, hyprpaper, 한글 입력(fcitx5).
- RobinOS 브랜딩: os-release, 배경화면(SVG → 빌드 시 PNG 렌더), 부트 메뉴 텍스트.
- 빌드 파이프라인: `build/build.sh`, 로컬 Docker 빌드, GitHub Actions ISO 빌드.
- QEMU 부팅 테스트 스크립트.
- **Robin 비서** (시그니처): 내장 CLI `robin` — 오프라인 명령 파서(볼륨/밝기/앱실행/
  네트워크/잠금/웹검색/상태) + 선택적 Ollama LLM 폴백. 터미널 환영(`robin welcome`),
  waybar Robin 버튼, SUPER+A 단축키. 파서 회귀 테스트 20케이스 + CI 검증.

- 데스크톱 첫 환영 알림(libnotify) + Robin 비서 확장: 전원(종료/재부팅/로그아웃,
  확인 후)·스크린샷·앱 목록·볼륨/밝기 퍼센트 지정.

### Fixed
- 터미널 환영을 `/etc/zsh/zshrc.local`로 이동 — `/etc/skel/.zshrc`가 `grml-zsh-config`
  와 충돌(`exists in filesystem`)하던 문제 해결.
- `/usr/local/bin` 스크립트 실행 권한을 `file_permissions`로 강제 (ISO에서 실행 안 되던 문제).
- 라이브(root)에서 Hyprland가 실행 거부 → `--i-am-really-stupid`로 우회. VM에선 소프트웨어
  렌더링 폴백 + 크래시 루프 제거.
- Hyprland 설정 경고 정리(`pseudotile`/`togglesplit`), 배경을 swaybg로 교체(VM 안정성).

### Verified
- VMware에서 라이브 ISO 부팅 → 자동 로그인 → Hyprland 데스크톱 렌더 + fcitx5(한글) + swaync 확인.
