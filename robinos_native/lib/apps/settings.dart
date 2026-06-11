import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/system_state.dart';
import '../robin/brains.dart';

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
          _section(sys, 'Robin 두뇌'),
          const SizedBox(height: 10),
          const _BrainSettings(),
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
