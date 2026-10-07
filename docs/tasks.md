# RobinOS 작업 목록

루프가 회차마다 읽고 갱신하는 작업 목록이에요. 절차는 [loop.md](loop.md), 제품 범위와 상태는 [design.md](design.md)에 있어요.

상태: `할 일` → `진행 중` → `검증 대기` → `완료`. 사용자가 해야 하는 일을 기다리거나 같은 실패가 세 번 반복되면 `막힘`으로 두고 다른 작업을 해요. `할 일`이 비면 [loop.md](loop.md)의 "백로그 채우기"로 채워요.

## 백그라운드 작업

WSL에서 도는 긴 작업이에요. WSL 작업은 한 번에 하나만 돌려요(`scripts/wsl-build.ps1 status`로 확인).

| 작업 | 시작 | 대상 | 결과 위치 | 상태 |
|---|---|---|---|---|
| ISO 빌드 → 부팅 테스트 → 설치 테스트 archinstall (WHPX) | 2026-10-08 04:24 | `1295721` | `build\boot-test`, `build\install-test`, 로그 `build\loop-*.log`, 순서 결과 `build\loop-chain.log` | 실행 중 |

## 정기 점검

처음부터 다시 확인하는 회귀 점검이에요. 마지막 날짜가 하루 넘게 지났거나 그 뒤 커밋이 10개 넘게 쌓이면 다시 해요([loop.md](loop.md) "정기 점검").

| 날짜 | 대상 커밋 | 한 것 | 결과 |
|---|---|---|---|
| 2026-10-08 | `7a000b9` | ISO 빌드(처음부터, 9분), 부팅 테스트(WHPX, 207초) | 통과. 스크린샷 18장 모두 정상 |
| 2026-10-07 | `16d652f` | ISO 빌드, 부팅 테스트 | 빌드 성공. 부팅 테스트에서 마법사 키 반복 문제(고침), 런처 검색 미확인 (T-001) |

## 품질 점검 기록

백로그 채우기 6번 출처예요. 가장 오래전에 본 영역부터 봐요.

| 영역 | 마지막으로 본 날 | 메모 |
|---|---|---|
| 코드 검토 | 2026-10-08 | `robin-install`(fstab의 `subvolid=`), `robinctl`(스냅샷 부팅 상태의 되돌리기, 랩 권한), `post-install.sh`(영어 출력), `Installer.qml`, `ShellState.qml`, `Launcher.qml`(열 때 hover 선택). 셸 QML의 나머지(QuickSettings, Welcome, Dock, Bar)는 아직 |
| 문서와 코드 맞추기 | 2026-10-07 | 문서 체계 정리 때 전체를 읽음. 명령과 경로까지 하나하나 대조하지는 않음 |
| 보안과 윤리 | 2026-10-08 | 웹 랩: docker 그룹 대신 sudo, 재부팅 때 자동 시작 끔, 기준을 ethics.md에 적음. 이미지 버전 고정과 DVWA 이미지 교체는 T-014 |
| 접근성 | 아직 | |
| 성능 | 아직 | 메모: `ShellState.qml`이 한/영 상태를 보려고 `fcitx5-remote`를 1초마다 새로 실행해요 |
| 업스트림 변화 | 2026-10-07 | 로컬 ISO 빌드 때 패키지 검사 통과, Hyprland 0.56.2, Quickshell 0.3.1 |

## 푸시 대기 커밋

`git log origin/main..HEAD`에 있는 커밋과, 푸시하기 전에 통과해야 하는 검증이에요. 검증이 끝나면 지우고 푸시해요.

| 커밋 | 내용 | 필요한 검증 |
|---|---|---|
| `6d13712` | 설치기 화면 | 부팅 테스트(설치기 1·2단계 스크린샷). 2026-10-08 실행에서 런처 hover 문제로 설치기가 안 열림 → `d5e4e47`로 고치고 다음 부팅 테스트에서 확인 |
| `1295721` | SDDM 첫 로그인 사용자·세션, 스냅샷 설명 영어로 | 설치 테스트 (실행 중) |
| `6a472db`~`ce4050e` | 설치기 fstab, 런처 hover, 스냅샷 부팅 상태에서 되돌리기, 웹 랩 sudo, 설치 스크립트 한국어 | 다음 ISO 빌드 + 부팅 테스트 + 설치 테스트 (T-013) |

`f772062`까지는 2026-10-08에 검증을 마치고 푸시했어요.

## 사용자 확인 필요

- **실기기 라이브 부팅**: USB로 실제 PC에서 ISO를 부팅해 봐야 해요. 사용자만 할 수 있어요. (`막힘`)

## 진행 중

(없음)

## 할 일 (위에서부터)

### T-012 설치본 첫 로그인 확인 (SDDM)
- 상태: 검증 대기
- 2026-10-08 설치 테스트에서 찾음: 설치 직후 SDDM이 기억한 사용자가 없어서 "사용자 이름" 칸을 비워 두고, 세션은 목록 첫 번째인 Hyprland(`robinos-session`의 렌더링 자동 전환이 빠짐)로 잡혔어요. 테마가 사용자가 한 명이면 그 사용자를, 처음 로그인이면 RobinOS 세션을 고르게 고침. snapper 스냅샷 설명의 한글은 GRUB에서 `&#xC2A4;`처럼 깨져서 영어로 바꿈
- 완료 기준: 다음 설치 테스트의 `rollback-03-desktop.png`에 RobinOS 데스크톱(환영 마법사)이 보이고, `snapshots-02`의 설명이 깨지지 않음

