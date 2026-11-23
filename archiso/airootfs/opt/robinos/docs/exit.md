# RobinOS가 멈추거나, 그만 쓰고 싶을 때

RobinOS는 개인 프로젝트예요. 언젠가 멈출 수 있고, 그때 내 컴퓨터가 어떻게 되는지를 미리 적어 둬요. 짧게 말하면 **컴퓨터는 계속 돌아가고, 파일은 그대로고, 저장소 한 줄을 빼면 일반 Arch Linux처럼 업데이트돼요.**

## RobinOS가 Arch 위에 얹은 것

RobinOS는 새 운영체제를 처음부터 만든 게 아니라 Arch Linux에 이것들을 얹은 거예요.

| 얹은 것 | 어디 있나 | 멈추면 |
|---|---|---|
| `robinos` 패키지: 화면(셸), `robinctl`, 학습 미션, 설정 기본값 | 내 컴퓨터(`/usr/share/robinos`, `/opt/robinos`) | 마지막으로 올라온 버전 그대로 남아요 |
| `[robinos]` 저장소: 위 패키지의 업데이트를 받는 곳 | GitHub 릴리스(`repo`) | 사라지면 업데이트만 못 받아요 |
| 부팅 메뉴, 스냅샷(snapper, grub-btrfs), 방화벽(ufw), 백업 앱 같은 설정 | 내 컴퓨터 | 모두 널리 쓰는 도구라 그대로 돌아가요 |

내 문서와 사진 같은 개인 파일은 `/home`에 있고 RobinOS 파일과 따로예요. 어떤 경우에도 건드리지 않아요.

## 프로젝트가 멈췄을 때

1. **컴퓨터는 그대로 켜져요.** 부팅, 로그인, 앱, 스냅샷으로 되돌리기는 모두 그대로예요.
2. **업데이트는 Arch 저장소에서 계속 와요.** `[robinos]` 저장소가 사라졌다면 `sudo pacman -Syu`가 그 저장소를 못 받아서 오류를 내요. `/etc/pacman.conf`의 맨 아래 `[robinos]` 블록(세 줄)을 지우면 돼요.

   ```bash
   sudoedit /etc/pacman.conf     # "# RobinOS files" 줄부터 [robinos] 블록을 지워요
   sudo pacman -Syu
   ```

   `robinos` 패키지는 어느 저장소에도 없는 패키지로 남고, pacman은 건드리지 않아요. 이때부터 `sudo robinctl update`는 필요 없고 `sudo pacman -Syu`를 써요. 스냅샷은 snap-pac이 pacman 앞뒤로 그대로 찍어요.
3. **RobinOS 화면은 마지막 버전에서 멈춰요.** 화면은 Hyprland와 Quickshell 위에서 돌아서, 그 둘이 크게 바뀌면 언젠가 깨질 수 있어요. 깨지면 부팅 메뉴의 스냅샷으로 돌아가거나, 아래 "다른 데스크톱으로"를 해요.

## RobinOS를 그만 쓰고 싶을 때

**RobinOS 파일만 지우고 일반 Arch로**

```bash
sudo pacman -Rns robinos           # RobinOS의 화면, robinctl, 미션, 설정 기본값
sudo pacman -S filesystem          # Arch의 os-release를 되돌려요(RobinOS 이름이 사라져요)
```

그다음 `/etc/pacman.conf`에서 `[robinos]` 블록을 지우고 쓰고 싶은 데스크톱을 설치해요(예: `sudo pacman -S gnome`이나 `plasma`). 로그인 화면(SDDM)에서 그 데스크톱을 골라요. 홈 폴더의 파일과 앱 설정은 그대로예요.

**다른 배포판으로**
파일은 `/home`에 있으니 외장 디스크에 복사하고 새로 설치해요. 설치기의 "만들어 둔 파티션에 설치"는 RobinOS가 아닌 배포판을 깔 때는 쓸 수 없어요. 그 배포판의 설치기를 쓰세요.

## 확인한 것과 확인하지 못한 것

- 설치 테스트가 매번 확인해요: `[robinos]` 블록을 뺀 설정으로도 `pacman -Sy`와 업데이트 계산이 되는지, 그때 `robinos`가 "저장소에 없는 패키지"로 남는지, 다른 패키지가 `robinos`에 기대고 있지 않아 지울 수 있는지.
- 확인하지 못한 것: `[robinos]` 서버가 실제로 사라진 상황, 그리고 `robinos`를 지운 뒤 다른 데스크톱으로 갈아타는 전 과정은 문서로만 있고 VM에서 해 본 적이 없어요.

## 소스는 열려 있어요

모든 코드는 GPL-3.0으로 [GitHub](https://github.com/Yoon-robin/RobinOS)에 있어요. 누구든 포크해서 이어 갈 수 있어요. ISO와 업데이트 저장소를 서명해서 올리는 방법은 [release.md](release.md)에 있어요. 이어 갈 사람은 서명 열쇠를 새로 만들어야 하고(지금 열쇠는 제 것이에요), 그 안내는 아직 따로 쓰지 않았어요.
