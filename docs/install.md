# RobinOS 설치

RobinOS는 라이브 USB로 부팅해서 설치해요. 방법은 두 가지예요.

- **방법 1: RobinOS 설치기** (권장): 라이브 화면에서 마우스로 설치해요. 디스크 나누기부터 스냅샷 설정까지 알아서 해요.
- **방법 2: Arch를 먼저 설치하고 RobinOS 입히기**: 이미 Arch Linux를 쓰고 있거나 archinstall로 직접 고르고 싶을 때예요.

## 준비

- **UEFI로 부팅하는 컴퓨터**: 2012년 이후 PC는 대부분 UEFI예요. 예전 방식(Legacy BIOS, CSM)으로는 설치할 수 없어요.
- **40GB 이상의 디스크 공간**
- **인터넷**: 설치하면서 최신 패키지를 내려받아요. 유선이 가장 편하고, Wi-Fi는 빠른 설정(`Win+S`)에서 연결해요.
- **백업**: 디스크 전체에 설치하면 그 디스크의 파일이 모두 지워져요. 윈도우 옆에 설치하더라도 중요한 파일은 먼저 백업하세요.
- **라이브 USB**: [build-iso.md](build-iso.md)로 만든 ISO를 Rufus(DD 이미지 모드)나 Ventoy로 USB에 담아요.

## 방법 1: RobinOS 설치기

1. USB로 부팅하면 라이브 데스크톱이 떠요. 환영 마법사는 건너뛰어도 돼요.
2. 독 맨 앞의 **RobinOS 설치**를 누르거나, 런처(`Win+Space`) 맨 위의 "RobinOS 설치"를 골라요.
3. 설치기가 네 단계로 물어봐요. 마우스 없이 `Tab`, `Enter`, `Space`로도 할 수 있어요.

| 단계 | 하는 일 |
|---|---|
| 1. 준비 확인 | 인터넷, 전원, 백업을 확인해요 |
| 2. 설치 위치 | 디스크를 고르고 설치 방식을 정해요: **윈도우 옆에 설치** 또는 **디스크 전체 사용** |
| 3. 사용자 | 사용자 이름(영어 소문자), 비밀번호, 컴퓨터 이름. 이 비밀번호로 로그인하고 `sudo`도 해요 |
| 4. 확인 | 고른 내용을 다시 보여 줘요. 디스크 전체를 쓰면 지워지는 걸 이해했다고 체크해야 넘어가요 |

4. **설치 시작**을 누르면 진행 막대와 단계가 보여요. 10분에서 30분쯤 걸리고, 그동안 라이브 화면의 다른 앱을 써도 돼요.
5. 끝나면 **다시 시작**을 누르고 USB를 빼요. GRUB 메뉴에서 "RobinOS Linux"로 켜지고, 로그인하면 환영 마법사가 떠요.

설치기가 하는 일이에요.

- GPT 디스크에 EFI 파티션과 Btrfs 파티션을 만들어요. 윈도우 옆에 설치할 때는 윈도우의 EFI 파티션을 같이 쓰고, 기존 파티션은 건드리지 않고 가장 큰 빈 공간에만 만들어요.
- Btrfs 하위 볼륨: `@`(시스템), `@home`(내 파일), `@log`, `@pkg`, `@snapshots`. `/boot`가 `@` 안에 있어서 스냅샷마다 그때의 커널이 같이 남아요.
- 한국어 화면(`ko_KR.UTF-8`), 서울 시간대, 한글 입력, RobinOS 데스크톱과 테마를 설치해요.
- 업데이트 전후 자동 스냅샷과 부팅 메뉴의 스냅샷 항목을 설정해요([recovery.md](recovery.md)).
- 부트로더는 GRUB이에요. 윈도우 옆에 설치하면 부팅 메뉴에 윈도우도 나오고, 윈도우와 시계가 어긋나지 않게 하드웨어 시계를 지역 시간으로 둬요.
- 설치 기록은 라이브 세션의 `/var/log/robin-install.log`에 남아요. 실패하면 설치기 화면에 이유가 나오고, 고친 뒤 처음부터 다시 할 수 있어요.

### 윈도우 옆에 설치하려면

"윈도우 옆에 설치"는 윈도우가 있는 GPT 디스크에 **40GB 이상의 할당되지 않은 공간**이 있을 때 고를 수 있어요.

