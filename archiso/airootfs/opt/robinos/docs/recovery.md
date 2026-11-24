# 복구: 스냅샷으로 되돌리기

업데이트나 설치 때문에 시스템이 망가져도 스냅샷으로 이전 상태로 돌아갈 수 있어요. RobinOS는 snapper(스냅샷), snap-pac(pacman 전후 자동 스냅샷), grub-btrfs(부팅 메뉴의 스냅샷 항목)를 써요.

## 스냅샷과 백업

스냅샷은 시스템(`/`)만 되돌리고, 같은 디스크 안에 있어요. 개인 파일(`/home`)은 스냅샷에 들어가지 않고, 디스크가 고장 나면 스냅샷도 같이 사라져요. 사진이나 문서는 백업 앱(Déjà Dup, 런처에서 "백업"이나 "파일 히스토리")으로 USB 디스크나 네트워크 폴더에 따로 백업해요. 윈도우의 파일 히스토리, macOS의 Time Machine과 같은 일을 해요.

## 준비 조건

- 루트(`/`)가 Btrfs의 `@` 하위 볼륨이어야 해요. archinstall에서 파일 시스템을 Btrfs로 고르고 기본 하위 볼륨(`@`, `@home`, `@log`, `@pkg`)을 그대로 쓰면 돼요.
- 부트로더는 GRUB이어야 부팅 메뉴에서 스냅샷을 고를 수 있어요.
- EFI 파티션은 archinstall 기본값(`/boot`)이어도 되고 `/efi`여도 돼요. `/boot`일 때는 커널이 스냅샷 밖에 있어서 RobinOS가 따로 챙겨요(아래 "커널은 어떻게 되돌아가나요" 참고).

## 처음 설정

Btrfs로 설치한 시스템에서 `scripts/post-install.sh`를 실행하면 자동으로 설정돼요. 직접 하려면 이렇게 해요.

```bash
sudo robinctl snapshot setup --dry-run
sudo robinctl snapshot setup
```

설정하면 이렇게 바뀌어요.

- Btrfs 최상위에 `@snapshots` 하위 볼륨을 만들고 `/etc/fstab`에 넣어 `/.snapshots`에 마운트해요. 스냅샷이 `@` 밖에 있어야 나중에 스냅샷을 통째로 새 `@`로 바꿀 수 있어요.
- `/`에 snapper 설정(`root`)을 만들어요.
- 스냅샷은 번호 기준으로 최근 10개, 중요 표시가 붙은 것은 5개까지 남기고 `snapper-cleanup.timer`가 정리해요. 시간마다 찍는 스냅샷은 만들지 않아요.
- `wheel` 그룹 사용자는 sudo 없이 목록을 볼 수 있어요.
- `grub-btrfsd`가 스냅샷이 생길 때마다 부팅 메뉴를 다시 만들어요.
- initramfs가 udev 방식이면 `grub-btrfs-overlayfs` 훅을 넣어서, 읽기 전용 스냅샷으로 부팅해도 쓰기가 되게 해요(바뀐 내용은 메모리에만 남아요).
- 설정 직후 상태를 중요 표시를 붙인 첫 스냅샷으로 남겨요.

`robinctl doctor`로 설정 상태를 확인할 수 있어요.

## 스냅샷이 생기는 때

| 언제 | 누가 | 종류 |
|---|---|---|
| pacman으로 설치, 삭제, 업데이트할 때마다 | snap-pac | 전(pre)과 후(post) 한 쌍 |
| `sudo robinctl update` | snap-pac (snap-pac이 없으면 robinctl이 업데이트 전에 하나) | 전과 후 |
| `sudo robinctl snapshot create [이름]`, 런처의 "스냅샷 만들기" | 직접 | 하나(single) |

## 목록 보기

```bash
robinctl snapshot list
```

`#`이 스냅샷 번호이고, 설명(Description)에 어떤 pacman 명령 전후인지 적혀 있어요. 되돌릴 때는 망가지기 직전의 `pre` 스냅샷 번호를 쓰면 돼요.

