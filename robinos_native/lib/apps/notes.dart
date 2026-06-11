import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/file_system.dart';

// 메모 — /문서/메모.txt 에 저장 (Finder·터미널과 공유)
class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  static const _path = '/문서/메모.txt';
  final _ctrl = TextEditingController();
  bool _loaded = false;
  bool _saved = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _ctrl.text = context.read<RobinFs>().get(_path)?.content ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    context.read<RobinFs>().write(_path, v);
    if (!_saved) return;
    setState(() => _saved = false);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _saved = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sys.chromeBorder)),
            ),
            child: Row(
              children: [
                Text('📄 $_path',
                    style: TextStyle(fontSize: 12, color: sys.textSec(0.55))),
                const Spacer(),
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
              style: TextStyle(fontSize: 14, height: 1.5, color: sys.textPrimary),
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
}
