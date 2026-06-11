import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> load() async {
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

  void _mkdir(String path) => _map[path] = FsEntry(path, true);
  void _set(String path, String content) =>
      _map[path] = FsEntry(path, false, content);

  String _join(String dir, String name) => dir == '/' ? '/$name' : '$dir/$name';

  void mkdir(String dir, String name) {
    final p = _join(dir, name);
    if (!_map.containsKey(p)) {
      _mkdir(p);
      _persist();
      notifyListeners();
    }
  }

  void write(String path, String content) {
    _set(path, content);
    _persist();
    notifyListeners();
  }

  void delete(String path) {
    _map.remove(path);
    _map.removeWhere((k, _) => k.startsWith('$path/'));
    _persist();
    notifyListeners();
  }

  void _persist() {
    final data = {
      for (final e in _map.values)
        e.path: {'d': e.isDir, 'c': e.content}
    };
    _prefs?.setString('robinos.fs', jsonEncode(data));
  }
}
