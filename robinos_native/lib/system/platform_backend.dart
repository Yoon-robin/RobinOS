// ===========================================================
// PlatformBackend — RobinOS가 "진짜 OS"를 제어하는 통로 (Phase C).
// UI/상태 코드는 이 인터페이스(platformBackend)만 호출하고,
// 플랫폼별 구현은 조건부 import로 선택된다:
//   - 웹/비-dart:io  → platform_backend_stub.dart (no-op)
//   - 리눅스 실기기   → platform_backend_io.dart  (Process.run: brightnessctl 등)
// 덕분에 웹 빌드에 dart:io가 새지 않고, 같은 셸 코드가 양쪽에서 동작한다.
// ===========================================================
import 'platform_backend_stub.dart'
    if (dart.library.io) 'platform_backend_io.dart';

abstract class PlatformBackend {
  // 실제 하드웨어 제어가 가능한 플랫폼인지(리눅스 실기기 등). 웹/스텁은 false.
  bool get isReal;

  // 밝기 0.0~1.0 (리눅스: brightnessctl). 웹/도구부재 시 no-op.
  Future<void> setBrightness(double value);

  // 볼륨 0.0~1.0 (리눅스: wpctl). 웹/도구부재 시 no-op.
  Future<void> setVolume(double value);
}

// 플랫폼별 구현 인스턴스 — 조건부 import가 createPlatformBackend()를 제공.
final PlatformBackend platformBackend = createPlatformBackend();
