# RobinOS 부팅 이미지 (Debian live-build)

부팅되는 RobinOS ISO를 만드는 설정 골격입니다. **Debian/Ubuntu 호스트에서만** 동작해요
(이 폴더는 Windows에서 작성된 템플릿 — 빌드는 리눅스에서).

## 사전 준비 (Debian 호스트)
```bash
sudo apt update
sudo apt install -y live-build

# 1) RobinOS 셸을 리눅스 바이너리로 빌드 (robinos_native/ 에서)
#    → phase-cd-plan.md "D-1" 참고
flutter build linux --release
# 빌드 결과(bundle/)를 이 폴더의 config/includes.chroot/opt/robinos/ 로 복사:
mkdir -p config/includes.chroot/opt/robinos
cp -r ../robinos_native/build/linux/x64/release/bundle/* config/includes.chroot/opt/robinos/
```

## 빌드
```bash
sudo ./build.sh      # = lb config + lb build
# 결과물: live-image-amd64.hybrid.iso  → USB로 굽기 (예: dd / Rufus / balenaEtcher)
```

## 부팅 흐름
전원 → Debian 라이브 부팅 → `robin` 자동 로그인 → `cage`(Wayland 키오스크) → **RobinOS 풀스크린**.
(Kali가 Xfce를 띄우는 자리에 RobinOS 셸이 들어가는 구조.)

## 파일
- `build.sh` — lb config/build 한 방 스크립트
- `config/package-lists/robinos.list.chroot` — 설치할 패키지 (cage, 한글/이모지 폰트 등)
- `config/includes.chroot/usr/local/bin/robinos-session` — cage로 RobinOS 실행
- `config/includes.chroot/lib/systemd/system/robinos-kiosk.service` — 부팅 시 자동 실행
- `config/hooks/live/0100-robinos.hook.chroot` — robin 유저 생성·서비스 활성화·(선택)Qwen2.5 내장

> ⚠️ 템플릿입니다. 실제 빌드에서 경로/패키지명/서비스 설정을 호스트에 맞게 조정하세요.
