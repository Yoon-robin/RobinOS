# RobinOS용 Hyper-V Arch VM

윈도우에서 RobinOS를 빌드하는 다른 방법이에요. 보통은 WSL 2가 더 간단해요([build-environment.md](build-environment.md)).

## 요구사항

- Windows 10/11 Pro, Enterprise 또는 Education
- 관리자 권한 PowerShell
- 펌웨어 설정에서 가상화가 켜져 있을 것
- 네트워크 연결

## VM 만들기

PowerShell을 관리자 권한으로 열고 실행해요.

```powershell
cd "C:\Users\robin\바탕화면\RobinOS"
powershell -ExecutionPolicy Bypass -File scripts/setup-hyperv-arch-vm.ps1
```

스크립트가 Hyper-V를 켰다면 윈도우를 재부팅하고 같은 명령을 한 번 더 실행하세요.

스크립트가 만드는 VM은 다음과 같아요.

| 항목 | 값 |
|---|---|
| VM 이름 | `RobinOS-Builder` |
| 메모리 | 8GB |
| CPU | 4개 |
| 디스크 | 60GB |
| 설치 ISO | `%USERPROFILE%\Downloads\RobinOS-Builder\archlinux-x86_64.iso` |

## VM 시작하기

```powershell
Start-VM -Name "RobinOS-Builder"
vmconnect.exe localhost "RobinOS-Builder"
```

## Arch 안에서 RobinOS 빌드하기

Arch 환경 안에서 실행해요.

```bash
sudo pacman -Syu
sudo pacman -S --needed git archiso grub qemu-full edk2-ovmf
git clone https://github.com/Yoon-robin/RobinOS.git
cd RobinOS
scripts/doctor-build.sh
scripts/build-iso.sh
```

빌드가 끝난 ISO는 여기에 생겨요.

```text
out/
```
