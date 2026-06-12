import 'package:flutter/material.dart';

// macOS식 등장 애니메이션 — 살짝 커지며(스케일) 부드럽게 페이드인.
// 오버레이/패널을 감싸면 마운트 시 자동으로 팝인. (TweenAnimationBuilder라 별도 컨트롤러 불필요)
class PopIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double from; // 시작 스케일 (1보다 작으면 커지며 등장, 크면 줄며 등장)
  final Alignment alignment;
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 190),
    this.from = 0.92,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: from + (1 - from) * t,
          alignment: alignment,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// 배경 흐림/딤이 부드럽게 들어오게 (오버레이 backdrop용).
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 190),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (_, t, child) =>
          Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      child: child,
    );
  }
}
