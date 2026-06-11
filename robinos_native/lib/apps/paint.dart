import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';

// 그림판 — 실제 캔버스 드로잉 (색·굵기·지우기·되돌리기).
class PaintApp extends StatefulWidget {
  const PaintApp({super.key});

  @override
  State<PaintApp> createState() => _PaintAppState();
}

class _Stroke {
  final List<Offset> points = [];
  final Color color;
  final double width;
  _Stroke(this.color, this.width);
}

class _PaintAppState extends State<PaintApp> {
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFF6C8CFF);
  double _width = 4;

  static const _palette = [
    Color(0xFF1C1C1E),
    Color(0xFFFF5F57),
    Color(0xFFFF9F4A),
    Color(0xFFFFC24A),
    Color(0xFF49D17A),
    Color(0xFF6C8CFF),
    Color(0xFFB57BFF),
    Color(0xFFFF6FA5),
  ];
  static const _widths = [2.0, 4.0, 8.0, 16.0];

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          // 툴바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: sys.chromeBorder)),
            ),
            child: Row(
              children: [
                for (final c in _palette) _swatch(c),
                const SizedBox(width: 12),
                Container(width: 1, height: 22, color: sys.textSec(0.15)),
                const SizedBox(width: 12),
                for (final w in _widths) _brush(sys, w),
                const Spacer(),
                _toolBtn(sys, Icons.undo, '되돌리기', () {
                  if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
                }),
                const SizedBox(width: 8),
                _toolBtn(sys, Icons.delete_outline, '지우기',
                    () => setState(() => _strokes.clear())),
              ],
            ),
          ),
          // 캔버스
          Expanded(
            child: ClipRect(
              child: GestureDetector(
                onPanStart: (d) => setState(() {
                  final s = _Stroke(_color, _width);
                  s.points.add(d.localPosition);
                  _strokes.add(s);
                }),
                onPanUpdate: (d) => setState(() {
                  if (_strokes.isNotEmpty) {
                    _strokes.last.points.add(d.localPosition);
                  }
                }),
                child: CustomPaint(
                  painter: _Painter(_strokes),
                  size: Size.infinite,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color c) {
    final active = c == _color;
    return GestureDetector(
      onTap: () => setState(() => _color = c),
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.white : Colors.black.withValues(alpha: 0.2),
            width: active ? 2.5 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }

  Widget _brush(SystemState sys, double w) {
    final active = w == _width;
    return GestureDetector(
      onTap: () => setState(() => _width = w),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: active ? sys.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: w + 4,
            height: w + 4,
            decoration: BoxDecoration(
              color: active ? sys.accent : sys.textSec(0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(SystemState sys, IconData icon, String tip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tip,
        child: Icon(icon, size: 19, color: sys.textSec(0.7)),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<_Stroke> strokes;
  _Painter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawCircle(
            s.points.first, s.width / 2, Paint()..color = s.color);
      } else {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final p in s.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}
