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

  test('a notification text value object carries title and body', () {
    const text = ReminderText('t', 'b');
    expect(text.title, 't');
    expect(text.body, 'b');
  });
}
