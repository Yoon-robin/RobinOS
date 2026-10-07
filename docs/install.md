# RobinOS 프로토타입 설치

RobinOS에는 아직 디스크에 직접 설치하는 완전한 설치기가 없어요.

ISO와 설치기가 자리 잡을 때까지는 아래 프로토타입 절차를 써요.

## 방법 A: 이미 설치된 Arch

archinstall로 새로 설치한다면 이렇게 고르세요. 업데이트 전 자동 스냅샷과 부팅 메뉴에서 되돌리기를 쓸 수 있어요([recovery.md](recovery.md)).

- 파일 시스템: Btrfs, 기본 하위 볼륨 그대로
- 부트로더: GRUB
- 디스크 구성: 기본 구성("best-effort default partition layout") 그대로

Arch가 설치된 시스템에서 실행해요. 루트가 Btrfs면 스냅샷 설정(`robinctl snapshot setup`)까지 해 줘요.

```bash
sudo scripts/post-install.sh --dry-run
sudo scripts/post-install.sh
robinctl doctor
```

그다음 보안 학습 프로필을 설치해요.

```bash
sudo robinctl profile security --dry-run
sudo robinctl profile security
```

## 방법 B: 라이브 ISO 프로토타입

RobinOS ISO로 부팅하고 아래 명령으로 살펴봐요.

```bash
robinctl doctor
robinctl learn
robinctl lab info web
robinctl lab list
robin-install
```

RobinOS 설치기는 만드는 중이에요. 라이브 화면 런처(`Super+Space`)의 "RobinOS 설치"로 그래픽 설치기를 열 수 있고, 실제 설치는 백엔드(`robin-install disks`, `sudo robin-install run 계획.json`)가 해요. 아직 VM에서 끝까지 설치해 보지 않았으니 진행 상황은 [tasks.md](tasks.md)를 보고, 그때까지는 방법 A를 쓰세요.

라이브 ISO는 RobinOS 파일을 여기에 준비해 둬요.

```bash
/opt/robinos
```

Arch를 설치한 뒤 이 디렉터리를 설치된 시스템에 복사하고 이 명령을 실행해요.

```bash
sudo /opt/robinos/scripts/post-install.sh
```

## 앞으로 설치기에 넣을 것

- 단계별 안내가 있는 디스크 파티션 나누기
- Btrfs 레이아웃
- Snapper 설정
- 부트로더 설정
- 사용자 만들기
- 한글 입력과 한국어 로캘 설정
- RobinOS 데스크톱 (Hyprland + Quickshell 셸)
- Security Lab 프로필 선택
