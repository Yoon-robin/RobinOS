import 'package:flutter/material.dart';
import '../apps/registry.dart';

// ===========================================================
// RobinAppIcon — RobinOS 자체 아이콘 언어.
// 이모지 대신 일관된 "그라데이션 스퀘어클 + 상단 글로스 + 글리프 + 컬러 글로우".
// 독·런치패드가 공유 → OS 전체 아이콘 톤이 하나로 묶이는 게 핵심(독자 미감).
//   · 3-스톱 대각 그라데이션(밝은 틴트 → 베이스 → 짙은 톤)으로 입체감.
//   · 색상별 컬러 글로우 그림자(맥OS의 중립 그림자와 차별화되는 RobinOS 시그니처).
//   · 상단 글로스 하이라이트로 유리/사탕 같은 광택.
// ===========================================================
class RobinAppIcon extends StatelessWidget {
  final AppDef app;
  final double size;
  const RobinAppIcon({super.key, required this.app, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final c = app.color;
    final radius = size * 0.27;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c, Colors.white, 0.24)!,
            c,
            Color.lerp(c, Colors.black, 0.26)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          // 색상 글로우 — 아이콘 고유색이 은은히 번지는 RobinOS 시그니처.
          BoxShadow(
            color: c.withValues(alpha: 0.42),
            blurRadius: size * 0.30,
            offset: Offset(0, size * 0.13),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 상단 글로스 하이라이트(광택).
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: size * 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radius)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 글리프.
          Center(
            child: Icon(
              app.glyph,
              color: Colors.white,
              size: size * 0.5,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
