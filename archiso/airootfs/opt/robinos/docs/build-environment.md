# RobinOS 빌드 환경

RobinOS ISO는 Arch Linux에서 빌드해야 해요. `mkarchiso`가 리눅스 도구, pacman 저장소, 루프 디바이스, squashfs, ISO 생성 도구를 쓰기 때문이에요.

## 윈도우 PC에서 WSL 2로 빌드하기 (권장)

윈도우 10/11 PC 한 대로 빌드부터 VM 테스트까지 할 수 있어요. WSL 2에 공식 Arch Linux 배포판을 깔아서 그 안에서 `mkarchiso`와 QEMU를 돌려요.

처음 한 번은 관리자 PowerShell에서 WSL 2를 켜고 재부팅해요.

```powershell
wsl --install --no-distribution
```

재부팅한 뒤 일반 PowerShell에서 Arch Linux를 설치하고 빌드 도구를 준비해요.

```powershell
wsl --install archlinux --no-launch
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 setup
```

그다음부터는 이 명령들로 빌드하고 테스트해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
```

- WSL 쪽에는 `/root/RobinOS`에 따로 클론을 두고, 명령을 실행할 때마다 이 저장소의 현재 커밋(HEAD)으로 맞춰요. 커밋하지 않은 변경은 넘어가지 않으니 먼저 커밋하세요. 윈도우 폴더(`/mnt/c`)에서 바로 빌드하면 느리고 파일 권한이 사라져요.
- ISO는 WSL 안의 `/root/RobinOS/out/`에 생겨요. 테스트 스크린샷과 시리얼 로그는 이 저장소의 `build\boot-test`, `build\install-test`로 복사돼요.
- 윈도우 10의 WSL 2에는 KVM이 없어서 WSL 안의 QEMU는 소프트웨어 에뮬레이션(TCG)으로 돌아요. 느리고, 느린 탓에 키 입력이 반복되는 일도 있어요. 그래서 부팅 테스트는 아래의 Windows용 QEMU(WHPX)를 먼저 써요.
- `scripts/wsl-build.ps1 shell`은 WSL의 `/root/RobinOS`에서 셸을 열어요.

### VM 테스트를 빠르게: Windows용 QEMU와 WHPX

윈도우 하이퍼바이저 플랫폼(WHPX)을 쓰면 VM이 TCG보다 몇 배 빨라요. 처음 한 번만 준비해요.

1. 관리자 PowerShell에서 하이퍼바이저 플랫폼을 켜고 재부팅해요.

   ```powershell
   dism /online /enable-feature /featurename:HypervisorPlatform /all /norestart
   ```

2. [qemu.weilnetz.de/w64](https://qemu.weilnetz.de/w64/)에서 `qemu-w64-setup-*.exe`와 `.sha512`를 받아 체크섬을 확인해요. 설치 파일을 실행하지 않고 7-Zip으로 `%USERPROFILE%\RobinOS-tools\qemu`에 풀어요. 관리자 권한이 필요 없어요.

   ```powershell
   & "C:\Program Files\7-Zip\7z.exe" x qemu-w64-setup-20260811.exe "-o$env:USERPROFILE\RobinOS-tools\qemu"
   ```

   7-Zip이 없으면 설치하지 않고 써도 돼요. [7-Zip GitHub 릴리스](https://github.com/ip7z/7zip/releases)에서 `7zr.exe`와 `7z<버전>-x64.exe`를 받아 SHA-256(릴리스 페이지의 digest)을 확인하고, `7zr.exe`로 설치 파일을 풀면 `7z.exe`가 나와요.

   ```powershell
   .\7zr.exe x 7z2604-x64.exe "-o$env:USERPROFILE\RobinOS-tools\7zip"
   & "$env:USERPROFILE\RobinOS-tools\7zip\7z.exe" x qemu-w64-setup-20260811.exe "-o$env:USERPROFILE\RobinOS-tools\qemu"
   ```

3. Windows용 Python이 있어야 해요(`python` 명령).

저장소가 `바탕화면`처럼 한글이 들어간 경로에 있어도 돼요. Windows용 QEMU는 명령줄의 한글 경로를 깨뜨려서, 스크립트가 QEMU를 `build\` 폴더에서 상대 경로로 실행해요.

이렇게 준비하면 `scripts/wsl-build.ps1 boot-test`가 알아서 WHPX를 써요. WSL이 ISO를 `build\vm`으로 복사하고 커널을 꺼내면(`scripts/vm-prepare.sh`), Windows에서 QEMU를 띄우고 `scripts/boot-test-qmp.py`가 TCP로 조작해요. `-Accel tcg`를 붙이면 예전처럼 WSL 안에서 돌고, QEMU 위치가 다르면 `-Qemu <경로>`로 알려 줘요.

## 처음 쓰는 PC에서 한 번에 검증하기

RobinOS를 빌드해 본 적 없는 윈도우 PC(학교 PC 등)에서는 `scripts/verify-all-in-one.ps1` 하나로 준비부터 검증까지 해요. 저장소를 미리 받지 않아도 돼요. PowerShell에서 이 한 줄을 실행해요(관리자가 아니어도 돼요).

```powershell
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iwr -UseBasicParsing https://raw.githubusercontent.com/Yoon-robin/RobinOS/claude/eoseohae-7nleia/scripts/verify-all-in-one.ps1 -OutFile $env:TEMP\rv.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\rv.ps1
```

1. 이 PC를 확인해요: 윈도우 빌드, 메모리, 남은 공간(40GB 이상), 관리자 권한, 가상화
2. WSL 2와 Arch Linux: 없으면 관리자일 때만 켜고 "다시 켠 뒤 다시 실행"하라고 해요. 관리자 권한이 없으면 무엇이 막혔는지 적고 멈춰요
3. 도구: 없는 것만 `%USERPROFILE%\RobinOS-tools`에 받아요. QEMU(qemu.weilnetz.de, SHA-512), 7-Zip(깃허브 릴리스 digest), Python(python.org API의 SHA-256), Git(MinGit, 깃허브 릴리스 digest). 체크섬이 맞지 않으면 지우고 멈춰요
4. 하이퍼바이저 플랫폼(WHPX)이 되는지 QEMU로 바로 시험해요
5. 브랜치를 `C:\RobinOS-verify\RobinOS`에 받고 `wsl-build.ps1`의 `setup`, `check`, `verify`를 차례로 돌려요. 메모리가 16GB보다 적으면 빌드·부팅 테스트·설치 테스트를 차례로(12GB보다 적으면 테스트 VM 4GB), WHPX가 안 되면 ISO 빌드와 느린 부팅 테스트만 해요
6. 결과를 `C:\RobinOS-verify\results-<시각>.zip`(요약 `summary.txt`, 단계별 기록, 스크린샷, 시리얼 로그)으로 모아요. 이 zip을 Claude 대화창에 올리면 돼요

단계마다 보통 걸리는 시간과 제한 시간을 보여 줘요. 제한 시간을 넘긴 단계는 그때 돌던 프로세스를 결과 폴더의 `<단계>-stuck.txt`에 남기고 멈춘 뒤 다음 단계로 넘어가요.

다시 실행해도 돼요. 앞서 실행한 것이 아직 돌고 있으면(창을 닫지 않았거나 멈췄으면) 먼저 끝내요. 받아 둔 도구와 저장소를 다시 쓰고, 끊긴 곳부터 이어서 해요. 브랜치는 `-Branch`, 설치 방식은 `-Installer`, 설치 테스트를 빼려면 `-SkipInstallTest`예요.

## 다른 PC에서 이어서 하기

작업 기록은 모두 깃허브에 있어요. 지금 할 일과 진행 상황은 [tasks.md](tasks.md), 작업 순서는 [loop.md](loop.md), Claude가 지킬 규칙은 저장소의 `CLAUDE.md`예요. 새 PC에서는 이렇게 해요.

1. 저장소를 받아요: `git clone https://github.com/Yoon-robin/RobinOS.git`
2. 위의 "윈도우 PC에서 WSL 2로 빌드하기"와 "VM 테스트를 빠르게"를 한 번 해요(WSL 2, Arch Linux, `wsl-build.ps1 setup`, Windows용 QEMU, Python)
3. 서명 열쇠를 옮겨요. 릴리스 ISO 체크섬과 RobinOS 패키지 저장소에 서명할 때만 필요해요(없으면 빌드는 되고 서명만 빠져요). 백업한 USB의 `robinos-release-secret.asc`를 바탕화면에 복사한 뒤 아래를 실행하고, 바탕화면의 복사본은 지워요.

   ```powershell
   $key = wsl.exe -d archlinux -e wslpath -a "$env:USERPROFILE\Desktop\robinos-release-secret.asc"
   wsl.exe -d archlinux -u root -e bash -c "install -d -m 700 /root/.robinos-signing && GNUPGHOME=/root/.robinos-signing gpg --batch --import '$key' && GNUPGHOME=/root/.robinos-signing gpg --list-secret-keys"
   ```

   지문 `D8EB 0C49 5CBF 5B2B BB57 EACC FD9B 53B8 B79E 9AAD`가 보이면 돼요.
