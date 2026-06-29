# RobinOS 빌드

RobinOS ISO는 **공식 Arch `releng` 프로파일을 베이스로 복사한 뒤 RobinOS 레이어를 얹어서**
빌드한다. 부팅·EFI·MBR 같은 깨지기 쉬운 부분은 공식 걸 그대로 쓰고, 그 위에 패키지 목록,
데스크톱 설정, 브랜딩만 더한다. ([build/build.sh](../build/build.sh) 참고)

빌드는 반드시 **Arch 환경 + root**에서 돈다. 방법 세 가지.

## 1. GitHub Actions (기본 / 권장)

`main`에 `iso/`, `branding/`, `build/`를 푸시하거나 Actions 탭에서 **Build RobinOS ISO →
Run workflow**를 누르면 Arch 컨테이너에서 ISO를 굽는다. 완료되면 워크플로 실행 페이지 하단
**Artifacts → robinos-iso**에서 ISO를 내려받는다.

- Linux 환경이 따로 필요 없다.
- 비공개 저장소는 Actions 분(分)을 소모한다(무료 한도 월 2000분, 빌드 1회 약 15~25분).

## 2. 로컬 Docker

Docker만 있으면 Arch 없이 빌드된다.

```bash
bash scripts/build-docker.sh
# → ./out/robinos-*.iso
```

> Windows라면 Docker Desktop(WSL2 백엔드)을 설치한 뒤 Git Bash/WSL에서 실행.

## 3. 로컬 Arch

```bash
sudo pacman -S archiso librsvg
sudo bash build/build.sh
# → ./out/robinos-*.iso
```

## 부팅 테스트

```bash
bash scripts/test-qemu.sh            # 최신 out/*.iso 자동 선택
bash scripts/test-qemu.sh path.iso   # 특정 ISO 지정
```

## USB로 굽기

```bash
# Linux
sudo dd if=out/robinos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Windows는 [Rufus](https://rufus.ie) / [balenaEtcher](https://etcher.balena.io)로 ISO를
그대로 USB에 쓰면 된다 (DD 모드).

## 설치

라이브 환경에서 터미널을 열고:

```bash
sudo archinstall
```

전용 RobinOS 설치기는 이후 단계에서 추가한다.
