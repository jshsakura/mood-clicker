/// Locale resolution for the app.
///
/// MaterialApp gets this through `localeListResolutionCallback`. Device
/// languages outside the supported set (ko, en, ja) fall back to English.
library;

import 'dart:ui' show Locale;

/// Picks the app locale from the device locale list.
///
/// An exact match (language and country) wins, then a language-only match.
/// When the device has no supported language at all, the app runs in
/// English.
Locale resolveAppLocale(
  List<Locale> deviceLocales,
  Iterable<Locale> supported,
) {
  Locale? languageMatch;
  for (final device in deviceLocales) {
    for (final candidate in supported) {
      if (device.languageCode != candidate.languageCode) {
        continue;
      }
      if (device.countryCode == candidate.countryCode &&
          device.scriptCode == candidate.scriptCode) {
        return candidate;
      }
      languageMatch ??= candidate;
    }
  }
  return languageMatch ?? _englishFallback(supported);
}

Locale _englishFallback(Iterable<Locale> supported) {
  return supported.firstWhere(
    (locale) => locale.languageCode == 'en',
    orElse: () => supported.first,
  );
}
