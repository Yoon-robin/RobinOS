# RobinOS 릴리스 체크리스트

RobinOS 프리뷰 ISO를 낼 때 쓰는 초기 릴리스 체크리스트예요.

## 빌드

Arch Linux에서:

```bash
sudo pacman -S --needed archiso git
scripts/doctor-build.sh
scripts/build-iso.sh
```

패키지 이름을 이미 확인했다면 이렇게 더 빨리 다시 빌드할 수 있어요.

```bash
scripts/build-iso.sh --skip-package-check
```

## 빌드 결과물

나와야 하는 파일:

```text
out/robinos-*.iso
out/SHA256SUMS
build/logs/mkarchiso-*.log
```

## 스모크 테스트

VM에서 ISO를 부팅하고 확인해요.

```bash
scripts/run-vm.sh
```

```bash
robinctl doctor
robinctl lab info web
ls /opt/robinos
ls /usr/share/sddm/themes/robinos
ls /usr/share/grub/themes/robinos
```

## 직접 화면 확인

- 라이브 부팅 메뉴에 RobinOS Security Learning Live가 보여요
- SDDM에 RobinOS 테마가 나와요
- RobinOS 데스크톱이 떠요: 상단 바, 독, 점 격자 배경화면
- `Super+Space`로 런처가, `Super+S`로 빠른 설정이 열려요
- foot이 RobinOS 색상을 쓰고, 오른쪽 Alt로 한/영이 바뀌어요

## 배포

아래 조건을 모두 채우기 전에는 배포하지 마세요.

- 정적 검증 통과
- Arch 패키지 검증 통과
- ISO 빌드 성공
- VM 부팅 성공
- SHA256SUMS 생성
- 문서와 MOTD에 윤리 안내가 보임
