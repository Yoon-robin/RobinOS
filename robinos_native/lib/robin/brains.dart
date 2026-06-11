import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'robin.dart';

// ===========================================================
// Robin 두뇌 (LLM) — 교체식. 웹 robin-deepseek.ts 대응 + 로컬 모델 추가.
//
// 셋 다 OpenAI 호환 → 한 함수(_chat)로 묶음:
//   • 로컬 파서  : robin.dart 의 localBrain (오프라인 기본)
//   • 내장 모델  : Ollama (Qwen2.5) — http://localhost:11434/v1 (온디바이스/프라이빗)
//   • 클라우드   : DeepSeek — https://api.deepseek.com
//
// ⚠️ 브라우저(웹) 미리보기에선 CORS로 막힐 수 있음 — 네이티브/리눅스 빌드에선 OK.
// 시스템 프롬프트는 앱 목록에서 자동 생성 → 새 앱 추가 시 Robin이 즉시 인지.
// ===========================================================

const _kBrain = 'robinos.brain'; // local | ollama | deepseek
const _kOllamaUrl = 'robinos.ollama.url';
const _kOllamaModel = 'robinos.ollama.model';
const _kDeepseekKey = 'robinos.deepseek.key';

const kOllamaDefaultUrl = 'http://localhost:11434/v1';
// 기본 내장 모델 = abliterated(거부 제거) → Robin이 "못 합니다" 안 함.
const kOllamaDefaultModel = 'huihui_ai/qwen2.5-abliterate:7b';

// 모델 프리셋 — 사용자가 탭으로 고르거나, 칸에 직접 아무 모델이나 입력 가능.
const kModelPresets = <(String, String)>[
  ('huihui_ai/qwen2.5-abliterate:7b', '검열 해제 · 균형 4.7GB'),
  ('huihui_ai/qwen2.5-abliterate:3b', '검열 해제 · 가벼움 1.9GB'),
  ('huihui_ai/qwen2.5-abliterate:0.5b', '검열 해제 · 초경량 398MB'),
  ('qwen2.5', '일반 Qwen2.5 · 4.7GB'),
  ('llama3.2', '일반 Llama 3.2 · 2GB'),
];

String _systemPrompt(RobinActions a) {
  final apps = a.apps().map((x) => '${x.id}(${x.name})').join(', ');
  return '''너는 Robin, RobinOS를 직접 제어하는 개인 에이전트야. 한국어로 짧고 친근하게 답해.
"저는 할 수 없습니다" 같은 말은 절대 하지 마 — 아래 action으로 직접 해내.
반드시 JSON "한 줄"로만 답해:
{"action":"<이름 또는 null>","arg":"<값>","reply":"<한국어 답변>"}

사용 가능한 action:
- openApp (arg = 앱 id) — 설치된 앱: $apps
- setTheme (arg = "dark" | "light")
- setWallpaper (arg = aurora|midnight|sunset|ocean|sakura|graphite)
- setAccent (arg = blue|purple|pink|teal|orange|green)
- setBrightness (arg = 0~100 정수, 퍼센트)
- calculate (arg = 수식; 결과는 네가 직접 계산해서 reply에 적어줘)
동작이 필요 없으면 {"action":null,"reply":"<답변>"}.''';
}

RobinResult _apply(String content, RobinActions a) {
  final m = RegExp(r'\{[\s\S]*\}').firstMatch(content);
  if (m == null) {
    final t = content.trim();
    return RobinResult(t.isEmpty ? '음, 잘 모르겠어요.' : t);
  }
  try {
    final o = jsonDecode(m.group(0)!) as Map<String, dynamic>;
    final reply = (o['reply'] ?? '네!').toString();
    final action = o['action']?.toString();
    final arg = (o['arg'] ?? '').toString();
    switch (action) {
      case 'openApp':
        a.openApp(arg);
        break;
      case 'setTheme':
        a.setTheme(arg == 'light');
        break;
      case 'setWallpaper':
        a.setWallpaper(arg);
        break;
      case 'setAccent':
        a.setAccent(arg);
        break;
      case 'setBrightness':
        final n = double.tryParse(arg);
        if (n != null) a.setBrightness((n / 100).clamp(0.25, 1.0));
        break;
    }
    return RobinResult(reply);
  } catch (_) {
    return RobinResult(content.trim());
  }
}

Future<RobinResult> _chat({
  required String baseUrl,
  required String model,
  String? apiKey,
  required String msg,
  required RobinActions a,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            if (apiKey != null && apiKey.isNotEmpty)
              'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.4,
            'stream': false,
            'messages': [
              {'role': 'system', 'content': _systemPrompt(a)},
              {'role': 'user', 'content': msg},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      return RobinResult('모델이 오류를 냈어요 (${res.statusCode}). 주소·모델·키를 확인해 주세요.');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    final content = (choices != null && choices.isNotEmpty
            ? (choices[0]['message']?['content'] ?? '')
            : '')
        .toString();
    return _apply(content, a);
  } catch (_) {
    return const RobinResult(
        '모델 서버에 연결하지 못했어요. (Ollama 실행 여부 / 주소 / 키를 확인해 주세요)');
  }
}

// 내장 모델 (Ollama · Qwen2.5)
Future<RobinResult> ollamaBrain(String msg, RobinActions a) async {
  final p = await SharedPreferences.getInstance();
  return _chat(
    baseUrl: p.getString(_kOllamaUrl) ?? kOllamaDefaultUrl,
    model: p.getString(_kOllamaModel) ?? kOllamaDefaultModel,
    msg: msg,
    a: a,
  );
}

// 클라우드 (DeepSeek)
Future<RobinResult> deepseekBrain(String msg, RobinActions a) async {
  final p = await SharedPreferences.getInstance();
  final key = p.getString(_kDeepseekKey) ?? '';
  if (key.isEmpty) {
    return const RobinResult('DeepSeek API 키가 아직 없어요. 설정에서 키를 입력하면 제가 더 똑똑해져요!');
  }
  return _chat(
    baseUrl: 'https://api.deepseek.com',
    model: 'deepseek-chat',
    apiKey: key,
    msg: msg,
    a: a,
  );
}

// 저장된 두뇌 선택 적용 (부팅 시 + 설정 변경 시)
Future<void> applySavedBrain() async {
  final p = await SharedPreferences.getInstance();
  switch (p.getString(_kBrain)) {
    case 'ollama':
      setRobinBrain(ollamaBrain);
      break;
    case 'deepseek':
      setRobinBrain(deepseekBrain);
      break;
    default:
      setRobinBrain(localBrain);
  }
}

Future<void> setBrainChoice(String choice) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kBrain, choice);
  await applySavedBrain();
}
