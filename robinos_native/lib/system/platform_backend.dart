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

// 주변 와이파이 네트워크 (nmcli 스캔 결과). 웹/스텁에선 만들어지지 않음.
class WifiNetwork {
  final String ssid;
  final int signal; // 신호 세기 0~100
  final bool secured; // 암호 필요 여부
  final bool active; // 현재 연결된 네트워크
  const WifiNetwork(this.ssid, this.signal, this.secured, this.active);
}

// 실제 파일/폴더 노드 (리눅스 홈 디렉터리 스캔 결과).
// path는 RobinFs 형식('/문서/메모.txt') — 구현이 $HOME 접두를 붙여 실제 경로로 변환.
class FsNode {
  final String path;
  final bool isDir;
  final String content; // 텍스트 파일만 채움; 폴더/바이너리/대용량은 ''
  const FsNode(this.path, this.isDir, this.content);
}

// 배터리 상태 (리눅스: /sys/class/power_supply). 배터리 없는 기기/웹은 null.
class BatteryInfo {
  final int level; // 0~100
  final bool charging;
  const BatteryInfo(this.level, this.charging);
}

// 디스플레이 출력 정보 (wlr-randr). 웹/도구부재: null.
class DisplayInfo {
  final String output; // 출력 이름(예: 'HDMI-A-1', 'eDP-1')
  final List<String> modes; // 해상도 목록(예: '1920x1080') — 중복 제거
  final String? current; // 현재 해상도
  const DisplayInfo(this.output, this.modes, this.current);
}

// 블루투스 기기 (bluetoothctl). 웹/스텁에선 만들어지지 않음.
class BtDevice {
  final String mac;
  final String name;
  final bool connected;
  final bool paired;
  const BtDevice(this.mac, this.name, this.connected, this.paired);
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

  // 화면 캡처 (리눅스: grim → 홈/사진 폴더에 PNG 저장, 저장 경로 반환).
  // 웹/도구부재/캡처실패: null. (grim은 wlr-screencopy 지원 컴포지터=labwc에서 동작)
  Future<String?> screenshot();

  // 주변 와이파이 스캔 (리눅스: nmcli dev wifi list). 웹/도구부재: 빈 목록.
  Future<List<WifiNetwork>> scanWifi();

  // 와이파이 접속 (리눅스: nmcli dev wifi connect). 암호는 사용자가 직접 입력한 값을 받는다.
  // 성공 시 true. 웹/도구부재/실패: false.
  Future<bool> connectWifi(String ssid, String password);

  // === 실제 파일시스템 (리눅스: robin 홈을 RobinFs 루트로 백킹) ===
  // 아래 path는 모두 RobinFs 형식('/문서/메모.txt') — 구현이 $HOME 접두를 붙인다.
  // 웹/스텁: 빈 목록 / no-op (RobinFs가 가상 모드로 폴백).

  // 홈 디렉터리를 재귀 스캔(숨김 제외, 깊이 제한). 텍스트 파일만 내용 포함.
  Future<List<FsNode>> fsScan();
  // 파일 쓰기(부모 폴더 자동 생성).
  Future<void> fsWriteFile(String path, String content);
  // 폴더 생성(recursive).
  Future<void> fsMakeDir(String path);
  // 파일/폴더 삭제(폴더는 recursive).
  Future<void> fsDelete(String path);
  // 이름/경로 변경(파일·폴더 공통).
  Future<void> fsRename(String fromPath, String toPath);

  // 배터리 상태 (리눅스: /sys/class/power_supply). 배터리 없음/웹: null.
  Future<BatteryInfo?> batteryInfo();

  // === 블루투스 (리눅스: bluetoothctl) ===
  // 주변 기기 스캔(짧게 스캔 후 알려진 기기 목록+상태). 웹/도구부재: 빈 목록.
  Future<List<BtDevice>> scanBluetooth();
  // 기기 연결(필요 시 페어링/신뢰 후 연결). just-works 페어링만 자동. 성공 시 true.
  Future<bool> connectBluetooth(String mac);
  // 기기 연결 해제.
  Future<void> disconnectBluetooth(String mac);

  // === 시간대 (리눅스: timedatectl) ===
  // 현재 시스템 시간대(예: 'Asia/Seoul'). 웹/도구부재: null.
  Future<String?> currentTimezone();
  // 시간대 변경(리눅스: sudo timedatectl set-timezone). 웹/도구부재: no-op.
  Future<void> setTimezone(String tz);

  // === 디스플레이 (리눅스: wlr-randr, sway에서 동작) ===
  // 첫 출력의 해상도 정보. 웹/도구부재: null.
  Future<DisplayInfo?> displayInfo();
  // 해상도 변경(리눅스: wlr-randr --output X --mode WxH). 웹/도구부재: no-op.
  Future<void> setDisplayMode(String output, String mode);

  // 현재 Wi-Fi 연결 여부 (리눅스: nmcli device status). 웹/도구부재: false.
  Future<bool> wifiConnected();
}

// 플랫폼별 구현 인스턴스 — 조건부 import가 createPlatformBackend()를 제공.
final PlatformBackend platformBackend = createPlatformBackend();
