import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';

void main() {
  test('supported locales stay ko, en and ja', () {
    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('ja'),
      Locale('ko'),
    ]);
  });

  test('every supported locale resolves the mood names', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.moodSelect_moodHappy, isNotEmpty);
      expect(l10n.moodSelect_moodExcited, isNotEmpty);
      expect(l10n.moodSelect_moodAngry, isNotEmpty);
      expect(l10n.moodSelect_moodSad, isNotEmpty);
      expect(l10n.moodSelect_moodAnxious, isNotEmpty);
    }
  });

  test('the tap label is translated', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.tap_todayLabel, 'Taps today');
    final ja = lookupAppLocalizations(const Locale('ja'));
    expect(ja.tap_todayLabel, isNotEmpty);
  });
}
