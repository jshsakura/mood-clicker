import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/reminder/reminder_port.dart';

void main() {
  test('every locale carries the reminder text', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.reminder_title, isNotEmpty, reason: '$locale reminder_title');
      expect(l10n.reminder_body, isNotEmpty, reason: '$locale reminder_body');
      expect(
        l10n.settings_reminder,
        isNotEmpty,
        reason: '$locale settings_reminder',
      );
      expect(
        l10n.settings_reminderTime,
        isNotEmpty,
        reason: '$locale settings_reminderTime',
      );
    }
  });

  test('the reminder copy reads as intended', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(
      ko.reminder_title,
      '\uC624\uB298 \uAE30\uBD84\uC740 \uC5B4\uB560\uB098\uC694?',
    );
    expect(
      ko.reminder_body,
      '\uC7A0\uAE50 \uB4E4\uC5B4\uC640 \uB450\uB4DC\uB824 \uBCF4\uC138\uC694',
    );
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.reminder_title, 'How was your mood today?');
    expect(en.reminder_body, 'Take a moment to tap it out');
    final ja = lookupAppLocalizations(const Locale('ja'));
    expect(
      ja.reminder_title,
      '\u4ECA\u65E5\u306E\u6C17\u5206\u306F\u3069\u3046\u3067\u3057\u305F\u304B\uFF1F',
    );
    expect(
      ja.reminder_body,
      '\u3061\u3087\u3063\u3068\u3060\u3051\u305F\u305F\u3044\u3066\u307F\u307E\u305B\u3093\u304B',
    );
  });

  test('a notification text value object carries title and body', () {
    const text = ReminderText('t', 'b');
    expect(text.title, 't');
    expect(text.body, 'b');
  });
}
