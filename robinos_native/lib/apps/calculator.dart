import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../system/system_state.dart';

// ===========================================================
// 계산기 앱 — 실제 동작 (웹 apps/Calculator.tsx 대응)
// ===========================================================
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _display = '0';
  double? _acc;
  String? _op;
  bool _resetNext = false;
  bool _sci = false; // 공학용 모드
  bool _deg = true; // 삼각함수 각도 단위(도/라디안)

  double get _value => double.tryParse(_display) ?? 0;

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return '오류';
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    final s = v.toString();
    return s.length > 12 ? v.toStringAsPrecision(10) : s;
  }

  void _digit(String d) {
    setState(() {
      if (_display == '오류') _display = '0';
      if (_resetNext || _display == '0') {
        _display = d;
        _resetNext = false;
      } else {
        if (_display.replaceAll('-', '').replaceAll('.', '').length >= 12) return;
        _display += d;
      }
    });
  }

  void _dot() {
    setState(() {
      if (_resetNext) {
        _display = '0.';
        _resetNext = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _clear() => setState(() {
        _display = '0';
        _acc = null;
        _op = null;
        _resetNext = false;
      });

  void _negate() => setState(() {
        if (_display == '0' || _display == '오류') return;
        _display =
            _display.startsWith('-') ? _display.substring(1) : '-$_display';
      });

  void _percent() => setState(() {
        _display = _fmt(_value / 100);
        _resetNext = true;
      });

  void _compute() {
    if (_op == null || _acc == null) {
      _acc = _value;
      return;
    }
    final b = _value;
    double r;
    switch (_op) {
      case '+':
        r = _acc! + b;
        break;
      case '−':
        r = _acc! - b;
        break;
      case '×':
        r = _acc! * b;
        break;
      case '÷':
        r = b == 0 ? double.nan : _acc! / b;
        break;
      case '^':
        r = math.pow(_acc!, b).toDouble();
        break;
      default:
        r = b;
    }
    _acc = r;
    _display = _fmt(r);
  }

  // 공학용 단항 연산 — 현재 값에 즉시 적용.
  void _unary(double Function(double) f) => setState(() {
        _display = _fmt(f(_value));
        _resetNext = true;
      });

  // 상수 입력(π·e) — 값으로 채우고 다음 입력은 새로.
  void _constVal(double v) => setState(() {
        _display = _fmt(v);
        _resetNext = true;
      });

  // 삼각함수(도/라디안 반영).
  double _toRad(double v) => _deg ? v * math.pi / 180 : v;

  void _setOp(String op) {
    setState(() {
      if (_op != null && !_resetNext) {
        _compute();
      } else {
        _acc = _value;
      }
      _op = op;
      _resetNext = true;
    });
  }

  void _equals() {
    setState(() {
      _compute();
      _op = null;
      _resetNext = true;
    });
  }

  void _backspace() {
    setState(() {
      if (_display == '오류' || _resetNext) {
        _display = '0';
        _resetNext = false;
      } else if (_display.length <= 1 ||
          (_display.length == 2 && _display.startsWith('-'))) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  // 물리 키보드 입력 (숫자/연산자/Enter/백스페이스 등)
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _equals();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _clear();
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (ch == null || ch.isEmpty) return KeyEventResult.ignored;
    if (RegExp(r'^[0-9]$').hasMatch(ch)) {
      _digit(ch);
      return KeyEventResult.handled;
    }
    switch (ch) {
      case '.':
        _dot();
        return KeyEventResult.handled;
      case '+':
        _setOp('+');
        return KeyEventResult.handled;
      case '-':
        _setOp('−');
        return KeyEventResult.handled;
      case '*':
      case 'x':
      case 'X':
        _setOp('×');
        return KeyEventResult.handled;
      case '/':
        _setOp('÷');
        return KeyEventResult.handled;
      case '=':
        _equals();
        return KeyEventResult.handled;
      case '%':
        _percent();
        return KeyEventResult.handled;
      case 'c':
      case 'C':
        _clear();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final digitBg = sys.isLight ? const Color(0xFFE9E9EE) : const Color(0xFF2B2B33);
    final funcBg = sys.isLight ? const Color(0xFFD3D3DA) : const Color(0xFF3A3A44);
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Container(
      color: sys.isLight ? const Color(0xFFF3F3F6) : const Color(0xFF15151B),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _modeBar(sys),
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Text(
                  _display,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    color: sys.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_sci) ...[
            _sciRow(sys, [
              ('sin', () => _unary((x) => math.sin(_toRad(x)))),
              ('cos', () => _unary((x) => math.cos(_toRad(x)))),
              ('tan', () => _unary((x) => math.tan(_toRad(x)))),
              ('√', () => _unary(math.sqrt)),
              ('x²', () => _unary((x) => x * x)),
            ]),
            _sciRow(sys, [
              ('ln', () => _unary(math.log)),
              ('log', () => _unary((x) => math.log(x) / math.ln10)),
              ('xʸ', () => _setOp('^')),
              ('π', () => _constVal(math.pi)),
              ('e', () => _constVal(math.e)),
            ]),
          ],
          _row([
            _key('C', funcBg, sys.textPrimary, onTap: _clear),
            _key('±', funcBg, sys.textPrimary, onTap: _negate),
            _key('%', funcBg, sys.textPrimary, onTap: _percent),
            _key('÷', sys.accent, Colors.white, onTap: () => _setOp('÷'), active: _op == '÷'),
          ]),
          _row([
            _key('7', digitBg, sys.textPrimary, onTap: () => _digit('7')),
            _key('8', digitBg, sys.textPrimary, onTap: () => _digit('8')),
            _key('9', digitBg, sys.textPrimary, onTap: () => _digit('9')),
            _key('×', sys.accent, Colors.white, onTap: () => _setOp('×'), active: _op == '×'),
          ]),
          _row([
            _key('4', digitBg, sys.textPrimary, onTap: () => _digit('4')),
            _key('5', digitBg, sys.textPrimary, onTap: () => _digit('5')),
            _key('6', digitBg, sys.textPrimary, onTap: () => _digit('6')),
            _key('−', sys.accent, Colors.white, onTap: () => _setOp('−'), active: _op == '−'),
          ]),
          _row([
            _key('1', digitBg, sys.textPrimary, onTap: () => _digit('1')),
            _key('2', digitBg, sys.textPrimary, onTap: () => _digit('2')),
            _key('3', digitBg, sys.textPrimary, onTap: () => _digit('3')),
            _key('+', sys.accent, Colors.white, onTap: () => _setOp('+'), active: _op == '+'),
          ]),
          _row([
            _key('0', digitBg, sys.textPrimary, flex: 2, onTap: () => _digit('0')),
            _key('.', digitBg, sys.textPrimary, onTap: _dot),
            _key('=', sys.accent, Colors.white, onTap: _equals),
          ]),
        ],
      ),
      ),
    );
  }

  Widget _row(List<Widget> children) =>
      Expanded(child: Row(children: children));

  // 상단 모드 바 — 기본/공학 토글 + (공학일 때) DEG/RAD.
  Widget _modeBar(SystemState sys) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _seg(sys, '기본', !_sci, () => setState(() => _sci = false)),
          const SizedBox(width: 6),
          _seg(sys, '공학', _sci, () => setState(() => _sci = true)),
          const Spacer(),
          if (_sci)
            GestureDetector(
              onTap: () => setState(() => _deg = !_deg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sys.textSec(0.2)),
                ),
                child: Text(_deg ? 'DEG' : 'RAD',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: sys.accent)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _seg(SystemState sys, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? sys.accent : sys.textSec(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : sys.textSec(0.7))),
      ),
    );
  }

  Widget _sciRow(SystemState sys, List<(String, VoidCallback)> keys) {
    final bg = sys.isLight ? const Color(0xFFD3D3DA) : const Color(0xFF3A3A44);
    return _row([
      for (final k in keys)
        _key(k.$1, bg, sys.textPrimary, onTap: k.$2, fontSize: 16),
    ]);
  }

  Widget _key(
    String label,
    Color bg,
    Color fg, {
    int flex = 1,
    VoidCallback? onTap,
    bool active = false,
    double fontSize = 22,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style:
                  TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
