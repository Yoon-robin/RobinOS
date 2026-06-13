import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/file_system.dart';
import '../system/app_intents.dart';

// 메모 — /문서/메모.txt 에 저장 (Finder·터미널과 공유)
class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  static const _dir = '/문서';
  String _path = '/문서/메모.txt';
  final _ctrl = TextEditingController();
  bool _loaded = false;
  bool _saved = true;
  bool _mono = false; // 모노스페이스(코드용) 토글
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    notesOpenTarget.addListener(_consumeIntent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final fs = context.read<RobinFs>();
      // Finder가 특정 파일을 열라고 했으면 그 파일로 시작
      final intent = notesOpenTarget.value;
      if (intent != null && fs.exists(intent)) {
        notesOpenTarget.value = null;
        _path = intent;
      }
      if (!fs.exists(_path)) fs.write(_path, '');
      _ctrl.text = fs.get(_path)?.content ?? '';
    }
  }

  @override
  void dispose() {
    notesOpenTarget.removeListener(_consumeIntent);
    _saveTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // 이미 열려 있는 메모 앱에 Finder가 다른 파일 열기를 요청했을 때 전환
  void _consumeIntent() {
    final target = notesOpenTarget.value;
    if (target == null || !mounted) return;
    final fs = context.read<RobinFs>();
    if (!fs.exists(target)) return;
    notesOpenTarget.value = null;
    _switchTo(target);
  }

  void _onChanged(String v) {
    context.read<RobinFs>().write(_path, v);
    _saved = false;
    setState(() {}); // 통계(줄·단어·글자) 라이브 갱신
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _saved = true);
    });
  }

  void _switchTo(String path) {
    setState(() {
      _path = path;
      _ctrl.text = context.read<RobinFs>().get(path)?.content ?? '';
    });
  }

  void _newNote() {
    final fs = context.read<RobinFs>();
    String p(String n) => '$_dir/$n';
    var name = '새 메모.txt';
    var n = 2;
    while (fs.exists(p(name))) {
      name = '새 메모 $n.txt';
      n++;
    }
    fs.write(p(name), '');
    _switchTo(p(name));
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final fs = context.watch<RobinFs>();
    final files = fs
        .list(_dir)
        .where((e) => !e.isDir && e.name.toLowerCase().endsWith('.txt'))
        .toList();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          // 파일 탭 바 (/문서의 .txt 들 + 새 메모)
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sys.chromeBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final e in files)
                          _chip(sys, e.name, e.path == _path,
                              () => _switchTo(e.path)),
                        _newChip(sys),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 모노스페이스 토글(코드/정렬용)
                GestureDetector(
                  onTap: () => setState(() => _mono = !_mono),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _mono ? sys.accent.withValues(alpha: 0.18) : null,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: _mono ? sys.accent : sys.textSec(0.2)),
                    ),
                    child: Text('</>',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _mono ? sys.accent : sys.textSec(0.6))),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_stats(),
                    style: TextStyle(fontSize: 11, color: sys.textSec(0.4))),
                const SizedBox(width: 10),
                Text(_saved ? '저장됨' : '저장 중…',
                    style: TextStyle(
                        fontSize: 11,
                        color: _saved ? sys.textSec(0.4) : sys.accent)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: sys.textPrimary,
                  fontFamily: _mono ? 'monospace' : null),
              decoration: InputDecoration(
                hintText: '메모를 입력하세요…',
                hintStyle: TextStyle(color: sys.textSec(0.35)),
                contentPadding: const EdgeInsets.all(18),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 줄·단어·글자 수 통계.
  String _stats() {
    final t = _ctrl.text;
    final lines = t.isEmpty ? 0 : '\n'.allMatches(t).length + 1;
    final words = t.trim().isEmpty ? 0 : t.trim().split(RegExp(r'\s+')).length;
    return '$lines줄 · $words단어 · ${t.characters.length}자';
  }

  Widget _chip(SystemState sys, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? sys.accent.withValues(alpha: 0.18) : sys.textSec(0.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? sys.accent : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: active ? sys.textPrimary : sys.textSec(0.7),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _newChip(SystemState sys) {
    return GestureDetector(
      onTap: _newNote,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sys.textSec(0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('+ 새 메모', style: TextStyle(fontSize: 12, color: sys.accent)),
      ),
    );
  }
}
