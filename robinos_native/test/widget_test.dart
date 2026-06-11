// RobinOS 네이티브 기본 스모크 테스트.
import 'package:flutter_test/flutter_test.dart';

import 'package:robinos_native/main.dart';

void main() {
  testWidgets('RobinOS desktop renders', (WidgetTester tester) async {
    await tester.pumpWidget(const RobinOSApp());

    // 데스크톱에 브랜드와 메뉴바가 떠야 한다.
    expect(find.text('RobinOS'), findsWidgets);
    expect(find.text('네이티브 빌드 · Flutter'), findsOneWidget);
  });
}
