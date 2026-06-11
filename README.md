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
- **앱 6종** — Finder(가상 파일시스템·새 파일/폴더·삭제) · 메모(저장) · 계산기(클릭+**키보드 입력**) · 그림판(캔버스) · 터미널(미니 셸) · 설정
- **테마** — 다크/라이트, 배경화면 9종, 강조색 8종, 밝기 — `shared_preferences`로 영구 저장
- **가상 파일시스템** — 메모·Finder·터미널이 공유 (한 곳에서 쓰면 다른 앱에 반영)

## Robin 에이전트 🪐

자연어로 OS를 직접 조작하는 개인 에이전트. **두뇌 교체식**:

| 두뇌 | 설명 |
|---|---|
| **로컬** | 규칙 기반 파서 (오프라인 기본) |
| **내장 (Qwen2.5)** | Ollama로 로컬 실행 — 기본은 `huihui_ai/qwen2.5-abliterate` (거부 없는 abliterated, 온디바이스·프라이빗) |
| **DeepSeek** | 클라우드 (OpenAI 호환) |

예) "다크모드 켜줘", "배경 오션으로", "강조색 핑크로", "계산기 열어", "12 곱하기 9는?"
시스템 프롬프트는 앱 목록에서 자동 생성돼 새 앱을 즉시 인지하고, 위험 동작은 확인을 거칩니다.

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

**부팅 ISO** — 가상화 없이 **GitHub Actions**에서 빌드 (Actions → *Build RobinOS ISO* → Run workflow)
→ 아티팩트 `robinos-iso`(.iso) 다운로드 → USB로 굽거나 QEMU(소프트 에뮬)로 부팅.
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
- ✅ **Phase D-3** — Debian live-build로 부팅 `.iso` (CI에서)
- ⏳ **Phase C** — 실제 시스템 연동 (밝기/전원/네트워크 = LinuxBackend) + Qwen2.5 첫 부팅 다운로드
- ⏳ **마감** — 실기기/USB 부팅, 폴리시

---

*Made by Robin (Yoon-robin). 🪐*