## 부팅 메뉴에서 스냅샷으로 부팅하기

시스템이 아예 안 켜지거나 데스크톱이 안 뜨면 이렇게 해요.

1. 컴퓨터를 켜고 GRUB 메뉴에서 `RobinOS snapshots`를 골라요. 날짜, 종류(pre/post/single), 설명이 나와요. 부팅 메뉴는 한글을 제대로 보여 주지 못해서 RobinOS가 만드는 스냅샷 설명은 영어예요. `robinctl snapshot create`에 한글 이름을 주면 `manual`로 저장해요.
2. 날짜와 설명을 보고 문제가 생기기 전 스냅샷을 골라요.
3. 그 시점의 시스템으로 부팅돼요. `/home`은 따로 된 하위 볼륨이라 내 파일은 지금 그대로예요.

이렇게 부팅한 상태는 임시예요. 재부팅하면 다시 원래(망가진) 상태로 켜져요. 이 상태로 계속 쓰려면 다음 단계로 되돌리세요.

데스크톱에 로그인하면 "스냅샷 N번으로 켰어요" 알림이 떠요. **이 상태로 되돌리기**를 누르고 비밀번호를 넣으면 아래 단계를 대신 해 주고, 끝나면 "지금 다시 시작"을 물어요. 터미널 없이 돼요(`robinos-snapshot-notice`, `robinctl snapshot booted`).

## 그 상태로 완전히 되돌리기

되돌릴 스냅샷 번호를 정하고 이렇게 실행해요. 스냅샷으로 부팅한 상태에서 해도 되고, 원래 시스템에서 해도 돼요.

```bash
robinctl snapshot list
sudo robinctl snapshot rollback 12
sudo reboot
```

`rollback`은 지금 시스템(`@`)을 `@.broken-<시각>`으로 이름만 바꿔 남겨 두고, 스냅샷 12번을 복사해 새 `@`를 만들어요. 재부팅하면 그 상태로 켜져요. 마음이 바뀌면 같은 방법으로 다른 스냅샷으로 다시 되돌리면 돼요.

직접 하고 싶다면 `rollback`이 하는 일의 핵심은 이거예요(원래 시스템으로 켰을 때). 스냅샷으로 부팅한 상태에서는 `/`가 메모리 위의 overlay라 장치 이름이 나오지 않으니 `sudo robinctl snapshot rollback`을 써요.

```bash
root_dev="$(findmnt -no SOURCE / | cut -d'[' -f1)"
sudo mount -o subvolid=5 "${root_dev}" /mnt
sudo mv /mnt/@ "/mnt/@.broken-$(date +%Y%m%d-%H%M%S)"
sudo btrfs subvolume snapshot /mnt/@snapshots/12/snapshot /mnt/@
sudo rm -f /mnt/@/var/lib/pacman/db.lck
sudo umount /mnt
sudo reboot
```

업데이트 전 스냅샷에는 pacman의 잠금 파일(`db.lck`)이 같이 찍혀 있어서 지워요. 그대로 두면 되돌린 뒤 pacman이 돌지 않아요. `/boot`가 EFI 파티션이면(archinstall 기본값) 아래 "EFI 파티션이 `/boot`일 때"처럼 `/mnt/@/.bootbackup`의 커널과 initramfs도 `/boot`로 복사해야 해요. `rollback`은 이것까지 해요.

재부팅해서 잘 되는 걸 확인했으면 남겨 둔 옛 시스템을 지워 공간을 돌려받아요. `@.broken-` 뒤의 이름은 `ls /mnt`로 확인하세요.

```bash
root_dev="$(findmnt -no SOURCE / | cut -d'[' -f1)"
sudo mount -o subvolid=5 "${root_dev}" /mnt
ls /mnt
sudo btrfs subvolume delete /mnt/@.broken-20261007-153000
sudo umount /mnt
```

