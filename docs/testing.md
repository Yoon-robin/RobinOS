# RobinOS 테스트

RobinOS는 GitHub Actions를 쓰지 않고 개발 PC에서 검증해요. 윈도우 PC라면 WSL 2의 Arch Linux에서 빌드하고 VM을 돌려요. 환경 준비는 [build-environment.md](build-environment.md)에 있어요.

무엇을 바꿨는지에 따라 필요한 검사가 달라요.

| 바꾼 것 | 필요한 검사 |
|---|---|
| 문서 | 정적 검증 |
| 셸 스크립트, `robinctl` | 정적 검증, `bash -n`, 가능한 부분은 직접 실행 |
| 셸 QML (`desktop/shell/`) | 정적 검증, 데스크톱 설정 검사, ISO 빌드, 자동 부팅 테스트 |
| Hyprland 설정, foot, 테마 | 데스크톱 설정 검사, ISO 빌드, 자동 부팅 테스트 |
| 패키지 목록, `archiso/` | 패키지 검사, ISO 빌드, 자동 부팅 테스트 |
| 설치와 복구 (`post-install.sh`, `robinctl snapshot`, `robin-install`) | 정적 검증, 설치 테스트 |

## 정적 검증

윈도우 PowerShell에서 저장소 루트로 가서 실행해요. 몇 초면 끝나요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
```

확인하는 것:

- 필수 파일과 ISO 오버레이(`archiso/airootfs/`) 경로
- SVG/XML 유효성
- 패키지 목록의 중복, 그리고 핵심·데스크톱·보안 패키지가 `archiso/packages.x86_64`에 다 들어 있는지
- `desktop/install-map.txt`에 적힌 원본 파일이 다 있는지
- 스크립트가 git에 실행 파일로 기록돼 있는지

Bash 문법까지 보려면 로컬 CI 래퍼를 써요. Git for Windows의 bash가 필요해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
```

`scripts/install-git-hooks.ps1`로 pre-push 훅을 설치하면 `git push` 전에 로컬 CI가 자동으로 돌아요.

## 데스크톱 설정 검사

Lua 문법, `Hyprland --verify-config`, QML 파싱(`qmlformat`), 데스크톱 스크립트의 `bash -n`을 보고, `qmllint`로 Quickshell 타입 정보와 맞춰 봐요. `qmllint`는 없는 속성이나 오타를 잡아요. 셸은 속성 이름 하나만 틀려도 통째로 뜨지 않으니 QML을 고쳤다면 꼭 돌려요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 check
```

Arch Linux에서는 `scripts/check-desktop.sh`와 `scripts/qmllint.sh`를 직접 실행해요.

## 패키지 검사

`pacman -Si`로 Arch 저장소에 패키지 이름이 실제로 있는지 확인해요. `scripts/build-iso.sh`가 빌드 전에 자동으로 실행해요. 따로 돌리려면 Arch Linux에서 이렇게 해요.

```bash
scripts/check-arch-packages.sh
```

패키지가 다른 저장소로 옮겨 갔거나 AUR에만 있다면 `packages/security-optional.txt`로 옮기거나 이름을 고치세요.

## ISO 빌드

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
```

자세한 과정은 [build-iso.md](build-iso.md)에 있어요. 결과물은 WSL의 `/root/RobinOS/out/`에 생겨요.

## 자동 부팅 테스트

`scripts/boot-test.sh`가 QEMU에서 ISO를 부팅하고, `scripts/boot-test-qmp.py`가 화면을 조작하면서 스크린샷을 찍어요.

