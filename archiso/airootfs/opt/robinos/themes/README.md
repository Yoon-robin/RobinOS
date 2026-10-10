# RobinOS 테마

이 디렉터리에는 RobinOS 시각 아이덴티티의 첫 작업물이 들어 있어요. 라이브 ISO와 설치된 시스템에서 써요.

## 들어 있는 것

- `themes/sddm/robinos`: SDDM 로그인 테마 프로토타입
- `themes/grub/robinos`: GRUB 부팅 메뉴 테마 프로토타입
- `assets/wallpapers/robinos-default.svg`: 배경화면 파일(바탕 화면의 기본 배경은 셸이 직접 그려요, [docs/desktop.md](../docs/desktop.md)의 "배경화면")
- `assets/wallpapers/robinos-lock.svg`: 잠금·로그인 화면 배경화면

## 설치 위치

이 파일들은 `robinos` 패키지에 들어 있어서(`scripts/stage-robinos.sh`) 설치본에는 아래 위치에 있고 `sudo robinctl update`로 함께 올라가요.

```text
assets/wallpapers/*.svg -> /usr/share/wallpapers/RobinOS/
themes/sddm/robinos -> /usr/share/sddm/themes/robinos
themes/grub/robinos -> /usr/share/grub/themes/robinos
```

데스크톱 테마(셸, Hyprland, foot, GTK/Qt, 글꼴)는 `desktop/`에 있고 `scripts/install-desktop.sh`로 설치해요. 자세한 내용은 `docs/desktop.md`를 보세요.

패키지 없이 이 저장소에서 바로 설치해 보려면 이렇게 해요.

```bash
sudo scripts/install-branding.sh --dry-run
sudo scripts/install-branding.sh
```

라이브 ISO 부팅 메뉴 브랜딩은 이렇게 해요.

```bash
scripts/prepare-archiso.sh
```

이 명령은 만들어진 `build/archiso-profile`을 대상으로 `scripts/customize-iso-boot.sh`를 실행해요.
