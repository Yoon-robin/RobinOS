import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'system/system_state.dart';
import 'system/file_system.dart';
import 'system/app_intents.dart';
import 'system/platform_backend.dart';
import 'robin/robin.dart';
import 'robin/brains.dart';
import 'apps/registry.dart';
import 'apps/notes.dart';
import 'apps/finder.dart';
import 'apps/terminal.dart';
import 'apps/calculator.dart';
import 'apps/settings.dart';
import 'apps/software.dart';
import 'apps/system_monitor.dart';
import 'apps/calendar.dart';
import 'apps/music.dart';
import 'apps/gallery.dart';
import 'apps/paint.dart';
import 'widgets/clock.dart';
import 'widgets/battery.dart';
import 'widgets/anim.dart';
import 'widgets/app_icon.dart';
import 'widgets/boot_screen.dart';
import 'widgets/lock_screen.dart';
import 'widgets/control_center.dart';
import 'widgets/spotlight.dart';
import 'widgets/launchpad.dart';
import 'widgets/mission_control.dart';
import 'widgets/notifications.dart';
import 'widgets/context_menu.dart';
import 'widgets/desktop_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sys = SystemState();
  final fs = RobinFs();
  await sys.load();
  await fs.load();
  await applySavedBrain(); // 저장된 Robin 두뇌 복원 (로컬/Ollama/DeepSeek)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sys),
        ChangeNotifierProvider.value(value: fs),
      ],
      child: const RobinOSApp(),
    ),
  );
}

class RobinOSApp extends StatelessWidget {
  const RobinOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RobinOS',
      debugShowCheckedModeBanner: false,
      home: Desktop(),
    );
  }
}

// ===========================================================
// 창 상태 — 웹 App.tsx 의 wins[] 대응
// ===========================================================
class WinState {
  final int key;
  final AppDef app;
  Offset pos;
  Size size;
  int z;
  bool minimized;
  bool maximized;
  Offset? restorePos;
  Size? restoreSize;
  Offset dragPointer = const Offset(-1, -1); // 타이틀바 드래그 중 커서 전역 위치
  bool closing = false; // 닫기 애니메이션 중
  bool minimizing = false; // 최소화 애니메이션 중

  WinState({
    required this.key,
    required this.app,
    required this.pos,
    required this.size,
    required this.z,
    this.minimized = false,
    this.maximized = false,
  });
}

// ===========================================================
// Desktop — 데스크톱 셸 + 창 관리자
// ===========================================================
class Desktop extends StatefulWidget {
  const Desktop({super.key});

