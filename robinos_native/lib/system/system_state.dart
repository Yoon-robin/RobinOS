import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_backend.dart';

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
  Wallpaper('forest', '포레스트', [Color(0xFF0B1A12), Color(0xFF102A1C), Color(0xFF06120C)]),
  Wallpaper('plum', '플럼', [Color(0xFF180C24), Color(0xFF221033), Color(0xFF0E0518)]),
  Wallpaper('ember', '엠버', [Color(0xFF1F0E0A), Color(0xFF2C1510), Color(0xFF120705)]),
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
  Accent('red', '레드', Color(0xFFFF5A5F)),
  Accent('cyan', '시안', Color(0xFF37C8E8)),
];

class SystemState extends ChangeNotifier {
  String _wallpaperId = 'aurora';
  String _accentId = 'blue';
  bool _light = false; // 해석된 현재값 (논리 판단용 — 즉시 반영)
  double _themeT = 0.0; // 0=다크 … 1=라이트. 토글 시 부드럽게 보간(전체 UI 크로스페이드).
  Timer? _themeAnim;
  String _themeMode = 'dark'; // dark | light | auto
  Timer? _autoTimer;
  double _brightness = 1.0;
  double _volume = 0.7;
  SharedPreferences? _prefs;

  // 설치된 실제 리눅스 앱(.desktop) 캐시 — 부팅 시 1회 로드, 런치패드·Robin이 공유.
  // 웹/스텁에선 빈 목록(리눅스 실기기에서만 채워짐).
  List<InstalledApp> _installedApps = const [];

  // --- 읽기 ---
  String get wallpaperId => _wallpaperId;
  String get accentId => _accentId;
  bool get isLight => _light;
  String get themeMode => _themeMode;
  double get brightness => _brightness;
  double get volume => _volume;
  List<InstalledApp> get installedApps => _installedApps;

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
  // _themeT(0=다크,1=라이트)로 두 팔레트를 보간 → 토글 시 전체 UI가 부드럽게 크로스페이드.
  Color _lp(Color dark, Color light) => Color.lerp(dark, light, _themeT)!;

  static const List<Color> _lightBg = [
    Color(0xFFE9EDF6),
    Color(0xFFF1ECF9),
    Color(0xFFFBFCFF),
  ];
  List<Color> get backgroundGradient {
    final dark = wallpaper.colors;
    return [
      for (var i = 0; i < 3; i++)
        Color.lerp(dark[i % dark.length], _lightBg[i], _themeT)!,
    ];
  }

  Color get windowSurface =>
      _lp(const Color(0xFF1A1A22), const Color(0xFFFAFAFC));
  Color get windowBorder => _lp(Colors.white.withValues(alpha: 0.10),
      Colors.black.withValues(alpha: 0.10));
  Color get titlebarOverlay => _lp(Colors.white.withValues(alpha: 0.04),
      Colors.black.withValues(alpha: 0.03));
  Color get textPrimary => _lp(Colors.white, const Color(0xFF1C1C1E));
  Color textSec(double a) => textPrimary.withValues(alpha: a);
  Color get chromeOverlay => _lp(Colors.white.withValues(alpha: 0.06),
      Colors.white.withValues(alpha: 0.55));
  Color get chromeBorder => _lp(Colors.white.withValues(alpha: 0.08),
      Colors.black.withValues(alpha: 0.08));
  Color get dockOverlay => _lp(Colors.white.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.45));
  Color get dockBorder => _lp(Colors.white.withValues(alpha: 0.12),
      Colors.black.withValues(alpha: 0.08));

  // --- 쓰기 (즉시 저장) ---
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _wallpaperId = _prefs?.getString('robinos.wallpaper') ?? 'aurora';
    _accentId = _prefs?.getString('robinos.accent') ?? 'blue';
    _themeMode = _prefs?.getString('robinos.thememode') ??
        ((_prefs?.getBool('robinos.light') ?? false) ? 'light' : 'dark');
    _applyMode();
    _ensureAutoTimer();
    _brightness = _prefs?.getDouble('robinos.brightness') ?? 1.0;
    _volume = _prefs?.getDouble('robinos.volume') ?? 0.7;
    notifyListeners();
    // 설치된 실앱은 부팅을 막지 않게 비동기로 로드(준비되면 notify).
    _loadInstalledApps();
  }

  // 설치된 실제 리눅스 앱 목록을 백그라운드로 로드(.desktop 스캔). 실패해도 조용히 무시.
  Future<void> _loadInstalledApps() async {
    if (!platformBackend.isReal) return;
    try {
      final apps = await platformBackend.listInstalledApps();
      if (apps.isNotEmpty) {
        _installedApps = apps;
        notifyListeners();
      }
    } catch (_) {}
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

  // 모드 → 실제 라이트 여부 계산 (자동은 시간대별: 07~19시 라이트)
  // animate=true면 _themeT를 부드럽게 보간(크로스페이드), false면 즉시 반영(부팅 등).
  void _applyMode({bool animate = false}) {
    if (_themeMode == 'auto') {
      final h = DateTime.now().hour;
      _light = h >= 7 && h < 19;
    } else {
      _light = _themeMode == 'light';
    }
    final target = _light ? 1.0 : 0.0;
    if (animate) {
      _animateThemeTo(target);
    } else {
      _themeAnim?.cancel();
      _themeAnim = null;
      _themeT = target;
    }
  }

  // _themeT를 target으로 ~320ms easeInOut 보간(60fps Timer). 명시적 토글에서만 사용.
  void _animateThemeTo(double target) {
    final from = _themeT;
    if ((target - from).abs() < 0.001) {
      _themeT = target;
      return;
    }
    final startMs = DateTime.now().millisecondsSinceEpoch;
    const durMs = 320;
    _themeAnim?.cancel();
    _themeAnim = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final raw = (DateTime.now().millisecondsSinceEpoch - startMs) / durMs;
      final done = raw >= 1.0;
      final p = Curves.easeInOut
          .transform(done ? 1.0 : raw.clamp(0.0, 1.0).toDouble());
      _themeT = from + (target - from) * p;
      notifyListeners();
      if (done) {
        _themeT = target;
        t.cancel();
        _themeAnim = null;
      }
    });
  }

  // 자동 모드일 때만 주기적으로 재평가(경계에서 자동 전환)
  void _ensureAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
    if (_themeMode == 'auto') {
      _autoTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        final was = _light;
        _applyMode(animate: true);
        if (was != _light) notifyListeners();
      });
    }
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    _prefs?.setString('robinos.thememode', mode);
    _applyMode(animate: true);
    _ensureAutoTimer();
    notifyListeners();
  }

  // 하위호환: Robin·제어센터가 쓰는 명시 전환
  void setLight(bool v) => setThemeMode(v ? 'light' : 'dark');

  void toggleTheme() => setThemeMode(_light ? 'dark' : 'light');

  @override
  void dispose() {
    _autoTimer?.cancel();
    _themeAnim?.cancel();
    super.dispose();
  }

  void setBrightness(double v) {
    _brightness = v.clamp(0.25, 1.0);
    _prefs?.setDouble('robinos.brightness', _brightness);
    // 리눅스 실기기면 실제 화면 밝기도 조절(brightnessctl). 웹/기타는 no-op.
    platformBackend.setBrightness(_brightness);
    notifyListeners();
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    _prefs?.setDouble('robinos.volume', _volume);
    // 리눅스 실기기면 실제 시스템 볼륨도 조절(wpctl). 웹/기타는 no-op.
    platformBackend.setVolume(_volume);
    notifyListeners();
  }
}
