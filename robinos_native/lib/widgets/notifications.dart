import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';

class NotifItem {
  final int id;
  final String icon;
  final String title;
  final String body;
  const NotifItem(this.id, this.icon, this.title, this.body);
}

// 토스트 알림 — 우측 상단에 쌓임. 탭하면 사라짐 (자동 사라짐은 Desktop이 관리).
class Toasts extends StatelessWidget {
  final List<NotifItem> items;
  final void Function(int id) onDismiss;
  const Toasts({super.key, required this.items, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final sys = context.watch<SystemState>();
    return Positioned(
      top: 42,
      right: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [for (final n in items) _toast(sys, n)],
      ),
    );
  }

  Widget _toast(SystemState sys, NotifItem n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onDismiss(n.id),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sys.isLight
                ? const Color(0xFFFAFAFC)
                : const Color(0xFF26262E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sys.chromeBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
                ),
                alignment: Alignment.center,
                child: Text(n.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: sys.textPrimary)),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: sys.textSec(0.7),
                            height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
