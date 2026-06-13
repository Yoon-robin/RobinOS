# RobinOS 🪐

> 나만의 데스크톱 OS. macOS 같은 깔끔한 UI·부드러운 애니메이션 + **Robin**이라는 자비스식 개인 에이전트가 핵심.
> *Robin은 만든 사람 이름이에요 — 새(bird)가 아닙니다.*

RobinOS는 **직접 만든 데스크톱 셸/DE**예요. 단순 테마가 아니라 창 관리자·파일시스템·앱·에이전트를 전부 만들고, 최종적으로 **리눅스(Debian) 위에서 부팅되는 OS**를 목표로 합니다.

---

## 구성 (3갈래)

| 갈래 | 위치 | 역할 |
|---|---|---|
| **웹 프로토타입** | `src/` (Vite + React + motion) | 빠르게 디자인하는 **청사진** |
| **네이티브 빌드** | `robinos_native/` (Flutter) | **실제 OS 셸** (청사진을 1:1 이식) |
| **부팅 이미지** | `boot/` (Debian live-build) | 부팅되는 **`.iso`** (Kali식 파이프라인) |

> 웹은 디자인용이고, **진짜 OS는 Flutter 네이티브 + Debian 부팅**으로 갑니다.

---

## 들어있는 것 (네이티브 빌드)

- **시작 흐름** — 부팅 화면 → 잠금화면(시계, 클릭/Enter 해제) → 데스크톱
- **창 관리자** — 신호등(닫기·최소화·최대화), 드래그 이동, **가장자리 리사이즈**, **가장자리 스냅**(상단→최대화, 좌/우→반쪽), 포커스/z-순서, 계단식 배치
- **독** — **마우스 확대(magnification)**, 실행 표시점, 런치패드 타일, Robin 오브
- **메뉴바** — 반투명 블러, 활성 앱 이름, 실시간 시계, Spotlight·미션컨트롤·제어센터 트리거
- **시스템 화면** — 제어센터(와이파이·테마·밝기·강조색·잠금) · Spotlight(앱 검색) · 런치패드 · 미션컨트롤 · 알림 토스트 · 우클릭 컨텍스트 메뉴 · 데스크톱 시계
- **멀티윈도 DE** — sway 컴포지터로 **실제 리눅스 앱**(Firefox 등)을 창으로 실행 (런치패드·Robin·Spotlight에서). RobinOS 셸은 백드롭, 앱은 floating 창
- **앱 11종 + 소프트웨어 센터** — Finder · 메모 · 계산기(클릭+**키보드**) · 그림판 · 터미널(리눅스에선 **진짜 bash**) · 설정 · **소프트웨어 센터**(apt 검색·설치·제거) · **시스템 모니터**(/proc 실시간 CPU·메모리·디스크·네트워크·프로세스) · **캘린더**(월/주 뷰·일정 저장) · **음악**(홈 오디오 mpv 재생) · **사진**(홈 이미지 갤러리·뷰어)
- **설정** — 테마·배경(9종)·강조색(8종)·밝기·볼륨·**Wi-Fi 연결**·**블루투스**·**시간대**·**디스플레이 해상도**·Robin 두뇌
- **시스템 화면** — 제어센터 · Spotlight(앱+실앱+파일 검색) · 런치패드 · 미션컨트롤 · **알림 센터**(히스토리) · 컨텍스트 메뉴
- **실시간 상태** — 메뉴바 **배터리·Wi-Fi 연결 상태**(실기기)
- **실제 파일시스템** — 리눅스에선 robin 홈의 **진짜 파일**을 Finder·메모가 다룸 (웹은 가상)
- **스크린샷**(grim) · 다크/라이트 · `shared_preferences` 영구 저장

## Robin 에이전트 🪐

자연어로 OS를 직접 조작하는 개인 에이전트. **두뇌 교체식**:

| 두뇌 | 설명 |
|---|---|
| **로컬** | 규칙 기반 파서 (오프라인 기본) |
| **내장 (Ollama)** | 로컬 LLM — 기본 `huihui_ai/qwen2.5-abliterate:7b` (거부 없는 abliterated, 온디바이스·프라이빗). **embed_ai ISO는 부팅 시 자동 활성화** |
| **DeepSeek** | 클라우드 (OpenAI 호환) |

예) "다크모드 켜줘", "배경 오션으로", "볼륨 50%", "와이파이 꺼", "스크린샷 찍어줘", "Firefox 실행해줘", "12 곱하기 9는?"
LLM은 앱 실행·테마·밝기·볼륨·Wi-Fi·블루투스·스크린샷을 JSON action으로 직접 수행하고, 위험 동작(전원 등)은 확인을 거칩니다.

---

## 빌드 / 실행

**웹 프로토타입 (디자인)**
```bash
npm install && npm run dev      # http://localhost:5173
```

**네이티브 미리보기 (개발)**
```bash
cd robinos_native
flutter run -d web-server --web-port 8091   # 빠른 미리보기
# 리눅스 데스크톱: flutter build linux --release
```

**부팅 ISO** — [**Releases**](../../releases)에서 최신 ISO 다운로드(일반 빌드마다 자동 업로드)
→ USB로 굽거나 QEMU(소프트 에뮬)로 부팅하면 sway 데스크톱 + Robin이 뜹니다.
**AI 내장(7B) ISO**는 Actions → *Build RobinOS ISO* → `embed_ai` 체크로 빌드(아티팩트 `robinos-iso`, ~6GB — Release 2GB 한도 초과라 아티팩트로 제공).
로컬 Debian에서 직접 빌드하려면 `boot/README.md` 참고.

---

## 네이티브 구조 (`robinos_native/lib/`)

```
main.dart            셸: 데스크톱·창관리자·독·메뉴바·Robin 패널·시작 흐름
system/
  system_state.dart  테마·배경·강조색·밝기 (provider)
  file_system.dart   가상 파일시스템 (RobinFs)
robin/
  robin.dart         Robin 두뇌(로컬 파서) + 손(RobinActions) + 결과
  brains.dart        Ollama(Qwen2.5)·DeepSeek (OpenAI 호환)
apps/
  registry.dart      앱 목록 + 계산기·설정·메모·Finder·터미널·그림판
widgets/             부팅·잠금·제어센터·Spotlight·런치패드·미션컨트롤·알림·시계 등
```

## 로드맵

- ✅ **Phase A** — 웹 프로토타입(디자인 청사진)
- ✅ **Phase B** — 네이티브 Flutter 재구현 (셸·앱·Robin·테마)
- ✅ **Phase C** — 실제 시스템 연동: 밝기·볼륨·전원·Wi-Fi·블루투스·시간대·디스플레이(LinuxBackend) + **실제 파일시스템**(robin 홈 백킹)
- ✅ **Phase D** — Debian live-build 부팅 `.iso` + **sway 멀티윈도 DE**(실제 리눅스 앱을 창으로) + **GitHub Release 자동 업로드**
- ✅ **AI 비서** — Ollama + `huihui_ai/qwen2.5-abliterate:7b` 내장, 부팅 시 자동 LLM 활성화
- ✅ **소프트웨어 센터** — `apt` 패키지 검색·설치(pkexec)
- ⏳ **마감** — 실기기/USB 부팅 최종 검증, layer-shell 독(독·메뉴바 항상 위)

> 📀 최신 ISO: **[Releases](../../releases)** (일반 빌드마다 자동 업로드) · 📝 변경 내역: **[CHANGELOG.md](CHANGELOG.md)**

---

*Made by Robin (Yoon-robin). 🪐*
