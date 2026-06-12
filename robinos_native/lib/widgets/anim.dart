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

// 리스트 아이템 staggered 등장 — 인덱스에 비례해 살짝 지연된 슬라이드업+페이드.
// 검색 결과·알림·앱 타일이 "주르륵" 부드럽게 나타나는 macOS/iOS 감성.
// (각 아이템이 자기 AnimationController로 1회 등장 — 리스트 빌드 시 index만 넘기면 됨)
class StaggerIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double dy; // 시작 시 아래로 내려둘 오프셋(px)
  const StaggerIn(
      {super.key, required this.child, this.index = 0, this.dy = 10});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    // 인덱스 비례 지연(최대 ~320ms)으로 순차 등장.
    final delayMs = (widget.index * 40).clamp(0, 320);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: child,
          ),
        );
      },
      child: widget.child,
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
