# 변경 로그 (Changelog)

RobinOS의 주요 변경을 기록합니다. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따릅니다.
ISO는 [Releases](../../releases)에서 받을 수 있어요(일반 빌드). AI 내장 ISO는 빌드 아티팩트로 제공됩니다.

## [Unreleased]

### Added — 추가
- **AI 비서 내장**: Ollama + `huihui_ai/qwen2.5-abliterate:7b` 모델을 ISO에 임베드 → Robin이 규칙 기반에서 **진짜 LLM**으로. 부팅 시 Ollama가 감지되면 자동으로 LLM 두뇌를 사용(없으면 규칙 두뇌). LLM이 앱 실행·테마·밝기·볼륨·Wi-Fi·블루투스·스크린샷을 직접 제어.
- **소프트웨어 센터**: `apt` 패키지 검색·설치(pkexec 인증) + 인기 앱 추천 칩.
- **실제 파일시스템**: Finder·메모가 리눅스 robin 홈의 **진짜 파일**을 읽고 씀(웹은 가상 유지).
- **Wi-Fi 연결 UI**(nmcli) / **블루투스 페어링**(bluetoothctl): 설정에서 검색·연결.
- **시간대**(timedatectl) / **디스플레이 해상도**(wlr-randr) 설정.
- **스크린샷**(grim), **알림 센터**(토스트 히스토리), **메뉴바 배터리·Wi-Fi 실시간 상태**.
- 런치패드·Spotlight·Robin으로 설치된 실제 리눅스 앱 실행.

### Changed — 변경
- **컴포지터 cage → sway**: 단일앱 키오스크에서 **멀티윈도 데스크톱 환경(DE)**으로. 실제 리눅스 앱을 창으로 띄우고(70% 중앙 배치로 RobinOS 독·메뉴바 노출), 검증 완료.
- 기본 데스크톱 앱 탑재: firefox/mousepad/imv/mpv/pavucontrol/foot.

### Polish — 디자인·애니메이션·최적화
- staggered 등장 애니메이션(알림·검색·런치패드·설정 칩), Robin 대화창 팝업, 독 magnification.
- 배터리 없는 기기 폴링 중단, 블루투스 스캔 병렬화 등 최적화.

### Fixed — 수정
- 파일시스템 홈 삭제/이탈 방어(`_unsafe` 가드), 이름 검증(`..`/`.` 거부) — 자체 코드리뷰 반영.

## [부팅 검증] - 2026-06-12
- **부팅 → 데스크톱 렌더 증명**: 커널 → systemd → seatd → sway → RobinOS UI (QEMU boottest 스크린샷).
- **Phase C 하드웨어 제어**: 밝기(brightnessctl)·볼륨(wpctl)·전원(systemctl)·Wi-Fi(nmcli)·블루투스(rfkill).
- Debian 디스크 설치기(Calamares) 토대.

## [셸] - 초기
- macOS식 웹 데스크톱 셸을 Flutter 네이티브로 이식: 데스크톱·창·독·Spotlight·미션컨트롤·런치패드·제어센터.
- 개인 에이전트 **Robin**(교체식 두뇌: 로컬/Ollama/DeepSeek) + 앱 6종(Finder·메모·계산기·그림판·터미널·설정).
