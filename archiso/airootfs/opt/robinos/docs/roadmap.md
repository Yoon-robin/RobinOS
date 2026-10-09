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
- `robinctl update` 구현 - 첫 프로토타입 완료
- `robinctl snapshot create` 구현 - 첫 프로토타입 완료
- `robinctl learn` 구현 - 리눅스·네트워크·포렌식·리버싱·웹·셸·시스템·보안 기초 미션 5개씩, 모두 40개 완료
- `/etc/robinos/config.toml`에 간단한 설정 파일 추가 - 완료 (버전, 데스크톱, 프로필 목록. `robinctl doctor`가 있는지 확인)

## 3단계: 보안 프로필

- 기본 CTF 도구 추가 - `passwords`, `forensics`, `reversing` 프로필
- 웹 보안 도구 추가 - `web` 프로필
- 네트워크 분석 도구 추가 - `network` 프로필
- 리버싱 도구 추가 - `reversing` 프로필
- 포렌식 도구 추가 - `forensics` 프로필
- 컨테이너 기반 취약 랩 추가

## 4단계: ISO 빌드

- `archiso` 프로필 만들기 - 첫 프로토타입 완료
- RobinOS 브랜딩 추가 - 첫 프로토타입 완료
- 라이브 ISO 부팅 메뉴 브랜딩 추가 - 첫 프로토타입 완료
- 프로젝트 정적 검증 추가 - 첫 프로토타입 완료
- ISO 빌드와 체크섬 생성 과정 스크립트화 - 첫 프로토타입 완료
- 설치기 추가 - 자체 설치기(Quickshell 화면 + `robin-install`), 디스크 전체 설치 VM 검증 완료
- VM에서 테스트 - QEMU 부팅 테스트 자동화 완료 (`Boot-test RobinOS ISO`)
- 빌드 방법 문서화 - 완료 ([build-iso.md](build-iso.md), [build-environment.md](build-environment.md))

## 5단계: 안전과 복구

- Btrfs 레이아웃 - archinstall 기본 하위 볼륨을 써요
- Snapper 연동 - `robinctl snapshot setup`, 2026-10-08 VM 설치 테스트로 검증
- 부트로더의 스냅샷 항목 - `robinctl snapshot setup`이 grub-btrfs를 설정해요
- `robinctl update`의 업데이트 전 스냅샷 - snap-pac으로 모든 pacman 작업 전후에 만들어요
- 복구 문서 - [recovery.md](recovery.md)

## 6단계: 공개 프리뷰

- 서명된 ISO 빌드
- 체크섬 공개
- 설치 가이드 작성 - 초안 완료 ([install.md](install.md)), 윈도우 옆 설치 검증 뒤 다듬기
- 첫 CTF 랩 가이드 작성 - [ctf.md](ctf.md), 입문 CTF 5문제 `robinctl ctf` (2026-10-09)
- GitHub 릴리스 만들기
