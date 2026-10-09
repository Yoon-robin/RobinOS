# RobinOS

![RobinOS 로고: 프롬프트 커서 위에 앉은 하얀 울새](assets/brand/robinos-logo-horizontal.svg)

RobinOS는 Arch 기반 보안 학습용 운영체제예요. 윤리적 해킹, CTF 연습, 악성코드를 안전하게 분석하는 랩, 네트워크 기초, 개발자에게 편한 워크플로에 집중해요.

목표는 Kali Linux를 따라 만드는 게 아니에요. RobinOS는 그 자체로 하나의 학습용 워크스테이션이어야 해요. 더 안전한 기본값, 한국어 사용자에게 맞춘 설정, 안내가 붙은 도구, 언제든 똑같이 다시 만들 수 있는 랩, 보안 작업에 맞춘 깔끔한 데스크톱을 갖추려고 해요.

RobinOS는 윈도우에서 넘어온 사람이 매일 쓰는 OS예요. 쓰면서 리눅스와 보안을 함께 배워요. 전체 설계는 [docs/design.md](docs/design.md)에 있어요.

## 누구를 위한 OS인가요

이런 사람에게 맞아요:

- 리눅스, 네트워크, 웹 보안, 리버싱, 포렌식을 배우는 학생
- 바로 연습할 수 있는 워크스테이션이 필요한 CTF 플레이어
- 매일 쓰는 시스템에 위험한 도구를 잔뜩 쌓지 않고 보안 랩을 갖추고 싶은 개발자
- 첫 부팅부터 글꼴, 한글 입력, 로캘, 문서가 자연스럽게 갖춰져 있길 바라는 한국어 사용자

이런 용도로 만들지 않았어요:

- 허가 없이 실제 시스템을 공격하는 일
- 활동 은폐, 지속성 확보, 탐지 회피, 자격 증명 탈취
- 합법적인 랩 환경 없이 공격 자동화 도구를 넣어 배포하는 일

## 핵심 아이디어

- Arch 기반, 골라 둔 보안 프로필
- Hyprland 데스크톱과 shadcn/ui zinc 스타일로 만든 RobinOS 전용 Quickshell 셸 ([docs/desktop.md](docs/desktop.md))
- 윈도우 사용자에게 익숙한 기본값: 자유 배치 창, 독, `Alt+Tab`, `Alt+F4`, `Win+E`, `Win+D`, `Win+V`(클립보드 기록), `Win+Shift+S`(캡처 도구), `Ctrl+Shift+Esc`(작업 관리자), 시계를 누르면 달력, 사진을 "배경으로 설정", 빠른 설정의 화면 배율·야간 모드·비행기 모드, Wi-Fi·블루투스 연결 창, 출력 장치와 앱별 음량을 고르는 소리 창, `Win+N` 알림 센터, `Alt+Tab` 창 전환 화면(미리보기), `Win+Tab` 작업 보기, 독 아이콘 위의 창 미리보기, `Win+.` 이모지, `Win+←/→` 창 반쪽 붙이기, 바의 트레이 아이콘, 런처에서 파일 찾기, 업데이트 알림
- 학습 센터: 리눅스·네트워크·포렌식·리버싱·웹·셸·시스템·보안 기초 미션 40개의 진행도와 다음 미션, 입문 CTF. 미션은 실제 터미널에서 풀어요
- 매일 쓰는 데 필요한 것: Firefox, LibreOffice(한국어), 동영상·음악 재생, 앱 스토어(Flathub)와 Steam, 프린터, NVIDIA 그래픽 카드 드라이버(GTX 16, RTX 20 이후)
- pacman 작업 전후 자동 Btrfs 스냅샷과 부팅 메뉴에서 되돌리기 ([docs/recovery.md](docs/recovery.md))
- 한글 입력, 한글 글꼴, 한국어 로캘과 문서가 기본
- 설정, 프로필, 스냅샷, 진단, 랩 도구를 다루는 `robinctl` 명령
- 모의해킹 패키지를 전부 쏟아 넣지 않고 학습 순서에 맞춰 정리한 도구 구성
- 컨테이너와 가상 머신(VM)으로 격리한 실습 랩

## 계획 중인 에디션

### RobinOS Core

최소 구성 데스크톱, 한국어 사용자에게 맞춘 기본 설정, 안전한 업데이트 계층, `robinctl`의 기본 틀을 담아요.

### RobinOS Security Lab

Core에 웹 보안, 네트워크 분석, CTF, 리버싱, 포렌식, 무선 보안 학습용으로 골라 둔 도구를 더해요.

