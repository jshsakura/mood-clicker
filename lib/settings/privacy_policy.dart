/// The privacy policy shipped with the app: one markdown file per language,
/// the same files the repository keeps under docs/privacy-policy.
library;

import 'dart:ui' show Locale;

const Map<String, String> privacyDocAssets = {
  'ko': 'docs/privacy-policy/ko.md',
  'en': 'docs/privacy-policy/en.md',
  'ja': 'docs/privacy-policy/ja.md',
};

/// The policy document for [locale]. Languages without their own document
/// read the English one, like the rest of the app.
String privacyDocPath(Locale locale) {
  return privacyDocAssets[locale.languageCode] ?? privacyDocAssets['en']!;
}
