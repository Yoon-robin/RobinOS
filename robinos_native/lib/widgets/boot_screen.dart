import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import 'anim.dart';

// 부팅 스플래시 — 강조색 R 오브가 호흡(펄스)하며 등장(팝), 진행 + 상태 텍스트,
// 끝에 부드럽게 페이드아웃 후 onDone. 강조색을 따르므로 사용자 테마와 일관.
class BootScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BootScreen({super.key, required this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with TickerProviderStateMixin {
  late final AnimationController _main; // 0→1: 등장·진행·상태
  late final AnimationController _pulse; // 반복: 오브 호흡
  late final AnimationController _fade; // 종료 페이드아웃
  static const _statuses = [
    '시스템 초기화 중…',
    '서비스 시작 중…',
    '데스크톱 불러오는 중…',
    '거의 다 됐어요…',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    _main = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _fade.forward().whenComplete(widget.onDone);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return AnimatedBuilder(
      animation: Listenable.merge([_main, _pulse, _fade]),
      builder: (_, _) {
        final entrance =
            Curves.easeOutCubic.transform((_main.value / 0.32).clamp(0.0, 1.0));
        final pop = kRobinPop.transform((_main.value / 0.45).clamp(0.0, 1.0));
        final progress = ((_main.value - 0.12) / 0.78).clamp(0.0, 1.0);
        final breathe = _pulse.value;
        final screenOpacity = (1 - _fade.value).clamp(0.0, 1.0);
        final statusIdx =
            (progress * _statuses.length).floor().clamp(0, _statuses.length - 1);
        return Opacity(
          opacity: screenOpacity,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E1020), Color(0xFF0B0B12), Color(0xFF080810)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: entrance,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * pop,
                      child: _orb(sys, breathe),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: entrance,
                    child: const Text('RobinOS',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                  ),
                  const SizedBox(height: 30),
                  _bar(sys, progress.toDouble()),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: entrance * 0.85,
                    child: Text(_statuses[statusIdx],
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orb(SystemState sys, double breathe) {
    return Transform.scale(
      scale: 1 + 0.05 * breathe,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [sys.accent, sys.accent2],
          ),
          boxShadow: [
            BoxShadow(
              color: sys.accent.withValues(alpha: 0.40 + 0.25 * breathe),
              blurRadius: 40 + 20 * breathe,
              spreadRadius: 2 + 3 * breathe,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('R',
            style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1)),
      ),
    );
  }

  Widget _bar(SystemState sys, double p) {
    return Container(
      width: 190,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: p.clamp(0.02, 1.0).toDouble(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: sys.accent.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
