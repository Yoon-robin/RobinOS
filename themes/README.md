# RobinOS 테마

이 디렉터리에는 RobinOS 시각 아이덴티티의 첫 작업물이 들어 있어요. 라이브 ISO와 설치된 시스템에서 써요.

## 들어 있는 것

- `themes/sddm/robinos`: SDDM 로그인 테마 프로토타입
- `themes/grub/robinos`: GRUB 부팅 메뉴 테마 프로토타입
- `assets/wallpapers/robinos-default.svg`: 기본 데스크톱 배경화면
- `assets/wallpapers/robinos-lock.svg`: 잠금·로그인 화면 배경화면

## 설치 위치

나중에 패키지로 만들면 이렇게 설치해야 해요.

```text
assets/wallpapers/*.svg -> /usr/share/wallpapers/RobinOS/
themes/sddm/robinos -> /usr/share/sddm/themes/robinos
themes/grub/robinos -> /usr/share/grub/themes/robinos
```

데스크톱 테마(셸, Hyprland, foot, GTK/Qt, 글꼴)는 `desktop/`에 있고 `scripts/install-desktop.sh`로 설치해요. 자세한 내용은 `docs/desktop.md`를 보세요.

지금 프로토타입에서는 이렇게 해요.

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

라이브 ISO 부팅 메뉴 브랜딩은 이렇게 해요.

```bash
scripts/prepare-archiso.sh
```

이 명령은 만들어진 `build/archiso-profile`을 대상으로 `scripts/customize-iso-boot.sh`를 실행해요.
