import '../system/system_state.dart';
import '../widgets/clock.dart';

// ===========================================================
// Robin — RobinOS의 개인 에이전트 (웹 system/robin.ts 대응)
// 구조: 두뇌(brain) + 손(RobinActions) + 결과(RobinResult).
// 두뇌는 교체 가능(setRobinBrain) → 나중에 DeepSeek로 드롭인.
// ===========================================================

class RobinResult {
  final String reply;
  final RobinConfirm? confirm; // 위험 동작은 확인 받기
  const RobinResult(this.reply, {this.confirm});
}

class RobinConfirm {
  final String text;
  final void Function() run;
  const RobinConfirm(this.text, this.run);
}

class AppInfo {
  final String id;
  final String name;
  const AppInfo(this.id, this.name);
}

// Robin의 "손" — OS를 실제로 조작하는 콜백 모음. App에서 주입.
class RobinActions {
  final void Function(String appId) openApp;
  final List<AppInfo> Function() apps;
  final void Function(bool light) setTheme;
  final bool Function() isLight;
  final void Function(String id) setWallpaper;
  final void Function(String id) setAccent;
  final void Function(double v) setBrightness;
  final double Function() brightness;
  final void Function() lock;
  final void Function(String appId) closeApp;
  final void Function() closeAll;

  const RobinActions({
    required this.openApp,
    required this.apps,
    required this.setTheme,
    required this.isLight,
    required this.setWallpaper,
    required this.setAccent,
    required this.setBrightness,
    required this.brightness,
    required this.lock,
    required this.closeApp,
    required this.closeAll,
  });
}

typedef RobinBrain = Future<RobinResult> Function(String msg, RobinActions a);

// 현재 두뇌 (기본 = 로컬 인텐트 파서). DeepSeek 연결 시 교체.
RobinBrain _brain = localBrain;
void setRobinBrain(RobinBrain b) => _brain = b;
Future<RobinResult> runRobin(String msg, RobinActions a) => _brain(msg, a);

