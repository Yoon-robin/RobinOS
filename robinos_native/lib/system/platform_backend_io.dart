// dart:io 플랫폼용 백엔드. 리눅스 실기기에선 표준 CLI 도구로 실제 시스템을 제어.
// 도구가 없거나 권한이 없으면 조용히 무시(UI엔 영향 없음) → 개발 중에도 안전.
import 'dart:io';
import 'platform_backend.dart';

PlatformBackend createPlatformBackend() =>
    Platform.isLinux ? const _LinuxBackend() : const _NoopBackend();

class _LinuxBackend implements PlatformBackend {
  const _LinuxBackend();

  @override
  bool get isReal => true;

  @override
  Future<void> setBrightness(double value) async {
    final pct = (value.clamp(0.05, 1.0) * 100).round();
    await _run('brightnessctl', ['set', '$pct%']);
  }

  @override
  Future<void> setVolume(double value) async {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    await _run('wpctl', ['set-volume', '@DEFAULT_AUDIO_SINK@', '$pct%']);
  }

  @override
  Future<void> reboot() async => _run('systemctl', ['reboot']);

  @override
  Future<void> powerOff() async => _run('systemctl', ['poweroff']);

  @override
  Future<void> setWifi(bool on) async =>
      _run('nmcli', ['radio', 'wifi', on ? 'on' : 'off']);

  @override
  Future<void> setBluetooth(bool on) async =>
      _run('rfkill', [on ? 'unblock' : 'block', 'bluetooth']);

  @override
  Future<void> runInstaller() async =>
      _run('sh', ['-c', 'sudo -E calamares || calamares']);

  @override
  Future<String?> runShell(String cmd, String cwd) async {
    try {
      final r = await Process.run('bash', ['-c', cmd],
          workingDirectory: cwd.isEmpty ? null : cwd);
      return '${r.stdout}${r.stderr}';
    } catch (e) {
      return 'shell 오류: $e\n';
    }
  }

  Future<void> _run(String exe, List<String> args) async {
    try {
      await Process.run(exe, args);
    } catch (_) {
      // 바이너리 부재/권한 없음 → 무시.
    }
  }
}

// dart:io는 있으나 리눅스가 아닌 경우(개발용 macOS/Windows) no-op.
class _NoopBackend implements PlatformBackend {
  const _NoopBackend();

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
  Future<void> setWifi(bool on) async {}

  @override
  Future<void> setBluetooth(bool on) async {}

  @override
  Future<void> runInstaller() async {}

  @override
  Future<String?> runShell(String cmd, String cwd) async => null;
}
