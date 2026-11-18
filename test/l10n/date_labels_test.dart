import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/date_labels.dart';

void main() {
  // Korean and Japanese strings appear as escapes so the code stays English
  // only, per the repository rule.
  final ko = const Locale('ko');
  final en = const Locale('en');
  final ja = const Locale('ja');
  final fr = const Locale('fr');
  final november = DateTime(2026, 11, 18);

  group('monthTitle', () {
    test('formats each supported locale', () {
      expect(monthTitle(ko, november), '2026\uB144 11\uC6D4');
      expect(monthTitle(en, november), 'November 2026');
      expect(monthTitle(ja, november), '2026\u5E7411\u6708');
    });

    test('unsupported locales fall back to English', () {
      expect(monthTitle(fr, november), monthTitle(en, november));
    });
  });

  group('weekdayLabels', () {
    test('starts on Sunday for each supported locale', () {
      expect(weekdayLabels(ko), [
        '\uC77C',
        '\uC6D4',
        '\uD654',
        '\uC218',
        '\uBAA9',
        '\uAE08',
        '\uD1A0',
      ]);
      expect(weekdayLabels(en).first, 'Sun');
      expect(weekdayLabels(ja).first, '\u65E5');
    });

    test('unsupported locales fall back to English', () {
      expect(weekdayLabels(fr), weekdayLabels(en));
    });
  });

  group('dayTitle', () {
    test('formats each supported locale', () {
      expect(dayTitle(ko, november), '11\uC6D4 18\uC77C');
      expect(dayTitle(en, november), 'Nov 18');
      expect(dayTitle(ja, november), '11\u670818\u65E5');
    });

    test('unsupported locales fall back to English', () {
      expect(dayTitle(fr, november), dayTitle(en, november));
    });
  });
}