### T-013 스냅샷으로 부팅한 상태에서 되돌리기 테스트
- 목표: 복구 문서의 비상 경로(부팅 메뉴에서 스냅샷으로 부팅 → `robinctl snapshot rollback`)를 설치 테스트로 확인
- 2026-10-08: 루트가 overlay일 때 `robinctl`이 멈추던 걸 고침(`5f22e5e`). 테스트는 아직
- 할 일: `install-test.py`의 snapshots 단계는 cowsay 설치까지 하고 끄기. 새 `snapshot-boot` 단계에서 GRUB의 스냅샷 하위 메뉴로 cowsay 설치 전(pre) 스냅샷을 골라 부팅하고(위치는 snapshots 단계가 `grub-btrfs.cfg`에서 찾아 `OUT`에 적어 둠), `findmnt -no FSTYPE /`가 overlay인지, cowsay가 없는지 본 뒤 거기서 `robinctl snapshot rollback`. `wsl-build.ps1`, `install-test.sh`의 단계 목록도 같이
- 완료 기준: 설치 테스트 모든 단계 통과, `snapshot-boot` 단계의 GRUB 스냅샷 메뉴 스크린샷

### T-014 웹 랩 이미지 정리
- 목표: 랩 이미지 버전을 고정하고(`bkimminich/juice-shop:<버전>`), 2018년 이후 갱신이 없는 `vulnerables/web-dvwa`를 공식 `ghcr.io/digininja/dvwa`로 바꾸기
- 확인: 이미지 태그와 포트(공식 DVWA 이미지의 포트, 첫 설정 화면), `robinctl lab info web` 안내, `labs/web/README.md`
- 검증: WSL에 Docker를 깔 수 없으면 설치 테스트 VM에서 `robinctl lab start web` 후 `curl -s 127.0.0.1:3000`, `:8080`

### T-004 설치기 백엔드 검증
- 목표: `installer/robin-install`이 디스크 전체 설치를 끝까지 해내는지
- 명령: `scripts/wsl-build.ps1 install-test -Installer robinos`
- 완료 기준: 설치 테스트 모든 단계 통과. EFI는 `/efi`, `/.bootbackup` 없이 커널이 스냅샷에 들어가는지(`ls /.snapshots/*/snapshot/boot`), `/etc/fstab`의 Btrfs 줄에 `subvolid=`가 없는지
- 메모: 설치기는 post-install.sh를 chroot에서 돌려요. chroot에서 `systemd-detect-virt --chroot`, `localectl` 대체, `mountpoint /.snapshots`가 맞게 동작하는지 봐요.

### T-005 설치기 화면
- 상태: 진행 중. 2026-10-08 부팅 테스트에서 런처 hover 문제로 설치기가 안 열려 고침(`d5e4e47`), 다음 부팅 테스트에서 확인. 첫 구현(`desktop/shell/Installer.qml`, `InputField.qml`, 런처 "RobinOS 설치", `qs ipc call shell installer`), qmllint 통과. 부팅 테스트에 설치기 1·2단계 스크린샷을 넣었고(테스트 VM에 빈 64GB 디스크), 다음 ISO 빌드에서 확인해요. 독에 넣는 건 아직
- 목표: 라이브 세션에서 마우스로 설치할 수 있는 그래픽 설치기
- 설계: `desktop/shell/Installer.qml` (Quickshell `FloatingWindow`, 일반 창). 단계: 환영(인터넷, 전원, 백업 안내) → 설치 위치(`robin-install disks` JSON, 디스크 카드, "디스크 전체 사용"/"윈도우 옆에 설치", 빈 공간이 없으면 윈도우의 "볼륨 축소" 안내) → 사용자(이름, 비밀번호 두 번, 컴퓨터 이름) → 확인(지워지는 디스크 경고) → 진행(`sudo -n robin-install run -`에 계획 JSON을 표준 입력으로, `@@` 줄로 진행률, 로그 보기) → 완료(다시 시작)
- 진입점: 라이브 세션(`/run/archiso`가 있을 때)에서만 런처 추천 맨 위와 독에 "RobinOS 설치"
- 완료 기준: `qmllint` 통과, 부팅 테스트에 설치기 화면 스크린샷 추가, 설치기로 끝까지 설치하는 경로를 설치 테스트에 추가할지 결정
- 메모: Quickshell `FloatingWindow` 속성은 `title`, `minimumSize`, `maximumSize` 등이 있어요(0.3.1 타입 정보 확인).

