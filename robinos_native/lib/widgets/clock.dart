import 'dart:async';
import 'package:flutter/material.dart';

// 한국어 시간/날짜 포맷 + 1초마다 갱신되는 시계 위젯.
String robinTime(DateTime t) {
  final ampm = t.hour < 12 ? '오전' : '오후';
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$ampm $h12:$m';
}

String robinTimeWithSec(DateTime t) {
  final s = t.second.toString().padLeft(2, '0');
  return '${robinTime(t)}:$s';
}

String robinDate(DateTime t) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  return '${t.month}월 ${t.day}일 ${days[t.weekday - 1]}요일';
}

String robinBigTime(DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h12:$m';
}

class LiveClock extends StatefulWidget {
  final String Function(DateTime) format;
  final TextStyle style;
  const LiveClock({super.key, required this.format, required this.style});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.format(_now), style: widget.style);
}
