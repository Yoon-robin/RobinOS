# RobinOS 실기기 테스트 가이드

일부 기능은 가상머신(소프트웨어 렌더링)에서 확인이 안 된다. 아래는 **실제 PC에
USB로 부팅**해서 검증하는 방법과, 각 항목에서 무엇을 봐야 하는지다.

## 0. ISO 받기 / USB 굽기

1. GitHub Actions에서 최신 `robinos-iso` 아티팩트를 받는다
   (Actions → 최신 성공 실행 → Artifacts, 또는 `gh run download <id> -n robinos-iso`).
2. [Rufus](https://rufus.ie) 또는 [balenaEtcher](https://etcher.balena.io)로 USB에
   **DD 모드**로 굽는다.
3. 대상 PC를 USB로 부팅(부팅 메뉴 F12/F11/ESC 등).

## 1. 부팅 → 데스크톱 (VM에서 검증됨, 실기기 재확인)

- 부팅 메뉴에 **RobinOS** 표시 → 자동 로그인(robin) → **Hyprland 데스크톱**.
- 실기기에선 GPU 가속으로 뜬다(VM처럼 소프트웨어 렌더링 폴백을 안 탄다).
- 확인: waybar(Robin 버튼·시계·오디오·전원), 배경화면(R 마크), 한글 트레이(fcitx5).

## 2. 부트 스플래시 (Plymouth) — **VM에서 안 보임, 실기기 필요**

- 부팅 중(부팅 메뉴 이후, 데스크톱 전) **RobinOS 로고가 은은하게 펄스**하는 스플래시.
- VM에선 초기 KMS 한계로 텍스트만 나온다. 실기기의 실제 GPU에선 그래픽 스플래시가 떠야 한다.
- 안 뜨면: 부팅 시 커널 로그(`journalctl -b | grep -i plymouth`)를 확인.

## 3. 로그인/잠금 화면 (hyprlock) — **VM에서 트리거 못 함**

- 데스크톱에서 **SUPER+L** → RobinOS 잠금 화면(블러 배경 + 큰 시계 + 날짜 + 마크 + 비번 필드).
- 라이브(robin)는 비밀번호가 없으므로 잠그면 그냥 Enter로 풀린다(설치본에선 실제 비번).

## 4. 설치 (robinos-install) — **VM/실기기에서 실행 테스트 필요**

> ⚠️ 대상 디스크를 전부 지운다. 반드시 빈 디스크 / 지워도 되는 디스크로.

1. 터미널(SUPER+Return)에서 먼저 **모의 실행**으로 계획 확인:
   ```
   lsblk                       # 디스크 이름 확인 (예: /dev/sda, /dev/nvme0n1)
   sudo robinos-install --disk /dev/sdX --user 내이름 --password 내비번 --dry-run
   ```
2. 계획이 맞으면 `--dry-run` 빼고 실제 설치. 끝나면 USB 빼고 재부팅.
3. 확인: 설치본이 **라이브와 똑같은 RobinOS 데스크톱**으로 부팅되는지, 만든 계정으로
   로그인·sudo 되는지.
4. 문제가 나면 어느 단계(파티션/rsync/chroot/부트로더)에서 멈췄는지 메시지를 캡처해 알려달라.

## 5. Robin 비서

- 터미널에서 `robin` → 대화형. `볼륨 올려줘` / `밝기 50%` / `스크린샷` / `상태` / `앱 목록` 등.
- 로컬 LLM을 쓰려면 Ollama 설치 후 `~/.config/robin/config.json`에
  `{"llm_enabled": true, "model": "qwen2.5"}` → `robin ask <질문>`.

## 알려진 VM 한계 (실기기에선 해당 없음)

- Plymouth 스플래시 미표시(초기 KMS).
- Hyprland가 소프트웨어 렌더링으로 느리게 뜸.
- `vncdo`로 SUPER/VT 전환 키가 불안정 → 자동 테스트에서 데스크톱 상호작용·설치기 실행을
  끝까지 못 몰았다. 실기기 실제 키보드로는 정상 동작할 것.
