# RobinOS ISO 빌드

Arch Linux나 Arch 기반 VM에서 빌드해요.

윈도우 PC에서는 `scripts/wsl-build.ps1 build` 하나로 아래 과정을 WSL 2의 Arch Linux에서 해요. 환경 준비는 [build-environment.md](build-environment.md)에 있어요.

## 요구사항

```bash
sudo pacman -S --needed archiso git grub
```

빌드하기 전에 패키지 이름이 맞는지 확인해요.

```bash
scripts/doctor-build.sh
scripts/check-arch-packages.sh
```

## 프로필 준비

Arch Linux에서 저장소 루트로 가서 실행해요.

```bash
scripts/prepare-archiso.sh
```

이 스크립트는 Arch 공식 `releng` 프로필을 `build/archiso-profile`에 복사한 뒤, 그 위에 RobinOS 파일을 덮어써요.
`scripts/customize-iso-boot.sh`도 함께 실행해서 라이브 부팅 메뉴 이름을 바꾸고, 생성된 프로필에 RobinOS GRUB 테마를 넣어 둬요.

Windows PowerShell에서는 프로젝트 파일을 소스 오버레이에 동기화하는 데까지만 할 수 있어요.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-archiso-files.ps1
```

실제 ISO 빌드는 여전히 Arch Linux에서 해야 해요.

RobinOS 스크립트의 실행 권한은 ISO 프로필의 `archiso/profiledef.sh`에서 설정해요.

## 빌드

```bash
scripts/build-iso.sh
```

빌드는 프로필을 준비한 뒤, 같은 커밋의 RobinOS 패키지(`robinos`)를 만들어 ISO의 `/opt/robinos/pkg`에 넣어요(`sudo scripts/build-package.sh`). 설치기는 이 패키지로 RobinOS 파일의 주인을 pacman에 넘겨요([design.md](design.md) "RobinOS 파일 업데이트"). 패키지는 작업 트리가 아니라 HEAD를 `git clone`해서 만들어요. 커밋하지 않은 변경은 오버레이에는 들어가도 패키지에는 안 들어가고, 설치할 때 패키지가 그 파일을 덮어써요. 그러니 빌드 전에 먼저 커밋해요.

ISO, 체크섬 파일, 패키지, 빌드 로그는 아래 위치에 저장돼요.

```text
out/robinos-*.iso
out/SHA256SUMS
out/SHA256SUMS.sig                          (이 PC에 릴리스 열쇠가 있을 때)
out/packages/robinos-*.pkg.tar.zst(.sig)
build/logs/
```

빌드 환경 점검을 건너뛰려면 `--skip-doctor`를 붙여요.

패키지 확인을 이미 마쳤다면 이렇게 더 빠르게 다시 빌드할 수 있어요.

```bash
scripts/build-iso.sh --skip-package-check
```

빌드로 생긴 결과물을 지우려면 아래 명령을 실행해요.

```bash
scripts/clean-build.sh --yes
```

가장 최근에 만든 ISO를 QEMU로 부팅해 보려면 이렇게 해요.

```bash
scripts/run-vm.sh
```

## VM에서 처음 확인할 것

ISO로 부팅한 뒤 다음 명령을 실행해 봐요.

```bash
robinctl version
robinctl doctor
robinctl profile list
robinctl lab list
ls /opt/robinos/assets/brand
ls /usr/share/grub/themes/robinos
```

라이브 ISO 부팅 메뉴 수정은 소스 오버레이인 `archiso/`에 바로 하지 않고 `build/archiso-profile`에 적용돼요. 빌드 프로필을 새로 만들고 싶을 때마다 `scripts/prepare-archiso.sh`를 다시 실행하세요.
