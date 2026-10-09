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
| 설치와 복구 (`post-install.sh`, `robinctl snapshot`, `robin-install`) | 정적 검증, 설치기 테스트, 설치 테스트 |

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

`check`는 VM 없이 도는 빠른 테스트 두 개도 함께 돌려요. `scripts/test-robinctl.sh`는 미션 채점, 보안 프로필, 랩, 윈도우 명령 힌트를 보고, `scripts/test-robin-install.py`는 설치기가 그래픽 카드에 맞는 드라이버를 고르는지(가짜 `/sys/bus/pci/devices`로), initramfs 훅, fstab 정리를 봐요. 실제 NVIDIA 카드에서 드라이버가 뜨는지는 실기기에서만 확인할 수 있어요.

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

`scripts/boot-test.sh`가 QEMU에서 ISO를 부팅하고, `scripts/boot-test-qmp.py`가 화면을 조작하면서 스크린샷을 찍어요(2026-10-09 기준 58장). 키는 QMP `send-key`로, 마우스는 VM에 붙인 `usb-tablet`에 QMP `input-send-event`로 화면 좌표(1600×900)를 찍어 눌러요(`click()`). 소리 창을 보려고 소리를 버리는 사운드 카드(`-audiodev none`, `hda-duplex`)도 붙여요.

1. 부팅과 첫 로그인
2. 환영 마법사의 모든 단계, 마지막에 열리는 학습 센터(0/40)
3. 데스크톱
4. 런처: 추천 목록, `term` 검색, 윈도우 이름 `notepad` 검색
5. 설치기 첫 두 단계(테스트 VM에는 빈 64GB 디스크가 있어요)
6. 빠른 설정, Tab으로 옮긴 키보드 포커스, 마우스로 누른 방해 금지 타일, Wi-Fi 타일 화살표로 연 연결 창(VM에는 Wi-Fi 장치가 없다는 안내), `Super+Alt+D`로 연 달력, `Super+F1`로 연 단축키 보기
7. 터미널: `ipconfig` 힌트, `robinctl learn show 1`과 미션 1 풀기(라이트 모드 런처에 "1/40 완료"), 포털이 알려 주는 제목 표시줄 단추 배치(`button-layout`)
8. 독처럼 최소화하고 되돌리기, `Super+←`(왼쪽 절반), `Super+↑`(최대화), `Super+↓` 두 번(원래 크기), `Super+Ctrl+→`(빈 작업 공간 2)와 `Super+Ctrl+←`, `Super+D` 두 번(바탕 화면 보기와 되돌리기), `Super+Shift+S`(영역 고르기 화면, Esc로 취소), `Shift+Print`로 찍은 전체 화면 알림("폴더 열기" 단추), `Super+V`(복사한 글이 클립보드 기록에), `notify-send`로 띄운 한국어 알림(오른쪽 아래)과 `Super+N`으로 연 알림 센터, IPC로 연 블루투스 연결 창(창 밖을 눌러 닫기), 런처에서 윈도우 이름 `mixer`로 연 소리 창(VM 사운드 카드가 출력·입력 장치로, `pw-play`가 앱별 음량에), 바의 트레이 아이콘(ISO에 든 테스트용 `scripts/sni-test-item.sh`를 띄우고, 아이콘을 눌러 앱에 닿는지), 바의 상태 아이콘 위 휠로 줄인 음량(음량 표시), Wallpaper 포털로 바꾼 배경화면과 런처의 "기본 배경화면으로", 독과 런처에서 오른쪽 클릭으로 계산기 고정하기, `Alt`를 누른 채 `Tab`을 눌러 연 창 전환 화면(터미널과 계산기 미리보기)과 `Alt`를 놓아 바뀐 창
9. 셸을 끄면 `robinos-shell`이 다시 띄우는지
10. 라이트 모드(셸 IPC `setDark false`): 터미널(`robinctl learn` 목록), 런처(최근에 연 앱)와 파일 찾기(`notes`), Alt+F4로 닫았다가 IPC로 다시 연 학습 센터(미션 1에 체크, 미션 2 줄을 눌러 터미널에 열기, 닫기 단추), 빠른 설정, 화면 배율 125%(저장된 파일 내용과 함께), 야간 모드(VM 그래픽에는 색 변환이 없어 `hyprsunset`이 켜지는지만 봐요). 찍은 뒤 다크로 돌려요
11. 잠금 화면과 잠금 해제

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
```

스크린샷과 `serial.log`는 `build\boot-test`에 생겨요. 테스트는 `robinos.debug`를 붙여 부팅해서 `robinos-session`이 Hyprland와 셸 출력을 저널로 보내고, 그 내용이 `serial.log`에 남아요. 셸이 안 뜨면 여기서 QML 오류를 찾으세요.

Windows용 QEMU가 준비돼 있으면 WHPX 가속으로 돌아요([build-environment.md](build-environment.md)). 없으면 WSL 안에서 소프트웨어 에뮬레이션(TCG)으로 돌고, 기다리는 시간을 4배로 늘려요. TCG에서는 VM이 느려서 키 입력이 반복될 수 있으니, 이상한 결과가 나오면 테스트 탓인지 먼저 가려요.

## 묶음 검증 (verify)

여러 커밋을 한 번에 검증할 때는 빌드와 두 테스트를 따로 돌리지 않고 이렇게 해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 verify -Installer robinos
```

