# RobinOS 아키텍처

이 문서는 **네이티브 빌드(`robinos_native/`, Flutter)** 의 내부 구조를 설명합니다.
(웹 프로토타입 `src/`는 디자인 청사진일 뿐 — 실제 OS는 이 Flutter 코드입니다.)

## 큰 그림

```
부팅 → 잠금 → 데스크톱 셸(Desktop)
                 ├─ 창 관리자 (RobinWindow × N)
                 ├─ 독 / 메뉴바 / 시스템 화면(제어센터·Spotlight·런치패드·미션컨트롤·알림·컨텍스트메뉴)
                 ├─ 앱 (Finder·메모·계산기·그림판·터미널·설정)
                 └─ Robin 패널 (개인 에이전트)
상태: SystemState(테마·배경·강조색·밝기) + RobinFs(가상 파일시스템)  ← provider
```

## 1. 상태 관리 (provider)

- **`SystemState`** (`system/system_state.dart`) — ChangeNotifier. 테마모드(dark/light/**auto**)·배경화면·강조색·밝기. `shared_preferences`로 영구 저장.
  - **팔레트는 한 곳에서 결정**: `isLight`로 해석된 `_light`를 바탕으로 `windowSurface`/`textPrimary`/`chromeOverlay` 등 게터가 모든 색을 제공. 위젯은 `sys.windowSurface`처럼 읽기만 → 다크/라이트 전환이 자동 반영.
  - `auto` 모드는 07~19시 라이트, 5분 타이머로 경계에서 자동 전환.
- **`RobinFs`** (`system/file_system.dart`) — ChangeNotifier. 평면 맵(path→FsEntry), `shared_preferences` 저장. 메모·Finder·터미널이 **공유** → 한 곳에서 쓰면 즉시 반영.
- 두 상태는 `main()`에서 `MultiProvider`로 주입.

## 2. 교체 가능한 백엔드 (핵심 설계 철학)

"디자인 → 실제 OS"를 **재작성이 아니라 백엔드 교체**로 만드는 게 목표.

- **저장소**: 지금은 `shared_preferences`(웹=localStorage / 리눅스=파일). 한 곳만 바꾸면 됨.
- **Phase C `LinuxBackend`(예정)**: 밝기·전원·네트워크 같은 실제 시스템 제어를 `Process.run`(brightnessctl·systemctl·nmcli)으로. 웹엔 `dart:io`가 없으므로 **조건부 import** 패턴으로 분리:
  ```dart
  import 'platform_backend_stub.dart'
      if (dart.library.io) 'platform_backend_io.dart';
  ```
  `SystemState.setBrightness`가 백엔드도 호출 → 리눅스에선 실제 밝기, 웹에선 no-op. UI 코드는 무변경.

## 3. Robin 에이전트

`두뇌(brain) + 손(RobinActions) + 얼굴(오로라 오브·채팅 패널)` 구조.

- **두뇌 교체식** (`robin/robin.dart`, `robin/brains.dart`): `RobinBrain` typedef + `setRobinBrain`. 로컬 파서 / Ollama(Qwen2.5 abliterated) / DeepSeek — 셋 다 OpenAI 호환 한 함수로.
- **손**: `RobinActions`(openApp/setTheme/setWallpaper/setAccent/setBrightness 콜백)를 Desktop이 주입 → Robin이 진짜 OS를 조작.
- **시스템 프롬프트 자동 생성**: `a.apps()`에서 앱 목록을 뽑아 생성 → 새 앱을 즉시 인지(하드코딩 X).
- **가드레일**: 정의된 action만 실행(임의 코드 X), 위험 동작은 `RobinResult.confirm`로 확인.
- 대화기록은 `shared_preferences`에 저장(닫아도 유지).

## 4. 창 관리자

- **`WinState`**: pos·size·z·minimized·maximized·restorePos/Size·dragPointer.
- `Desktop`(`main.dart`)이 `_wins[]`·`_zTop` 보유. 열기(중복 시 포커스)·포커스(z 증가)·이동·**리사이즈**(가장자리 핸들)·**스냅**(드래그 종료 시 `dragPointer`가 닿은 화면 가장자리로 — 상단=최대화, 좌/우=반쪽)·최소/최대화.
- `RobinWindow`는 `TweenAnimationBuilder`로 열 때 스프링 인.

## 5. 빌드 / CI

- **`check.yml`** (푸시마다, 빠름): `flutter analyze` + `flutter test`.
- **`build-iso.yml`** (수동 dispatch, ~18분): Flutter 리눅스 빌드 → 바이너리를 `boot/`에 스테이징 → **Debian bookworm 컨테이너**에서 `live-build`로 ISO(우분투 러너의 live-build 불일치 회피) → QEMU(TCG) 부팅 스크린샷 → 아티팩트.
- 가상화 불필요(컨테이너=커널 공유) — BIOS 가상화 못 켜는 환경 대응.

## 6. 파일 맵

```
lib/
  main.dart              Desktop(셸)·RobinWindow·_Dock·_MenuBar·RobinPanel·_AppContent(라우터)
  system/
    system_state.dart    테마·배경·강조색·밝기
    file_system.dart     RobinFs (가상 파일시스템)
  robin/
    robin.dart           localBrain(한국어 인텐트 파서)+수식 평가, RobinActions/Result/Brain
    brains.dart          ollamaBrain·deepseekBrain (OpenAI 호환) + applySavedBrain
  apps/
    registry.dart        AppDef + kApps
    calculator.dart settings.dart notes.dart finder.dart terminal.dart paint.dart
  widgets/
    clock.dart boot_screen.dart lock_screen.dart control_center.dart
    spotlight.dart launchpad.dart mission_control.dart notifications.dart
    context_menu.dart desktop_widget.dart
test/widget_test.dart    순수 로직 단위테스트(시계·localBrain)
```

자세한 진행/로드맵은 [README](../README.md)와 `phase-cd-plan.md` 참고.
