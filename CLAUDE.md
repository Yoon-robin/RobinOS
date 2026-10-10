# RobinOS: Claude 작업 규칙

RobinOS는 Arch Linux 기반의 한국어 우선 "나만의 OS"예요. Hyprland 위에 직접 만든 Quickshell 셸을 얹었고, 매일 쓰는 컴퓨터로 충분하면서 리눅스와 보안도 배울 수 있는 걸 목표로 해요. 중심은 RobinOS다운 경험이고, 윈도우 닮기와 보안 학습은 그 기능 중 하나예요(2026-10-10 사용자 결정). 제품 설계는 [docs/design.md](docs/design.md)에 있어요.

## 꼭 지킬 것

- **사용자와는 한국어로만 말해요.** 진행 상황 한 줄, 질문, 명령 설명(`description`), 커밋 메시지까지 모두 한국어예요. 코드 식별자와 코드 주석은 영어(기존 관례)예요.
- **문서와 사용자에게 보이는 글은 한국어 해요체**로 써요. 말투는 [docs/design.md](docs/design.md)를 따라요.
- **검증은 이 PC에서 해요.** GitHub Actions는 수동 실행 전용이고 쓰지 않아요. 방법은 [docs/testing.md](docs/testing.md)에 있어요.
- **스스로 판단해서 진행해요.** 사용자가 "알아서 해"라고 했어요. 다만 관리자 권한, 윈도우 시스템 설정, force push, 푸시한 히스토리 다시 쓰기, 릴리스나 원격 브랜치 삭제, 돈이 드는 일, 제품 방향을 크게 바꾸는 결정은 직접 하지 않고 [docs/tasks.md](docs/tasks.md)의 "사용자 확인 필요"에 적은 뒤 다른 일을 계속해요(답을 기다리며 멈추지 않아요). 내가 만든 로컬 작업 브랜치(`work/batch*`)는 main에 합친 뒤 지워도 돼요. 공식 출처의 개발 도구는 내려받아도 돼요(체크섬 확인).
- **푸시는 검증이 끝난 뒤에만 해요.** 기준은 [docs/loop.md](docs/loop.md)의 "푸시"를 따라요.

## 루프로 일할 때

[docs/loop.md](docs/loop.md)의 순서를 따라요. 작업 목록과 진행 상태는 [docs/tasks.md](docs/tasks.md)가 원본이에요. 어떤 문서에 무엇을 쓰는지는 [docs/README.md](docs/README.md)에 있어요.

- **루프는 스스로 멈추지 않아요.** 할 일이 떨어지면 [docs/loop.md](docs/loop.md)의 "백로그 채우기"로 새 작업을 만들고, 막힌 작업은 `막힘`으로 두고 다른 일을 해요.
- **회차는 언제나 다음 회차 예약(`ScheduleWakeup`)으로 끝나요.** 오류나 실패가 있어도 마찬가지예요. 사용자가 멈추라고 할 때만 멈춰요.

