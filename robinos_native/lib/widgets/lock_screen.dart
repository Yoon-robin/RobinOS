import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import 'clock.dart';

// 잠금 화면 — 큰 시계 + 날짜, 클릭하거나 Enter로 잠금 해제.
class LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const LockScreen({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter ||
                e.logicalKey == LogicalKeyboardKey.space)) {
          onUnlock();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: onUnlock,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 (살짝 어둡게 + 블러 느낌)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: sys.backgroundGradient,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.28)),
            ),
            // 시계
            Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Column(
                children: [
                  LiveClock(
                    format: robinDate,
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  LiveClock(
                    format: robinBigTime,
                    style: const TextStyle(
                        fontSize: 96,
                        color: Colors.white,
                        fontWeight: FontWeight.w200,
                        height: 1.1,
                        letterSpacing: -2),
                  ),
                ],
              ),
            ),
            // 하단 안내
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [sys.accent, sys.accent2]),
                        boxShadow: [
                          BoxShadow(
                              color: sys.accent.withValues(alpha: 0.5),
                              blurRadius: 20)
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('R',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1)),
                    ),
                    const SizedBox(height: 14),
                    Text('클릭하거나 Enter로 잠금 해제',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
