import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import 'anim.dart';

class CtxItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool danger;
  const CtxItem(this.label, this.onTap, {this.icon, this.danger = false});
}

// 우클릭 컨텍스트 메뉴 — pos 위치에 뜨고, 바깥 클릭 시 닫힘.
class ContextMenu extends StatelessWidget {
  final Offset pos;
  final List<CtxItem> items;
  final VoidCallback onClose;
  const ContextMenu({
    super.key,
    required this.pos,
    required this.items,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final size = MediaQuery.sizeOf(context);
    const w = 210.0;
    final h = items.length * 38.0 + 12;
    final left = pos.dx.clamp(0.0, size.width - w - 8);
    final top = pos.dy.clamp(32.0, size.height - h - 8);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: PopIn(
            from: 0.9,
            duration: const Duration(milliseconds: 130),
            alignment: Alignment.topLeft,
            child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: w,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: sys.isLight
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF26262E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sys.chromeBorder),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final it in items) _row(sys, it)],
                ),
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _row(SystemState sys, CtxItem it) {
    final color = it.danger ? const Color(0xFFFF5F57) : sys.textPrimary;
    return GestureDetector(
      onTap: () {
        onClose();
        it.onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        color: Colors.transparent,
        child: Row(
          children: [
            if (it.icon != null) ...[
              Icon(it.icon, size: 16, color: color),
              const SizedBox(width: 10),
            ],
            Text(it.label, style: TextStyle(fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }
}
