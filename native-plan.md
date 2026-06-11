# RobinOS 네이티브(Flutter) 빌드 계획 — Phase B

웹 프로토타입(React)을 **청사진**으로 삼아 Flutter로 재구현한다.
개발 타깃: 지금은 Windows에서 `flutter run -d chrome`(빠른 미리보기) → 나중에 Linux 데스크톱 빌드(Phase D).

## 프로젝트
- `robinos_native/` (flutter create)
- 상태관리: `provider` (가벼움) — 웹의 SystemContext 대응
- 패키지 후보: `google_fonts`(Inter=SF 대체), 필요 시 `macos_ui`(macOS 룩)

## 구조 매핑 (웹 → Flutter)

| 웹 (현재) | Flutter (lib/) |
|---|---|
| `main.tsx` / `index.html` | `main.dart` |
| `App.tsx` (창 관리자) | `shell/desktop.dart` + `shell/window_manager.dart` |
| `system/SystemContext.tsx` | `system/system_state.dart` (ChangeNotifier) |
| `system/systemAPI.ts` (추상화) | `system/system_api.dart` (동일 패턴: 백엔드 교체용) |
| `system/robin.ts`, `robin-deepseek.ts` | `robin/robin.dart`, `robin/deepseek.dart` |
| `components/Dock` 등 | `widgets/dock.dart`, `menubar.dart`, `window.dart`, `launchpad.dart`, `spotlight.dart`, `mission_control.dart`, `notifications.dart`, `control_center.dart`, `robin_panel.dart`, `lock_screen.dart`, `boot_screen.dart`, `desktop_widget.dart` |
| `apps/*` | `apps/finder.dart`, `notes.dart`, `calculator.dart`, `paint.dart`, `terminal.dart`, `settings.dart`, `about.dart` |
| `data/apps.ts` (레지스트리) | `apps/registry.dart` (AppDef + robinTool) |
| 브랜드(`public/brand`) | `assets/brand/` |

## 재구현 순서 (마일스톤)
1. **프로젝트 + 데스크톱 배경 + 독(정적)** ← 첫 창("RobinOS가 Flutter로 뜬다")
2. 창 관리자 + 창 1개 (이동·리사이즈·신호등)
3. system_api + 상태(테마·배경·밝기) → 설정 일부
4. 앱 하나씩 (계산기 → 메모 → Finder → …)
5. Robin (오로라 오브 + 채팅 + 액션 + 두뇌 교체)
6. 폴리시 + 라이트/다크

## 핵심 원칙
- **디자인은 웹 프로토타입을 보고 1:1로 옮긴다** (청사진).
- systemAPI/Robin의 "교체 가능한 백엔드/두뇌" 패턴을 Dart에서도 유지 → Linux 연동·DeepSeek 그대로.
- 각 마일스톤마다 실행 가능한 결과물.
