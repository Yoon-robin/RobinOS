# 복구: 스냅샷으로 되돌리기

업데이트나 설치 때문에 시스템이 망가져도 스냅샷으로 이전 상태로 돌아갈 수 있어요. RobinOS는 snapper(스냅샷), snap-pac(pacman 전후 자동 스냅샷), grub-btrfs(부팅 메뉴의 스냅샷 항목)를 써요.

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

## 그 상태로 완전히 되돌리기

되돌릴 스냅샷 번호를 정하고 이렇게 실행해요. 스냅샷으로 부팅한 상태에서 해도 되고, 원래 시스템에서 해도 돼요.

```bash
robinctl snapshot list
sudo robinctl snapshot rollback 12
sudo reboot
```

`rollback`은 지금 시스템(`@`)을 `@.broken-<시각>`으로 이름만 바꿔 남겨 두고, 스냅샷 12번을 복사해 새 `@`를 만들어요. 재부팅하면 그 상태로 켜져요. 마음이 바뀌면 같은 방법으로 다른 스냅샷으로 다시 되돌리면 돼요.

직접 하고 싶다면 `rollback`이 하는 일은 이게 전부예요.

```bash
root_dev="$(findmnt -no SOURCE / | cut -d'[' -f1)"
sudo mount -o subvolid=5 "${root_dev}" /mnt
sudo mv /mnt/@ /mnt/@.broken
sudo btrfs subvolume snapshot /mnt/@snapshots/12/snapshot /mnt/@
sudo umount /mnt
sudo reboot
```

재부팅해서 잘 되는 걸 확인했으면 남겨 둔 옛 시스템을 지워 공간을 돌려받아요. `@.broken-` 뒤의 이름은 `ls /mnt`로 확인하세요.

```bash
root_dev="$(findmnt -no SOURCE / | cut -d'[' -f1)"
sudo mount -o subvolid=5 "${root_dev}" /mnt
ls /mnt
sudo btrfs subvolume delete /mnt/@.broken-20261007-153000
sudo umount /mnt
```

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