1. 윈도우에서 "디스크 관리"(시작 버튼 오른쪽 클릭 → 디스크 관리)를 열어요.
2. C: 드라이브를 오른쪽 클릭하고 **볼륨 축소**로 40GB 이상(넉넉하게 60GB 이상 권장)을 비워요. 빈 공간은 "할당되지 않음"으로 남겨 두세요. 새 볼륨을 만들면 안 돼요.
3. 윈도우의 **빠른 시작**을 꺼 두면 RobinOS에서 윈도우 파티션을 안전하게 열 수 있어요(제어판 → 전원 옵션 → 전원 단추 작동 설정).
4. BitLocker를 쓰고 있다면 복구 키를 미리 확인해 두세요. 부팅 순서가 바뀌면 복구 키를 물을 수 있어요.

> 윈도우 옆 설치는 아직 실제 윈도우 디스크로 확인하는 중이에요([tasks.md](tasks.md)의 T-006). 디스크 전체 설치는 VM 설치 테스트로 확인했어요.

### 명령으로 설치하기

설치기 화면 대신 터미널에서도 설치할 수 있어요. 라이브 세션에서 실행해요.

```bash
sudo robin-install disks
```

설치할 수 있는 디스크와 윈도우 여부, 빈 공간이 JSON으로 나와요. 계획 파일을 만들어 넘기면 그대로 설치해요. 비밀번호가 들어 있어서 설치기가 읽은 뒤 지워요.

```json
{
  "disk": "/dev/nvme0n1",
  "mode": "alongside",
  "user": "robin",
  "password": "비밀번호",
  "hostname": "robinos",
  "timezone": "Asia/Seoul"
}
```

```bash
sudo robin-install run 계획.json
```

`mode`는 `alongside`(윈도우 옆) 또는 `whole`(디스크 전체)예요.

## 방법 2: Arch를 먼저 설치하고 RobinOS 입히기

archinstall로 Arch를 설치한다면 이렇게 골라야 스냅샷과 부팅 메뉴에서 되돌리기를 쓸 수 있어요.

- 파일 시스템: Btrfs, 기본 하위 볼륨 그대로
- 부트로더: GRUB
- 디스크 구성: 기본 구성("best-effort default partition layout") 그대로

윈도우와 같은 디스크에 직접 나눠 설치했다면, 부팅 메뉴에 윈도우가 나오도록 설치한 시스템에서 `/etc/default/grub.d/20-dual-boot.cfg`에 `GRUB_DISABLE_OS_PROBER=false`를 적고 `sudo grub-mkconfig -o /boot/grub/grub.cfg`를 실행하세요. RobinOS 설치기는 이걸 알아서 해요.

설치한 Arch에서 RobinOS 파일을 받아 설치 후 설정을 실행해요. 라이브 ISO로 설치했다면 `/opt/robinos`를 설치한 시스템에 복사해서 써도 돼요. 루트가 Btrfs면 스냅샷 설정(`robinctl snapshot setup`)까지 해요.

```bash
sudo scripts/post-install.sh --dry-run
sudo scripts/post-install.sh
robinctl doctor
```

## 설치한 다음

```bash
robinctl doctor
robinctl learn
```

`robinctl doctor`로 한글 입력, 스냅샷, 부팅 메뉴 설정을 확인하고, `robinctl learn`으로 학습 미션(리눅스 기초, 네트워크 기초)을 시작해요. 보안 실습 도구는 배우는 단계에 맞춰 프로필 하나씩 설치해요.

```bash
robinctl profile list
robinctl profile network --dry-run
sudo robinctl profile network
```

프로필은 `network`(네트워크 분석), `web`(웹 보안과 로컬 웹 랩), `forensics`, `reversing`, `passwords`, `wireless`, `vm`이고, `security`는 전부예요.

업데이트는 `sudo robinctl update`로 해요. 업데이트 전후에 스냅샷이 생겨서, 문제가 생기면 [recovery.md](recovery.md)대로 되돌리면 돼요.

## 아직 없는 것

- 설치기에서 언어와 시간대 고르기(지금은 한국어, 서울로 정해져 있어요)
- 설치기에서 보안 실습 프로필 고르기
- 디스크 암호화(LUKS)