  @override
  State<Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<Desktop> {
  final List<WinState> _wins = [];
  int _keySeq = 0;
  int _zTop = 1;
  Size _deskSize = const Size(1280, 800);
  bool _robinOpen = false;

  // 시작 흐름 + 화면들
  bool _booted = false;
  bool _locked = true;
  bool _spotlight = false;
  bool _launchpad = false;
  bool _mission = false;
  bool _control = false;
  ({Offset pos, List<CtxItem> items})? _ctx;

  // 알림 — _notifs는 누적 히스토리(알림 센터), _activeToasts는 지금 화면에 떠있는 토스트 id.
  final List<NotifItem> _notifs = [];
  final Set<int> _activeToasts = {};
  int _notifSeq = 0;
  bool _notifCenter = false;

  @override
  void initState() {
    super.initState();
    notesOpenTarget.addListener(_onNotesIntent);
  }

  @override
  void dispose() {
    notesOpenTarget.removeListener(_onNotesIntent);
    super.dispose();
  }

  // Finder가 .txt를 "메모에서 열기" 요청 → 메모 앱을 연다 (전환은 NotesApp이 처리)
  void _onNotesIntent() {
    if (notesOpenTarget.value != null) _openAppById('notes');
  }

  // Robin "메모 만들어줘" → /문서에 새 .txt 생성 후 메모 앱에서 연다.
  void _newNote() {
    final fs = context.read<RobinFs>();
    String p(String n) => '/문서/$n';
    var name = '새 메모.txt';
    var n = 2;
    while (fs.exists(p(name))) {
      name = '새 메모 $n.txt';
      n++;
    }
    fs.write(p(name), '');
    notesOpenTarget.value = p(name); // 리스너가 메모 앱 열고 NotesApp이 전환
  }

  void _notify(String icon, String title, String body) {
    final id = ++_notifSeq;
    setState(() {
      _notifs.add(NotifItem(id, icon, title, body));
      _activeToasts.add(id);
    });
    // 5초 뒤 토스트만 사라지고, 알림은 센터 히스토리에 남는다.
    Timer(const Duration(seconds: 5), () => _dismissNotif(id));
  }

  // 토스트 닫기 — 화면에서만 치우고 히스토리는 보존.
  void _dismissNotif(int id) {
    if (mounted) setState(() => _activeToasts.remove(id));
  }

  void _clearNotifs() => setState(() {
        _notifs.clear();
        _activeToasts.clear();
      });

  // 알림 센터에서 개별 알림을 히스토리째 제거(스와이프).
  void _removeNotif(int id) => setState(() {
        _notifs.removeWhere((n) => n.id == id);
        _activeToasts.remove(id);
      });

  void _unlock() {
    setState(() => _locked = false);
    _notify('🪐', 'RobinOS', '환영해요! 독의 R 오브를 눌러 Robin을 불러보세요.');
  }

  void _closeOverlays() => setState(() {
        _spotlight = false;
        _launchpad = false;
        _mission = false;
        _control = false;
        _notifCenter = false;
        _ctx = null;
      });

  bool get _anyOverlay =>
      _spotlight ||
      _launchpad ||
      _mission ||
      _control ||
      _notifCenter ||
      _ctx != null;

  // 전역 단축키 — TextField가 먼저 키를 소비하므로 입력과 충돌하지 않음.
  // ⌘/Ctrl+Space=Spotlight, ⌘/Ctrl+K=Robin, ⌘/Ctrl+,=설정, Esc=닫기.
  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      if (_anyOverlay) {
        _closeOverlays();
        return KeyEventResult.handled;
      }
      if (_robinOpen) {
        setState(() => _robinOpen = false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final meta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (!meta) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.space) {
      setState(() {
        _spotlight = !_spotlight;
        if (_spotlight) {
          _launchpad = _mission = _control = false;
        }
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      setState(() => _robinOpen = !_robinOpen);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.comma) {
      _openAppById('settings');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openAppById(String id) {
    final match = kApps.where((a) => a.id == id);
    if (match.isNotEmpty) _openApp(match.first);
  }

  // 독 아이콘 우클릭 메뉴 (열기 / 닫기)
  void _dockMenu(AppDef app, Offset pos) {
    final running = _wins.any((w) => w.app.id == app.id);
    setState(() {
      _ctx = (
        pos: pos,
        items: [
          CtxItem('열기', () => _openAppById(app.id), icon: Icons.launch),
          if (running)
            CtxItem(
              '닫기',
              () => setState(
                  () => _wins.removeWhere((w) => w.app.id == app.id)),
              icon: Icons.close,
              danger: true,
            ),
        ],
      );
    });
  }

  void _desktopMenu(Offset pos) {
    final sys = context.read<SystemState>();
    setState(() {
      _ctx = (
        pos: pos,
        items: [
          CtxItem('미션 컨트롤', () => setState(() => _mission = true),
              icon: Icons.grid_view_rounded),
          CtxItem('Spotlight 검색', () => setState(() => _spotlight = true),
              icon: Icons.search),
          CtxItem('배경화면 바꾸기', () => _openAppById('settings'),
              icon: Icons.wallpaper),
          CtxItem(sys.isLight ? '다크 모드' : '라이트 모드', sys.toggleTheme,
              icon: Icons.contrast),
        ],
      );
    });
  }

  WinState? get _focused {
    final visible = _wins.where((w) => !w.minimized).toList();
    if (visible.isEmpty) return null;
    visible.sort((a, b) => a.z.compareTo(b.z));
    return visible.last;
  }

  void _openApp(AppDef app) {
    setState(() {
      final existing = _wins.where((w) => w.app.id == app.id).toList();
      if (existing.isNotEmpty) {
        final w = existing.first;
        w.minimized = false;
        w.z = ++_zTop;
        return;
      }
      final n = _wins.length;
      final cx = (_deskSize.width - app.size.width) / 2 + n * 28;
      final cy = (_deskSize.height - app.size.height) / 2 - 20 + n * 24;
      _wins.add(WinState(
        key: ++_keySeq,
        app: app,
        pos: Offset(
          cx.clamp(8, _deskSize.width - 120),
          cy.clamp(44, _deskSize.height - 160),
        ),
        size: app.size,
        z: ++_zTop,
      ));
    });
  }

  void _focus(WinState w) {
    if (_focused == w) return;
    setState(() => w.z = ++_zTop);
  }

  void _close(WinState w) {
    setState(() => w.closing = true);
    Future.delayed(const Duration(milliseconds: 175), () {
      if (mounted) setState(() => _wins.remove(w));
    });
  }

  void _move(WinState w, DragUpdateDetails d) {
    if (w.maximized) return;
    w.dragPointer = d.globalPosition;
    setState(() {
      final nx = (w.pos.dx + d.delta.dx)
          .clamp(-w.size.width + 80.0, _deskSize.width - 80.0);
      final ny = (w.pos.dy + d.delta.dy).clamp(32.0, _deskSize.height - 60.0);
      w.pos = Offset(nx, ny);
    });
  }

  void _resize(WinState w, Offset delta) {
    if (w.maximized) return;
    setState(() {
      final nw = (w.size.width + delta.dx)
          .clamp(240.0, (_deskSize.width - w.pos.dx).clamp(240.0, 4000.0));
      final nh = (w.size.height + delta.dy)
          .clamp(160.0, (_deskSize.height - w.pos.dy).clamp(160.0, 4000.0));
      w.size = Size(nw, nh);
    });
  }

  // 드래그 종료 시 가장자리 스냅 — 커서가 닿은 화면 가장자리로 판정 (macOS식)
  // 상단→최대화, 좌→왼쪽 절반, 우→오른쪽 절반
  void _snap(WinState w) {
    if (w.maximized) return;
    final p = w.dragPointer;
    w.dragPointer = const Offset(-1, -1);
    if (p.dx < 0) return; // 드래그 정보 없음
    final topH = _deskSize.height - 40 - 96;
    if (p.dy <= 38) {
      setState(() {
        w.restorePos = w.pos;
        w.restoreSize = w.size;
        w.maximized = true;
        w.pos = const Offset(8, 40);
        w.size = Size(_deskSize.width - 16, topH);
        w.z = ++_zTop;
      });
    } else if (p.dx <= 12) {
      setState(() {
        w.pos = const Offset(8, 40);
        w.size = Size(_deskSize.width / 2 - 12, topH);
        w.z = ++_zTop;
      });
    } else if (p.dx >= _deskSize.width - 12) {
      setState(() {
        w.pos = Offset(_deskSize.width / 2 + 4, 40);
        w.size = Size(_deskSize.width / 2 - 12, topH);
        w.z = ++_zTop;
      });
    }
  }

  void _toggleMin(WinState w) {
    setState(() => w.minimizing = true);
    Future.delayed(const Duration(milliseconds: 175), () {
      if (mounted) {
        setState(() {
          w.minimized = true;
          w.minimizing = false;
        });
      }
    });
  }

  void _toggleMax(WinState w) {
    setState(() {
      if (w.maximized) {
        w.maximized = false;
        if (w.restorePos != null) w.pos = w.restorePos!;
        if (w.restoreSize != null) w.size = w.restoreSize!;
      } else {
        w.restorePos = w.pos;
        w.restoreSize = w.size;
        w.maximized = true;
        w.pos = const Offset(8, 40);
        w.size = Size(_deskSize.width - 16, _deskSize.height - 40 - 96);
      }
      w.z = ++_zTop;
    });
  }

  Set<String> get _openIds => _wins.map((w) => w.app.id).toSet();

  void _lock() => setState(() => _locked = true);

  void _restore(int key) {
    final w = _wins.firstWhere((x) => x.key == key);
    setState(() {
      w.minimized = false;
      w.z = ++_zTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    if (!_booted) {
      return Scaffold(
        body: BootScreen(onDone: () => setState(() => _booted = true)),
      );
    }
    final robinActions = RobinActions(
      openApp: _openAppById,
      apps: () => kApps.map((a) => AppInfo(a.id, a.name)).toList(),
      setTheme: sys.setLight,
      isLight: () => sys.isLight,
      setWallpaper: sys.setWallpaper,
      setAccent: sys.setAccent,
      setBrightness: sys.setBrightness,
      brightness: () => sys.brightness,
      setVolume: sys.setVolume,
      volume: () => sys.volume,
      lock: _lock,
      closeApp: (id) =>
          setState(() => _wins.removeWhere((w) => w.app.id == id)),
      closeAll: () => setState(() => _wins.clear()),
      reboot: () => platformBackend.reboot(),
      powerOff: () => platformBackend.powerOff(),
      setWifi: (on) => platformBackend.setWifi(on),
      setBluetooth: (on) => platformBackend.setBluetooth(on),
      newNote: _newNote,
      realApps: () =>
          sys.installedApps.map((e) => AppInfo(e.exec, e.name)).toList(),
      launchReal: (exec) => platformBackend.launchApp(exec),
      screenshot: () => platformBackend.screenshot(),
      batteryText: () async {
        final b = await platformBackend.batteryInfo();
        if (b == null) return null;
        return b.charging ? '${b.level}%, 충전 중이에요 ⚡' : '${b.level}%예요 🔋';
      },
    );
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
        builder: (context, constraints) {
          _deskSize = Size(constraints.maxWidth, constraints.maxHeight);
          final visibleWins = _wins.where((w) => !w.minimized).toList()
            ..sort((a, b) => a.z.compareTo(b.z));
          final focused = _focused;
          final hasWindows = visibleWins.isNotEmpty;

          return Stack(
            children: [
              // 배경 (좌클릭=오버레이 닫기, 우클릭=컨텍스트 메뉴)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeOverlays,
                  onSecondaryTapDown: (d) => _desktopMenu(d.globalPosition),
                  child: const _AuroraBackground(),
                ),
              ),
              if (!hasWindows)
                const Positioned(top: 64, left: 40, child: DesktopClock()),
              if (!hasWindows) const _Welcome(),
              for (final w in visibleWins)
                RobinWindow(
                  key: ValueKey(w.key),
                  win: w,
                  focused: w == focused,
                  onFocus: () => _focus(w),
                  onMove: (d) => _move(w, d),
                  onSnap: () => _snap(w),
                  onResize: (d) => _resize(w, d),
                  onClose: () => _close(w),
                  onMinimize: () => _toggleMin(w),
                  onMaximize: () => _toggleMax(w),
                ),
              Align(
                alignment: Alignment.topCenter,
                child: _MenuBar(
                  activeApp: focused?.app.name ?? 'RobinOS',
                  onLogo: () => setState(() => _launchpad = true),
                  onSearch: () => setState(() => _spotlight = true),
                  onMission: () => setState(() => _mission = true),
                  onControl: () => setState(() => _control = true),
                  onNotifCenter: () => setState(() => _notifCenter = true),
                  onCalendar: () => _openAppById('calendar'),
                  notifCount: _notifs.length,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _Dock(
                  openIds: _openIds,
                  onTap: _openApp,
                  robinActive: _robinOpen,
                  onRobinTap: () => setState(() => _robinOpen = !_robinOpen),
                  onLaunchpad: () => setState(() => _launchpad = true),
                  onAppContext: _dockMenu,
                ),
              ),
              if (sys.brightness < 0.999)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: (1 - sys.brightness) * 0.7),
                    ),
                  ),
                ),
              if (_robinOpen)
                Positioned(
                  right: 18,
                  bottom: 96,
                  child: PopIn(
                    from: 0.94,
                    alignment: Alignment.bottomRight,
                    child: RobinPanel(
                      actions: robinActions,
                      onClose: () => setState(() => _robinOpen = false),
                    ),
                  ),
                ),
              // 화면 오버레이
              if (_control)
                ControlCenter(onLock: _lock, onClose: _closeOverlays),
              if (_spotlight)
                Spotlight(onOpen: _openAppById, onClose: _closeOverlays),
              if (_launchpad)
                Launchpad(onOpen: _openAppById, onClose: _closeOverlays),
              if (_mission)
                MissionControl(
                  wins: _wins
                      .map((w) => MissionWin(w.key, w.app, w.app.name))
                      .toList(),
                  onSelect: _restore,
                  onClose: _closeOverlays,
                ),
              Toasts(
                items:
                    _notifs.where((n) => _activeToasts.contains(n.id)).toList(),
                onDismiss: _dismissNotif,
              ),
              if (_notifCenter)
                NotificationCenter(
                  items: _notifs,
                  onClose: () => setState(() => _notifCenter = false),
                  onClearAll: _clearNotifs,
                  onDismiss: _removeNotif,
                ),
              if (_ctx != null)
                ContextMenu(
                  pos: _ctx!.pos,
                  items: _ctx!.items,
                  onClose: () => setState(() => _ctx = null),
                ),
              if (_locked)
                Positioned.fill(child: LockScreen(onUnlock: _unlock)),
            ],
          );
        },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 배경: 그라데이션 + 강조색 블롭 3개 (테마/배경/강조색 반응)
// -----------------------------------------------------------
class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground> {
  // 마우스 위치(중앙 기준 -0.5~0.5). 패럴랙스용 — 움직일 때만 갱신(정지 시 repaint 0).
  // 상시 애니메이션을 피해 softrender(QEMU/저사양)에서도 가볍게.
  Offset _m = Offset.zero;

  void _onHover(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final nx = (local.dx / size.width - 0.5).clamp(-0.5, 0.5);
    final ny = (local.dy / size.height - 0.5).clamp(-0.5, 0.5);
    setState(() => _m = Offset(nx.toDouble(), ny.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    final blob = sys.accent;
    final blob2 = sys.accent2;
    final a = sys.isLight ? 0.30 : 0.34;
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return MouseRegion(
          opaque: false,
          onHover: (e) => _onHover(e.localPosition, size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sys.backgroundGradient,
              ),
            ),
            child: Stack(
              children: [
                // 깊이별 패럴랙스 — 블롭마다 이동량/방향을 달리해 입체감.
                _Blob(
                    top: -120,
                    left: -80,
                    size: 460,
                    offset: _m * 26,
                    color: blob.withValues(alpha: a)),
                _Blob(
                    top: 120,
                    right: -120,
                    size: 520,
                    offset: _m * -34,
                    color: blob2.withValues(alpha: a)),
                _Blob(
                  bottom: -160,
                  left: 160,
                  size: 480,
                  offset: _m * 18,
                  color: sys.accent.withValues(alpha: a * 0.8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;
  final Color color;
  final Offset offset; // 패럴랙스 이동량
  const _Blob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      // 부드럽게 따라오도록 미세 트랜지션(움직임 끝나면 멈춤).
      child: AnimatedSlide(
        offset: offset / size, // AnimatedSlide는 자식 크기 비율 → px를 비율로 환산
        duration: const Duration(milliseconds: 220),
        curve: kRobinEase,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 가운데 환영 — R 스퀘어클 (강조색)
// -----------------------------------------------------------
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [sys.accent, sys.accent2],
              ),
              boxShadow: [
                BoxShadow(
                  color: sys.accent.withValues(alpha: 0.45),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'R',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'RobinOS',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: sys.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '독에서 앱을 열어보세요',
            style: TextStyle(fontSize: 15, color: sys.textSec(0.5)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 상단 메뉴바
// -----------------------------------------------------------
class _MenuBar extends StatelessWidget {
  final String activeApp;
  final VoidCallback onLogo, onSearch, onMission, onControl, onNotifCenter;
  final VoidCallback onCalendar;
  final int notifCount;
  const _MenuBar({
    required this.activeApp,
    required this.onLogo,
    required this.onSearch,
    required this.onMission,
    required this.onControl,
    required this.onNotifCenter,
    required this.onCalendar,
    required this.notifCount,
  });

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: sys.chromeOverlay,
            border: Border(bottom: BorderSide(color: sys.chromeBorder)),
          ),
          child: Row(
            children: [
              // R 로고 → 런치패드
              _hover(
                onTap: onLogo,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
                  ),
                  alignment: Alignment.center,
                  child: const Text('R',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1)),
                ),
              ),
              const SizedBox(width: 12),
              Text(activeApp,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sys.textPrimary)),
              const SizedBox(width: 18),
              ..._menus.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(m,
                      style:
                          TextStyle(fontSize: 13, color: sys.textSec(0.75))),
                ),
              ),
              const Spacer(),
              // 우측: Spotlight · 미션컨트롤 · 제어센터 · 시계
              _icon(sys, Icons.grid_view_rounded, onMission),
              _icon(sys, Icons.search, onSearch),
              _hover(
                onTap: onControl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const WifiIndicator(),
                      const SizedBox(width: 6),
                      const BatteryIndicator(),
                    ],
                  ),
                ),
              ),
              // 알림 센터 종 아이콘 (누적 알림 있으면 점 배지)
              _hover(
                onTap: onNotifCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 16, color: sys.textSec(0.8)),
                      if (notifCount > 0)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: sys.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _hover(
                onTap: onCalendar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: LiveClock(
                    format: (t) => '${robinDate(t)}  ${robinTime(t)}',
                    style: TextStyle(fontSize: 12.5, color: sys.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(SystemState sys, IconData icon, VoidCallback onTap) => _hover(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, size: 16, color: sys.textSec(0.8)),
        ),
      );

  Widget _hover({required Widget child, required VoidCallback onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );

  static const _menus = ['파일', '편집', '보기', '윈도우'];
}

// ===========================================================
// RobinWindow — 창 1개 (신호등 + 드래그 + 포커스)
// ===========================================================
class RobinWindow extends StatelessWidget {
  final WinState win;
  final bool focused;
  final VoidCallback onFocus;
  final ValueChanged<DragUpdateDetails> onMove;
  final VoidCallback onSnap;
  final ValueChanged<Offset> onResize;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;

  const RobinWindow({
    super.key,
    required this.win,
    required this.focused,
    required this.onFocus,
    required this.onMove,
    required this.onSnap,
    required this.onResize,
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
  });

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Positioned(
      left: win.pos.dx,
      top: win.pos.dy,
      width: win.size.width,
      height: win.size.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
            begin: 0.0, end: (win.closing || win.minimizing) ? 0.0 : 1.0),
        duration: const Duration(milliseconds: 210),
        // RobinOS 시그니처 팝(살짝 튕기며 열림). 닫힘은 앞쪽으로 빠르게 사라져 자연스러움.
        curve: kRobinPop,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
        ),
        child: Listener(
        onPointerDown: (_) => onFocus(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
          decoration: BoxDecoration(
            color: sys.windowSurface.withValues(alpha: sys.isLight ? 0.96 : 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused
                  ? sys.accent.withValues(alpha: sys.isLight ? 0.4 : 0.45)
                  : sys.windowBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: focused ? 0.45 : 0.25),
                blurRadius: focused ? 40 : 20,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) => onMove(d),
                  onPanEnd: (_) => onSnap(),
                  onDoubleTap: onMaximize,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sys.titlebarOverlay,
                      border: Border(
                        bottom: BorderSide(color: sys.chromeBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TrafficLights(
                          onClose: onClose,
                          onMin: onMinimize,
                          onMax: onMaximize,
                        ),
                        Expanded(
                          child: Text(
                            win.app.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sys.textSec(focused ? 0.9 : 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 54),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _AppContent(app: win.app)),
              ],
            ),
          ),
        ),
            ),
            if (!win.maximized) ..._resizeHandles(),
          ],
        ),
      ),
      ),
    );
  }

  // 창 가장자리/모서리 리사이즈 핸들 (최대화 상태가 아닐 때만)
  List<Widget> _resizeHandles() {
    return [
      Positioned(
        top: 8,
        bottom: 14,
        right: 0,
        width: 6,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => onResize(Offset(d.delta.dx, 0)),
          ),
        ),
      ),
      Positioned(
        left: 8,
        right: 14,
        bottom: 0,
        height: 6,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => onResize(Offset(0, d.delta.dy)),
          ),
        ),
      ),
      Positioned(
        right: 0,
        bottom: 0,
        width: 18,
        height: 18,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => onResize(d.delta),
          ),
        ),
      ),
    ];
  }
}

