// 웹/비-dart:io 플랫폼용 no-op 백엔드. (조건부 import 기본값)
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
}
