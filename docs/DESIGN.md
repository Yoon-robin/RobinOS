# RobinOS 디자인 방향

## 한 줄

Arch의 가벼움과 투명함은 그대로, 켜자마자 완성된 데스크톱.

## 베이스

- **Arch Linux** (rolling). 베이스를 갈아엎지 않고 `releng` 위에 레이어만 얹는다.
- 설치된 시스템도 평범한 Arch처럼 동작한다 — `pacman`, AUR 다 그대로.

## 데스크톱: Hyprland

기성 데스크톱(GNOME/KDE) 대신 Wayland 컴포지터 **Hyprland**를 고른 이유:

- 애니메이션·블러·둥근 모서리 같은 시각 효과가 기본기로 강하다.
- 가볍고 빠르다. 최적화 여지가 크다.
- 설정이 텍스트 파일 하나라 RobinOS 시그니처를 코드로 박아넣기 좋다.

구성: `waybar`(바) · `wofi`(런처) · `swaync`(알림) · `kitty`(터미널) · `hyprpaper`(배경) ·
`hyprlock`/`hypridle`(잠금·유휴) · `thunar`(파일) · `fcitx5-hangul`(한글 입력).

## 시각 언어

- **팔레트**: 다크 베이스(`#14171f` / `#0b0d14`)에 블루→퍼플 액센트(`#78aaff` → `#7d5fff`).
- **시그니처 이징**: `bezier robin = 0.16, 1, 0.3, 1` — 빠르게 나와서 부드럽게 안착.
- **모서리**: 12px 라운딩 + 멀티패스 블러 + 은은한 그림자.
- **타이포**: JetBrainsMono Nerd Font.

## 폴리시 3축 (항상 챙긴다)

1. 미려한 디자인
2. 예쁜 애니메이션
3. 최적화

기능만 채우지 않는다.

## 로드맵 (대략)

1. ✅ 테마 적용된 Hyprland로 부팅되는 라이브 ISO (현재 목표)
2. ⬜ 실기기 USB 부팅 검증
3. ⬜ 오디오(PipeWire) · 네트워크(NM) 매끄럽게
4. ⬜ 전용 RobinOS 설치기 (archinstall 래핑 → 자체 GUI)
5. ⬜ 부트 스플래시(Plymouth) · 그리터 브랜딩
6. ⬜ 영속성(persistence) · 업데이트 채널