class _TrafficLights extends StatefulWidget {
  final VoidCallback onClose, onMin, onMax;
  const _TrafficLights({
    required this.onClose,
    required this.onMin,
    required this.onMax,
  });

  @override
  State<_TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<_TrafficLights> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _light(const Color(0xFFFF5F57), '×', widget.onClose),
          const SizedBox(width: 8),
          _light(const Color(0xFFFEBC2E), '–', widget.onMin),
          const SizedBox(width: 8),
          _light(const Color(0xFF28C840), '+', widget.onMax),
        ],
      ),
    );
  }

  Widget _light(Color color, String glyph, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: _hover
            ? Text(
                glyph,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0x99000000),
                ),
              )
            : null,
      ),
    );
  }
}

// 앱 내용 — 설정은 실제 앱, 나머지는 플레이스홀더
class _AppContent extends StatelessWidget {
  final AppDef app;
  const _AppContent({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.id == 'settings') return const SettingsApp();
    if (app.id == 'software') return const SoftwareApp();
    if (app.id == 'monitor') return const SystemMonitorApp();
    if (app.id == 'calendar') return const CalendarApp();
    if (app.id == 'music') return const MusicApp();
    if (app.id == 'gallery') return const GalleryApp();
    if (app.id == 'calc') return const CalculatorApp();
    if (app.id == 'notes') return const NotesApp();
    if (app.id == 'finder') return const FinderApp();
    if (app.id == 'terminal') return const TerminalApp();
    if (app.id == 'paint') return const PaintApp();
    final sys = context.watch<SystemState>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [app.color, Color.lerp(app.color, Colors.black, 0.25)!],
              ),
            ),
            alignment: Alignment.center,
            child: Text(app.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 16),
          Text(
            app.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: sys.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text('곧 만들 앱이에요', style: TextStyle(fontSize: 13, color: sys.textSec(0.45))),
        ],
      ),
    );
  }
}

