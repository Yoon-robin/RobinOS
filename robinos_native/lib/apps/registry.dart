import 'package:flutter/material.dart';

// ===========================================================
// 앱 레지스트리 — 웹의 data/apps.ts 대응.
// main.dart 와 여러 화면(Spotlight·런치패드 등)이 공유 (순환참조 방지).
// ===========================================================
class AppDef {
  final String id;
  final String name;
  final String emoji; // (구) 이모지 — 폴백/호환용. 실제 표시는 glyph(RobinAppIcon).
  final Color color;
  final Size size;
  final IconData glyph; // RobinOS 자체 아이콘 언어의 글리프(독·런치패드 공용).
  const AppDef(
    this.id,
    this.name,
    this.emoji,
    this.color, {
    this.size = const Size(560, 400),
    required this.glyph,
  });
}

const kApps = <AppDef>[
  AppDef('finder', 'Finder', '📁', Color(0xFF4AA3FF),
      glyph: Icons.folder_rounded),
  AppDef('notes', '메모', '📝', Color(0xFFFFC24A),
      size: Size(520, 420), glyph: Icons.sticky_note_2_rounded),
  AppDef('calc', '계산기', '🧮', Color(0xFF9B8CFF),
      size: Size(280, 420), glyph: Icons.calculate_rounded),
  AppDef('paint', '그림판', '🎨', Color(0xFFFF6FA5),
      size: Size(640, 460), glyph: Icons.brush_rounded),
  AppDef('terminal', '터미널', '⌨️', Color(0xFF2B2B33),
      size: Size(600, 380), glyph: Icons.terminal_rounded),
  AppDef('settings', '설정', '⚙️', Color(0xFF8A8A92),
      size: Size(640, 480), glyph: Icons.settings_rounded),
  AppDef('software', '소프트웨어', '📦', Color(0xFF5B8DEF),
      size: Size(660, 500), glyph: Icons.inventory_2_rounded),
  AppDef('monitor', '시스템 모니터', '📊', Color(0xFF49D17A),
      size: Size(620, 560), glyph: Icons.monitor_heart_rounded),
  AppDef('calendar', '캘린더', '📅', Color(0xFFFF5A5F),
      size: Size(600, 600), glyph: Icons.calendar_month_rounded),
];
