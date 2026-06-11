import 'package:flutter/material.dart';
import 'clock.dart';

// 데스크톱 시계 위젯 — 창 뒤 배경에 큰 시계 + 날짜.
class DesktopClock extends StatelessWidget {
  const DesktopClock({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveClock(
            format: robinBigTime,
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w200,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1,
              letterSpacing: -2,
              shadows: const [
                Shadow(color: Color(0x55000000), blurRadius: 24),
              ],
            ),
          ),
          const SizedBox(height: 2),
          LiveClock(
            format: robinDate,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
              shadows: const [Shadow(color: Color(0x55000000), blurRadius: 16)],
            ),
          ),
        ],
      ),
    );
  }
}
