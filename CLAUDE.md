# RobinOS: Claude 작업 규칙

RobinOS는 Arch Linux 기반의 한국어 우선 보안 학습 OS예요. Hyprland 위에 직접 만든 Quickshell 셸을 얹었고, 윈도우에서 넘어온 사람이 매일 쓰면서 리눅스와 보안을 배우는 걸 목표로 해요. 제품 설계는 [docs/design.md](docs/design.md)에 있어요.

## 꼭 지킬 것

- **사용자와는 한국어로만 말해요.** 진행 상황 한 줄, 질문, 명령 설명(`description`), 커밋 메시지까지 모두 한국어예요. 코드 식별자와 코드 주석은 영어(기존 관례)예요.
- **문서와 사용자에게 보이는 글은 한국어 해요체**로 써요. 말투는 [docs/design.md](docs/design.md)를 따라요.
- **검증은 이 PC에서 해요.** GitHub Actions는 수동 실행 전용이고 쓰지 않아요. 방법은 [docs/testing.md](docs/testing.md)에 있어요.
- **스스로 판단해서 진행해요.** 사용자가 "알아서 해"라고 했어요. 다만 관리자 권한, 윈도우 시스템 설정, force push, 히스토리 다시 쓰기, 릴리스나 브랜치 삭제, 돈이 드는 일, 제품 방향을 크게 바꾸는 결정은 직접 하지 않고 [docs/tasks.md](docs/tasks.md)의 "사용자 확인 필요"에 적어요. 공식 출처의 개발 도구는 내려받아도 돼요(체크섬 확인).
- **푸시는 검증이 끝난 뒤에만 해요.** 기준은 [docs/loop.md](docs/loop.md)의 "푸시"를 따라요.

## 루프로 일할 때

[docs/loop.md](docs/loop.md)의 순서를 따라요. 작업 목록과 진행 상태는 [docs/tasks.md](docs/tasks.md)가 원본이에요. 어떤 문서에 무엇을 쓰는지는 [docs/README.md](docs/README.md)에 있어요.

- **루프는 스스로 멈추지 않아요.** 할 일이 떨어지면 [docs/loop.md](docs/loop.md)의 "백로그 채우기"로 새 작업을 만들고, 막힌 작업은 `막힘`으로 두고 다른 일을 해요.
- **회차는 언제나 다음 회차 예약(`ScheduleWakeup`)으로 끝나요.** 오류나 실패가 있어도 마찬가지예요. 사용자가 멈추라고 할 때만 멈춰요.

## 주요 명령 (PowerShell, 저장소 루트)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1            # 정적 검증 (커밋 전 필수)
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 check             # Hyprland, QML 파싱, qmllint
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 status            # WSL에서 도는 빌드/VM, 최근 결과
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build             # ISO 빌드 (WSL, HEAD 기준)
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test         # 부팅 테스트 → build\boot-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test      # 설치 테스트 → build\install-test
powershell -ExecutionPolicy Bypass -File scripts/sync-archiso-files.ps1          # ISO 오버레이 맞추기
```

## 저장소 지도

| 위치 | 내용 |
|---|---|
| `bin/robinctl` | 관리 도구 (bash): doctor, update, snapshot, profile, learn, lab |
| `installer/robin-install` | 설치기 백엔드 (Python, 라이브 ISO에서 실행) |
| `desktop/shell/` | Quickshell 셸 (QML). `Theme.qml`이 디자인 토큰 원본, `ShellState.qml`이 공유 상태 |
| `desktop/hypr/`, `desktop/foot/`, ... | 데스크톱 설정. 설치 위치는 `desktop/install-map.txt` |
| `scripts/` | 빌드, 설치, 테스트 스크립트 |
| `packages/*.txt` | 패키지 목록. ISO 목록은 `archiso/packages.x86_64`. `apps.txt`는 설치본에만 들어가요(ISO는 2GiB 한도) |
| `practice/` | 학습 미션 연습 프로그램의 소스. `build.sh`가 만든 압축본이 `bin/robinctl` 안에 있어요 |
| `archiso/` | ISO 프로필 오버레이. `archiso/airootfs/opt/robinos`와 `usr/share/robinos`는 동기화 스크립트가 만드는 사본 |
| `docs/` | 문서 (한국어) |

## 이 환경에서 자주 걸리는 것

- **WSL 작업은 한 번에 하나**: `build`, `boot-test`, `install-test`는 WSL 클론(`/root/RobinOS`)을 HEAD로 리셋해요. 다른 작업이 돌고 있으면 스크립트가 거부해요. 먼저 커밋해야 변경이 넘어가요.
- **긴 작업은 `&`로 띄우지 않아요**: 명령이 끝난 것처럼 보여도 PowerShell과 QEMU가 살아남아서, 다음 실행과 같은 폴더·포트를 쓰다 서로 망가뜨려요(2026-10-08). 도구의 백그라운드 실행을 쓰고, 이상하면 `Get-CimInstance Win32_Process`로 `wsl-build`·`qemu-system` 프로세스부터 확인해요.
- **설치 테스트는 VM 디스크 파일을 공유해요**: `install-test`가 도는 동안에는 `build\install-test`를 지우거나 다른 `install-test`를 시작하지 않아요. 같은 이유로 `install-test.py`, `bin/`, `scripts/` 등 공유 폴더로 복사되는 파일은 복사가 끝난 뒤에 고쳐요(그 전에는 작업 트리를 따로 만들어요).
- **wsl.exe는 `-e`로**: `wsl.exe -- 명령`은 셸을 한 번 더 거쳐 `$?`나 따옴표가 깨져요. `wsl.exe -d archlinux -u root -e bash -lc '...'`처럼 쓰고, 긴 명령은 스크립트 파일로 만들어 실행해요.
- **PowerShell 5.1과 한글**: BOM 없는 UTF-8 `.ps1`의 한글은 깨져요. 한글이 들어간 `.ps1`은 UTF-8 BOM으로 저장해요.
- **CRLF**: 윈도우 체크아웃의 `.ps1`은 CRLF예요. 그 안의 here-string을 bash에 넘기면 `\r`이 붙어요. `Invoke-Wsl`처럼 넘기기 전에 `\r`을 지워요.
- **VM 테스트는 WHPX로**: Windows용 QEMU(`%USERPROFILE%\RobinOS-tools\qemu`)가 있으면 `boot-test`가 WHPX로 돌아요. WSL의 QEMU는 KVM이 없어 TCG로만 돌아요.
- **Bash 도구의 heredoc**: `\n` 같은 이스케이프가 바뀌어 들어가요. 이스케이프가 있는 수정은 Edit 도구로 해요.
- **ISO 오버레이 동기화**: `sync-archiso-files.ps1`이 `archiso/airootfs/etc/sddm.conf.d/10-robinos-theme.conf`를 CRLF로 다시 써요. 실제로 바뀐 게 없으면 `git checkout`으로 되돌려요.
- **실행 권한**: 윈도우는 실행 비트를 기록하지 않아요. 새 스크립트는 `git update-index --chmod=+x <파일>`로 남겨요. `validate-project.ps1`이 확인해요.
- **QML 한 줄 실수로 셸 전체가 안 떠요**: QML을 고치면 `wsl-build.ps1 check`(qmllint)를 꼭 돌려요. 셸이 안 뜨면 부팅 테스트의 `serial.log`에서 오류를 찾아요.
- **느린 VM(TCG)의 키 반복**: 부팅 테스트에서 키가 반복 입력될 수 있어요. 테스트 결과가 이상하면 제품 문제인지 먼저 가려요.