// -----------------------------------------------------------
// 로컬 두뇌 — 한국어 인텐트 파서 (오프라인에서도 동작)
// -----------------------------------------------------------
Future<RobinResult> localBrain(String msg, RobinActions a) async {
  final m = msg.trim();
  final low = m.toLowerCase();

  if (m.isEmpty) return const RobinResult('네, 말씀하세요!');

  // 인사
  if (RegExp(r'안녕|하이|반가|헬로|hello|^hi\b').hasMatch(low)) {
    return const RobinResult('안녕하세요! 저는 Robin이에요. RobinOS를 직접 조작해 드릴게요 🪐');
  }

  // 정체성
  if (m.contains('누구') ||
      m.contains('네 이름') ||
      m.contains('너 이름') ||
      m.contains('이름이 뭐') ||
      m.contains('정체')) {
    return const RobinResult(
        '저는 Robin이에요 — 이 OS의 개인 비서예요. 화면도 켜고 끄고, 앱도 열고, 계산도 해드려요 🙂');
  }

  // 시간 / 날짜
  if (m.contains('몇 시') ||
      m.contains('몇시') ||
      m.contains('시각') ||
      (m.contains('시간') &&
          (m.contains('지금') || m.contains('현재') || m.contains('알려')))) {
    return RobinResult('지금은 ${robinTime(DateTime.now())}이에요 ⏰');
  }
  if (m.contains('며칠') ||
      m.contains('날짜') ||
      m.contains('요일') ||
      (m.contains('오늘') && m.contains('무슨'))) {
    return RobinResult('오늘은 ${robinDate(DateTime.now())}이에요 📅');
  }

  // 도움말
  if (m.contains('도움') ||
      m.contains('뭐 할') ||
      m.contains('뭘 할') ||
      m.contains('할 수 있') ||
      m.contains('기능')) {
    return const RobinResult(
      '저는 RobinOS를 직접 제어해요:\n'
      '• "다크모드 켜줘" / "라이트모드로"\n'
      '• "배경 오션으로 바꿔"\n'
      '• "강조색 핑크로"\n'
      '• "밝기 올려 / 내려 / 최대"\n'
      '• "계산기 열어" (모든 앱 가능)\n'
      '• "12 곱하기 9는?"\n'
      '나중에 DeepSeek 두뇌가 연결되면 훨씬 똑똑해져요!',
    );
  }

  // 테마 토글 (현재 반대로)
  if (m.contains('테마') &&
      (m.contains('바꿔') ||
          m.contains('바꾸') ||
          m.contains('토글') ||
          m.contains('전환') ||
          m.contains('반대'))) {
    final toLight = !a.isLight();
    a.setTheme(toLight);
    return RobinResult(toLight ? '라이트 모드로 바꿨어요 ☀️' : '다크 모드로 바꿨어요 🌙');
  }

  // 테마
  if (m.contains('다크') || m.contains('어두') || m.contains('야간')) {
    a.setTheme(false);
    return const RobinResult('다크 모드로 바꿨어요 🌙');
  }
  if (m.contains('라이트') || m.contains('밝은') || m.contains('화이트') || m.contains('주간')) {
    a.setTheme(true);
    return const RobinResult('라이트 모드로 바꿨어요 ☀️');
  }

  // 배경화면 (이름 매칭)
  if (m.contains('배경') || m.contains('바탕') || m.contains('월페이퍼')) {
    for (final w in kWallpapers) {
      if (m.contains(w.name)) {
        a.setWallpaper(w.id);
        return RobinResult('배경을 ${w.name}(으)로 바꿨어요 🖼️');
      }
    }
    return RobinResult(
        '어떤 배경으로 바꿀까요? ${kWallpapers.map((w) => w.name).join(", ")} 중에 골라주세요!');
  }
  for (final w in kWallpapers) {
    if (m.contains(w.name) && (m.contains('바꿔') || m.contains('로 해') || m.contains('으로'))) {
      a.setWallpaper(w.id);
      return RobinResult('배경을 ${w.name}(으)로 바꿨어요 🖼️');
    }
  }

  // 강조색
  if (m.contains('강조') ||
      m.contains('악센트') ||
      m.contains('포인트') ||
      m.contains('색깔') ||
      m.contains('색상') ||
      m.contains('테마색')) {
    for (final c in kAccents) {
      if (m.contains(c.name) || _accentAlias(c.id, m)) {
        a.setAccent(c.id);
        return RobinResult('강조색을 ${c.name}(으)로 바꿨어요 🎨');
      }
    }
    return RobinResult('강조색은 ${kAccents.map((c) => c.name).join(", ")} 중에 고를 수 있어요!');
  }
  for (final c in kAccents) {
    if ((m.contains(c.name) || _accentAlias(c.id, m)) &&
        (m.contains('색') || m.contains('바꿔'))) {
      a.setAccent(c.id);
      return RobinResult('강조색을 ${c.name}(으)로 바꿨어요 🎨');
    }
  }

  // 밝기
  if (m.contains('밝기') || m.contains('밝게') || m.contains('어둡게')) {
    if (m.contains('최대') || m.contains('제일') || m.contains('가장')) {
      a.setBrightness(1.0);
      return const RobinResult('밝기를 최대로 올렸어요 🔆');
    }
    if (m.contains('최소') || m.contains('어둡게')) {
      a.setBrightness(0.3);
      return const RobinResult('밝기를 낮췄어요 🔅');
    }
    final pm = RegExp(r'(\d{1,3})\s*%').firstMatch(m);
    if (pm != null) {
      final v = (int.parse(pm.group(1)!) / 100).clamp(0.25, 1.0).toDouble();
      a.setBrightness(v);
      return RobinResult('밝기를 ${(v * 100).round()}%로 맞췄어요');
    }
    if (m.contains('올려') || m.contains('높여') || m.contains('밝게')) {
      a.setBrightness((a.brightness() + 0.2).clamp(0.25, 1.0));
      return const RobinResult('밝기를 올렸어요 🔆');
    }
    if (m.contains('내려') || m.contains('낮춰')) {
      a.setBrightness((a.brightness() - 0.2).clamp(0.25, 1.0));
      return const RobinResult('밝기를 내렸어요 🔅');
    }
  }

  // 앱 닫기 / 전부 닫기
  if (m.contains('닫') || m.contains('종료')) {
    final wantAll = m.contains('전부') ||
        m.contains('모두') ||
        m.contains('모든') ||
        m.contains('전체') ||
        m.contains('싹') ||
        RegExp(r'다\s*(닫|종료)').hasMatch(m);
    if (wantAll) {
      a.closeAll();
      return const RobinResult('열린 창을 모두 닫았어요 🧹');
    }
    for (final app in a.apps()) {
      if (m.contains(app.name) || low.contains(app.id)) {
        a.closeApp(app.id);
        return RobinResult('${app.name} 창을 닫았어요.');
      }
    }
    return const RobinResult('어떤 창을 닫을까요? "계산기 닫아"처럼요. (전부 닫으려면 "다 닫아")');
  }

  // 계산
  final calc = _tryCalc(m);
  if (calc != null) return RobinResult('$calc 이에요 🧮');

  // 앱 열기 (모든 앱)
  for (final app in a.apps()) {
    if ((m.contains(app.name) || low.contains(app.id)) &&
        (m.contains('열') || m.contains('실행') || m.contains('켜') || m.contains('보여') || m.contains('띄'))) {
      a.openApp(app.id);
      return RobinResult('${app.name}을(를) 열었어요!');
    }
  }
  for (final app in a.apps()) {
    if (m == app.name || low == app.id) {
      a.openApp(app.id);
      return RobinResult('${app.name}을(를) 열었어요!');
    }
  }

  // 감사 / 칭찬
  if (m.contains('고마') ||
      m.contains('감사') ||
      m.contains('땡큐') ||
      low.contains('thank') ||
      m.contains('잘했') ||
      m.contains('최고') ||
      m.contains('멋지')) {
    return const RobinResult('천만에요! 더 필요한 게 있으면 언제든 불러주세요 😊');
  }

  // 잠금 — 실제로 잠금 화면으로
  if (m.contains('잠그') || m.contains('잠가') || m.contains('잠금') || low.contains('lock')) {
    a.lock();
    return const RobinResult('화면을 잠갔어요. 다시 오실 때 봬요 🔒');
  }

  // 폴백
  return const RobinResult(
    '음, 아직 그건 잘 못 알아들었어요. "도움말"이라고 하면 제가 할 수 있는 걸 알려드려요. '
    '(DeepSeek 두뇌를 연결하면 훨씬 더 똑똑해져요!)',
  );
}

