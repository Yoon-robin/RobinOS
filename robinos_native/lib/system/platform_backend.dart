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

// 설치된 실제 리눅스 앱 (.desktop 항목) — B(데스크톱 환경) 앱 런처용.
class InstalledApp {
  final String name;
  final String exec;
  const InstalledApp(this.name, this.exec);
}

abstract class PlatformBackend {
  // 실제 하드웨어 제어가 가능한 플랫폼인지(리눅스 실기기 등). 웹/스텁은 false.
  bool get isReal;

  // 밝기 0.0~1.0 (리눅스: brightnessctl). 웹/도구부재 시 no-op.
  Future<void> setBrightness(double value);

  // 볼륨 0.0~1.0 (리눅스: wpctl). 웹/도구부재 시 no-op.
  Future<void> setVolume(double value);

  // 전원 (리눅스: systemctl). 웹/도구부재 시 no-op. 위험 동작이므로
  // Robin은 확인(RobinConfirm)을 거친 뒤에만 호출한다.
  Future<void> reboot();
  Future<void> powerOff();

  // 와이파이 on/off (리눅스: nmcli radio wifi). 웹/도구부재 시 no-op.
  Future<void> setWifi(bool on);

  // 블루투스 on/off (리눅스: rfkill). 웹/도구부재 시 no-op.
  Future<void> setBluetooth(bool on);

  // RobinOS를 디스크에 설치 (리눅스: Calamares 그래픽 설치기 실행). 웹/도구부재 시 no-op.
  Future<void> runInstaller();

  // 실제 셸 명령 실행 (리눅스: bash -c, stdout+stderr 반환).
  // 웹/비리눅스: null → 터미널이 RobinFs 가짜 셸로 폴백.
  Future<String?> runShell(String cmd, String cwd);

  // 설치된 실제 리눅스 앱 목록 (.desktop 스캔). 웹/비리눅스: 빈 목록.
  Future<List<InstalledApp>> listInstalledApps();

  // 실제 리눅스 앱/명령을 detached로 실행 (B: 진짜 앱 띄우기). 웹/비리눅스: no-op.
  Future<void> launchApp(String exec);
}

// 플랫폼별 구현 인스턴스 — 조건부 import가 createPlatformBackend()를 제공.
final PlatformBackend platformBackend = createPlatformBackend();