### RobinOS Live

워크숍, 수업, 간단한 실습, 시스템 복구 같은 작업에 쓰는 부팅 가능한 라이브 ISO예요.

## 첫 마일스톤

첫 마일스톤은 아래 내용을 갖춘, 부팅되는 Arch ISO예요.

- RobinOS 브랜딩을 입힌 부팅 화면, 로그인 화면, 배경화면, 터미널 프롬프트
- RobinOS 셸을 얹은 Hyprland 데스크톱 (VM에서는 자동으로 소프트웨어 렌더링)
- 한글 입력과 한글 글꼴 기본 설정
- `robinctl doctor`
- `robinctl profile security`
- 골라 둔 패키지 목록
- Btrfs + Snapper 설계
- VM에서 검증한 설치 과정

## 초기 명령

지금은 `robinctl` 초기 프로토타입이 있어요.

```bash
bin/robinctl version
bin/robinctl doctor
bin/robinctl profile list
bin/robinctl profile network --dry-run
bin/robinctl profile security --dry-run
bin/robinctl packages core
bin/robinctl packages web
bin/robinctl packages optional
bin/robinctl snapshot setup --dry-run
bin/robinctl snapshot list
bin/robinctl learn
bin/robinctl learn show 1
bin/robinctl learn check 1
bin/robinctl ctf
bin/robinctl lab list
bin/robinctl lab info web
bin/robinctl lab info net
bin/robinctl lab status web
```

`robinctl doctor`는 데스크톱(Hyprland, Quickshell, RobinOS 셸)과 브랜딩 요소(SDDM 테마, 설치된 시스템의 GRUB 테마)도 확인해요. NVIDIA 그래픽 카드가 있으면 드라이버가 떠 있는지, 설치본에서는 인쇄 서비스가 켜져 있는지도 알려 줘요.

## 학습 미션

`robinctl learn`은 터미널에서 직접 풀어 보는 미션 40개예요. 리눅스, 네트워크, 포렌식, 리버싱, 웹, 셸, 시스템, 보안 기초가 5개씩 차례로 이어져요. 미션마다 윈도우에서는 어떻게 하는지와 비교해 설명하고, `robinctl learn check`가 결과를 확인해 진행도를 저장해요. 런처에서 "학습 미션"을 고르면 학습 센터 창에서 진행도와 다음 미션을 보고, 고른 미션을 터미널에서 열 수 있어요.

| # | 미션 | 배우는 명령 |
|---|---|---|
| 1 | 폴더 만들고 이동하기 | `pwd`, `ls`, `cd`, `mkdir` |
| 2 | 파일 만들고 읽기 | `echo`, `cat`, `>`, `>>`, `nano` |
| 3 | 복사, 이동, 삭제 | `cp`, `mv`, `rm` |
| 4 | 실행 권한 주기 | `ls -l`, `chmod`, `./` |
| 5 | 찾기와 파이프 | `grep`, `\|`, `wc`, `>` |
| 6 | 내 IP 주소 보기 | `ip a` |
| 7 | 이름으로 주소 찾기 | `getent hosts`, `/etc/hosts` |
| 8 | 네트워크 도구 설치하기 | `robinctl profile network` (인터넷 필요) |
| 9 | 포트 열고 확인하기 | `nc -l`, `ss -tln` |
| 10 | 내 컴퓨터 스캔하기 | `nmap 127.0.0.1` (내 컴퓨터만) |
| 11 | 파일의 진짜 종류 알아내기 | `file`, `xxd` |
| 12 | 해시로 같은 파일 찾기 | `sha256sum` |
| 13 | 사진 속 정보 읽기 | `exiftool` |
| 14 | 파일 속에 숨은 파일 찾기 | `binwalk`, `strings`, `bsdtar` |
| 15 | 로그에서 수상한 접속 찾기 | `grep`, `sort`, `uniq -c` |
| 16 | 실행 파일 살펴보기 | `file`, `readelf` |
| 17 | 프로그램 속 글자 찾기 | `strings` |
| 18 | 라이브러리 호출 엿보기 | `ltrace` |
| 19 | 시스템 호출 엿보기 | `strace` |
| 20 | 기계어 읽어 보기 | `objdump` |
| 21 | 웹 서버 켜고 접속하기 | `python3`, `curl` |
| 22 | 응답 헤더 읽기 | `curl -I` |
| 23 | robots.txt 읽기 | `curl`, `robots.txt` |
| 24 | 쿠키 주고받기 | `curl -c`, `curl -b` |
| 25 | 상태 코드와 리다이렉트 | `curl -i`, `curl -L` |
| 26 | 환경 변수 보기 | `echo $HOME`, `env` |
| 27 | 명령은 어디에 있을까 (PATH) | `echo $PATH`, `which` |
| 28 | 명령에 별명 붙이기 | `alias`, `~/.bashrc` |
| 29 | 스크립트에 값 넘기기 | `$1`, 큰따옴표와 작은따옴표 |
| 30 | 종료 코드와 && \|\| | `echo $?`, `&&`, `\|\|` |
| 31 | 실행 중인 프로그램 보기 | `ps`, `pgrep`, `&`, `$!` |
| 32 | 프로그램 끝내기 | `kill` |
| 33 | 디스크 공간 보기 | `df -h`, `du -sh` |
| 34 | 서비스 상태 보기 | `systemctl status`, `systemctl is-active` |
| 35 | 시스템 기록 읽기 | `journalctl`, `uname -r` |
| 36 | 사용자와 그룹 보기 | `whoami`, `id`, `groups` |
| 37 | 나만 읽는 파일 만들기 | `chmod 600`, `ls -l` |
| 38 | SSH 열쇠 만들기 | `ssh-keygen -t ed25519` |
| 39 | 내려받은 파일 검사하기 | `sha256sum -c` |
| 40 | 파일 암호화하기 | `gpg -c`, `gpg -d` |

