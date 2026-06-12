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

  @override
  Future<List<InstalledApp>> listInstalledApps() async {
    final home = Platform.environment['HOME'] ?? '';
    final dirs = [
      '/usr/share/applications',
      '/usr/local/share/applications',
      if (home.isNotEmpty) '$home/.local/share/applications',
    ];
    final apps = <InstalledApp>[];
    final seen = <String>{};
    for (final d in dirs) {
      final dir = Directory(d);
      if (!dir.existsSync()) continue;
      try {
        for (final f in dir.listSync()) {
          if (f is! File || !f.path.endsWith('.desktop')) continue;
          try {
            String? name, exec;
            var hidden = false;
            for (final l in f.readAsLinesSync()) {
              if (name == null && l.startsWith('Name=')) {
                name = l.substring(5).trim();
              } else if (exec == null && l.startsWith('Exec=')) {
                exec = l.substring(5).replaceAll(RegExp(r'%[a-zA-Z]'), '').trim();
              } else if (l == 'NoDisplay=true' || l == 'Terminal=true') {
                hidden = true;
              }
            }
            if (hidden || name == null || exec == null || exec.isEmpty) continue;
            if (seen.add(name)) apps.add(InstalledApp(name, exec));
          } catch (_) {}
        }
      } catch (_) {}
    }
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  @override
  Future<void> launchApp(String exec) async {
    try {
      await Process.start('sh', ['-c', exec],
          mode: ProcessStartMode.detached);
    } catch (_) {}
  }

  @override
  Future<String?> screenshot() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return null;
    final dir = '$home/사진';
    try {
      Directory(dir).createSync(recursive: true);
    } catch (_) {}
    final n = DateTime.now();
    String p2(int v) => v.toString().padLeft(2, '0');
    final fname =
        '스크린샷-${n.year}${p2(n.month)}${p2(n.day)}-${p2(n.hour)}${p2(n.minute)}${p2(n.second)}.png';
    final path = '$dir/$fname';
    try {
      final r = await Process.run('grim', [path]);
      if (r.exitCode == 0) return path;
    } catch (_) {}
    return null;
  }

  @override
  Future<List<WifiNetwork>> scanWifi() async {
    try {
      // -t(terse, 콜론 구분) + 필드 고정. SSID가 마지막이라 콜론 포함 시 뒤를 합쳐 복원.
      final r = await Process.run('nmcli',
          ['-t', '-f', 'ACTIVE,SIGNAL,SECURITY,SSID', 'device', 'wifi', 'list']);
      if (r.exitCode != 0) return const [];
      final nets = <String, WifiNetwork>{};
      for (final line in '${r.stdout}'.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(':');
        if (parts.length < 4) continue;
        final active = parts[0] == 'yes';
        final signal = int.tryParse(parts[1]) ?? 0;
        final security = parts[2];
        // nmcli terse는 SSID 내 콜론을 '\:'로 이스케이프 → 합친 뒤 복원.
        final ssid = parts.sublist(3).join(':').replaceAll(r'\:', ':').trim();
        if (ssid.isEmpty) continue;
        final secured = security.isNotEmpty && security != '--';
        final prev = nets[ssid];
        if (prev == null || active || signal > prev.signal) {
          nets[ssid] = WifiNetwork(
              ssid, signal, secured, active || (prev?.active ?? false));
        }
      }
      final list = nets.values.toList()
        ..sort((a, b) {
          if (a.active != b.active) return a.active ? -1 : 1;
          return b.signal.compareTo(a.signal);
        });
      return list;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> connectWifi(String ssid, String password) async {
    try {
      final args = ['device', 'wifi', 'connect', ssid];
      if (password.isNotEmpty) {
        args.add('password');
        args.add(password);
      }
      final r = await Process.run('nmcli', args);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // --- 파일시스템: robin 홈을 RobinFs 루트로 백킹 ---
  String get _home => Platform.environment['HOME'] ?? '/home/robin';
  // RobinFs 경로('/문서/a.txt') → 실제 경로('$HOME/문서/a.txt'). '/'는 홈 자체.
  String _real(String p) => p == '/' ? _home : '$_home$p';

  bool _isTextPath(String p) {
    final l = p.toLowerCase();
    const exts = [
      '.txt', '.md', '.log', '.json', '.yaml', '.yml',
      '.sh', '.conf', '.ini', '.csv', '.dart', '.py', '.c', '.h', '.xml',
    ];
    return exts.any(l.endsWith);
  }

  @override
  Future<List<FsNode>> fsScan() async {
    final root = Directory(_home);
    if (!root.existsSync()) return const [];
    final out = <FsNode>[];
    void walk(Directory d, int depth) {
      if (depth > 4) return; // 깊이 제한(홈 폭주 방지)
      List<FileSystemEntity> kids;
      try {
        kids = d.listSync();
      } catch (_) {
        return;
      }
      for (final ent in kids) {
        final base = ent.path.split('/').last;
        if (base.startsWith('.')) continue; // 숨김 제외
        // 실제 경로에서 홈 접두를 떼 RobinFs 경로로.
        var vpath = ent.path.substring(_home.length);
        if (!vpath.startsWith('/')) vpath = '/$vpath';
        if (ent is Directory) {
          out.add(FsNode(vpath, true, ''));
          walk(ent, depth + 1);
        } else if (ent is File) {
          var content = '';
          try {
            if (_isTextPath(vpath) && ent.lengthSync() <= 256 * 1024) {
              content = ent.readAsStringSync();
            }
          } catch (_) {}
          out.add(FsNode(vpath, false, content));
        }
      }
    }

    walk(root, 0);
    return out;
  }

  @override
  Future<void> fsWriteFile(String path, String content) async {
    try {
      final f = File(_real(path));
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    } catch (_) {}
  }

  @override
  Future<void> fsMakeDir(String path) async {
    try {
      Directory(_real(path)).createSync(recursive: true);
    } catch (_) {}
  }

  @override
  Future<void> fsDelete(String path) async {
    try {
      final r = _real(path);
      final d = Directory(r);
      if (d.existsSync()) {
        d.deleteSync(recursive: true);
        return;
      }
      final f = File(r);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  @override
  Future<void> fsRename(String fromPath, String toPath) async {
    try {
      final from = _real(fromPath);
      final to = _real(toPath);
      final d = Directory(from);
      if (d.existsSync()) {
        d.renameSync(to);
        return;
      }
      final f = File(from);
      if (f.existsSync()) f.renameSync(to);
    } catch (_) {}
  }

  @override
  Future<BatteryInfo?> batteryInfo() async {
    try {
      for (final n in const ['BAT0', 'BAT1', 'BAT']) {
        final cap = File('/sys/class/power_supply/$n/capacity');
        if (!cap.existsSync()) continue;
        final level = (int.tryParse(cap.readAsStringSync().trim()) ?? 0)
            .clamp(0, 100);
        var charging = false;
        final st = File('/sys/class/power_supply/$n/status');
        if (st.existsSync()) {
          charging = st.readAsStringSync().trim().toLowerCase() == 'charging';
        }
        return BatteryInfo(level, charging);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<BtDevice>> scanBluetooth() async {
    try {
      // 짧게 스캔(6초)해 주변 기기를 등록시킨 뒤 목록을 읽는다.
      await Process.run('bluetoothctl', ['--timeout', '6', 'scan', 'on']);
      final r = await Process.run('bluetoothctl', ['devices']);
      if (r.exitCode != 0) return const [];
      final out = <BtDevice>[];
      final re = RegExp(r'^Device\s+([0-9A-Fa-f:]{17})\s+(.*)$');
      for (final line in '${r.stdout}'.split('\n')) {
        final m = re.firstMatch(line.trim());
        if (m == null) continue;
        final mac = m.group(1)!;
        final name = m.group(2)!.trim();
        var connected = false, paired = false;
        try {
          final info = await Process.run('bluetoothctl', ['info', mac]);
          final it = '${info.stdout}';
          connected = it.contains('Connected: yes');
          paired = it.contains('Paired: yes');
        } catch (_) {}
        out.add(BtDevice(mac, name.isEmpty ? mac : name, connected, paired));
      }
      out.sort((a, b) {
        if (a.connected != b.connected) return a.connected ? -1 : 1;
        if (a.paired != b.paired) return a.paired ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> connectBluetooth(String mac) async {
    try {
      final info = await Process.run('bluetoothctl', ['info', mac]);
      if (!'${info.stdout}'.contains('Paired: yes')) {
        await Process.run('bluetoothctl', ['pair', mac]);
        await Process.run('bluetoothctl', ['trust', mac]);
      }
      final r = await Process.run('bluetoothctl', ['connect', mac]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnectBluetooth(String mac) async {
    try {
      await Process.run('bluetoothctl', ['disconnect', mac]);
    } catch (_) {}
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
}
