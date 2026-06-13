import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../widgets/anim.dart';

// 시스템 모니터 — CPU·메모리·네트워크·프로세스를 /proc·/sys로 실시간 측정.
// 리눅스 실기기는 실측, 웹/개발 모드는 부드러운 데모 데이터(스텁).
// 디자인: 카드 + 모핑 스파크라인(커스텀페인트), 애니: 게이지/바 트윈, 최적화: 1.2s 폴링·앱 닫히면 타이머 해제.
class SystemMonitorApp extends StatefulWidget {
  const SystemMonitorApp({super.key});

  @override
  State<SystemMonitorApp> createState() => _SystemMonitorAppState();
}

const int _kHist = 48; // 스파크라인 보관 포인트 수(약 1분치)

class _SystemMonitorAppState extends State<SystemMonitorApp> {
  Timer? _timer;
  SystemStats? _stats;
  bool _loadedOnce = false;

  // 고정 길이 히스토리(모핑 보간이 깔끔하도록 길이 불변). 0~1 정규화.
  final List<double> _cpuHist = List.filled(_kHist, 0);
  final List<double> _memHist = List.filled(_kHist, 0);
  final List<double> _rxHist = List.filled(_kHist, 0);
  final List<double> _txHist = List.filled(_kHist, 0);
  double _netMax = 64 * 1024; // 네트워크 정규화 기준(적응형)

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final s = await platformBackend.systemStats();
    if (!mounted) return;
    setState(() {
      _loadedOnce = true;
      if (s == null) return;
      _stats = s;
      _push(_cpuHist, (s.cpu / 100).clamp(0, 1).toDouble());
      _push(_memHist,
          s.memTotalKb > 0 ? (s.memUsedKb / s.memTotalKb).clamp(0, 1) : 0);
      // 네트워크 기준을 관측 최대에 맞춰 천천히 적응(스파이크 후 서서히 수축).
      final peak = s.netRxBps > s.netTxBps ? s.netRxBps : s.netTxBps;
      _netMax = (_netMax * 0.9).clamp(64 * 1024, double.infinity).toDouble();
      if (peak > _netMax) _netMax = peak;
      _push(_rxHist, (s.netRxBps / _netMax).clamp(0, 1));
      _push(_txHist, (s.netTxBps / _netMax).clamp(0, 1));
    });
  }

  void _push(List<double> buf, num v) {
    for (var i = 0; i < buf.length - 1; i++) {
      buf[i] = buf[i + 1];
    }
    buf[buf.length - 1] = v.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final s = _stats;
    if (s == null) {
      return Container(
        color: sys.windowSurface,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _loadedOnce
                ? '이 플랫폼에선 시스템 지표를 읽을 수 없어요.\n리눅스 실기기에서 /proc로 실시간 측정돼요.'
                : '측정 준비 중…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: sys.textSec(0.5), height: 1.5),
          ),
        ),
      );
    }
    return Container(
      color: sys.windowSurface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        children: [
          _cpuCard(sys, s),
          const SizedBox(height: 12),
          _memCard(sys, s),
          const SizedBox(height: 12),
          if (s.diskTotalKb > 0) ...[
            _diskCard(sys, s),
            const SizedBox(height: 12),
          ],
          _netCard(sys, s),
          const SizedBox(height: 12),
          _procCard(sys, s),
          const SizedBox(height: 12),
          _footer(sys, s),
        ],
      ),
    );
  }

  // ---- CPU 카드 ----
  Widget _cpuCard(SystemState sys, SystemStats s) {
    return _card(
      sys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(sys, '프로세서', Icons.memory,
              '부하 ${s.load1.toStringAsFixed(2)} · ${s.cores.length}코어'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 큰 % (카운팅 애니)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: s.cpu),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  '${v.round()}',
                  style: TextStyle(
                      fontSize: 46,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      color: sys.textPrimary,
                      letterSpacing: -2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7, left: 2),
                child: Text('%',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: sys.textSec(0.5))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: _Sparkline(
                      data: _cpuHist, color: sys.accent, fill: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 코어별 바
          SizedBox(
            height: 38,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < s.cores.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(child: _coreBar(sys, s.cores[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coreBar(SystemState sys, double pct) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              color: sys.textSec(0.06),
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                    begin: 0, end: (pct / 100).clamp(0.03, 1.0).toDouble()),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOut,
                builder: (_, t, _) => FractionallySizedBox(
                  heightFactor: t,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [sys.accent, sys.accent2],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- 메모리 카드 ----
  Widget _memCard(SystemState sys, SystemStats s) {
    final frac = s.memTotalKb > 0 ? s.memUsedKb / s.memTotalKb : 0.0;
    return _card(
      sys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(sys, '메모리', Icons.developer_board,
              '${_fmtKb(s.memUsedKb)} / ${_fmtKb(s.memTotalKb)}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _bigBar(sys, frac.toDouble())),
              const SizedBox(width: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: frac * 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text('${v.round()}%',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: sys.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
            child: _Sparkline(data: _memHist, color: sys.accent2, fill: true),
          ),
          if (s.swapTotalKb > 0) ...[
            const SizedBox(height: 8),
            Text('스왑 ${_fmtKb(s.swapUsedKb)} / ${_fmtKb(s.swapTotalKb)}',
                style: TextStyle(fontSize: 11.5, color: sys.textSec(0.45))),
          ],
        ],
      ),
    );
  }

  // ---- 저장공간 카드 ----
  Widget _diskCard(SystemState sys, SystemStats s) {
    final frac = s.diskTotalKb > 0 ? s.diskUsedKb / s.diskTotalKb : 0.0;
    return _card(
      sys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(sys, '저장공간', Icons.storage_rounded,
              '${_fmtKb(s.diskUsedKb)} / ${_fmtKb(s.diskTotalKb)}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _bigBar(sys, frac.toDouble())),
              const SizedBox(width: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: frac * 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text('${v.round()}%',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: sys.textPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 네트워크 카드 ----
  Widget _netCard(SystemState sys, SystemStats s) {
    return _card(
      sys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(sys, '네트워크', Icons.swap_vert, null),
          const SizedBox(height: 8),
          Row(
            children: [
              _netStat(sys, Icons.arrow_downward, '받기', _fmtBps(s.netRxBps),
                  const Color(0xFF49D17A)),
              const SizedBox(width: 20),
              _netStat(sys, Icons.arrow_upward, '보내기', _fmtBps(s.netTxBps),
                  const Color(0xFF6C8CFF)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                _Sparkline(
                    data: _rxHist,
                    color: const Color(0xFF49D17A),
                    fill: true),
                _Sparkline(
                    data: _txHist,
                    color: const Color(0xFF6C8CFF),
                    fill: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _netStat(
      SystemState sys, IconData ic, String label, String val, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, size: 15, color: c),
        const SizedBox(width: 5),
        Text('$label  ',
            style: TextStyle(fontSize: 12, color: sys.textSec(0.5))),
        Text(val,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sys.textPrimary)),
      ],
    );
  }

  // ---- 프로세스 카드 (CPU 상위) ----
  Widget _procCard(SystemState sys, SystemStats s) {
    return _card(
      sys,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHead(sys, '프로세스', Icons.list_alt, 'CPU 상위'),
          const SizedBox(height: 6),
          if (s.procs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('표시할 프로세스가 없어요.',
                  style: TextStyle(fontSize: 12, color: sys.textSec(0.45))),
            )
          else
            for (var i = 0; i < s.procs.length; i++)
              StaggerIn(index: i, child: _procRow(sys, s.procs[i])),
        ],
      ),
    );
  }

  Widget _procRow(SystemState sys, ProcInfo p) {
    final double frac = (p.cpu / 100).clamp(0.0, 1.0).toDouble();
    final mem = p.memMb >= 1024
        ? '${(p.memMb / 1024).toStringAsFixed(1)}G'
        : '${p.memMb.round()}M';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: sys.textPrimary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 8,
                color: sys.textSec(0.06),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: frac),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOut,
                  builder: (_, t, _) => FractionallySizedBox(
                    widthFactor: t,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                            colors: [sys.accent, sys.accent2]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Text('${p.cpu.toStringAsFixed(0)}%  $mem',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11.5,
                    color: sys.textSec(0.6),
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }

  Widget _footer(SystemState sys, SystemStats s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bolt, size: 14, color: sys.textSec(0.4)),
        const SizedBox(width: 4),
        Text('가동 ${_fmtUptime(s.uptimeSec)}',
            style: TextStyle(fontSize: 11.5, color: sys.textSec(0.45))),
        const SizedBox(width: 14),
        Text('·', style: TextStyle(color: sys.textSec(0.3))),
        const SizedBox(width: 14),
        Text('부하 ${s.load1.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 11.5, color: sys.textSec(0.45))),
      ],
    );
  }

  // ---- 공통 위젯 ----
  Widget _card(SystemState sys, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sys.textSec(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sys.textSec(0.07)),
      ),
      child: child,
    );
  }

  Widget _cardHead(SystemState sys, String title, IconData ic, String? sub) {
    return Row(
      children: [
        Icon(ic, size: 16, color: sys.accent),
        const SizedBox(width: 7),
        Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: sys.textPrimary)),
        if (sub != null) ...[
          const Spacer(),
          Text(sub,
              style: TextStyle(fontSize: 11.5, color: sys.textSec(0.45))),
        ],
      ],
    );
  }

  Widget _bigBar(SystemState sys, double frac) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 12,
        color: sys.textSec(0.06),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: frac.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => FractionallySizedBox(
            widthFactor: t,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- 포맷 헬퍼 ----
  String _fmtKb(int kb) {
    final mb = kb / 1024;
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  String _fmtBps(double bps) {
    if (bps >= 1e6) return '${(bps / 1e6).toStringAsFixed(1)} MB/s';
    if (bps >= 1e3) return '${(bps / 1e3).toStringAsFixed(0)} KB/s';
    return '${bps.toStringAsFixed(0)} B/s';
  }

  String _fmtUptime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h >= 24) return '${h ~/ 24}일 ${h % 24}시간';
    if (h > 0) return '$h시간 $m분';
    return '$m분';
  }
}

// ===========================================================
// _Sparkline — 0~1 정규화 데이터의 부드러운 면적/선 차트.
// 데이터가 바뀌면 이전→새 값으로 모핑(보간)하며 다시 그림(예쁜 전환).
// 길이가 고정(_kHist)이라 인덱스별 lerp가 깔끔하게 맞물린다.
// ===========================================================
class _Sparkline extends StatefulWidget {
  final List<double> data; // 오래된→최신, 0~1
  final Color color;
  final bool fill;
  const _Sparkline({required this.data, required this.color, this.fill = true});

  @override
  State<_Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<_Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late List<double> _from;
  late List<double> _to;

  @override
  void initState() {
    super.initState();
    _from = List<double>.from(widget.data);
    _to = List<double>.from(widget.data);
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didUpdateWidget(covariant _Sparkline old) {
    super.didUpdateWidget(old);
    // 현재 화면에 보이던 보간값을 시작점으로 잡아 끊김 없이 새 값으로 이동.
    final t = Curves.easeOut.transform(_c.value);
    _from = List<double>.generate(_to.length, (i) {
      final f = i < _from.length ? _from[i] : _to[i];
      return f + (_to[i] - f) * t;
    });
    _to = List<double>.from(widget.data);
    _c.forward(from: 0);
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
      builder: (_, _) {
        final t = Curves.easeOut.transform(_c.value);
        final n = _to.length;
        final cur = List<double>.generate(n, (i) {
          final f = i < _from.length ? _from[i] : _to[i];
          return f + (_to[i] - f) * t;
        });
        return CustomPaint(
          painter: _SparkPainter(cur, widget.color, widget.fill),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool fill;
  _SparkPainter(this.data, this.color, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final w = size.width, h = size.height;
    final dx = w / (data.length - 1);
    // 위/아래 약간 여백을 둬 선이 잘리지 않게.
    double y(double v) {
      final c = v.clamp(0.0, 1.0).toDouble();
      return h - 2 - c * (h - 4);
    }
    final pts = <Offset>[
      for (var i = 0; i < data.length; i++) Offset(i * dx, y(data[i])),
    ];

    // 부드러운 곡선 path (중점 quadratic 스무딩).
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset(
          (pts[i - 1].dx + pts[i].dx) / 2, (pts[i - 1].dy + pts[i].dy) / 2);
      line.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    line.lineTo(pts.last.dx, pts.last.dy);

    if (fill) {
      final area = Path.from(line)
        ..lineTo(pts.last.dx, h)
        ..lineTo(pts.first.dx, h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // 최신값 헤드 점 + 부드러운 글로우.
    final head = pts.last;
    canvas.drawCircle(head, 6, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(head, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data != data || old.color != color || old.fill != fill;
}
