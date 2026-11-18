import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/locale_resolution.dart';

void main() {
  const supported = [Locale('ko'), Locale('en'), Locale('ja')];

  test('an exact language and country match wins', () {
    expect(
      resolveAppLocale(const [Locale('ko', 'KR')], supported),
      const Locale('ko'),
    );
  });

  test('a language-only match follows the device', () {
    expect(
      resolveAppLocale(const [Locale('ja', 'JP')], supported),
      const Locale('ja'),
    );
    expect(
      resolveAppLocale(const [Locale('en', 'GB')], supported),
      const Locale('en'),
    );
  });

  test('an unsupported device language falls back to English', () {
    expect(
      resolveAppLocale(const [Locale('fr', 'FR')], supported),
      const Locale('en'),
    );
  });

  test(
    'a supported language later in the device list still wins over fallback',
    () {
      expect(
        resolveAppLocale(const [
          Locale('fr', 'FR'),
          Locale('ko', 'KR'),
        ], supported),
        const Locale('ko'),
      );
    },
  );

  test('an empty device list falls back to English', () {
    expect(resolveAppLocale(const [], supported), const Locale('en'));
  });
}
