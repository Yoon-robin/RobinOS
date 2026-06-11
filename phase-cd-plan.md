# RobinOS — Phase C & D 계획 (실제 부팅 OS로)

> 지금까지(Phase A·B): 웹 프로토타입(청사진) → 네이티브 Flutter 앱(데스크톱·창관리자·앱·Robin·멀티두뇌)까지 완성.
> 여기부터는 **진짜 컴퓨터에 부팅되는 OS**로 가는 길. ⚠️ 이 단계는 **Debian 빌드 호스트(리눅스)** 가 있어야 실제로 만들고 검증할 수 있어요. 아래는 정확한 파이프라인 + 실행 스크립트 골격입니다.

---

## Phase C — 실제 시스템 연동 (RobinOS가 진짜 하드웨어를 만짐)

웹의 `systemAPI`(교체식 백엔드) 정신을 Flutter에서도 유지 → 지금은 "앱 안에서만" 동작하는 것들을 **리눅스 실제 호출**로 바꾼다.

| 기능 | 현재 (네이티브 앱 안) | Phase C (리눅스 실제) |
|---|---|---|
| Robin 두뇌 | 로컬 파서 / Ollama / DeepSeek | **Ollama(Qwen2.5) 가 이미 실제 연동** ✅ (localhost:11434) |
| 밝기 | 검은 오버레이(가짜) | `brightnessctl` / sysfs `/sys/class/backlight` |
| 배경화면 | 앱 내부 그라데이션 | 실제 컴포지터 배경 (cage/swaybg) |
| 네트워크 표시 | (없음) | `nmcli` (NetworkManager) |
| 전원 | (없음) | `systemctl poweroff/reboot/suspend` |
| 볼륨 | (없음) | `wpctl` (PipeWire) |
| 앱 실행 | 내장 앱만 | 추가로 실제 `.desktop` 앱 exec |

**구현 방식**: Dart `Process.run(...)` 로 위 CLI들을 호출하는 `LinuxBackend` 를 만들고, 앱 시작 시 플랫폼이 Linux면 주입.
- 새 파일: `lib/system/platform_backend.dart` (`abstract class PlatformBackend` + `WebBackend`/`LinuxBackend`).
- `SystemState.setBrightness` 등이 이 백엔드를 통하게 → UI 코드는 그대로, 동작만 진짜가 됨.
- Robin 의 `RobinActions` 도 같은 백엔드를 쓰면 "Robin이 진짜 OS를 제어" 가 완성.

**보안 가드레일(이미 설계됨, 유지)**: Robin은 정의된 action만 실행(임의 명령 X), 위험 동작은 `RobinResult.confirm` 확인. Phase C에서 `poweroff` 같은 건 반드시 confirm 게이트.

---

## Phase D — 부팅 ISO (Kali 식 파이프라인)

### D-1. Flutter 리눅스 빌드
RobinOS 셸을 리눅스 실행파일로 빌드 (웹이 아니라 **네이티브 데스크톱 바이너리**):
```bash
# Debian 호스트에서 (한 번만) 리눅스 데스크톱 도구체인 설치
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
flutter config --enable-linux-desktop
flutter build linux --release
# 결과물: build/linux/x64/release/bundle/  (robinos_native 실행파일 + 라이브러리)
```

### D-2. 컴포지터로 풀스크린 띄우기 (Xfce 자리에 RobinOS)
Kali가 라이브 ISO에서 Xfce를 자동 실행하듯, 우리는 **cage**(가벼운 Wayland 키오스크 컴포지터)로 RobinOS 바이너리만 풀스크린 실행한다.
- `cage -- /opt/robinos/robinos_native`
- 부팅 → 자동 로그인 → cage → RobinOS. 데스크톱 환경 전체가 RobinOS.

### D-3. Debian live-build 로 ISO 굽기
Kali와 동일한 도구(`live-build`)로 부팅 가능한 ISO 생성. → `boot/` 폴더에 설정 골격 있음.
```bash
cd boot
sudo ./build.sh        # lb config + lb build  (Debian 호스트에서)
# 결과물: robinos-live.iso  → USB로 구워 부팅
```

### D-4. Qwen2.5 "내장" (오프라인 동작)
진짜로 OS에 모델을 넣으려면 chroot 단계에서 Ollama 설치 + 모델을 이미지에 미리 받아둔다:
```bash
# boot/config/hooks/ 안에서 (빌드 시 실행)
curl -fsSL https://ollama.com/install.sh | sh
ollama serve & sleep 3
ollama pull qwen2.5          # ⚠️ 7B ≈ 4.7GB → ISO 커짐. 가벼우면 qwen2.5:3b (≈2GB)
```
이렇게 하면 USB로 부팅한 RobinOS가 **인터넷 없이도 Robin(Qwen2.5)** 으로 동작.

---

## 순서 요약
1. **Phase C** 먼저: `LinuxBackend` 로 밝기·전원·네트워크·Ollama 실연동 (앱 상태에서 개발/검증 가능).
2. **Phase D-1/2**: 리눅스 빌드 + cage 로 로컬 PC에서 "전체화면 RobinOS" 확인.
3. **Phase D-3/4**: live-build ISO + Qwen2.5 내장 → USB 부팅.

## 현실 점검
- C와 D-1/D-2 는 리눅스 PC만 있으면 바로 가능.
- D-3/D-4 (ISO·모델 내장) 는 디스크/시간이 꽤 듦(모델 포함 시 ISO 5GB+). 처음엔 모델 빼고 ISO → 부팅 확인 → 나중에 모델 내장 권장.
- `boot/` 의 파일들은 **검증 안 된 템플릿**(이 Windows 머신에선 빌드 불가). Debian 호스트에서 돌려보며 조정 필요.
