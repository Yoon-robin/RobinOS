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

## 데이터 영속성 (선택) — 재부팅해도 메모·설정 유지
ISO 부팅 파라미터에 `persistence`가 이미 들어 있어요. USB에 **`persistence` 라벨 파티션**만 만들면
RobinOS 데이터(메모·설정·Robin 대화 = robin 유저 홈의 shared_preferences)가 재부팅 후에도 남아요.
파티션이 없으면 그냥 휘발성으로 부팅(무해).

USB에 ISO를 구운 뒤, 남은 공간에 두 번째 파티션을 추가:
```bash
# USB가 /dev/sdX 라고 가정 — lsblk 로 반드시 확인! (틀리면 다른 디스크가 지워질 수 있음)
sudo parted /dev/sdX -- mkpart primary ext4 4GiB 100%   # ISO 뒤 남은 공간
sudo mkfs.ext4 -L persistence /dev/sdX3                  # 라벨은 반드시 'persistence'
sudo mount /dev/sdX3 /mnt
echo "/home union" | sudo tee /mnt/persistence.conf      # /home 을 유지(= RobinOS 데이터)
sudo umount /mnt
```
이제 그 USB로 부팅하면 메모·설정·Robin 대화가 재부팅 후에도 살아남아요.
(전체 시스템 변경까지 유지하려면 `/ union` 한 줄. 더 무겁지만 설치형처럼 동작.)

## AI 모델 내장 (선택) — 오프라인 Robin
GitHub Actions → **Build RobinOS ISO** → Run workflow → `embed_ai` ✅ + `ai_model` 지정
(예: `qwen2.5:1.5b` 가벼움 / `huihui_ai/qwen2.5-abliterate:7b` 거부 없는 모델). Ollama+모델이
ISO에 박혀 네트워크 없이 Robin이 동작해요(ISO가 GB 단위로 커짐). 기본 빌드는 비활성(가벼움).

## 파일
- `build.sh` — lb config/build 한 방 스크립트
- `config/package-lists/robinos.list.chroot` — 설치할 패키지 (cage, 한글/이모지 폰트 등)
- `config/includes.chroot/usr/local/bin/robinos-session` — cage로 RobinOS 실행
- `config/includes.chroot/lib/systemd/system/robinos-kiosk.service` — 부팅 시 자동 실행
- `config/hooks/live/0100-robinos.hook.chroot` — robin 유저 생성·서비스 활성화·(선택)Qwen2.5 내장

> ⚠️ 템플릿입니다. 실제 빌드에서 경로/패키지명/서비스 설정을 호스트에 맞게 조정하세요.
