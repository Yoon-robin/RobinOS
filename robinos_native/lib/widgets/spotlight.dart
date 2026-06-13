import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/file_system.dart';
import '../system/platform_backend.dart';
import '../system/app_intents.dart';
import '../apps/registry.dart';
import 'anim.dart';
import 'app_icon.dart';

// Spotlight 검색 결과 한 줄(앱 또는 파일).
class _Hit {
  final String label;
  final String badge; // '앱' / '메모'
  final Color color;
  final IconData glyph; // RobinAppIcon용 글리프
  final VoidCallback onOpen;
  const _Hit(this.label, this.badge, this.color, this.glyph, this.onOpen);
}

// Spotlight — 가운데 검색창에서 앱·메모 검색 → Enter/클릭으로 실행.
class Spotlight extends StatefulWidget {
  final void Function(String id) onOpen;
  final VoidCallback onClose;
  const Spotlight({super.key, required this.onOpen, required this.onClose});

  @override
  State<Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<Spotlight> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_Hit> _hits(RobinFs fs) {
    final q = _q.trim().toLowerCase();
    final apps = (q.isEmpty
            ? kApps
            : kApps.where(
                (a) => a.name.toLowerCase().contains(q) || a.id.contains(q)))
        .map((a) => _Hit(a.name, '앱', a.color, a.glyph, () {
              widget.onOpen(a.id);
              widget.onClose();
            }));
    // 설치된 실제 리눅스 앱(리눅스 실기기) → 선택 시 launchApp으로 실행.
    final real = q.isEmpty
        ? const <_Hit>[]
        : context
            .read<SystemState>()
            .installedApps
            .where((a) => a.name.toLowerCase().contains(q))
            .map((a) =>
                _Hit(a.name, '앱', const Color(0xFF49D17A), Icons.widgets_rounded,
                    () {
                  platformBackend.launchApp(a.exec);
                  widget.onClose();
                }));
    // 메모/문서(.txt) 전역 검색 → 선택 시 메모 앱에서 열기
    final files = q.isEmpty
        ? const <_Hit>[]
        : fs.entries
            .where((e) =>
                !e.isDir &&
                e.name.toLowerCase().endsWith('.txt') &&
                e.name.toLowerCase().contains(q))
            .map((e) => _Hit(
                    e.name, '메모', const Color(0xFF4AA3FF), Icons.description_rounded,
                    () {
                  notesOpenTarget.value = e.path;
                  widget.onClose();
                }));
    return [...apps, ...real, ...files];
  }

  void _openFirst(RobinFs fs) {
    final r = _hits(fs);
    if (r.isNotEmpty) r.first.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final fs = context.watch<RobinFs>();
    final results = _hits(fs);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.35),
          child: PopIn(
            from: 0.96,
            alignment: Alignment.topCenter,
            child: Container(
            width: 540,
            decoration: BoxDecoration(
              color: sys.isLight
                  ? Colors.white.withValues(alpha: 0.96)
                  : const Color(0xFF20202A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sys.chromeBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 18)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 검색창
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 22, color: sys.textSec(0.5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Focus(
                          onKeyEvent: (_, e) {
                            if (e is KeyDownEvent &&
                                e.logicalKey == LogicalKeyboardKey.escape) {
                              widget.onClose();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            onChanged: (v) => setState(() => _q = v),
                            onSubmitted: (_) => _openFirst(fs),
                            style: TextStyle(fontSize: 19, color: sys.textPrimary),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Spotlight 검색',
                              hintStyle: TextStyle(
                                  fontSize: 19, color: sys.textSec(0.35)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (results.isNotEmpty)
                  Divider(height: 1, color: sys.chromeBorder),
                // 결과
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final a in results) _resultRow(sys, a),
                      if (results.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('결과 없음',
                              style: TextStyle(color: sys.textSec(0.4))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _resultRow(SystemState sys, _Hit h) {
    return GestureDetector(
      onTap: h.onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        margin: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            RobinAppIcon(glyph: h.glyph, color: h.color, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(h.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, color: sys.textPrimary)),
            ),
            const SizedBox(width: 8),
            Text(h.badge, style: TextStyle(fontSize: 12, color: sys.textSec(0.4))),
          ],
        ),
      ),
    );
  }
}
