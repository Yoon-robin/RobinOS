import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/system_state.dart';
import '../system/platform_backend.dart';
import '../robin/brains.dart';
import '../widgets/anim.dart';

// ===========================================================
// 설정 앱 — 테마 · 배경화면 · 강조색 · 밝기 · Robin 두뇌
// ===========================================================
class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(sys, '테마'),
          const SizedBox(height: 10),
          Row(
            children: [
              _segBtn(sys, '🌙 다크', sys.themeMode == 'dark',
                  () => sys.setThemeMode('dark')),
              const SizedBox(width: 8),
              _segBtn(sys, '☀️ 라이트', sys.themeMode == 'light',
                  () => sys.setThemeMode('light')),
              const SizedBox(width: 8),
              _segBtn(sys, '🕐 자동', sys.themeMode == 'auto',
                  () => sys.setThemeMode('auto')),
            ],
          ),
          const SizedBox(height: 26),
          _section(sys, '배경화면'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final w in kWallpapers) _wallTile(sys, w, w.id == sys.wallpaperId),
            ],
          ),
          const SizedBox(height: 26),
          _section(sys, '강조색'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final a in kAccents)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _accentDot(sys, a, a.id == sys.accentId),
                ),
            ],
          ),
          const SizedBox(height: 26),
          _section(sys, '밝기'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('🔅', style: TextStyle(color: sys.textSec(0.6))),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: sys.accent,
                    thumbColor: sys.accent,
                    inactiveTrackColor: sys.textSec(0.15),
                    overlayColor: sys.accent.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: sys.brightness,
                    min: 0.25,
                    max: 1.0,
                    onChanged: sys.setBrightness,
                  ),
                ),
              ),
              Text('🔆', style: TextStyle(color: sys.textSec(0.6))),
            ],
          ),
          const SizedBox(height: 26),
          _section(sys, '볼륨'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('🔈', style: TextStyle(color: sys.textSec(0.6))),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: sys.accent,
                    thumbColor: sys.accent,
                    inactiveTrackColor: sys.textSec(0.15),
                    overlayColor: sys.accent.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: sys.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: sys.setVolume,
                  ),
                ),
              ),
              Text('🔊', style: TextStyle(color: sys.textSec(0.6))),
            ],
          ),
          const SizedBox(height: 26),
          _section(sys, '네트워크'),
          const SizedBox(height: 10),
          const _WifiSettings(),
          const SizedBox(height: 26),
          _section(sys, '블루투스'),
          const SizedBox(height: 10),
          const _BtSettings(),
          const SizedBox(height: 26),
          _section(sys, 'Robin 두뇌'),
          const SizedBox(height: 10),
          const _BrainSettings(),
          const SizedBox(height: 26),
          _section(sys, '시스템'),
          const SizedBox(height: 10),
          _infoRow(sys, 'RobinOS', '네이티브 빌드 · Flutter'),
          _infoRow(
            sys,
            '하드웨어 제어',
            platformBackend.isReal
                ? '활성 — 리눅스에서 밝기·볼륨·전원·Wi-Fi 실제 제어'
                : '시뮬레이션 — 웹/개발 모드 (실기기 부팅 시 활성화)',
          ),
          // 리눅스 실기기(라이브 부팅)에서만 디스크 설치 진입점 노출.
          if (platformBackend.isReal) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => platformBackend.runInstaller(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: sys.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sys.accent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.install_desktop, size: 18, color: sys.accent),
                    const SizedBox(width: 10),
                    Text('RobinOS 디스크에 설치',
                        style: TextStyle(
                            fontSize: 13.5,
                            color: sys.accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text('파티션·유저 설정 후 디스크에 설치합니다 (Calamares 설치기).',
                style: TextStyle(fontSize: 11, color: sys.textSec(0.4))),
          ],
        ],
      ),
    );
  }

  Widget _section(SystemState sys, String t) => Text(
        t,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: sys.textSec(0.5),
        ),
      );

  Widget _infoRow(SystemState sys, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(fontSize: 12.5, color: sys.textSec(0.55))),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12.5, color: sys.textPrimary, height: 1.4)),
            ),
          ],
        ),
      );

  Widget _segBtn(SystemState sys, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? sys.accent : sys.textSec(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? sys.accent : sys.textSec(0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : sys.textSec(0.8),
          ),
        ),
      ),
    );
  }

  Widget _wallTile(SystemState sys, Wallpaper w, bool active) {
    return GestureDetector(
      onTap: () => sys.setWallpaper(w.id),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: w.colors,
              ),
              border: Border.all(
                color: active ? sys.accent : sys.textSec(0.12),
                width: active ? 2.5 : 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            w.name,
            style: TextStyle(
              fontSize: 11,
              color: active ? sys.textPrimary : sys.textSec(0.55),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentDot(SystemState sys, Accent a, bool active) {
    return GestureDetector(
      onTap: () => sys.setAccent(a.id),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: a.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? sys.textPrimary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: a.color.withValues(alpha: 0.5), blurRadius: 10)]
              : null,
        ),
        child: active ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}

// -----------------------------------------------------------
// Robin 두뇌 선택 — 로컬 / 내장 모델(Ollama·Qwen2.5) / DeepSeek
// -----------------------------------------------------------
class _BrainSettings extends StatefulWidget {
  const _BrainSettings();

  @override
  State<_BrainSettings> createState() => _BrainSettingsState();
}

class _BrainSettingsState extends State<_BrainSettings> {
  String _choice = 'local';
  final _ollamaUrl = TextEditingController();
  final _ollamaModel = TextEditingController();
  final _dsKey = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _choice = p.getString('robinos.brain') ?? 'local';
      _ollamaUrl.text = p.getString('robinos.ollama.url') ?? kOllamaDefaultUrl;
      _ollamaModel.text = p.getString('robinos.ollama.model') ?? kOllamaDefaultModel;
      _dsKey.text = p.getString('robinos.deepseek.key') ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _ollamaUrl.dispose();
    _ollamaModel.dispose();
    _dsKey.dispose();
    super.dispose();
  }

  Future<void> _pick(String c) async {
    setState(() => _choice = c);
    await setBrainChoice(c);
  }

  Future<void> _save(String key, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    if (!_loaded) {
      return SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('불러오는 중…', style: TextStyle(color: sys.textSec(0.4), fontSize: 12)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _opt(sys, 'local', '💬 로컬', '오프라인 기본'),
            _opt(sys, 'ollama', '🧠 내장 (Qwen2.5)', 'Ollama · 온디바이스'),
            _opt(sys, 'deepseek', '☁️ DeepSeek', '클라우드'),
          ],
        ),
        const SizedBox(height: 12),
        if (_choice == 'ollama') ...[
          _field(sys, 'Ollama 주소', _ollamaUrl, 'robinos.ollama.url'),
          const SizedBox(height: 8),
          _field(sys, '모델', _ollamaModel, 'robinos.ollama.model'),
          const SizedBox(height: 10),
          Text('프리셋 (탭하면 적용 · 직접 입력도 가능)',
              style: TextStyle(fontSize: 11, color: sys.textSec(0.5))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in kModelPresets) _presetChip(sys, p.$1, p.$2),
            ],
          ),
          const SizedBox(height: 10),
          _hint(sys,
              '원하는 모델을 골라 쓰세요. 직접 입력도 되고, 허깅페이스 GGUF도 Ollama로 불러올 수 있어요. 기본값은 huihui의 abliterated(거부 없음) 모델이에요. 받으려면:  ollama run <모델>'),
        ] else if (_choice == 'deepseek') ...[
          _field(sys, 'API 키', _dsKey, 'robinos.deepseek.key', obscure: true),
          const SizedBox(height: 8),
          _hint(sys, '클라우드 모델이라 대화 내용이 DeepSeek 서버로 전송돼요. 프라이버시가 중요하면 내장(Ollama)을 권해요.'),
        ] else
          _hint(sys, '키 없이 바로 쓰는 규칙 기반 두뇌예요. 테마·앱·계산 등 기본 명령을 알아들어요.'),
      ],
    );
  }

  Widget _opt(SystemState sys, String id, String title, String sub) {
    final active = _choice == id;
    return GestureDetector(
      onTap: () => _pick(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 168,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? sys.accent.withValues(alpha: 0.16) : sys.textSec(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? sys.accent : sys.textSec(0.12),
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sys.textPrimary)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 11, color: sys.textSec(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _field(SystemState sys, String label, TextEditingController c, String key,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: sys.textSec(0.5))),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          obscureText: obscure,
          onChanged: (v) => _save(key, v),
          style: TextStyle(fontSize: 13, color: sys.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: sys.textSec(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _hint(SystemState sys, String text) => Text(
        text,
        style: TextStyle(fontSize: 11.5, color: sys.textSec(0.45), height: 1.4),
      );

  Widget _presetChip(SystemState sys, String model, String desc) {
    final active = _ollamaModel.text == model;
    return GestureDetector(
      onTap: () {
        setState(() => _ollamaModel.text = model);
        _save('robinos.ollama.model', model);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? sys.accent.withValues(alpha: 0.16) : sys.textSec(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? sys.accent : sys.textSec(0.12),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(model,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: sys.textPrimary)),
            const SizedBox(height: 1),
            Text(desc, style: TextStyle(fontSize: 10, color: sys.textSec(0.5))),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 네트워크 — 주변 Wi-Fi 검색 + 연결 (리눅스: nmcli). 암호는 사용자가 직접 입력.
// 웹/개발 모드에선 안내만 표시(스캔 결과가 비어 있음).
// -----------------------------------------------------------
class _WifiSettings extends StatefulWidget {
  const _WifiSettings();

  @override
  State<_WifiSettings> createState() => _WifiSettingsState();
}

class _WifiSettingsState extends State<_WifiSettings> {
  bool _scanning = false;
  bool _connecting = false;
  List<WifiNetwork> _nets = const [];
  String? _expanded; // 암호 입력칸을 펼친 SSID
  String? _status; // 연결 결과 안내
  final _pw = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (platformBackend.isReal) _scan();
  }

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _status = null;
    });
    final nets = await platformBackend.scanWifi();
    if (!mounted) return;
    setState(() {
      _nets = nets;
      _scanning = false;
    });
  }

  Future<void> _connect(WifiNetwork n, String password) async {
    setState(() {
      _connecting = true;
      _status = null;
    });
    final ok = await platformBackend.connectWifi(n.ssid, password);
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _status = ok
          ? '${n.ssid}에 연결됐어요.'
          : '${n.ssid} 연결에 실패했어요. 암호를 확인해 주세요.';
      if (ok) {
        _expanded = null;
        _pw.clear();
      }
    });
    if (ok) _scan(); // 연결됨 표시 갱신
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    if (!platformBackend.isReal) {
      return _hintBox(sys,
          '리눅스 실기기로 부팅하면 주변 Wi-Fi를 검색해 연결할 수 있어요. (지금은 웹/개발 모드)');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_scanning ? '검색 중…' : '주변 네트워크 ${_nets.length}개',
                style: TextStyle(fontSize: 12, color: sys.textSec(0.6))),
            const Spacer(),
            GestureDetector(
              onTap: _scanning ? null : _scan,
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 15, color: sys.accent),
                  const SizedBox(width: 4),
                  Text('다시 검색',
                      style: TextStyle(fontSize: 12, color: sys.accent)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_nets.isEmpty && !_scanning)
          _hintBox(sys, '검색된 네트워크가 없어요. Wi-Fi가 켜져 있는지 확인하고 다시 검색해 주세요.')
        else
          for (var i = 0; i < _nets.length; i++)
            StaggerIn(index: i, child: _row(sys, _nets[i])),
        if (_status != null) ...[
          const SizedBox(height: 6),
          Text(_status!,
              style: TextStyle(fontSize: 11.5, color: sys.textSec(0.6))),
        ],
      ],
    );
  }

  Widget _row(SystemState sys, WifiNetwork n) {
    final isExpanded = _expanded == n.ssid;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:
            n.active ? sys.accent.withValues(alpha: 0.14) : sys.textSec(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: n.active
                ? sys.accent.withValues(alpha: 0.5)
                : sys.textSec(0.1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (n.active) return;
              if (n.secured) {
                setState(() {
                  _expanded = isExpanded ? null : n.ssid;
                  _pw.clear();
                  _status = null;
                });
              } else {
                _connect(n, '');
              }
            },
            child: Row(
              children: [
                Icon(_wifiIcon(n.signal), size: 18, color: sys.textPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(n.ssid,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: sys.textPrimary,
                          fontWeight:
                              n.active ? FontWeight.w600 : FontWeight.w400)),
                ),
                if (n.secured)
                  Icon(Icons.lock, size: 13, color: sys.textSec(0.45)),
                if (n.active) ...[
                  const SizedBox(width: 6),
                  Text('연결됨',
                      style: TextStyle(
                          fontSize: 11,
                          color: sys.accent,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pw,
                    obscureText: true,
                    autofocus: true,
                    style: TextStyle(fontSize: 13, color: sys.textPrimary),
                    onSubmitted: (v) => _connect(n, v),
                    decoration: InputDecoration(
                      hintText: '암호',
                      hintStyle:
                          TextStyle(color: sys.textSec(0.4), fontSize: 13),
                      isDense: true,
                      filled: true,
                      fillColor: sys.textSec(0.08),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _connecting ? null : () => _connect(n, _pw.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: sys.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _connecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('연결',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _hintBox(SystemState sys, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sys.textSec(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style:
                TextStyle(fontSize: 12, color: sys.textSec(0.55), height: 1.4)),
      );

  IconData _wifiIcon(int signal) {
    if (signal >= 67) return Icons.wifi;
    if (signal >= 34) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }
}

// -----------------------------------------------------------
// 블루투스 — 주변 기기 검색 + 연결/해제 (리눅스: bluetoothctl).
// just-works 페어링만 자동(PIN 방식은 실패할 수 있음). 웹/개발 모드는 안내만.
// -----------------------------------------------------------
class _BtSettings extends StatefulWidget {
  const _BtSettings();

  @override
  State<_BtSettings> createState() => _BtSettingsState();
}

class _BtSettingsState extends State<_BtSettings> {
  bool _scanning = false;
  bool _busy = false;
  List<BtDevice> _devs = const [];
  String? _status;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _status = null;
    });
    final d = await platformBackend.scanBluetooth();
    if (!mounted) return;
    setState(() {
      _devs = d;
      _scanning = false;
    });
  }

  Future<void> _toggle(BtDevice d) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    String msg;
    if (d.connected) {
      await platformBackend.disconnectBluetooth(d.mac);
      msg = '${d.name} 연결을 끊었어요.';
    } else {
      final ok = await platformBackend.connectBluetooth(d.mac);
      msg = ok
          ? '${d.name}에 연결됐어요.'
          : '${d.name} 연결에 실패했어요(페어링이 필요하거나 PIN 방식일 수 있어요).';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = msg;
    });
    _scan();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.watch<SystemState>();
    if (!platformBackend.isReal) {
      return _hintBox(sys,
          '리눅스 실기기에서 블루투스 기기를 검색·연결할 수 있어요. (지금은 웹/개발 모드)');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_scanning ? '검색 중… (약 6초)' : '기기 ${_devs.length}개',
                style: TextStyle(fontSize: 12, color: sys.textSec(0.6))),
            const Spacer(),
            GestureDetector(
              onTap: _scanning ? null : _scan,
              child: Row(
                children: [
                  Icon(Icons.bluetooth_searching, size: 15, color: sys.accent),
                  const SizedBox(width: 4),
                  Text('검색',
                      style: TextStyle(fontSize: 12, color: sys.accent)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_devs.isEmpty && !_scanning)
          _hintBox(sys, '검색을 눌러 주변 블루투스 기기를 찾아보세요. (블루투스가 켜져 있어야 해요)')
        else
          for (var i = 0; i < _devs.length; i++)
            StaggerIn(index: i, child: _row(sys, _devs[i])),
        if (_status != null) ...[
          const SizedBox(height: 6),
          Text(_status!,
              style: TextStyle(fontSize: 11.5, color: sys.textSec(0.6))),
        ],
      ],
    );
  }

  Widget _row(SystemState sys, BtDevice d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:
            d.connected ? sys.accent.withValues(alpha: 0.14) : sys.textSec(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: d.connected
                ? sys.accent.withValues(alpha: 0.5)
                : sys.textSec(0.1)),
      ),
      child: Row(
        children: [
          Icon(d.connected ? Icons.bluetooth_connected : Icons.bluetooth,
              size: 18, color: sys.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(d.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5,
                    color: sys.textPrimary,
                    fontWeight:
                        d.connected ? FontWeight.w600 : FontWeight.w400)),
          ),
          if (d.connected)
            Text('연결됨',
                style: TextStyle(
                    fontSize: 11,
                    color: sys.accent,
                    fontWeight: FontWeight.w600))
          else if (d.paired)
            Text('페어링됨', style: TextStyle(fontSize: 11, color: sys.textSec(0.45))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _busy ? null : () => _toggle(d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: d.connected ? sys.textSec(0.1) : sys.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(d.connected ? '해제' : '연결',
                  style: TextStyle(
                      fontSize: 12,
                      color: d.connected ? sys.textPrimary : Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintBox(SystemState sys, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sys.textSec(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style:
                TextStyle(fontSize: 12, color: sys.textSec(0.55), height: 1.4)),
      );
}