// ===========================================================
// Robin 패널 — 채팅 UI (웹 components/Robin.tsx 대응)
// ===========================================================
class _Msg {
  final String text;
  final bool fromUser;
  final RobinConfirm? confirm;
  const _Msg(this.text, this.fromUser, {this.confirm});
}

class RobinPanel extends StatefulWidget {
  final RobinActions actions;
  final VoidCallback onClose;
  const RobinPanel({super.key, required this.actions, required this.onClose});

  @override
  State<RobinPanel> createState() => _RobinPanelState();
}

class _RobinPanelState extends State<RobinPanel> {
  final List<_Msg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  static const _greeting = _Msg(
      '안녕하세요! 저는 Robin이에요. "도움말"이라고 하거나 바로 명령해보세요 🪐', false);

  @override
  void initState() {
    super.initState();
    _msgs.add(_greeting);
    _loadChat();
  }

  // 저장된 대화 복원 (없으면 인사만)
  Future<void> _loadChat() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('robinos.robin.chat');
    if (raw == null || !mounted) return;
    try {
      final list = jsonDecode(raw) as List;
      if (list.isNotEmpty) {
        setState(() {
          _msgs.clear();
          for (final m in list) {
            _msgs.add(_Msg(m['t'] as String, m['u'] as bool));
          }
        });
        _scrollDown();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('robinos.robin.chat',
        jsonEncode(_msgs.map((m) => {'t': m.text, 'u': m.fromUser}).toList()));
  }

  void _clearChat() {
    setState(() {
      _msgs
        ..clear()
        ..add(_greeting);
    });
    _persist();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _msgs.add(_Msg(text, true));
      _ctrl.clear();
      _loading = true;
    });
    _scrollDown();
    final res = await runRobin(text, widget.actions);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _msgs.add(_Msg(res.reply, false, confirm: res.confirm));
    });
    _scrollDown();
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(
          scale: 0.85 + 0.15 * t.clamp(0, 1),
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
      child: Container(
        width: 344,
        height: 470,
        decoration: BoxDecoration(
          color: sys.windowSurface.withValues(alpha: sys.isLight ? 0.98 : 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sys.windowBorder),
          boxShadow: [
            BoxShadow(
              color: sys.accent.withValues(alpha: 0.28),
              blurRadius: 44,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _header(sys),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  itemCount: _msgs.length + (_loading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _msgs.length) return _thinking(sys);
                    return _bubble(sys, _msgs[i]);
                  },
                ),
              ),
              _inputBar(sys),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(SystemState sys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
      ),
      child: Row(
        children: [
          _orb(20),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Robin',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1)),
              Text('개인 에이전트',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _clearChat,
            child: const Icon(Icons.delete_sweep_outlined,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size) {
    final sys = context.read<SystemState>();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [sys.accent2, sys.accent]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      alignment: Alignment.center,
      child: Text('R',
          style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1)),
    );
  }

  Widget _bubble(SystemState sys, _Msg m) {
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sys.accent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(m.text,
              style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.35)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orb(24),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sys.textSec(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(m.text,
                      style: TextStyle(
                          fontSize: 13.5, color: sys.textPrimary, height: 1.4)),
                ),
                if (m.confirm != null) _confirmRow(sys, m.confirm!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(SystemState sys, RobinConfirm c) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              c.run();
              setState(() => _msgs.add(_Msg('네, 실행했어요!', false)));
              _scrollDown();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                  color: sys.accent, borderRadius: BorderRadius.circular(9)),
              child: Text(c.text,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _msgs.add(const _Msg('취소했어요.', false)));
              _scrollDown();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: sys.textSec(0.25)),
              ),
              child: Text('취소',
                  style: TextStyle(fontSize: 12.5, color: sys.textSec(0.8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thinking(SystemState sys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _orb(24),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sys.textSec(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('• • •',
                style: TextStyle(fontSize: 14, color: sys.textSec(0.5), height: 1)),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(SystemState sys) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sys.chromeBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              style: TextStyle(fontSize: 13.5, color: sys.textPrimary),
              decoration: InputDecoration(
                hintText: 'Robin에게 말하기…',
                hintStyle: TextStyle(fontSize: 13.5, color: sys.textSec(0.4)),
                isDense: true,
                filled: true,
                fillColor: sys.textSec(0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [sys.accent, sys.accent2]),
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// 하단 독
// ===========================================================
class _Dock extends StatefulWidget {
  final Set<String> openIds;
  final ValueChanged<AppDef> onTap;
  final bool robinActive;
  final VoidCallback onRobinTap;
  final VoidCallback onLaunchpad;
  final void Function(AppDef, Offset) onAppContext;
  const _Dock({
    required this.openIds,
    required this.onTap,
    required this.robinActive,
    required this.onRobinTap,
    required this.onLaunchpad,
    required this.onAppContext,
  });

  @override
  State<_Dock> createState() => _DockState();
}

class _DockState extends State<_Dock> {
  int? _hovered; // 마우스가 올라간 앱 아이콘 인덱스

  double _scaleFor(int i) {
    if (_hovered == null) return 1.0;
    final d = (i - _hovered!).abs();
    // 가우시안 감쇠 — 계단식 대신 부드러운 확대 웨이브(맥OS 독 느낌).
    const peak = 0.36; // 최대 추가 배율(중심 1.36x)
    const sigma = 1.4; // 확산(이웃까지 자연스럽게 번짐)
    return 1.0 + peak * math.exp(-(d * d) / (2 * sigma * sigma));
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sys.dockOverlay,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sys.dockBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 런치패드
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onLaunchpad,
                    child: Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF5A5A66), Color(0xFF34343C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.grid_view_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: sys.textSec(0.15),
                ),
                for (int i = 0; i < kApps.length; i++)
                  _DockIcon(
                    app: kApps[i],
                    running: widget.openIds.contains(kApps[i].id),
                    dotColor: sys.textSec(0.85),
                    scale: _scaleFor(i),
                    onHover: (h) => setState(() {
                      if (h) {
                        _hovered = i;
                      } else if (_hovered == i) {
                        _hovered = null;
                      }
                    }),
                    onTap: () => widget.onTap(kApps[i]),
                    onContext: (pos) => widget.onAppContext(kApps[i], pos),
                  ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: sys.textSec(0.15),
                ),
                // Robin 오브 (강조색) — 클릭하면 채팅 패널
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onRobinTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [sys.accent, sys.accent2],
                        ),
                        border: widget.robinActive
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 2.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: sys.accent.withValues(
                                alpha: widget.robinActive ? 0.85 : 0.5),
                            blurRadius: widget.robinActive ? 28 : 20,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'R',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final AppDef app;
  final bool running;
  final Color dotColor;
  final double scale;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final void Function(Offset)? onContext;
  const _DockIcon({
    required this.app,
    required this.running,
    required this.dotColor,
    required this.scale,
    required this.onHover,
    required this.onTap,
    this.onContext,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown:
            onContext == null ? null : (d) => onContext!(d.globalPosition),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: RobinAppIcon(glyph: app.glyph, color: app.color, size: 52),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: running ? dotColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
