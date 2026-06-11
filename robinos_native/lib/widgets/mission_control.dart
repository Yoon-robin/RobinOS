import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../apps/registry.dart';

class MissionWin {
  final int key;
  final AppDef app;
  final String title;
  const MissionWin(this.key, this.app, this.title);
}

// 미션 컨트롤 — 열린 창을 카드로 한눈에. 카드 탭 → 그 창으로.
class MissionControl extends StatelessWidget {
  final List<MissionWin> wins;
  final void Function(int key) onSelect;
  final VoidCallback onClose;
  const MissionControl({
    super.key,
    required this.wins,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: Colors.black.withValues(alpha: sys.isLight ? 0.2 : 0.4),
          child: Center(
            child: wins.isEmpty
                ? Text('열린 창이 없어요',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.7)))
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 26,
                      runSpacing: 26,
                      children: [for (final w in wins) _card(sys, w)],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _card(SystemState sys, MissionWin w) {
    return GestureDetector(
      onTap: () {
        onSelect(w.key);
        onClose();
      },
      child: Container(
        width: 230,
        height: 150,
        decoration: BoxDecoration(
          color: sys.windowSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            // 타이틀바 흉내
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sys.titlebarOverlay,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  _dot(const Color(0xFFFF5F57)),
                  _dot(const Color(0xFFFEBC2E)),
                  _dot(const Color(0xFF28C840)),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.app.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 8),
                    Text(w.title,
                        style: TextStyle(
                            fontSize: 13,
                            color: sys.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