## 시스템 재설정: 설치 직후로 되돌리기

윈도우의 "이 PC 초기화(내 파일 유지)"처럼, 개인 파일은 두고 시스템만 설치했을 때로 돌리는 방법이에요. 개인 파일과 다른 하위 볼륨이 남으니 "공장 초기화"가 아니라 "시스템 재설정"이라고 불러요.

설정 앱 **업데이트** 쪽 아래의 **시스템 재설정**에서 **재설정…**을 누르면 터미널이 열려요. 무엇이 남는지 보여 주고 묻고, 비밀번호를 받은 뒤 되돌리고, 다시 시작할지 물어요. 터미널에서는 이렇게 해요.

```bash
sudo robinctl snapshot reset
```

### 처음 상태 스냅샷

`robinctl snapshot setup`이 마지막에 찍는 첫 스냅샷("RobinOS snapshot setup", 중요 표시)이 처음 상태예요. 이 스냅샷에는 정리 규칙(cleanup)이 없어서 snapper가 지우지 않아요. 스냅샷이 아무리 쌓여도 남아요. `robinctl snapshot list`에서 Cleanup 칸이 빈 1번이에요. `reset`은 번호가 아니라 이 설명으로 찾아요.

- RobinOS 설치기로 깔았으면 사용자 계정을 만든 뒤, 데스크톱 설정 중에 찍혀요.
- archinstall로 깔고 `post-install.sh`를 돌렸으면 그 스크립트가 끝날 때 찍혀요.

### 되돌아가는 것과 남는 것

재설정은 `@` 하위 볼륨을 첫 스냅샷의 사본으로 바꾸고, 몇 가지는 지금 시스템에서 옮겨 와요.

| 그대로 남아요 | 설치 직후로 돌아가요 |
|---|---|
| 개인 파일과 내 설정 (`/home`, `@home`): 문서, 사진, 브라우저, `~/.config`, 내 계정에만 깐 Flatpak 앱, Steam 게임 | 설치한 프로그램과 업데이트 (`/usr`, `/opt`): 패키지 버전이 설치 때로 |
| 옮겨 와요: 사용자 계정과 지금 비밀번호(root 포함), 그룹 소속, 저장한 와이파이, 컴퓨터 이름, 시간대, 부팅 메뉴(`/boot/grub`가 `@` 안일 때) | 그 밖의 시스템 설정 (`/etc`): 프린터, 방화벽 규칙, 직접 고친 설정 파일 |
| 시스템 기록 (`/var/log`, `@log`), 받아 둔 패키지 (`@pkg`) | 앱 스토어로 깐 앱 (`/var/lib/flatpak`), 웹 연습 랩의 Docker 이미지 (`/var/lib/docker`), 블루투스 연결 기록 |
| 스냅샷 (`@snapshots`)과 지금 시스템의 사본 (`@.broken-<시각>`) | 커널: EFI가 `/efi`면 `@` 안이라 같이, `/boot`면 `/.bootbackup` 사본으로 같이 |

설치한 뒤 생긴 그룹(예: Docker를 깔면 생기는 `docker`)은 그 프로그램이 없어지니 따라오지 않아요. 부팅 메뉴를 옮기는 건 윈도우 옆에 설치했을 때를 위해서예요. RobinOS 설치기는 첫 스냅샷을 찍은 뒤에 윈도우 항목을 메뉴에 넣어서, 옮기지 않으면 윈도우가 메뉴에서 빠져요.

### 주의할 것

