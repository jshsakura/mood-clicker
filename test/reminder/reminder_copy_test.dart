import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';

/// The reminder follows three rules, pinned here:
/// 1. No guilt. The copy never blames the reader for missed days or streaks.
/// 2. Lock screen privacy. The notification never names a mood.
/// 3. At most one reminder a day. That rule lives in the planner tests.
void main() {
  AppLocalizations of(Locale locale) => lookupAppLocalizations(locale);

  test('the copy stays free of guilt words in every locale', () {
    const banned = [
      // Korean: yesterday, streak, missed, skipped, forgot.
      '\uC5B4\uC81C', '\uC5F0\uC18D', '\uB191\uCE58', '\uBBF8\uB8E8',
      '\uC7A1\uC740', '\uC78A\uC5C8',
      // English: yesterday, streak, missed, skipped, forgot, don't miss.
      'yesterday', 'streak', 'missed', 'skipped', 'forgot', "don't miss",
      // Japanese: yesterday, streak, forgot.
      '\u6628\u65E5', '\u9023\u7D9A', '\u5FD8\u308C',
    ];
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = of(locale);
      for (final text in [l10n.reminder_title, l10n.reminder_body]) {
        for (final word in banned) {
          expect(
            text.toLowerCase(),
            isNot(contains(word.toLowerCase())),
            reason: '$locale must not say $word in $text',
          );
        }
      }
    }
  });

  test('the notification never names a mood on the lock screen', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = of(locale);
      final moodNames = [
        l10n.moodSelect_moodHappy,
        l10n.moodSelect_moodExcited,
        l10n.moodSelect_moodAngry,
        l10n.moodSelect_moodSad,
        l10n.moodSelect_moodAnxious,
      ];
      for (final text in [l10n.reminder_title, l10n.reminder_body]) {
        for (final mood in moodNames) {
          expect(text, isNot(contains(mood)), reason: '$locale leaks $mood');
        }
      }
    }
  });

  test('the corrected copy reads as intended', () {
    expect(
      of(const Locale('ko')).reminder_body,
      '\uC7A0\uAE50 \uB4E4\uB7EC \uC624\uB298 \uB9C8\uC74C\uC744 \uB0A8\uACA8 \uBCF4\uC138\uC694',
    );
    expect(
      of(const Locale('en')).reminder_body,
      'A moment to check in with yourself',
    );
    expect(
      of(const Locale('ja')).reminder_body,
      '\u5C11\u3057\u3060\u3051\u3001\u4ECA\u65E5\u306E\u6C17\u6301\u3061\u3092\u6B8B\u3057\u3066\u307F\u307E\u305B\u3093\u304B',
    );
  });
}
