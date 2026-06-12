import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import 'anim.dart';

class NotifItem {
  final int id;
  final String icon;
  final String title;
  final String body;
  final DateTime time;
  NotifItem(this.id, this.icon, this.title, this.body, {DateTime? time})
      : time = time ?? DateTime.now();
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

// 알림 센터 — 메뉴바 종 아이콘에서 열림. 누적 알림을 최신순으로 보여주고 모아서 지운다.
// (토스트는 잠깐 떴다 사라지지만, 그 내용은 여기 히스토리에 남는다 — macOS식.)
class NotificationCenter extends StatelessWidget {
  final List<NotifItem> items;
  final VoidCallback onClose;
  final VoidCallback onClearAll;
  const NotificationCenter({
    super.key,
    required this.items,
    required this.onClose,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final ordered = items.reversed.toList(); // 최신이 위로
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
          ),
        ),
        Positioned(
          top: 38,
          right: 12,
          child: PopIn(
            from: 0.95,
            alignment: Alignment.topRight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: 330,
                  constraints: const BoxConstraints(maxHeight: 460),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sys.isLight
                        ? Colors.white.withValues(alpha: 0.72)
                        : const Color(0xFF1C1C24).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sys.chromeBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('알림',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: sys.textPrimary)),
                          const Spacer(),
                          if (ordered.isNotEmpty)
                            GestureDetector(
                              onTap: onClearAll,
                              child: Text('모두 지우기',
                                  style: TextStyle(
                                      fontSize: 12, color: sys.accent)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (ordered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text('새 알림이 없어요',
                                style: TextStyle(
                                    fontSize: 13, color: sys.textSec(0.5))),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: ordered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _card(sys, ordered[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(SystemState sys, NotifItem n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sys.textSec(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
            ),
            alignment: Alignment.center,
            child: Text(n.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sys.textPrimary)),
                    ),
                    Text(_ago(n.time),
                        style: TextStyle(
                            fontSize: 10.5, color: sys.textSec(0.45))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(n.body,
                    style: TextStyle(
                        fontSize: 12, color: sys.textSec(0.7), height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '방금';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }
}
