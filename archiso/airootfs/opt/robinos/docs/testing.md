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

## 화면 확인

확인할 것:

- 부팅 메뉴에 RobinOS Security Learning Live가 보여요
- SDDM이 RobinOS 테마를 써요
- RobinOS 데스크톱이 떠요: 상단 바, 독, 점 격자 배경화면
- `Super+Space`로 런처가, `Super+S`로 빠른 설정이 열려요
- foot이 RobinOS 색상을 쓰고, 오른쪽 Alt로 한/영이 바뀌어요
- `/opt/robinos`에 문서, 스크립트, 패키지, 랩, 에셋, 테마가 들어 있어요

자세한 내용은 `docs/vm-smoke-test.md`에 있어요.