1. squashfs를 xz 대신 zstd로 압축한 테스트 ISO를 빌드해요(`ROBINOS_FAST_ISO=1`). 빌드와 부팅이 빨라지는 대신 2GiB를 넘어서 릴리스에는 쓰지 않아요.
2. ISO를 `build\vm`에 한 번만 준비하고, 부팅 테스트(QMP 47011)와 설치 테스트(47021, 47022)를 동시에 띄워요. VM마다 6GB와 CPU 4개를 써요. 부팅 테스트의 출력은 `build\verify-boot.log`에 남아요.
3. 끝나면 빌드와 테스트에 걸린 시간을 보여 줘요. 결과는 따로 돌릴 때와 같은 `build\boot-test`, `build\install-test`에 생겨요.

WHPX가 필요해요. TCG에서는 `build`, `boot-test`, `install-test`를 차례로 돌려요.

## 설치 테스트

`scripts/install-test.sh`는 빈 40GB 디스크에 RobinOS를 설치하고, 설치한 시스템을 시리얼 콘솔로 조작하면서 확인해요. RobinOS 파일은 ISO 안의 사본이 아니라 지금 저장소 것을 써요(읽기 전용 FAT 디스크로 넘겨요).

설치 방식은 세 가지예요.

- `archinstall` (기본): [install.md](install.md)의 방법 A예요. archinstall로 Arch를 설치하고(기본 Btrfs 구성, GRUB, EFI는 `/boot`) `scripts/post-install.sh --yes`를 실행해요.
- `robinos`: RobinOS 설치기 백엔드(`installer/robin-install`)로 디스크 전체에 설치해요(EFI는 `/efi`).
- `windows`: 윈도우가 깔린 것처럼 꾸민 64GB 디스크(100MB EFI 파티션과 그 안의 윈도우 부팅 관리자 자리, MSR, 20GB NTFS "C:", 나머지 빈 공간)에 RobinOS 설치기로 "윈도우 옆에 설치"해요. 설치 뒤 윈도우 파티션 세 개의 위치와 C:의 앞부분이 그대로인지, 윈도우 부팅 파일이 남아 있고 `EFI/RobinOS`만 더해졌는지, 하드웨어 시계가 지역 시간인지 확인해요.

설치한 뒤 확인하는 것:

1. `robinctl doctor`, 스냅샷 설정, `/etc/fstab`의 `@snapshots`, grub-btrfs 항목, 부팅 메뉴 이름, 보안 프로필 목록, 설치본 전용 앱(`packages/apps.txt`: 인쇄 서비스가 응답하는지, LibreOffice 한국어판, 앱 스토어와 Flathub 저장소, 동영상·음악 재생 앱과 `gio`로 본 기본 앱), 배경화면 포털 백엔드와 포털 설정, `filesystem`을 다시 설치한 뒤에도 RobinOS인 os-release, 사용자 `~/.bashrc`의 RobinOS 설정, `which`, 열린 포트
2. 재부팅해서 GRUB 메뉴와 스냅샷 하위 메뉴 스크린샷
3. `pacman -S cowsay`로 snap-pac의 전후 스냅샷이 생기는지
4. 다시 켜서 GRUB의 스냅샷 하위 메뉴로 cowsay 설치 전 스냅샷을 골라 부팅하고([recovery.md](recovery.md)의 비상 경로), 그 안에서 `robinctl snapshot rollback`
5. 다시 켜서 cowsay가 사라졌는지 확인하고, SDDM에서 로그인한 데스크톱 스크린샷과 런처 장면(`word`, `store`, `printer`, `steam`, `video`)
6. `-Lab`을 붙이면 마지막에 웹 랩을 실제로 띄워요: `robinctl profile web`으로 Docker를 설치하고 `robinctl lab start web`으로 고정한 이미지를 받아 켠 뒤, Juice Shop과 DVWA가 `127.0.0.1`에서만 응답하는지, 셸의 랩 상태 확인(docker-proxy)이 보는지 확인하고 꺼요. 이어서 네트워크 스캔 랩(`robinctl lab start net`)을 켜고, 172.30.66.0/24의 네 대(웹 페이지, Redis 포트, 31337 배너, 포트 없는 컴퓨터의 ping)가 응답하는지, 호스트 포트에는 아무것도 열리지 않는지 확인하고 꺼요. 이미지를 내려받아서 몇 분 더 걸려요

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test -Installer robinos
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test -Installer windows
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test -Lab
```

패키지를 내려받으니 인터넷이 필요해요. Windows용 QEMU가 있으면 부팅 테스트처럼 WHPX로 돌아요(UEFI 펌웨어는 QEMU에 들어 있는 `edk2-x86_64-code.fd`, 공유 폴더는 `fat:` 디스크). 없으면 WSL 안에서 TCG로 돌아서 한 시간 넘게 걸릴 수 있어요. 결과(스크린샷, 단계별 시리얼 로그)는 `build\install-test`에 생겨요.

설치 테스트는 VM을 켤 때마다 `scripts/install-test.py`를 새로 읽어요. 테스트가 도는 동안 이 파일을 고치면 남은 단계가 바뀐 확인으로 돌아서, 아직 설치하지 않은 것을 찾다가 실패할 수 있어요. 고칠 게 있으면 테스트가 끝난 뒤에 고쳐요.

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
