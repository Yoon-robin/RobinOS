import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/system_state.dart';
import '../widgets/anim.dart';

// 캘린더 — 월/주 뷰 + 로컬 일정(shared_preferences). 월 전환은 RobinOS 시그니처 슬라이드.
// 웹/리눅스 공통(순수 Flutter). 일정은 'YYYY-MM-DD' 키에 문자열 목록으로 저장.
class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

const _kWeekdays = ['일', '월', '화', '수', '목', '금', '토'];
const _kMonths = [
  '1월', '2월', '3월', '4월', '5월', '6월',
  '7월', '8월', '9월', '10월', '11월', '12월',
];

class _CalendarAppState extends State<CalendarApp> {
  late DateTime _month; // 표시 중인 달의 1일
  late DateTime _selected; // 선택한 날
  late final DateTime _today;
  bool _weekView = false;
  int _dir = 1; // 전환 방향(다음=+1, 이전=-1)
  Map<String, List<String>> _events = {};
  SharedPreferences? _prefs;
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    _month = DateTime(n.year, n.month, 1);
    _selected = _today;
    _load();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString('robinos.calendar.events');
    if (raw != null && raw.isNotEmpty) {
      try {
        final m = json.decode(raw) as Map<String, dynamic>;
        _events = m.map((k, v) =>
            MapEntry(k, (v as List).map((e) => e.toString()).toList()));
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  void _save() {
    _prefs?.setString('robinos.calendar.events', json.encode(_events));
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _shiftMonth(int delta) {
    setState(() {
      _dir = delta;
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  void _shiftWeek(int delta) {
    setState(() {
      _dir = delta;
      _selected = _selected.add(Duration(days: 7 * delta));
      _month = DateTime(_selected.year, _selected.month, 1);
    });
  }

  void _goToday() {
    setState(() {
      _dir = _today.isBefore(_month) ? -1 : 1;
      _selected = _today;
      _month = DateTime(_today.year, _today.month, 1);
    });
  }

  void _addEvent() {
    final t = _addCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      (_events[_key(_selected)] ??= []).add(t);
      _addCtrl.clear();
    });
    _save();
  }

  void _removeEvent(int i) {
    setState(() {
      final k = _key(_selected);
      _events[k]?.removeAt(i);
      if (_events[k]?.isEmpty ?? false) _events.remove(k);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Container(
      color: sys.windowSurface,
      child: Column(
        children: [
          _header(sys),
          _weekdayRow(sys),
          // 월/주 그리드 — 전환 시 방향에 맞춰 슬라이드+페이드(kRobinEase).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: kRobinEase,
            switchOutCurve: kRobinEase,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: Offset(0.18 * _dir, 0),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _weekView
                ? _weekGrid(sys)
                : _monthGrid(sys, key: ValueKey('m${_month.year}-${_month.month}')),
          ),
          const Divider(height: 1),
          Expanded(child: _eventsPanel(sys)),
        ],
      ),
    );
  }

  Widget _header(SystemState sys) {
    final label = _weekView
        ? _weekLabel()
        : '${_month.year}년 ${_kMonths[_month.month - 1]}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: sys.textPrimary)),
          const Spacer(),
          _navBtn(sys, Icons.chevron_left_rounded,
              () => _weekView ? _shiftWeek(-1) : _shiftMonth(-1)),
          _miniBtn(sys, '오늘', _goToday),
          _navBtn(sys, Icons.chevron_right_rounded,
              () => _weekView ? _shiftWeek(1) : _shiftMonth(1)),
          const SizedBox(width: 8),
          _segToggle(sys),
        ],
      ),
    );
  }

  String _weekLabel() {
    final start = _selected.subtract(Duration(days: _selected.weekday % 7));
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${start.year}년 ${_kMonths[start.month - 1]} ${start.day}–${end.day}일';
    }
    return '${_kMonths[start.month - 1]} ${start.day}일 – ${_kMonths[end.month - 1]} ${end.day}일';
  }

  Widget _segToggle(SystemState sys) {
    Widget seg(String t, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? sys.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : sys.textSec(0.6))),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sys.textSec(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('월', !_weekView, () => setState(() => _weekView = false)),
        seg('주', _weekView, () => setState(() => _weekView = true)),
      ]),
    );
  }

  Widget _navBtn(SystemState sys, IconData ic, VoidCallback onTap) =>
      IconButton(
        onPressed: onTap,
        icon: Icon(ic, size: 24, color: sys.textSec(0.7)),
        splashRadius: 18,
        visualDensity: VisualDensity.compact,
      );

  Widget _miniBtn(SystemState sys, String t, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sys.textSec(0.18)),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 12, color: sys.textSec(0.7), fontWeight: FontWeight.w600)),
        ),
      );

  Widget _weekdayRow(SystemState sys) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(_kWeekdays[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: i == 0
                              ? const Color(0xFFFF5A5F)
                              : (i == 6
                                  ? const Color(0xFF4AA3FF)
                                  : sys.textSec(0.45)))),
                ),
              ),
          ],
        ),
      );

  // 월 그리드 — 6주 × 7일(앞뒤 달 흐리게). 셀 높이 고정.
  Widget _monthGrid(SystemState sys, {required Key key}) {
    final firstWeekday = _month.weekday % 7; // 일=0
    final start = _month.subtract(Duration(days: firstWeekday));
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var w = 0; w < 6; w++)
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                        child: _dayCell(
                            sys, start.add(Duration(days: w * 7 + d)))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 주 그리드 — 선택일이 속한 주의 7일을 큰 셀로.
  Widget _weekGrid(SystemState sys) {
    final start = _selected.subtract(Duration(days: _selected.weekday % 7));
    return Padding(
      key: ValueKey('w${_key(start)}'),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: SizedBox(
        height: 84,
        child: Row(
          children: [
            for (var d = 0; d < 7; d++)
              Expanded(
                  child: _dayCell(sys, start.add(Duration(days: d)), big: true)),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(SystemState sys, DateTime day, {bool big = false}) {
    final isToday = _same(day, _today);
    final isSel = _same(day, _selected);
    final inMonth = day.month == _month.month;
    final has = _events[_key(day)]?.isNotEmpty ?? false;
    final weekday = day.weekday % 7;
    Color txt;
    if (isSel) {
      txt = Colors.white;
    } else if (!inMonth && !_weekView) {
      txt = sys.textSec(0.25);
    } else if (weekday == 0) {
      txt = const Color(0xFFFF5A5F);
    } else if (weekday == 6) {
      txt = const Color(0xFF4AA3FF);
    } else {
      txt = sys.textPrimary;
    }
    return GestureDetector(
      onTap: () => setState(() => _selected = day),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: isSel ? sys.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(big ? 12 : 10),
          border: isToday && !isSel
              ? Border.all(color: sys.accent, width: 1.6)
              : null,
          boxShadow: isSel
              ? [
                  BoxShadow(
                      color: sys.accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}',
                style: TextStyle(
                    fontSize: big ? 17 : 14,
                    fontWeight:
                        isToday || isSel ? FontWeight.w700 : FontWeight.w500,
                    color: txt)),
            if (has) ...[
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSel ? Colors.white : sys.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventsPanel(SystemState sys) {
    final list = _events[_key(_selected)] ?? const [];
    final title =
        '${_kMonths[_selected.month - 1]} ${_selected.day}일 ${_kWeekdays[_selected.weekday % 7]}요일';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: sys.textPrimary)),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text('일정이 없어요. 아래에 추가해 보세요.',
                      style: TextStyle(fontSize: 13, color: sys.textSec(0.4))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: list.length,
                  itemBuilder: (_, i) => StaggerIn(
                    index: i,
                    child: _eventRow(sys, list[i], i),
                  ),
                ),
        ),
        _addRow(sys),
      ],
    );
  }

  Widget _eventRow(SystemState sys, String text, int i) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: sys.textSec(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 10),
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: sys.accent),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13.5, color: sys.textPrimary)),
            ),
            GestureDetector(
              onTap: () => _removeEvent(i),
              child: Icon(Icons.close_rounded,
                  size: 17, color: sys.textSec(0.4)),
            ),
          ],
        ),
      );

  Widget _addRow(SystemState sys) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                onSubmitted: (_) => _addEvent(),
                style: TextStyle(fontSize: 13.5, color: sys.textPrimary),
                decoration: InputDecoration(
                  hintText: '일정 추가',
                  hintStyle: TextStyle(color: sys.textSec(0.4), fontSize: 13.5),
                  isDense: true,
                  filled: true,
                  fillColor: sys.textSec(0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addEvent,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: sys.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}