### T-006 "윈도우 옆에 설치" 검증
- 목표: 윈도우가 있는 디스크에서 기존 파티션을 건드리지 않고 빈 공간에만 설치하는지
- 할 일: 설치 테스트에 윈도우 흉내 디스크 시나리오 추가(GPT, 100MB ESP, NTFS 파티션, 빈 공간 40GB 이상). 설치 뒤 NTFS 파티션이 그대로인지, ESP에 `EFI/RobinOS`가 생겼는지, 시계가 localtime인지 확인
- 완료 기준: 시나리오 통과

### T-007 설치기 결정과 설치 문서 갱신
- 목표: [design.md](design.md) 미결정 사항의 "그래픽 설치기"를 결정으로 옮기고(자체 설치기, `pacstrap`, Quickshell 화면, Calamares를 쓰지 않는 이유), [install.md](install.md)를 설치기 기준으로 다시 쓰기
- 조건: T-004, T-005 끝난 뒤

### T-008 부팅 메뉴 이름을 RobinOS로
- 목표: 설치된 시스템의 GRUB 메뉴가 "Arch Linux" 대신 "RobinOS"로 보이게(`GRUB_DISTRIBUTOR`, grub-btrfs 하위 메뉴 이름)
- 같이 고칠 것: `install-test.py`의 `boot_from_grub()`가 찾는 글자, `recovery.md`의 메뉴 이름

### T-009 로고 SVG 색 정리
- 상태: 검증 대기. 2026-10-08 색을 바꿈(옛 청록 → zinc, 위쪽 날개만 Robin red), rsvg-convert로 렌더링해서 확인. 남은 것: 설치 테스트의 SDDM 스크린샷에서 로고 확인
- 목표: [brand.md](brand.md)에 적힌 대로 `assets/brand/*.svg`의 옛 청록색을 zinc와 Robin red로 바꾸기
- 검증: 정적 검증(SVG 유효성), 부팅 테스트의 SDDM·GRUB 화면

### T-010 보안 학습 프로필 나누기 (로드맵 3단계)
- 목표: `robinctl profile`을 학습 단계별 묶음으로(web, network, reversing, forensics). 패키지 목록과 [design.md](design.md) 학습 설계에 맞추기
- 검증: 패키지 검사, `robinctl profile ... --dry-run`

### T-011 v0.2 후보 (지금은 하지 않아요)
- Qt 앱 제목 표시줄(hyprbars), 작업 표시줄 클릭으로 최소화, `Win+D`, 학습 센터 앱, 네트워크·CTF 랩

## 완료

최근 것이 위에 있어요.

- 2026-10-08 T-002 VM 테스트를 WHPX로: 부팅 테스트 207초(TCG의 몇 분의 일), 설치 테스트는 모든 단계 통과. WHPX가 게스트의 재부팅을 처리하지 못해서(`Unexpected VP exit code 4`) 설치 테스트는 부팅마다 QEMU를 새로 띄워요(`8c3293d`). QEMU 11.1은 `C:\Users\Blitz\RobinOS-tools\qemu`, OVMF는 QEMU에 들어 있는 edk2 파일을 써요
- 2026-10-08 T-003 설치 테스트(archinstall 방식) 통과: archinstall 설치 → post-install → 스냅샷 설정(`@snapshots` fstab, 커널 백업 훅, grub-btrfs 항목) → GRUB 스냅샷 하위 메뉴 → cowsay 설치로 snap-pac 전후 스냅샷 → `robinctl snapshot rollback` → 다음 부팅에서 cowsay가 사라짐. 그 과정에서 테스트 쪽 문제 일곱 개를 고침(archinstall 무인 실행의 멈춤 두 가지, 한글 프롬프트와 UTF-8 조각, 캡처의 프롬프트, WHPX가 재부팅을 못 하는 문제 등, `90035c1`~`8c3293d`). 제품 쪽에서 찾은 것: 설치본 첫 로그인에서 SDDM이 사용자를 고르지 않고 세션이 Hyprland로 잡힘, 스냅샷 한글 설명이 GRUB에서 깨짐 → 고침(다음 설치 테스트에서 확인, T-012)
- 2026-10-08 T-001 데스크톱 변경 부팅 테스트 확인: 마법사 5단계와 미션 터미널, `notepad` 검색, 미션 화면, 잠금 화면 모두 정상(WHPX 부팅 테스트, ISO `7a000b9`). 마법사 키 반복 무시(`12e6b2a`), ISO 빌드가 이전 빌드를 다시 포장하던 문제(`7a000b9`), WSL 동기화 CRLF 문제(`3f110df`)를 같이 고침
- 2026-10-07 GitHub Actions를 수동 실행 전용으로, 문서 체계와 루프 절차 정리 (이번 커밋)
- 2026-10-07 WSL 2 빌드 도우미 `scripts/wsl-build.ps1`, 설치 테스트 `scripts/install-test.*` (`d1b4577`). 로컬 ISO 빌드 9분 성공
- 2026-10-07 업데이트 전 자동 스냅샷과 되돌리기 (`16d652f`, VM 검증 전)
- 2026-10-07 환영 마법사 (`99db372`), 터미널 한글 간격 (`200c07d`)
- 2026-10-07 문서 한국어화 (`521181c`), 런처 윈도우 이름 검색 (`7b4011b`), 리눅스 기초 미션 `robinctl learn` (`7f0ed7f`)
