import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../apps/registry.dart';
import 'anim.dart';

// 런치패드 — 전체화면 앱 그리드. 앱 탭 → 실행, 빈 곳 탭 → 닫기.
class Launchpad extends StatelessWidget {
  final void Function(String id) onOpen;
  final VoidCallback onClose;
  const Launchpad({super.key, required this.onOpen, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          color: Colors.black.withValues(alpha: sys.isLight ? 0.25 : 0.45),
          child: Center(
            child: PopIn(
              from: 0.9,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 40,
                  runSpacing: 36,
                  children: [
                    for (final a in kApps) _tile(sys, a),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(SystemState sys, AppDef a) {
    return GestureDetector(
      onTap: () {
        onOpen(a.id);
        onClose();
      },
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [a.color, Color.lerp(a.color, Colors.black, 0.25)!],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(a.emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 10),
            Text(a.name,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
