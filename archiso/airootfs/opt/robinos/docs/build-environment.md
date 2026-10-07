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
- 윈도우 10의 WSL 2에는 KVM이 없어서 QEMU가 소프트웨어 에뮬레이션(TCG)으로 돌아요. 부팅 테스트는 기다리는 시간을 4배로 늘려서 자동으로 맞춰요. 윈도우 11은 중첩 가상화로 KVM을 쓸 수 있어요.
- `scripts/wsl-build.ps1 shell`은 WSL의 `/root/RobinOS`에서 셸을 열어요.

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
