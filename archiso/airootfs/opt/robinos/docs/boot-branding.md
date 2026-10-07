# RobinOS 부팅 브랜딩

RobinOS에는 부팅 브랜딩의 첫 버전이 들어 있어요.

## 구성

- GRUB 테마: `themes/grub/robinos`
- GRUB 기본 설정 스니펫: `config/grub/10-robinos-theme.cfg`
- SDDM 테마: `themes/sddm/robinos`
- 잠금 화면 배경화면: `assets/wallpapers/robinos-lock.svg`
- 데스크톱 배경화면: `assets/wallpapers/robinos-default.svg`

## 설치된 시스템

설치된 Arch나 RobinOS 시스템에서:

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

스크립트가 설치하는 파일:

```text
/usr/share/grub/themes/robinos
/etc/default/grub.d/10-robinos-theme.cfg
/usr/share/sddm/themes/robinos
/etc/sddm.conf.d/10-robinos-theme.conf
```

`grub-mkconfig`를 쓸 수 있고 `/boot/grub`이 있으면 이 파일도 다시 만들어요.

```text
/boot/grub/grub.cfg
```

## 라이브 ISO

테마 파일은 라이브 파일 시스템의 이 위치에 들어 있어요.

```text
/usr/share/grub/themes/robinos
/opt/robinos/themes/grub/robinos
```

라이브 ISO 부팅 메뉴는 이 스크립트가 바꿔요.

```bash
scripts/customize-iso-boot.sh build/archiso-profile
```

이 스크립트는 아래 스크립트가 자동으로 실행해요.

```bash
scripts/prepare-archiso.sh
```

커스터마이저가 하는 일:

- RobinOS GRUB 테마를 생성된 프로필의 `grub/themes/robinos`에 복사해요
- GRUB 설정 파일이 있으면 `set theme=/grub/themes/robinos/theme.txt`를 추가해요
- GRUB 메뉴 문구를 RobinOS로 바꿔요
- Syslinux 메뉴 제목이 있으면 RobinOS로 바꿔요
- systemd-boot 로더 항목이 있으면 이름을 바꿔요

archiso 라벨이나 부팅 경로 같은 저수준 부팅 매개변수는 건드리지 않아요.