// 색 별칭 (한국어 일반 명칭 → accent id)
bool _accentAlias(String id, String m) {
  const alias = {
    'blue': ['파랑', '파란', '블루'],
    'purple': ['보라', '퍼플'],
    'pink': ['핑크', '분홍'],
    'teal': ['틸', '청록', '민트'],
    'orange': ['오렌지', '주황'],
    'green': ['초록', '그린', '녹색'],
    'red': ['레드', '빨강', '빨간', '적색'],
    'cyan': ['시안', '하늘', '하늘색'],
  };
  return alias[id]?.any(m.contains) ?? false;
}

// 한국어 수식 → 계산. "12 곱하기 9는?" → "12*9 = 108"
String? _tryCalc(String input) {
  var s = input
      .replaceAll('곱하기', '*')
      .replaceAll('곱', '*')
      .replaceAll('×', '*')
      .replaceAll(RegExp(r'[xX]'), '*')
      .replaceAll('더하기', '+')
      .replaceAll('플러스', '+')
      .replaceAll('빼기', '-')
      .replaceAll('마이너스', '-')
      .replaceAll('나누기', '/')
      .replaceAll('÷', '/');
  final mathPart =
      RegExp(r'[\d+\-*/().\s]+').allMatches(s).map((x) => x.group(0)!).join('');
  if (!RegExp(r'\d').hasMatch(mathPart) || !RegExp(r'[+\-*/]').hasMatch(mathPart)) {
    return null;
  }
  final r = _eval(mathPart);
  if (r == null || r.isNaN || r.isInfinite) return null;
  final clean = mathPart.replaceAll(' ', '');
  final rs = (r == r.roundToDouble() && r.abs() < 1e15)
      ? r.toInt().toString()
      : r.toStringAsPrecision(10);
  return '$clean = $rs';
}

// 수식 평가 (shunting-yard → RPN). +,-,*,/,괄호 지원.
double? _eval(String expr) {
  final tokens = <String>[];
  for (final mt in RegExp(r'\d+\.?\d*|[+\-*/()]').allMatches(expr)) {
    tokens.add(mt.group(0)!);
  }
  if (tokens.isEmpty) return null;

  int prec(String o) => (o == '+' || o == '-') ? 1 : (o == '*' || o == '/') ? 2 : 0;

  final out = <String>[];
  final ops = <String>[];
  for (final t in tokens) {
    if (double.tryParse(t) != null) {
      out.add(t);
    } else if (t == '(') {
      ops.add(t);
    } else if (t == ')') {
      while (ops.isNotEmpty && ops.last != '(') {
        out.add(ops.removeLast());
      }
      if (ops.isNotEmpty) ops.removeLast();
    } else {
      while (ops.isNotEmpty && prec(ops.last) >= prec(t)) {
        out.add(ops.removeLast());
      }
      ops.add(t);
    }
  }
  while (ops.isNotEmpty) {
    out.add(ops.removeLast());
  }

  final st = <double>[];
  for (final t in out) {
    final n = double.tryParse(t);
    if (n != null) {
      st.add(n);
    } else {
      if (st.length < 2) return null;
      final b = st.removeLast();
      final a = st.removeLast();
      st.add(t == '+'
          ? a + b
          : t == '-'
              ? a - b
              : t == '*'
                  ? a * b
                  : (b == 0 ? double.nan : a / b));
    }
  }
  return st.length == 1 ? st.first : null;
}
