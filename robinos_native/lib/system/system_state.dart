import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===========================================================
// SystemState — 웹의 SystemContext 대응 (테마·배경·강조색·밝기)
// provider 의 ChangeNotifier. shared_preferences 로 영구 저장.
// "교체 가능한 백엔드" 정신은 유지: 저장소는 _prefs 한 곳만 바꾸면 됨.
// ===========================================================

class Wallpaper {
  final String id;
  final String name;
  final List<Color> colors; // 다크모드 배경 그라데이션
  const Wallpaper(this.id, this.name, this.colors);
}

const kWallpapers = <Wallpaper>[
  Wallpaper('aurora', '오로라', [Color(0xFF0E1020), Color(0xFF150F22), Color(0xFF0B0B12)]),
  Wallpaper('midnight', '미드나잇', [Color(0xFF05070F), Color(0xFF0A0E1A), Color(0xFF02030A)]),
  Wallpaper('sunset', '선셋', [Color(0xFF2A1018), Color(0xFF3A1A20), Color(0xFF170A10)]),
  Wallpaper('ocean', '오션', [Color(0xFF071A22), Color(0xFF0A2630), Color(0xFF03121A)]),
  Wallpaper('sakura', '사쿠라', [Color(0xFF24121C), Color(0xFF301826), Color(0xFF160A12)]),
  Wallpaper('graphite', '그래파이트', [Color(0xFF141416), Color(0xFF1C1C20), Color(0xFF0C0C0E)]),
];

class Accent {
  final String id;
  final String name;
  final Color color;
  const Accent(this.id, this.name, this.color);
}

const kAccents = <Accent>[
  Accent('blue', '블루', Color(0xFF6C8CFF)),
  Accent('purple', '퍼플', Color(0xFFB57BFF)),
  Accent('pink', '핑크', Color(0xFFFF6FA5)),
  Accent('teal', '틸', Color(0xFF38D6C4)),
  Accent('orange', '오렌지', Color(0xFFFF9F4A)),
  Accent('green', '그린', Color(0xFF49D17A)),
];

class SystemState extends ChangeNotifier {
  String _wallpaperId = 'aurora';
  String _accentId = 'blue';
  bool _light = false;
  double _brightness = 1.0;
  SharedPreferences? _prefs;

  // --- 읽기 ---
  String get wallpaperId => _wallpaperId;
  String get accentId => _accentId;
  bool get isLight => _light;
  double get brightness => _brightness;

  Wallpaper get wallpaper => kWallpapers.firstWhere(
        (w) => w.id == _wallpaperId,
        orElse: () => kWallpapers.first,
      );

  Color get accent => kAccents
      .firstWhere((a) => a.id == _accentId, orElse: () => kAccents.first)
      .color;

  // 강조색의 보조 색 (Robin 오브·블롭 그라데이션 끝점) — 살짝 보라/핑크로 흘림
  Color get accent2 {
    final i = kAccents.indexWhere((a) => a.id == _accentId);
    return kAccents[(i + 1) % kAccents.length].color;
  }

  // --- 라이트/다크 팔레트 (한 곳에서 색을 결정) ---
  List<Color> get backgroundGradient => _light
      ? const [Color(0xFFE9EDF6), Color(0xFFF1ECF9), Color(0xFFFBFCFF)]
      : wallpaper.colors;

  Color get windowSurface =>
      _light ? const Color(0xFFFAFAFC) : const Color(0xFF1A1A22);
  Color get windowBorder => _light
      ? Colors.black.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.10);
  Color get titlebarOverlay => _light
      ? Colors.black.withValues(alpha: 0.03)
      : Colors.white.withValues(alpha: 0.04);
  Color get textPrimary => _light ? const Color(0xFF1C1C1E) : Colors.white;
  Color textSec(double a) => textPrimary.withValues(alpha: a);
  Color get chromeOverlay => _light
      ? Colors.white.withValues(alpha: 0.55)
      : Colors.white.withValues(alpha: 0.06);
  Color get chromeBorder => _light
      ? Colors.black.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.08);
  Color get dockOverlay => _light
      ? Colors.white.withValues(alpha: 0.45)
      : Colors.white.withValues(alpha: 0.08);
  Color get dockBorder => _light
      ? Colors.black.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.12);

  // --- 쓰기 (즉시 저장) ---
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _wallpaperId = _prefs?.getString('robinos.wallpaper') ?? 'aurora';
    _accentId = _prefs?.getString('robinos.accent') ?? 'blue';
    _light = _prefs?.getBool('robinos.light') ?? false;
    _brightness = _prefs?.getDouble('robinos.brightness') ?? 1.0;
    notifyListeners();
  }

  void setWallpaper(String id) {
    _wallpaperId = id;
    _prefs?.setString('robinos.wallpaper', id);
    notifyListeners();
  }

  void setAccent(String id) {
    _accentId = id;
    _prefs?.setString('robinos.accent', id);
    notifyListeners();
  }

  void setLight(bool v) {
    _light = v;
    _prefs?.setBool('robinos.light', v);
    notifyListeners();
  }

  void toggleTheme() => setLight(!_light);

  void setBrightness(double v) {
    _brightness = v.clamp(0.25, 1.0);
    _prefs?.setDouble('robinos.brightness', _brightness);
    notifyListeners();
  }
}
