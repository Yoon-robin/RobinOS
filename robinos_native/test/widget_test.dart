// RobinOS 단위 테스트 — 순수 로직(시계 포맷 / Robin 로컬 두뇌).
// provider·shared_preferences·위젯 펌프가 필요 없어 CI에서 안정적으로 돈다.
import 'package:flutter_test/flutter_test.dart';
import 'package:robinos_native/widgets/clock.dart';
import 'package:robinos_native/robin/robin.dart';
import 'package:robinos_native/system/file_system.dart';
import 'package:robinos_native/system/platform_backend.dart';

RobinActions _actions(Map<String, String> log) => RobinActions(
      openApp: (id) => log['open'] = id,
      apps: () => const [AppInfo('calc', '계산기'), AppInfo('notes', '메모')],
      setTheme: (light) => log['theme'] = light ? 'light' : 'dark',
      isLight: () => false,
      setWallpaper: (id) => log['wallpaper'] = id,
      setAccent: (id) => log['accent'] = id,
      setBrightness: (v) => log['brightness'] = v.toStringAsFixed(2),
      brightness: () => 1.0,
      lock: () => log['lock'] = '1',
      closeApp: (id) => log['close'] = id,
      closeAll: () => log['close'] = 'all',
    );

void main() {
  group('clock format', () {
    test('robinTime 오전/오후 경계', () {
      expect(robinTime(DateTime(2026, 6, 12, 9, 5)), '오전 9:05');
      expect(robinTime(DateTime(2026, 6, 12, 13, 30)), '오후 1:30');
      expect(robinTime(DateTime(2026, 6, 12, 0, 0)), '오전 12:00');
      expect(robinTime(DateTime(2026, 6, 12, 12, 0)), '오후 12:00');
    });
    test('robinBigTime / robinDate', () {
      expect(robinBigTime(DateTime(2026, 6, 12, 8, 7)), '8:07');
      // 2026-06-12 는 금요일
      expect(robinDate(DateTime(2026, 6, 12)), '6월 12일 금요일');
    });
  });

  group('localBrain 인텐트', () {
    test('인사', () async {
      final r = await localBrain('안녕', _actions({}));
      expect(r.reply, contains('Robin'));
    });
    test('계산: 12 곱하기 9 = 108', () async {
      final r = await localBrain('12 곱하기 9는?', _actions({}));
      expect(r.reply, contains('108'));
    });
    test('다크모드 → setTheme(dark)', () async {
      final log = <String, String>{};
      await localBrain('다크모드 켜줘', _actions(log));
      expect(log['theme'], 'dark');
    });
    test('라이트모드 → setTheme(light)', () async {
      final log = <String, String>{};
      await localBrain('라이트모드로', _actions(log));
      expect(log['theme'], 'light');
    });
    test('앱 열기 → openApp(calc)', () async {
      final log = <String, String>{};
      await localBrain('계산기 열어', _actions(log));
      expect(log['open'], 'calc');
    });
    test('강조색 핑크 → setAccent(pink)', () async {
      final log = <String, String>{};
      await localBrain('강조색 핑크로 바꿔', _actions(log));
      expect(log['accent'], 'pink');
    });
  });

  group('RobinFs.rename', () {
    test('파일 이름 변경 — 내용 보존, 옛 경로 제거', () {
      final fs = RobinFs();
      fs.write('/문서/메모.txt', '안녕');
      final to = fs.rename('/문서/메모.txt', '일기.txt');
      expect(to, '/문서/일기.txt');
      expect(fs.exists('/문서/메모.txt'), false);
      expect(fs.get('/문서/일기.txt')?.content, '안녕');
    });

    test('폴더 이름 변경 — 하위 항목 경로까지 재작성', () {
      final fs = RobinFs();
      fs.mkdir('/', '작업');
      fs.write('/작업/a.txt', '1');
      fs.write('/작업/하위/b.txt', '2');
      final to = fs.rename('/작업', '프로젝트');
      expect(to, '/프로젝트');
      expect(fs.exists('/작업'), false);
      expect(fs.exists('/작업/a.txt'), false);
      expect(fs.get('/프로젝트/a.txt')?.content, '1');
      expect(fs.get('/프로젝트/하위/b.txt')?.content, '2');
    });

    test('이름 충돌 시 무시(null) — 기존 항목 보존', () {
      final fs = RobinFs();
      fs.write('/문서/a.txt', 'A');
      fs.write('/문서/b.txt', 'B');
      final to = fs.rename('/문서/a.txt', 'b.txt');
      expect(to, isNull);
      expect(fs.get('/문서/a.txt')?.content, 'A');
      expect(fs.get('/문서/b.txt')?.content, 'B');
    });

    test('빈 이름·슬래시 포함은 거부(null)', () {
      final fs = RobinFs();
      fs.write('/문서/a.txt', 'A');
      expect(fs.rename('/문서/a.txt', '   '), isNull);
      expect(fs.rename('/문서/a.txt', '하위/c.txt'), isNull);
      expect(fs.exists('/문서/a.txt'), true);
    });
  });

  group('localBrain 확장 인텐트', () {
    test('시간 질문 → 오전/오후 포함', () async {
      final r = await localBrain('지금 몇 시야?', _actions({}));
      expect(r.reply, anyOf(contains('오전'), contains('오후')));
    });
    test('날짜 질문 → 요일 포함', () async {
      final r = await localBrain('오늘 무슨 요일이야?', _actions({}));
      expect(r.reply, contains('요일'));
    });
    test('정체성 질문 → 비서 소개', () async {
      final r = await localBrain('너 누구야?', _actions({}));
      expect(r.reply, contains('비서'));
    });
    test('테마 토글(현재 다크) → setTheme(light)', () async {
      final log = <String, String>{};
      await localBrain('테마 바꿔줘', _actions(log));
      expect(log['theme'], 'light');
    });
    test('감사 → 천만에요', () async {
      final r = await localBrain('고마워!', _actions({}));
      expect(r.reply, contains('천만'));
    });
    test('잠금 → lock() 호출', () async {
      final log = <String, String>{};
      final r = await localBrain('화면 잠가줘', _actions(log));
      expect(log['lock'], '1');
      expect(r.reply, contains('잠갔'));
    });
    test('앱 닫기 → closeApp(calc)', () async {
      final log = <String, String>{};
      await localBrain('계산기 닫아', _actions(log));
      expect(log['close'], 'calc');
    });
    test('전부 닫기 → closeAll', () async {
      final log = <String, String>{};
      await localBrain('다 닫아줘', _actions(log));
      expect(log['close'], 'all');
    });
  });

  group('PlatformBackend (Phase C)', () {
    test('setBrightness/setVolume 는 도구가 없어도 예외 없이 완료', () async {
      // 리눅스 CI엔 brightnessctl/wpctl 미설치 → Process.run 예외를 내부에서 흡수.
      await platformBackend.setBrightness(0.5);
      await platformBackend.setVolume(0.3);
      expect(platformBackend.isReal, isA<bool>());
    });
  });
}