4. Claude Code에서 저장소 폴더를 열고 `/loop docs/loop.md 절차대로 RobinOS 작업을 한 회차 진행해`라고 보내요. tasks.md를 읽고 이어서 해요.

VMware 시험(T-025)은 VMware Workstation과 VM이 있는 PC에서만 해요.

이미 준비된 PC로 돌아왔을 때는 `git pull`을 하고, `wsl-build.ps1 setup`도 한 번 다시 돌려요. WSL의 Quickshell과 Qt가 ISO에 들어가는 최신판과 같아야 `check`의 qmllint가 실제 제품과 같은 기준으로 봐요. 2026-10-12 robin PC는 Quickshell 0.3.1에 머물러 있었고, `setup` 뒤에 0.3.2 기준 오탐 6개가 처음 드러났어요(`scripts/qmllint.sh`에서 걸러요).

## 다른 방법

저장소를 고치고 정적 검사를 하는 건 윈도우에서도 돼요. WSL 2를 쓰지 않는다면 ISO를 만들려면 아래 중 하나가 있어야 해요.

- Arch Linux VM
- Arch Linux를 설치한 실기기
- Docker와 특권(privileged) 컨테이너를 쓸 수 있는 리눅스 호스트
- Arch 도구를 제대로 돌릴 수 있는 VM 환경

## Arch Linux VM

윈도우 Pro라면 프로젝트에 들어 있는 Hyper-V 도우미 스크립트를 쓸 수 있어요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-hyperv-arch-vm.ps1
```

`docs/hyperv-vm.md`를 참고하세요.

```bash
sudo pacman -Syu
sudo pacman -S --needed git archiso grub qemu-full edk2-ovmf
git clone https://github.com/Yoon-robin/RobinOS.git
cd RobinOS
scripts/doctor-build.sh
scripts/build-iso.sh
scripts/run-vm.sh
```

## 윈도우 기능 켜기 도우미

관리자 권한 PowerShell에서 실행해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-windows-build-env.ps1
```

WSL 기본 기능을 켜 주는데, 재부팅이 필요할 수 있어요. 이것만으로는 부족하고, `mkarchiso`를 실행하려면 Arch를 돌릴 수 있는 리눅스 환경이 여전히 필요해요.

## Docker로 빌드하기

Docker가 설치된 리눅스 호스트에서 실행해요.

```bash
scripts/build-in-arch-container.sh
```

Docker를 특권 모드로 돌려야 해서, 일반적인 윈도우 Docker 환경에서는 안 될 수 있어요.
