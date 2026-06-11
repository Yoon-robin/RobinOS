import 'package:flutter/foundation.dart';

// ===========================================================
// 앱 간 인텐트 — 앱들이 서로를 직접 알지 않고 느슨하게 협력하는 통로.
// 예) Finder에서 .txt "메모에서 열기":
//   1) Finder가 notesOpenTarget.value = 경로
//   2) Desktop이 이를 듣고 메모 앱을 연다
//   3) NotesApp이 그 경로로 전환한 뒤 값을 비운다(null)
// ===========================================================

// 메모 앱에서 열어야 할 파일 경로 (없으면 null)
final ValueNotifier<String?> notesOpenTarget = ValueNotifier<String?>(null);
