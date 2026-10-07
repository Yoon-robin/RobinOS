# RobinOS 테스트

RobinOS의 초기 검증은 두 단계로 나뉘어요.

## 윈도우에서 정적 검증

저장소 루트에서 실행하세요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
```

검사 항목:

- 필수 파일
- SVG/XML 유효성
- 중복된 패키지 항목
- `archiso/packages.x86_64`에 핵심 패키지가 다 들어 있는지
- ISO에 들어가야 할 보안 패키지가 다 들어 있는지
- ISO 오버레이 경로

GitHub Actions에서도 `.github/workflows/validate.yml`로 같은 검사를 실행해요.

로컬 CI 래퍼는 이렇게 실행해요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/ci-local.ps1
```

## Arch에서 패키지 검증

Arch Linux나 RobinOS 라이브 환경에서 실행하세요.

```bash
scripts/check-arch-packages.sh
```

`pacman -Si`로 설정된 저장소에 패키지 이름이 실제로 있는지 확인해요.

같은 패키지 검사를 GitHub Actions에서 `.github/workflows/arch-package-check.yml`로 직접 실행할 수도 있어요.

## ISO 빌드 스모크 테스트

Arch Linux에서:

```bash
sudo pacman -S --needed archiso git
scripts/doctor-build.sh
scripts/build-iso.sh
```

예상 결과:

```text
out/robinos-*.iso
out/SHA256SUMS
build/logs/mkarchiso-*.log
```

## VM 부팅 확인

QEMU로 ISO를 부팅해요.

```bash
scripts/run-vm.sh
```

VM에서 ISO로 부팅한 다음 확인해요.

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

`scripts/boot-test.sh`가 QEMU에서 ISO를 부팅하고 환영 마법사, 런처, 빠른 설정, 터미널, 잠금 화면을 차례로 열면서 스크린샷을 찍어요. 윈도우 PC에서는 WSL 2로 돌려요([build-environment.md](build-environment.md)).

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
```

스크린샷과 `serial.log`는 `build\boot-test`에 생겨요.

## 설치 테스트

`scripts/install-test.sh`는 [install.md](install.md)의 설치 과정을 VM에서 처음부터 끝까지 돌려요.

1. 라이브 ISO에서 archinstall로 빈 40GB 디스크에 설치해요(기본 Btrfs 구성, GRUB, EFI는 `/boot`).
2. 설치한 시스템에서 `scripts/post-install.sh --yes`를 실행해요. 이때 쓰는 RobinOS 파일은 ISO 안의 사본이 아니라 지금 저장소예요.
3. 다시 부팅해서 GRUB 메뉴와 스냅샷 하위 메뉴를 찍고, `pacman -S cowsay`로 snap-pac 스냅샷이 생기는지 봐요.
4. 설치 전 스냅샷으로 `robinctl snapshot rollback` 하고 재부팅해서 cowsay가 사라졌는지 확인해요.
5. SDDM에서 로그인해 데스크톱을 찍어요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
```

패키지를 내려받아 설치하니까 인터넷이 필요하고, 소프트웨어 에뮬레이션에서는 한 시간 넘게 걸릴 수 있어요. 결과는 `build\install-test`에 생겨요.

## 화면 확인

확인할 것:

- 부팅 메뉴에 RobinOS Security Learning Live가 보여요
- SDDM이 RobinOS 테마를 써요
- RobinOS 데스크톱이 떠요: 상단 바, 독, 점 격자 배경화면
- `Super+Space`로 런처가, `Super+S`로 빠른 설정이 열려요
- foot이 RobinOS 색상을 쓰고, 오른쪽 Alt로 한/영이 바뀌어요
- `/opt/robinos`에 문서, 스크립트, 패키지, 랩, 에셋, 테마가 들어 있어요

자세한 내용은 `docs/vm-smoke-test.md`에 있어요.
