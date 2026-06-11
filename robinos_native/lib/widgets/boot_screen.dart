import 'dart:async';
import 'package:flutter/material.dart';

// 부팅 화면 — R 로고 + 진행 바, 약 2초 후 onDone.
class BootScreen extends StatefulWidget {
  final VoidCallback onDone;
  const BootScreen({super.key, required this.onDone});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  double _p = 0;
  Timer? _tick;
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) return;
      setState(() => _p = (_p + 0.05).clamp(0, 1));
      if (_p >= 1) t.cancel();
    });
    _done = Timer(const Duration(milliseconds: 2000), widget.onDone);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _done?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B0B12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C8CFF), Color(0xFFB57BFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C8CFF).withValues(alpha: 0.5),
                    blurRadius: 44,
                    spreadRadius: 4,
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
            const SizedBox(height: 28),
            const Text('RobinOS',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3)),
            const SizedBox(height: 30),
            // 진행 바
            Container(
              width: 180,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _p,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C8CFF), Color(0xFFB57BFF)]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
