# RobinOS 빌드 환경

RobinOS ISO는 Arch Linux에서 빌드해야 해요. `mkarchiso`가 리눅스 도구, pacman 저장소, 루프 디바이스, squashfs, ISO 생성 도구를 쓰기 때문이에요.

## 지금 윈도우에서의 한계

저장소를 고치고 정적 검사를 하는 건 윈도우에서도 돼요. 하지만 ISO를 만들려면 아래 중 하나가 있어야 해요.

- Arch Linux VM
- Arch Linux를 설치한 실기기
- Docker와 특권(privileged) 컨테이너를 쓸 수 있는 리눅스 호스트
- Arch 도구를 제대로 돌릴 수 있는 WSL/VM 환경

## 권장 방법

Arch Linux VM을 쓰세요.

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

## 윈도우 도우미 스크립트

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
