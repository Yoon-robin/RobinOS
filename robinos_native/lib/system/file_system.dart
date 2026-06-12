import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_backend.dart';

// ===========================================================
// RobinFs — 가상 파일시스템 (웹 systemAPI.fs 대응)
// 평면 맵(path → FsEntry), shared_preferences 영구 저장.
// 메모/Finder/터미널이 공유 → 한 곳에서 쓰면 다른 곳에 반영.
// ===========================================================
class FsEntry {
  final String path; // 예: '/문서/메모.txt'
  final bool isDir;
  String content;
  FsEntry(this.path, this.isDir, [this.content = '']);

  String get name => path == '/' ? '/' : path.split('/').last;
  String get parent {
    final i = path.lastIndexOf('/');
    return i <= 0 ? '/' : path.substring(0, i);
  }
}

class RobinFs extends ChangeNotifier {
  final Map<String, FsEntry> _map = {};
  SharedPreferences? _prefs;
  // load() 시점에 리눅스 실기기면 true → 실제 디스크(robin 홈)에 미러.
  // 테스트는 load()를 부르지 않으므로 항상 false = 순수 가상(부작용 없음).
  bool _realBacked = false;

  Future<void> load() async {
    // 리눅스 실기기: robin 홈을 RobinFs 루트로 백킹(진짜 파일).
    if (platformBackend.isReal) {
      _realBacked = true;
      await _loadFromDisk();
      notifyListeners();
      return;
    }
    // 웹/개발: 가상 파일시스템(shared_preferences 영속).
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString('robinos.fs');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        data.forEach((k, v) {
          _map[k] = FsEntry(k, v['d'] == true, (v['c'] ?? '') as String);
        });
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
      _persist();
    }
    notifyListeners();
  }

  // 리눅스: 홈을 스캔해 _map 구성. 기본 폴더(문서/사진/다운로드)는 보장하고,
  // 홈이 비어 있으면 환영 파일도 실제로 만든다.
  Future<void> _loadFromDisk() async {
    final nodes = await platformBackend.fsScan();
    _map.clear();
    for (final n in nodes) {
      _map[n.path] = FsEntry(n.path, n.isDir, n.content);
    }
    final hadAny = _map.isNotEmpty;
    for (final d in const ['/문서', '/사진', '/다운로드']) {
      if (!_map.containsKey(d)) {
        _map[d] = FsEntry(d, true);
        platformBackend.fsMakeDir(d);
      }
    }
    if (!hadAny) {
      const wp = '/문서/환영.txt';
      const wc =
          'RobinOS에 오신 걸 환영해요! 🪐\n\nRobin에게 무엇이든 시켜보세요.\n예) "다크모드 켜줘", "계산기 열어"';
      _map[wp] = FsEntry(wp, false, wc);
      platformBackend.fsWriteFile(wp, wc);
    }
  }

  // 변경 영속: 실기기면 디스크에 미러, 아니면 shared_preferences.
  void _sync(void Function() diskOp) {
    if (_realBacked) {
      diskOp();
    } else {
      _persist();
    }
  }

  void _seed() {
    _map.clear();
    _mkdir('/문서');
    _mkdir('/사진');
    _mkdir('/다운로드');
    _set('/문서/환영.txt',
        'RobinOS에 오신 걸 환영해요! 🪐\n\nRobin에게 무엇이든 시켜보세요.\n예) "다크모드 켜줘", "계산기 열어"');
  }

  List<FsEntry> list(String dir) {
    final items = _map.values
        .where((e) => e.parent == dir && e.path != dir)
        .toList();
    items.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return items;
  }

  FsEntry? get(String path) => _map[path];
  bool exists(String path) => _map.containsKey(path);

  // 전체 항목 (Spotlight 전역 검색 등)
  List<FsEntry> get entries => _map.values.toList();

  void _mkdir(String path) => _map[path] = FsEntry(path, true);
  void _set(String path, String content) =>
      _map[path] = FsEntry(path, false, content);

  String _join(String dir, String name) => dir == '/' ? '/$name' : '$dir/$name';

  void mkdir(String dir, String name) {
    final p = _join(dir, name);
    if (!_map.containsKey(p)) {
      _mkdir(p);
      _sync(() => platformBackend.fsMakeDir(p));
      notifyListeners();
    }
  }

  void write(String path, String content) {
    _set(path, content);
    _sync(() => platformBackend.fsWriteFile(path, content));
    notifyListeners();
  }

  void delete(String path) {
    _map.remove(path);
    _map.removeWhere((k, _) => k.startsWith('$path/'));
    _sync(() => platformBackend.fsDelete(path));
    notifyListeners();
  }

  // 이름 변경 — 폴더면 하위 경로(자식 전부)도 함께 재작성.
  // 이름 충돌/빈 이름/'/' 포함이면 무시. 성공 시 새 경로 반환(없으면 null).
  String? rename(String from, String newName) {
    final entry = _map[from];
    final name = newName.trim();
    if (entry == null || name.isEmpty || name.contains('/')) return null;
    final to = _join(entry.parent, name);
    if (to == from || _map.containsKey(to)) return null;
    if (entry.isDir) {
      final affected =
          _map.keys.where((k) => k == from || k.startsWith('$from/')).toList();
      for (final k in affected) {
        final e = _map.remove(k)!;
        final nk = to + k.substring(from.length);
        _map[nk] = FsEntry(nk, e.isDir, e.content);
      }
    } else {
      _map.remove(from);
      _map[to] = FsEntry(to, false, entry.content);
    }
    _sync(() => platformBackend.fsRename(from, to));
    notifyListeners();
    return to;
  }

  void _persist() {
    final data = {
      for (final e in _map.values)
        e.path: {'d': e.isDir, 'c': e.content}
    };
    _prefs?.setString('robinos.fs', jsonEncode(data));
  }
}
