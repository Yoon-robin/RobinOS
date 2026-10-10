# RobinOS 로드맵

v0.1 범위와 진행 상황은 `docs/design.md`에서 관리해요.

## 0단계: 정체성

- 이름, 로고 방향, 색상 체계, 데스크톱 분위기 정하기
- 기본 데스크톱 정하기: Hyprland + Quickshell 셸 (결정 완료, `docs/design.md` 참고)
- 한국어·영어 한 줄 소개 쓰기
- 윤리적 사용 정책 정하기

## 1단계: 재현 가능한 Arch 워크스테이션

- 패키지 목록 만들기
- 설치 후 설정 스크립트 만들기
- 한글 글꼴, 한글 입력, 로캘, 시간대 설정
- 터미널 프롬프트 브랜딩 추가 - 완료 (`robin@robinos ~ >`, 실패한 명령의 종료 코드, fastfetch의 울새 그림, os-release의 RobinOS 이름)
- 임시 배경화면과 로그인 테마 추가 - 완료 (셸이 직접 그리는 배경화면, 새 SDDM 테마)

## 2단계: `robinctl`

- `robinctl doctor` 구현 - 첫 프로토타입 완료
- `robinctl profile` 구현 - 학습 단계별 프로필 7개(network, web, forensics, reversing, passwords, wireless, vm)와 전부(security)
- `robinctl update` 구현 - 완료 (업데이트 전후 스냅샷, 앱 스토어 앱, RobinOS 파일)
- `robinctl repo` 구현 - RobinOS 파일 업데이트 저장소를 켜고 파일을 `robinos` 패키지로 옮겨요 (2026-10-10, VM 검증 전)
- `robinctl snapshot create` 구현 - 첫 프로토타입 완료
- `robinctl learn` 구현 - 리눅스·네트워크·포렌식·리버싱·웹·셸·시스템·보안 기초·텍스트 다루기 미션 5개씩, 모두 45개 완료
- `/etc/robinos/config.toml`에 간단한 설정 파일 추가 - 완료 (버전, 데스크톱, 프로필 목록. `robinctl doctor`가 있는지 확인)

## 3단계: 보안 프로필

- 기본 CTF 도구 추가 - `passwords`, `forensics`, `reversing` 프로필
- 웹 보안 도구 추가 - `web` 프로필
- 네트워크 분석 도구 추가 - `network` 프로필
- 리버싱 도구 추가 - `reversing` 프로필
- 포렌식 도구 추가 - `forensics` 프로필
- 컨테이너 기반 취약 랩 추가 - 웹 랩(Juice Shop, DVWA, `robinctl lab start web`, 127.0.0.1에만), 네트워크 스캔 랩(`robinctl lab start net`) 완료

## 4단계: ISO 빌드

- `archiso` 프로필 만들기 - 첫 프로토타입 완료
- RobinOS 브랜딩 추가 - 첫 프로토타입 완료
- 라이브 ISO 부팅 메뉴 브랜딩 추가 - 첫 프로토타입 완료
- 프로젝트 정적 검증 추가 - 첫 프로토타입 완료
- ISO 빌드와 체크섬 생성 과정 스크립트화 - 첫 프로토타입 완료
- 설치기 추가 - 자체 설치기(Quickshell 화면 + `robin-install`), 디스크 전체 설치 VM 검증 완료
- VM에서 테스트 - QEMU 부팅 테스트와 설치 테스트 자동화 완료 (`wsl-build.ps1 boot-test`, `install-test`, 둘을 함께 하는 `verify`)
- 빌드 방법 문서화 - 완료 ([build-iso.md](build-iso.md), [build-environment.md](build-environment.md))

## 5단계: 안전과 복구

- Btrfs 레이아웃 - 완료. 설치기가 `@`, `@home`, `@log`, `@pkg`, `@snapshots`를 만들어요(archinstall로 설치하면 `robinctl snapshot setup`이 `@snapshots`를 더해요)
- Snapper 연동 - `robinctl snapshot setup`, 2026-10-08 VM 설치 테스트로 검증
- 부트로더의 스냅샷 항목 - `robinctl snapshot setup`이 grub-btrfs를 설정해요
- `robinctl update`의 업데이트 전 스냅샷 - snap-pac으로 모든 pacman 작업 전후에 만들어요
- 복구 문서 - [recovery.md](recovery.md)

## 6단계: 공개 프리뷰

- 서명된 ISO 빌드 - 2026-10-10 릴리스 열쇠를 만들고 `build-iso.sh`가 `SHA256SUMS.sig`를 만들어요([release.md](release.md) "서명", RobinOS 패키지 저장소와 같은 열쇠)
- 체크섬 공개 - 릴리스에 `SHA256SUMS`를 함께 올려요(v0.1, 2026-10-08)
- 설치 가이드 작성 - 초안 완료 ([install.md](install.md)), 윈도우 옆 설치 검증 뒤 다듬기
- 첫 CTF 랩 가이드 작성 - [ctf.md](ctf.md), 입문 CTF 10문제 `robinctl ctf` (2026-10-09, 6~10번은 2026-10-10)
- GitHub 릴리스 만들기 - v0.1 프리뷰 공개(2026-10-08), v0.2 프리뷰 공개(2026-10-10, `v0.2.0`, 서명한 `SHA256SUMS`와 함께)

## 7단계: 매일 쓰는 나만의 OS

2026-10-10 방향 결정과 설계 점검([design.md](design.md) "설계 점검")에서 나온 단계예요. 작업은 [tasks.md](tasks.md)에 있어요.

- 실제 PC에서 라이브 부팅과 설치 - 사용자 확인 필요
- 보안 부팅 - 끄는 안내 완료(T-147), 켠 채로 부팅은 조사(T-148)
- RobinOS 설정 앱 - 디스플레이, 날짜·시간, 사용자, 기본 앱까지(T-149)
- 부팅 화면 - Plymouth RobinOS 테마(T-150)
- 화면의 정체성 문구 - 로고 한 줄 소개, 로그인·잠금 화면, 부팅 메뉴(T-151)
- RobinOS 파일 업데이트 저장소 - 패키지(T-143), 저장소(T-144), 설치본 연결(T-145, VM 검증 전)
