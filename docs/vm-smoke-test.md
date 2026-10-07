# RobinOS VM 스모크 테스트

ISO를 빌드했으면 VM에서 부팅해서 라이브 환경을 확인해요.

## QEMU

Arch Linux에서 실행해요.

```bash
sudo pacman -S --needed qemu-full
scripts/run-vm.sh
```

메모리와 CPU를 더 주려면 이렇게 실행해요.

```bash
scripts/run-vm.sh --memory 8192 --cpus 4
```

특정 ISO로 부팅하려면 경로를 지정해요.

```bash
scripts/run-vm.sh --iso out/robinos-YYYY.MM.DD-x86_64.iso
```

UEFI 부팅도 시험해 볼 수 있어요.

```bash
sudo pacman -S --needed edk2-ovmf
scripts/run-vm.sh --uefi
```

## 라이브 환경 점검

부팅한 라이브 환경에서 실행해요.

```bash
robinctl version
robinctl doctor
robinctl lab info web
robinctl packages core
robinctl packages security
ls /opt/robinos
ls /usr/share/sddm/themes/robinos
ls /usr/share/grub/themes/robinos
```

## 자동 부팅 테스트

GitHub Actions가 새 ISO가 나올 때마다 부팅해서 데스크톱 스크린샷을 찍어요(`docs/ci.md`). 리눅스 호스트에서도 같은 테스트를 돌릴 수 있어요.

```bash
scripts/boot-test.sh out/robinos-*.iso
```

## 화면 확인

- 부팅 메뉴에 "RobinOS Security Learning Live"가 보여요.
- SDDM이 RobinOS 테마로 떠요.
- RobinOS 데스크톱이 시작되고 상단 바, 독, 점 격자 배경화면이 보여요.
- `Super+Space`로 런처가, `Super+S`로 빠른 설정이 열려요.
- foot이 RobinOS 색상을 쓰고, 오른쪽 Alt로 한/영이 바뀌어요.
- `~/.local/state/robinos/session.log`에 렌더링 모드가 찍혀요(VM에서는 대부분 소프트웨어 모드).
- `/etc/motd`에 윤리 안내문이 나와요.
