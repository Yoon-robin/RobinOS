import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../apps/registry.dart';

// Spotlight — 가운데 검색창에서 앱 검색 → Enter/클릭으로 실행.
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

  List<AppDef> get _results {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return kApps;
    return kApps
        .where((a) => a.name.toLowerCase().contains(q) || a.id.contains(q))
        .toList();
  }

  void _openFirst() {
    final r = _results;
    if (r.isNotEmpty) {
      widget.onOpen(r.first.id);
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final results = _results;
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
                            onSubmitted: (_) => _openFirst(),
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
      ],
    );
  }

  Widget _resultRow(SystemState sys, AppDef a) {
    return GestureDetector(
      onTap: () {
        widget.onOpen(a.id);
        widget.onClose();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        margin: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(
                  colors: [a.color, Color.lerp(a.color, Colors.black, 0.25)!],
                ),
              ),
              alignment: Alignment.center,
              child: Text(a.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Text(a.name,
                style: TextStyle(fontSize: 14.5, color: sys.textPrimary)),
            const Spacer(),
            Text('앱', style: TextStyle(fontSize: 12, color: sys.textSec(0.4))),
          ],
        ),
      ),
    );
  }
}