## 주요 명령 (PowerShell, 저장소 루트)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ready.ps1 [-Check]              # 커밋 전 필수: 오버레이 동기화 + sddm 되돌리기 + 정적 검증 (+ check)
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 check             # Hyprland, QML 파싱, qmllint
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 status            # WSL에서 도는 빌드/VM, 최근 결과
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build             # ISO 빌드 (WSL, HEAD 기준)
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test         # 부팅 테스트 → build\boot-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test      # 설치 테스트 → build\install-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 verify -Installer robinos  # 묶음 검증: 빠른 ISO + 부팅·설치 테스트 동시에
powershell -ExecutionPolicy Bypass -File scripts/sync-archiso-files.ps1          # ISO 오버레이 맞추기
```

## 저장소에서 코드만으로는 모르는 것

- `archiso/airootfs/opt/robinos`와 `usr/share/robinos`는 원본이 아니라 동기화 스크립트가 만드는 사본이에요. 원본(`bin/`, `desktop/`, `scripts/` 등)을 고쳐요. 데스크톱 파일의 설치 위치는 `desktop/install-map.txt`예요.
- `packages/apps.txt`는 설치본에만 들어가요. 라이브 ISO는 깃허브 첨부 한도(2GiB) 때문에 `archiso/packages.x86_64`에 넣지 않아요.
- `practice/`는 학습 미션 연습 프로그램의 소스예요. 각 `build.sh`가 만든 압축본이 `bin/robinctl` 안에 들어 있어서, 소스를 고치면 다시 만들어 넣어요.

## 이 환경에서 자주 걸리는 것

- **`wsl-build.ps1` 작업은 한 번에 하나**: `build`, `boot-test`, `install-test`, `verify`는 WSL 클론(`/root/RobinOS`)을 HEAD로 리셋해요. 먼저 커밋해야 변경이 넘어가요. `verify`는 안에서 부팅·설치 테스트 두 VM을 함께 돌려요. 바쁜지 확인하는 코드는 WSL 안만 봐서 윈도우에서 도는 WHPX QEMU는 못 봐요. 테스트를 띄우기 전에 `Get-Process qemu-system-x86_64`로 확인해요.
- **긴 작업은 `&`로 띄우지 않아요**: 명령이 끝난 것처럼 보여도 PowerShell과 QEMU가 살아남아서, 다음 실행과 같은 폴더·포트를 쓰다 서로 망가뜨려요(2026-10-08). 도구의 백그라운드 실행을 쓰고, 이상하면 `Get-CimInstance Win32_Process`로 `wsl-build`·`qemu-system` 프로세스부터 확인해요.
- **설치 테스트는 작업 트리를 읽어요**: 시작할 때 HEAD가 아니라 윈도우 작업 트리(`bin/`, `scripts/`, `desktop/` 등)를 공유 폴더로 복사하고, `scripts/install-test.py`는 VM을 켤 때마다(단계마다) 다시 읽어요. 그래서 설치 테스트나 `verify`가 끝날 때까지 이 작업 트리를 고치지 않아요. 그동안의 작업은 `git worktree add ../RobinOS-wt -b work/batchN`에서 하고, 검증이 통과하면 합쳐요([docs/loop.md](docs/loop.md) "5. 검증").
- **wsl.exe는 `-e`로**: `wsl.exe -- 명령`은 셸을 한 번 더 거쳐 `$?`나 따옴표가 깨져요. `wsl.exe -d archlinux -u root -e bash -lc '...'`처럼 쓰고, 긴 명령은 스크립트 파일로 만들어 실행해요.
- **PowerShell 5.1과 한글**: BOM 없는 UTF-8 `.ps1`의 한글은 깨져요. 한글이 들어간 `.ps1`은 UTF-8 BOM으로 저장해요.
- **CRLF**: 윈도우 체크아웃의 `.ps1`은 CRLF예요. 그 안의 here-string을 bash에 넘기면 `\r`이 붙어요. `Invoke-Wsl`처럼 넘기기 전에 `\r`을 지워요.
- **VM 테스트는 WHPX로**: Windows용 QEMU(`%USERPROFILE%\RobinOS-tools\qemu`)가 있으면 `boot-test`가 WHPX로 돌아요. WSL의 QEMU는 KVM이 없어 TCG로만 돌아요.
- **Bash 도구의 heredoc과 sed**: `\n` 같은 이스케이프가 바뀌어 들어가요. 이스케이프나 여러 줄이 있는 수정은 Edit 도구로 해요.
- **검사 결과를 파이프로 가리지 않아요**: `validate ... | tail -1 && git commit`은 검증이 실패해도 커밋해요(2026-10-08). `scripts/ready.ps1`의 종료 코드로 판단해요. 오버레이 동기화와 sddm 설정 줄 끝 되돌리기도 `ready.ps1`이 해요.
- **실행 권한**: 윈도우는 실행 비트를 기록하지 않아요. 새 스크립트는 `git update-index --chmod=+x <파일>`로 남겨요. `validate-project.ps1`이 확인해요.
- **QML 한 줄 실수로 셸 전체가 안 떠요**: QML을 고치면 `wsl-build.ps1 check`(qmllint)를 꼭 돌려요. 셸이 안 뜨면 부팅 테스트의 `serial.log`에서 오류를 찾아요.
- **느린 VM(TCG)의 키 반복**: 부팅 테스트에서 키가 반복 입력될 수 있어요. 테스트 결과가 이상하면 제품 문제인지 먼저 가려요.
