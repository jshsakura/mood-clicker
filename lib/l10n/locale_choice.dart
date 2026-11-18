/// The language setting shown in the settings screen.
///
/// `system` follows the device language; the other values pin one locale
/// no matter what the device says. The native label for each option comes
/// from the ARB keys settings_language*; the stored value is just a name.
library;

import 'dart:ui' show Locale;

enum LocaleChoice {
  system(null),
  ko(Locale('ko')),
  en(Locale('en')),
  ja(Locale('ja'));

  const LocaleChoice(this.locale);

  /// The locale to hand to MaterialApp, or null to follow the device.
  final Locale? locale;
}

/// Reads and writes the language choice. Implementations keep the value on
/// the device; tests inject an in-memory version.
abstract interface class LocaleChoiceStore {
  /// Returns the stored choice, or [LocaleChoice.system] when nothing is
  /// stored yet.
  Future<LocaleChoice> read();

  /// Persists the choice.
  Future<void> write(LocaleChoice choice);
}
