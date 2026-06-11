# RobinOS v1 — 부팅 OS 빌드 기획서

> "기획부터 제대로하고 실제 빌드하자" — 실제 빌드 전 확정 문서.
> 이 단계 목표: **USB/가상머신으로 부팅되는 RobinOS v1** 만들기.

---

## 1. 목표 (v1이 뭔가)
전원을 켜면 → 리눅스 부팅 → **RobinOS 셸이 풀스크린**으로 뜨고 → 앱을 쓰고 → **Robin(AI)에게 자연어로 명령**하면 OS가 움직인다. 인터넷 없이도 (모델 한 번 받으면) 동작.

## 2. 확정된 결정 (사용자 선택)
| 항목 | 결정 |
|---|---|
| v1 범위 | **풀** — 셸 + 앱5개 + 실제 시스템 제어(Phase C) + **내장 AI** |
| 내장 모델 | **첫 부팅 때 다운로드** (ISO는 작게, 받으면 오프라인) |
| 기본 모델 | **`huihui_ai/qwen2.5-abliterate`** (abliterated=거부 제거, 한국어 강함) |
| 모델 선택 | **사용자가 원하는 모델 자유 선택** (프리셋 + 직접 입력) ← 핵심 |
| 테스트 | **가상머신(QEMU/VirtualBox) 먼저** (안전·빠른 반복) |
| 베이스 | Debian bookworm + live-build |
| 개발 환경 | 이 Windows PC의 **WSL2(우분투)** = 리눅스 빌드실 |

## 3. 모델 전략 (사용자가 자기 모델 쓰기)
Robin 두뇌는 이미 **교체식**. 거기에 "모델 자유 선택"을 더한다.

- **기본 프리셋** (설정에서 한 번 탭으로 선택):
  - `huihui_ai/qwen2.5-abliterate:7b` — 기본 (4.7GB, 거부 없음)
  - `huihui_ai/qwen2.5-abliterate:3b` — 가벼움 (1.9GB)
  - `huihui_ai/qwen2.5-abliterate:0.5b` — 초경량 (398MB, 저사양/테스트)
  - 일반 `qwen2.5`, `llama3.2` 등도 프리셋으로
- **직접 입력**: 모델 칸에 아무 Ollama 모델 이름이나 적으면 그대로 사용.
- **완전 자유**: Ollama는 허깅페이스의 어떤 GGUF든 불러올 수 있어서(Modelfile), 사용자가 받은 모델 무엇이든 등록 가능.
- **다운로드 UX**: 설정 → "Robin 두뇌" → 내장 → 모델 고르기 → **[다운로드]** 버튼 → 진행률 표시(`ollama pull`). 이게 "첫 부팅 다운로드"를 사용자 주도로 자연스럽게 처리.

> abliterated 주의: 안전 필터가 제거된 모델이라 민감/논란 내용도 생성될 수 있음. 개인 전용 OS라 사용자 책임 하에 사용. (huihui.ai 고지)

## 4. 빌드 파이프라인 (전체 흐름)
```
[Windows PC]
   └─ WSL2 우분투  ← 리눅스 빌드실 (한 번 설치)
        ├─ 1) flutter build linux --release      → RobinOS 리눅스 실행파일
        ├─ 2) bundle/ → boot/config/.../opt/robinos/ 복사
        ├─ 3) (boot/) sudo ./build.sh            → live-build로 .iso
        └─ 4) QEMU로 .iso 부팅 테스트            → 화면 확인
   └─ (완성되면) USB로 구워 실제 PC 부팅
```
- 부팅 셸 띄우기: **cage**(Wayland 키오스크)로 RobinOS 바이너리만 풀스크린. (`boot/` 골격 이미 있음)
- 첫 부팅: Ollama 서비스 자동 실행 → 사용자가 설정에서 모델 받기 → 이후 오프라인 Robin.

## 5. 작업 순서 (마일스톤 체크리스트)
- [ ] **0. 코드 반영** (빌드 전, 작음): 기본 모델값을 huihui abliterate로, 설정에 모델 프리셋 + [다운로드] 버튼 추가
- [ ] **1. WSL2 우분투 설치** (이 PC에): `wsl --install -d Ubuntu` (1회, 재부팅)
- [ ] **2. 우분투에 도구 설치**: flutter linux 도구체인(clang/cmake/ninja/gtk), live-build, ollama
- [ ] **3. `flutter build linux`** → 리눅스 실행파일 확인 (우분투 안에서 바로 실행해 셸 뜨는지)
- [ ] **4. Phase C 연동**: 밝기/전원/네트워크 실제 제어(LinuxBackend) — 우분투에서 개발/검증
- [ ] **5. `boot/`로 ISO 빌드** → QEMU 부팅 → RobinOS 풀스크린 확인
- [ ] **6. 첫 부팅 모델 다운로드** 흐름 확인 (Ollama + huihui 모델)
- [ ] **7. USB로 실제 PC 부팅** (선택, 나중)

## 6. 리스크 / 주의
- **용량**: 7B 모델 4.7GB. 첫 부팅 다운로드라 ISO 자체는 작음(좋음). 저사양이면 3b/0.5b 권장.
- **검증 한계**: ISO·부팅은 WSL/QEMU에서만 검증 가능 (이 Windows 본체에선 X).
- **WSL 그래픽**: `flutter build linux`는 WSL에서 빌드는 되지만, GUI 실행 확인은 WSLg(내장 GUI) 또는 QEMU에서.
- **abliterated 모델**: 거부 없음 = 강력하지만 사용자 책임.

## 7. 다음 액션
이 기획 확정되면 → **0번(코드 반영)** 부터 하고 → WSL 설치(1번)로 실제 빌드 진입.
