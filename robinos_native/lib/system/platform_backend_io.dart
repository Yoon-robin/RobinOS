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
  Future<void> suspend() async => _run('systemctl', ['suspend']);

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

  // 쓰기/삭제 대상으로 위험한 경로 차단: 홈 자체('/')·빈 경로·상위 이탈('..').
  // (실호출 경로상 도달은 어렵지만, 홈 전체 deleteSync 같은 사고를 원천 차단하는 심층 방어.)
  bool _unsafe(String p) => p.isEmpty || p == '/' || p.contains('..');

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
    if (_unsafe(path)) return;
    try {
      final f = File(_real(path));
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    } catch (_) {}
  }

  @override
  Future<void> fsMakeDir(String path) async {
    if (_unsafe(path)) return;
    try {
      Directory(_real(path)).createSync(recursive: true);
    } catch (_) {}
  }

  @override
  Future<void> fsDelete(String path) async {
    if (_unsafe(path)) return;
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
    if (_unsafe(fromPath) || _unsafe(toPath)) return;
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
      final re = RegExp(r'^Device\s+([0-9A-Fa-f:]{17})\s+(.*)$');
      // 1) 기기 목록 파싱.
      final parsed = <(String mac, String name)>[];
      for (final line in '${r.stdout}'.split('\n')) {
        final m = re.firstMatch(line.trim());
        if (m == null) continue;
        parsed.add((m.group(1)!, m.group(2)!.trim()));
      }
      // 2) 각 기기 상태(info)를 병렬 조회(직렬이면 기기 수만큼 느려짐).
      final infos = await Future.wait(parsed.map((p) async {
        try {
          return '${(await Process.run('bluetoothctl', ['info', p.$1])).stdout}';
        } catch (_) {
          return '';
        }
      }));
      // 3) 조합.
      final out = <BtDevice>[];
      for (var i = 0; i < parsed.length; i++) {
        final mac = parsed[i].$1;
        final name = parsed[i].$2;
        final it = infos[i];
        out.add(BtDevice(mac, name.isEmpty ? mac : name,
            it.contains('Connected: yes'), it.contains('Paired: yes')));
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

  @override
  Future<String?> currentTimezone() async {
    try {
      final r = await Process.run(
          'timedatectl', ['show', '-p', 'Timezone', '--value']);
      if (r.exitCode != 0) return null;
      final tz = '${r.stdout}'.trim();
      return tz.isEmpty ? null : tz;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setTimezone(String tz) async {
    // tz는 프리셋/목록에서 온 검증된 IANA 이름. Process.run 인자라 셸 인젝션 없음.
    await _run('sudo', ['timedatectl', 'set-timezone', tz]);
  }

  @override
  Future<DisplayInfo?> displayInfo() async {
    try {
      final r = await Process.run('wlr-randr', const <String>[]);
      if (r.exitCode != 0) return null;
      String? output;
      final modes = <String>[];
      String? current;
      for (final line in '${r.stdout}'.split('\n')) {
        if (line.isEmpty) continue;
        if (!line.startsWith(' ') && !line.startsWith('\t')) {
          if (output != null) break; // 첫 출력만 다룬다.
          output = line.split(RegExp(r'\s+')).first.trim();
        } else {
          final m = RegExp(r'(\d{3,}x\d{3,})\s*px').firstMatch(line);
          if (m != null) {
            final mode = m.group(1)!;
            if (!modes.contains(mode)) modes.add(mode);
            if (line.contains('current')) current = mode;
          }
        }
      }
      if (output == null || modes.isEmpty) return null;
      return DisplayInfo(output, modes, current);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setDisplayMode(String output, String mode) async {
    await _run('wlr-randr', ['--output', output, '--mode', mode]);
  }

  @override
  Future<bool> wifiConnected() async {
    try {
      final r = await Process.run(
          'nmcli', ['-t', '-f', 'TYPE,STATE', 'device', 'status']);
      if (r.exitCode != 0) return false;
      for (final line in '${r.stdout}'.split('\n')) {
        final p = line.split(':');
        if (p.length >= 2 && p[0] == 'wifi' && p[1] == 'connected') return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<PackageInfo>> searchPackages(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final r = await Process.run('apt-cache', ['search', query]);
      if (r.exitCode != 0) return const [];
      // 설치된 패키지 집합(한 번에 조회해 각 결과에 표시).
      final inst = <String>{};
      try {
        final d = await Process.run('dpkg', ['--get-selections']);
        for (final l in '${d.stdout}'.split('\n')) {
          final p = l.split(RegExp(r'\s+'));
          if (p.length >= 2 && p[1] == 'install') {
            inst.add(p[0].split(':').first);
          }
        }
      } catch (_) {}
      final out = <PackageInfo>[];
      for (final line in '${r.stdout}'.split('\n')) {
        final i = line.indexOf(' - ');
        if (i < 1) continue;
        final name = line.substring(0, i).trim();
        final desc = line.substring(i + 3).trim();
        out.add(PackageInfo(name, desc, inst.contains(name)));
        if (out.length >= 40) break; // 상위 40개만
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> installPackage(String name) async {
    // pkexec가 polkit 암호 창을 띄움 → 사용자가 암호 입력 후 apt-get install.
    await _run('pkexec', ['apt-get', 'install', '-y', name]);
  }

  @override
  Future<void> removePackage(String name) async {
    // pkexec polkit 암호 후 apt-get remove. (purge가 아닌 remove — 설정 보존)
    await _run('pkexec', ['apt-get', 'remove', '-y', name]);
  }

  // === 시스템 모니터 (/proc·/sys) ===
  @override
  Future<SystemStats?> systemStats() async {
    try {
      // CPU·네트워크·프로세스CPU는 변화율 → 짧은 간격을 두고 두 번 샘플링해 델타로 계산.
      final cpu0 = _readCpu();
      final procJ0 = _readProcJiffies(); // 프로세스별 누적 jiffies (t0)
      final net0 = _readNet();
      final sw = Stopwatch()..start();
      await Future.delayed(const Duration(milliseconds: 250));
      sw.stop();
      final cpu1 = _readCpu();
      final procJ1 = _readProcJiffies(); // (t1)
      final net1 = _readNet();
      final dt = sw.elapsedMicroseconds / 1e6;
      final totalDelta = (cpu0.isNotEmpty && cpu1.isNotEmpty)
          ? (cpu1[0][1] - cpu0[0][1])
          : 0;

      double pct(List<int> a, List<int> b) {
        final dIdle = b[0] - a[0];
        final dTot = b[1] - a[1];
        if (dTot <= 0) return 0;
        final v = (dTot - dIdle) / dTot * 100;
        return v < 0 ? 0.0 : (v > 100 ? 100.0 : v);
      }

      final overall =
          (cpu0.isNotEmpty && cpu1.isNotEmpty) ? pct(cpu0[0], cpu1[0]) : 0.0;
      final cores = <double>[];
      final n = cpu0.length < cpu1.length ? cpu0.length : cpu1.length;
      for (var i = 1; i < n; i++) {
        cores.add(pct(cpu0[i], cpu1[i]));
      }

      final mem = _readMem();
      final disk = _readDisk();
      final rx = dt > 0 ? (net1.$1 - net0.$1) / dt : 0.0;
      final tx = dt > 0 ? (net1.$2 - net0.$2) / dt : 0.0;

      return SystemStats(
        cpu: overall,
        cores: cores,
        memUsedKb: mem['used']!,
        memTotalKb: mem['total']!,
        swapUsedKb: mem['swapUsed']!,
        swapTotalKb: mem['swapTotal']!,
        diskUsedKb: disk['used']!,
        diskTotalKb: disk['total']!,
        netRxBps: rx < 0 ? 0.0 : rx,
        netTxBps: tx < 0 ? 0.0 : tx,
        uptimeSec: _readUptime(),
        load1: _readLoad(),
        procs: _topProcs(procJ0, procJ1, totalDelta),
      );
    } catch (_) {
      return null;
    }
  }

  // /proc/stat → 각 cpu 라인의 [idle+iowait, total]. 0번이 전체, 이후가 코어별.
  List<List<int>> _readCpu() {
    final out = <List<int>>[];
    try {
      for (final l in File('/proc/stat').readAsLinesSync()) {
        if (!l.startsWith('cpu')) break; // cpu 라인은 파일 맨 앞에 연속.
        final p = l.trim().split(RegExp(r'\s+'));
        final nums = p.skip(1).map((s) => int.tryParse(s) ?? 0).toList();
        if (nums.length < 4) continue;
        final idle = nums[3] + (nums.length > 4 ? nums[4] : 0); // idle+iowait
        final total = nums.fold<int>(0, (a, b) => a + b);
        out.add([idle, total]);
      }
    } catch (_) {}
    return out;
  }

  // /proc/net/dev → (수신 bytes 합, 송신 bytes 합). lo(루프백)는 제외.
  (int, int) _readNet() {
    var rx = 0, tx = 0;
    try {
      for (final l in File('/proc/net/dev').readAsLinesSync()) {
        final i = l.indexOf(':');
        if (i < 0) continue;
        final iface = l.substring(0, i).trim();
        if (iface.isEmpty || iface == 'lo') continue;
        final f = l.substring(i + 1).trim().split(RegExp(r'\s+'));
        if (f.length < 9) continue;
        rx += int.tryParse(f[0]) ?? 0; // rx bytes
        tx += int.tryParse(f[8]) ?? 0; // tx bytes
      }
    } catch (_) {}
    return (rx, tx);
  }

  // /proc/meminfo → {total, used, swapTotal, swapUsed} (kB). used = total - available.
  Map<String, int> _readMem() {
    var total = 0, avail = 0, swapTotal = 0, swapFree = 0;
    try {
      for (final l in File('/proc/meminfo').readAsLinesSync()) {
        final c = l.indexOf(':');
        if (c < 0) continue;
        final key = l.substring(0, c).trim();
        final val =
            int.tryParse(l.substring(c + 1).trim().split(RegExp(r'\s+')).first) ??
                0;
        switch (key) {
          case 'MemTotal':
            total = val;
          case 'MemAvailable':
            avail = val;
          case 'SwapTotal':
            swapTotal = val;
          case 'SwapFree':
            swapFree = val;
        }
      }
    } catch (_) {}
    final used = total - avail < 0 ? 0 : total - avail;
    final swapUsed = swapTotal - swapFree < 0 ? 0 : swapTotal - swapFree;
    return {
      'total': total,
      'used': used,
      'swapTotal': swapTotal,
      'swapUsed': swapUsed,
    };
  }

  // 루트(/) 디스크 사용량 → {total, used} (kB). df -B1 --output 파싱.
  Map<String, int> _readDisk() {
    try {
      final r = Process.runSync('df', ['-B1', '--output=size,used', '/']);
      if (r.exitCode == 0) {
        final lines = '${r.stdout}'.trim().split('\n');
        if (lines.length >= 2) {
          final p = lines[1].trim().split(RegExp(r'\s+'));
          if (p.length >= 2) {
            return {
              'total': (int.tryParse(p[0]) ?? 0) ~/ 1024,
              'used': (int.tryParse(p[1]) ?? 0) ~/ 1024,
            };
          }
        }
      }
    } catch (_) {}
    return {'total': 0, 'used': 0};
  }

  int _readUptime() {
    try {
      final s = File('/proc/uptime').readAsStringSync().trim().split(' ').first;
      return (double.tryParse(s) ?? 0).floor();
    } catch (_) {
      return 0;
    }
  }

  double _readLoad() {
    try {
      return double.tryParse(
              File('/proc/loadavg').readAsStringSync().trim().split(' ').first) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  // 프로세스별 누적 CPU jiffies(utime+stime) 맵. /proc/[pid]/stat.
  // comm(2번째 필드)에 공백/괄호가 있을 수 있어 '마지막 )' 이후를 파싱.
  Map<int, int> _readProcJiffies() {
    final m = <int, int>{};
    try {
      for (final ent in Directory('/proc').listSync()) {
        if (ent is! Directory) continue;
        final pid = int.tryParse(ent.path.split('/').last);
        if (pid == null) continue;
        try {
          final s = File('${ent.path}/stat').readAsStringSync();
          final rp = s.lastIndexOf(')');
          if (rp < 0) continue;
          final p = s.substring(rp + 1).trim().split(RegExp(r'\s+'));
          // comm 이후: state(0) ppid(1) pgrp(2) ... utime(11) stime(12)
          if (p.length > 12) {
            m[pid] = (int.tryParse(p[11]) ?? 0) + (int.tryParse(p[12]) ?? 0);
          }
        } catch (_) {}
      }
    } catch (_) {}
    return m;
  }

  // CPU 점유 상위 프로세스 6개. 두 jiffies 스냅샷의 델타 / 전체 델타 → CPU%.
  // 각 후보의 mem(statm)·이름(comm)을 t1 시점에 읽어 합친다(추가 sleep 없음).
  List<ProcInfo> _topProcs(Map<int, int> j0, Map<int, int> j1, int totalDelta) {
    const pageBytes = 4096;
    final out = <ProcInfo>[];
    for (final e in j1.entries) {
      final pid = e.key;
      final delta = e.value - (j0[pid] ?? e.value);
      final cpu = totalDelta > 0
          ? (delta / totalDelta * 100).clamp(0.0, 100.0).toDouble()
          : 0.0;
      double memMb = 0;
      try {
        final statm = File('/proc/$pid/statm')
            .readAsStringSync()
            .trim()
            .split(RegExp(r'\s+'));
        if (statm.length >= 2) {
          memMb = (int.tryParse(statm[1]) ?? 0) * pageBytes / (1024 * 1024);
        }
      } catch (_) {
        continue; // 프로세스가 사라짐
      }
      if (memMb < 1 && cpu < 0.1) continue; // 사소한 프로세스 제외
      var name = '$pid';
      try {
        name = File('/proc/$pid/comm').readAsStringSync().trim();
      } catch (_) {}
      out.add(ProcInfo(pid, name.isEmpty ? '$pid' : name, cpu, memMb));
    }
    out.sort((a, b) {
      final c = b.cpu.compareTo(a.cpu);
      return c != 0 ? c : b.memMb.compareTo(a.memMb);
    });
    return out.length > 6 ? out.sublist(0, 6) : out;
  }

  @override
  Future<void> playAudio(String path) async {
    if (_unsafe(path)) return;
    // 기존 재생 정지 후 새 파일 재생(detached). --no-video로 오디오만.
    await _run('pkill', ['-x', 'mpv']);
    try {
      await Process.start(
          'mpv', ['--no-video', '--really-quiet', _real(path)],
          mode: ProcessStartMode.detached);
    } catch (_) {}
  }

  @override
  Future<void> stopAudio() async => _run('pkill', ['-x', 'mpv']);

  @override
  Future<List<AudioOutput>> audioOutputs() async {
    try {
      final defR = await Process.run('pactl', ['get-default-sink']);
      final def = defR.exitCode == 0 ? '${defR.stdout}'.trim() : '';
      final r = await Process.run('pactl', ['list', 'sinks']);
      if (r.exitCode != 0) return const [];
      final out = <AudioOutput>[];
      String? name, desc;
      void flush() {
        if (name != null) {
          out.add(AudioOutput(
              name!, (desc == null || desc!.isEmpty) ? name! : desc!,
              name == def));
        }
        name = null;
        desc = null;
      }

      for (final line in '${r.stdout}'.split('\n')) {
        final t = line.trim();
        if (t.startsWith('Sink #')) {
          flush();
        } else if (name == null && t.startsWith('Name:')) {
          name = t.substring(5).trim();
        } else if (desc == null && t.startsWith('Description:')) {
          desc = t.substring(12).trim();
        }
      }
      flush();
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> setAudioOutput(String name) async {
    try {
      await Process.run('pactl', ['set-default-sink', name]);
      // 진행 중 스트림도 새 출력으로 이동(전환이 즉시 체감되도록).
      final si = await Process.run('pactl', ['list', 'short', 'sink-inputs']);
      if (si.exitCode == 0) {
        for (final line in '${si.stdout}'.split('\n')) {
          final id = line.split('\t').first.trim();
          if (id.isNotEmpty && int.tryParse(id) != null) {
            await Process.run('pactl', ['move-sink-input', id, name]);
          }
        }
      }
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
  @override
  Future<SystemStats?> systemStats() async => null;
  @override
  Future<void> playAudio(String path) async {}
  @override
  Future<void> stopAudio() async {}
  @override
  Future<List<AudioOutput>> audioOutputs() async => const [];
  @override
  Future<void> setAudioOutput(String name) async {}
}
