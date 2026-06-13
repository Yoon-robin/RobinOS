// 웹/비-dart:io 플랫폼용 no-op 백엔드. (조건부 import 기본값)
import 'dart:math' as math;
import 'platform_backend.dart';

PlatformBackend createPlatformBackend() => const _StubBackend();

class _StubBackend implements PlatformBackend {
  const _StubBackend();

  @override
  bool get isReal => false;

  @override
  Future<void> setBrightness(double value) async {}

  @override
  Future<void> setVolume(double value) async {}

  @override
  Future<void> reboot() async {}

  @override
  Future<void> powerOff() async {}

  @override
  Future<void> suspend() async {}

  @override
  Future<void> setWifi(bool on) async {}

  @override
  Future<void> setBluetooth(bool on) async {}

  @override
  Future<void> runInstaller() async {}

  @override
  Future<String?> runShell(String cmd, String cwd) async => null;

  @override
  Future<List<InstalledApp>> listInstalledApps() async => const [];

  @override
  Future<void> launchApp(String exec) async {}

  @override
  Future<String?> screenshot() async => null;

  @override
  Future<List<WifiNetwork>> scanWifi() async => const [];

  @override
  Future<bool> connectWifi(String ssid, String password) async => false;

  @override
  Future<List<FsNode>> fsScan() async => const [];
  @override
  Future<void> fsWriteFile(String path, String content) async {}
  @override
  Future<void> fsMakeDir(String path) async {}
  @override
  Future<void> fsDelete(String path) async {}
  @override
  Future<void> fsRename(String fromPath, String toPath) async {}
  @override
  Future<BatteryInfo?> batteryInfo() async => null;
  @override
  Future<List<BtDevice>> scanBluetooth() async => const [];
  @override
  Future<bool> connectBluetooth(String mac) async => false;
  @override
  Future<void> disconnectBluetooth(String mac) async {}
  @override
  Future<String?> currentTimezone() async => null;
  @override
  Future<void> setTimezone(String tz) async {}
  @override
  Future<DisplayInfo?> displayInfo() async => null;
  @override
  Future<void> setDisplayMode(String output, String mode) async {}
  @override
  Future<bool> wifiConnected() async => false;
  @override
  Future<List<PackageInfo>> searchPackages(String query) async => const [];
  @override
  Future<void> installPackage(String name) async {}
  @override
  Future<void> removePackage(String name) async {}

  // 웹 데모용 — 시간 기반 부드러운 가짜 지표(실측은 리눅스 백엔드).
  @override
  Future<SystemStats?> systemStats() async {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double w(double base, double amp, double speed, double phase) {
      final v = base + amp * (0.5 + 0.5 * math.sin(t * speed + phase));
      return v < 0 ? 0.0 : (v > 100 ? 100.0 : v);
    }

    final cores = [
      w(28, 40, 1.3, 0),
      w(22, 50, 0.9, 1.7),
      w(18, 35, 1.6, 3.1),
      w(30, 45, 1.1, 4.6),
    ];
    final cpu = cores.reduce((a, b) => a + b) / cores.length;
    const totalKb = 16 * 1024 * 1024; // 16 GiB
    final usedKb =
        (totalKb * (0.42 + 0.12 * (0.5 + 0.5 * math.sin(t * 0.3)))).round();
    return SystemStats(
      cpu: cpu,
      cores: cores,
      memUsedKb: usedKb,
      memTotalKb: totalKb,
      swapUsedKb: (220 * 1024),
      swapTotalKb: (2 * 1024 * 1024),
      diskUsedKb: 168 * 1024 * 1024, // 168 GiB 사용
      diskTotalKb: 256 * 1024 * 1024, // 256 GiB
      netRxBps: 1.0e6 * (0.5 + 0.5 * math.sin(t * 0.8)) + 4.0e4,
      netTxBps: 2.4e5 * (0.5 + 0.5 * math.sin(t * 1.2 + 1)) + 1.0e4,
      uptimeSec: 19000 + DateTime.now().second,
      load1: cpu / 100 * cores.length,
      procs: [
        ProcInfo(412, 'firefox-esr', 980 + 60 * math.sin(t * 0.5)),
        ProcInfo(331, 'robinos_native', 540 + 30 * math.sin(t * 0.7 + 1)),
        ProcInfo(289, 'ollama', 1320 + 80 * math.sin(t * 0.3 + 2)),
        const ProcInfo(120, 'sway', 96),
        const ProcInfo(98, 'pipewire', 42),
        const ProcInfo(1, 'systemd', 12),
      ]..sort((a, b) => b.memMb.compareTo(a.memMb)),
    );
  }

  @override
  Future<void> playAudio(String path) async {}
  @override
  Future<void> stopAudio() async {}

  // 웹 데모 — 출력 장치 2개(전환은 no-op).
  @override
  Future<List<AudioOutput>> audioOutputs() async => const [
        AudioOutput('builtin', '내장 스피커', true),
        AudioOutput('hdmi', 'HDMI 오디오', false),
      ];
  @override
  Future<void> setAudioOutput(String name) async {}
}