- **패키지가 설치 때 버전이라 바로 업데이트해요.** 다시 시작한 뒤 `sudo robinctl update`를 실행해요.
- **휴대폰에서 받기 허용 같은 방화벽 규칙과 프린터는 다시 켜요.**
- **공간을 돌려받으려면 `@.broken-<시각>`을 지워요.** 지우는 방법은 위 "그 상태로 완전히 되돌리기"에 있어요. 그 전까지는 디스크에 옛 시스템이 그대로 있고, 마음이 바뀌면 그 사본이나 다른 스냅샷으로 돌아갈 수 있어요.
- 직접 하려면 `sudo robinctl snapshot rollback 1`도 돼요. 이때는 아무것도 옮겨 오지 않아서 비밀번호, 와이파이, 윈도우 부팅 항목까지 설치 때로 돌아가요.

### PC를 남에게 넘길 때

재설정은 `/home`을 남겨서 PC를 넘길 때는 맞지 않아요. 설치 USB로 켜서 "디스크 전체"로 다시 설치해요. 다시 설치하면 옛 파일이 보통 방법으로는 보이지 않지만, 디스크에 남은 조각까지 지우지는 않아요. 디스크 암호화를 켜 두었다면 옛 비밀번호와 복구 키를 모르는 사람은 그 조각을 읽을 수 없어요. 그래서 넘길 PC라면 처음부터 암호화를 켜 두는 게 좋아요.

### 다른 OS와 비교

| OS | 방법 | 남는 것 |
|---|---|---|
| 윈도우 "이 PC 초기화" | 내 파일 유지 또는 모두 제거를 골라 윈도우를 다시 깔아요 | 내 파일 유지라면 개인 파일. 설치한 앱은 지워져요 |
| ChromeOS Powerwash | 기기의 로컬 데이터를 모두 지워요 | 없어요. 계정에 동기화한 것만 다시 받아요 |
| Pop!_OS 다시 설치(Refresh) | 복구 파티션에서 시스템을 다시 깔아요 | 홈 폴더. 사용자 계정은 다시 만들어요 |
| openSUSE | snapper로 첫 스냅샷(설치 직후)을 포함해 원하는 스냅샷으로 되돌려요 | 하위 볼륨으로 나눈 홈과 기록 |
| RobinOS | 첫 스냅샷으로 되돌리기(위) | 홈, 기록, 받아 둔 패키지, 스냅샷 |

RobinOS는 openSUSE 방식에 가까워요. 다시 깔지 않아서 몇 초면 끝나고, 마음이 바뀌면 `@.broken-<시각>`이나 다른 스냅샷으로 다시 돌아갈 수 있어요. 대신 디스크가 망가진 경우에는 쓸 수 없어요(그때는 백업과 다시 설치).

## 커널은 어떻게 되돌아가나요

커널은 `/boot`에 있어요. 시스템을 되돌릴 때 커널도 같은 시점으로 돌아가야 커널 모듈과 버전이 맞아요.

- **EFI 파티션이 `/efi`일 때**: `/boot`가 Btrfs의 `@` 안에 있어서 커널도 스냅샷에 그대로 들어가요. 따로 할 일이 없어요.
- **EFI 파티션이 `/boot`일 때** (archinstall 기본값): `/boot`는 FAT32라 스냅샷에 들어가지 않아요. 그래서 `robinctl snapshot setup`이 pacman 훅 두 개(`/etc/pacman.d/hooks/04-robinos-boot-backup.hook`, `zy-robinos-boot-backup.hook`)를 넣어요. 커널이 바뀌는 pacman 작업 전후에 `/boot`를 `/.bootbackup`에 복사해서, 스냅샷마다 그때의 커널이 같이 남아요. `robinctl snapshot rollback`은 되돌린 스냅샷의 `/.bootbackup`에서 커널과 initramfs를 EFI 파티션으로 다시 복사해요.

설정하기 전에 만든 스냅샷에는 `/.bootbackup`이 없어요. 그런 스냅샷으로 되돌린 뒤 장치가 이상하면 커널을 다시 설치하세요.

```bash
sudo pacman -S linux
```

## 라이브 ISO

라이브 ISO는 루트가 메모리 위의 overlay라서 스냅샷을 쓰지 않아요. 라이브 세션에서 바꾼 내용은 재부팅하면 사라져요.