1. 부팅과 첫 로그인
2. 환영 마법사의 모든 단계, 마지막에 열리는 리눅스 기초 미션 터미널
3. 데스크톱
4. 런처: 추천 목록, `term` 검색, 윈도우 이름 `notepad` 검색
5. 빠른 설정
6. 터미널: `ipconfig` 힌트, `robinctl learn show 1`
7. 잠금 화면과 잠금 해제

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
```

스크린샷과 `serial.log`는 `build\boot-test`에 생겨요. 테스트는 `robinos.debug`를 붙여 부팅해서 `robinos-session`이 Hyprland와 셸 출력을 저널로 보내고, 그 내용이 `serial.log`에 남아요. 셸이 안 뜨면 여기서 QML 오류를 찾으세요.

Windows용 QEMU가 준비돼 있으면 WHPX 가속으로 돌아요([build-environment.md](build-environment.md)). 없으면 WSL 안에서 소프트웨어 에뮬레이션(TCG)으로 돌고, 기다리는 시간을 4배로 늘려요. TCG에서는 VM이 느려서 키 입력이 반복될 수 있으니, 이상한 결과가 나오면 테스트 탓인지 먼저 가려요.

## 설치 테스트

`scripts/install-test.sh`는 빈 40GB 디스크에 RobinOS를 설치하고, 설치한 시스템을 시리얼 콘솔로 조작하면서 확인해요. RobinOS 파일은 ISO 안의 사본이 아니라 지금 저장소 것을 써요(읽기 전용 FAT 디스크로 넘겨요).

설치 방식은 두 가지예요.

- `archinstall` (기본): [install.md](install.md)의 방법 A예요. archinstall로 Arch를 설치하고(기본 Btrfs 구성, GRUB, EFI는 `/boot`) `scripts/post-install.sh --yes`를 실행해요.
- `robinos`: RobinOS 설치기 백엔드(`installer/robin-install`)로 디스크 전체에 설치해요(EFI는 `/efi`).

설치한 뒤 확인하는 것:

1. `robinctl doctor`, 스냅샷 설정, `/etc/fstab`의 `@snapshots`, grub-btrfs 항목
2. 재부팅해서 GRUB 메뉴와 스냅샷 하위 메뉴 스크린샷
3. `pacman -S cowsay`로 snap-pac의 전후 스냅샷이 생기는지
4. 다시 켜서 GRUB의 스냅샷 하위 메뉴로 cowsay 설치 전 스냅샷을 골라 부팅하고([recovery.md](recovery.md)의 비상 경로), 그 안에서 `robinctl snapshot rollback`
5. 다시 켜서 cowsay가 사라졌는지 확인하고, SDDM에서 로그인한 데스크톱 스크린샷

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test -Installer robinos
```

패키지를 내려받으니 인터넷이 필요해요. Windows용 QEMU가 있으면 부팅 테스트처럼 WHPX로 돌아요(UEFI 펌웨어는 QEMU에 들어 있는 `edk2-x86_64-code.fd`, 공유 폴더는 `fat:` 디스크). 없으면 WSL 안에서 TCG로 돌아서 한 시간 넘게 걸릴 수 있어요. 결과(스크린샷, 단계별 시리얼 로그)는 `build\install-test`에 생겨요.

## VM에서 직접 써 보기

자동 테스트로 보기 어려운 것은 VM을 직접 띄워서 확인해요. Arch Linux(WSL 셸: `scripts/wsl-build.ps1 shell`)에서 실행해요.

```bash
scripts/run-vm.sh
scripts/run-vm.sh --memory 8192 --cpus 4
scripts/run-vm.sh --iso out/robinos-YYYY.MM.DD-x86_64.iso
scripts/run-vm.sh --uefi
scripts/run-vm.sh --gl
```

`--gl`은 GPU 가속 렌더링을 시험할 때 써요.

### 눈으로 확인할 것

- 부팅 메뉴에 "RobinOS Security Learning Live"가 보여요.
- 라이브 세션으로 바로 로그인하고 환영 마법사가 떠요.
- 데스크톱에 상단 바, 독, 점 격자 배경화면이 보여요.
- `Super+Space`로 런처가, `Super+S`로 빠른 설정이 열려요.
- 런처에서 "메모장"이나 `notepad`로 찾으면 텍스트 편집기가 나와요.
- 터미널이 RobinOS 색상을 쓰고, 오른쪽 Alt로 한/영이 바뀌고, 한글 글자 간격이 고르게 보여요.
- `robinctl learn`이 미션 목록을 보여 줘요.
- `~/.local/state/robinos/session.log`에 렌더링 방식이 찍혀요(VM에서는 대부분 software).
- `/etc/motd`에 윤리 안내가 나와요.

라이브 환경에서 이것도 확인해요.

```bash
robinctl doctor
robinctl lab info web
ls /opt/robinos /usr/share/sddm/themes/robinos /usr/share/grub/themes/robinos
```