리버싱 미션의 연습 프로그램은 직접 만든 작은 C 프로그램이에요. 소스는 [practice/reversing](practice/reversing)에 있고, 요령을 쓰면 코드를 보여 주는 것 말고는 아무 일도 하지 않아요. 웹 기초 미션의 연습 서버([practice/web/server.py](practice/web/server.py))는 파이썬 표준 라이브러리만 쓰고 `127.0.0.1:8000`에서만 열려요.

실습 파일은 모두 `~/practice`에 만들고, 진행도는 `~/.local/state/robinos/learn`에 저장해요. 처음부터 다시 하려면 `robinctl learn reset`을 실행하세요.

## 입문 CTF

미션을 끝냈다면 `robinctl ctf`로 입문 CTF 문제 10개를 풀어요. 미션처럼 할 일을 하나하나 알려 주지 않고, 미션에서 배운 기술(숨은 파일, 인코딩, 로그 분석, 반복 대입, 쿠키, 해시 검사, 권한, 사전 공격, 포트 찾기, 파일 속 파일)을 스스로 골라 써서 `ROBIN{...}` 모양의 플래그를 찾아요. 문제 파일은 `~/practice/ctf`에 생기고, 5번은 웹 연습 서버를 써요. 모두 내 컴퓨터 안에서만 풀어요. 푸는 요령과 다음에 연습할 곳은 [docs/ctf.md](docs/ctf.md)에 있어요.

```bash
robinctl ctf                               # 문제 목록과 푼 것
robinctl ctf show 1                        # 문제와 힌트
robinctl ctf submit 1 'ROBIN{...}'         # 플래그 확인
```

## 설치

라이브 USB로 부팅해서 독 맨 앞의 **RobinOS 설치**를 눌러요. 윈도우 옆에 설치하거나 디스크 전체를 쓸 수 있고, 디스크 나누기, 한국어 설정, 업데이트 전 자동 스냅샷까지 설치기가 알아서 해요. 이미 Arch를 쓰고 있다면 `sudo scripts/post-install.sh`로 RobinOS를 입힐 수 있어요. 자세한 방법은 [docs/install.md](docs/install.md)에 있어요.

## 빌드와 검증

빌드와 테스트는 개발 PC에서 해요. GitHub Actions는 수동 실행으로만 남겨 뒀어요([docs/ci.md](docs/ci.md)). 윈도우 PC에서는 WSL 2의 Arch Linux를 써요([docs/build-environment.md](docs/build-environment.md)).

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 check
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 build
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 boot-test
powershell -ExecutionPolicy Bypass -File scripts/wsl-build.ps1 install-test
```

무엇을 바꿨을 때 어떤 검사를 돌릴지는 [docs/testing.md](docs/testing.md)에 있어요.

## 문서와 작업 관리

- [docs/README.md](docs/README.md): 문서 지도. 어떤 문서가 무엇의 원본인지 정리돼 있어요.
- [docs/design.md](docs/design.md): 제품 설계와 v0.1 범위의 진행 상황
- [docs/tasks.md](docs/tasks.md): 지금 할 일과 진행 중인 작업
