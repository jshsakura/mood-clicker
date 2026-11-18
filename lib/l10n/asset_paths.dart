/// Per-language asset paths with a Korean fallback.
///
/// Stamps are designer-made images (`assets/stamps/<language>/<name>.svg`)
/// and cheers are JSON phrase packs (`assets/cheers/<language>.json`). A
/// language without its own file shows the Korean one, so a missing
/// translation never leaves a blank screen.
library;

/// Says whether an asset path ships with the app. Production code backs
/// this with the asset manifest; tests inject a fake.
typedef AssetExists = bool Function(String path);

const String _fallbackLanguage = 'ko';

/// Path of a stamp image for [languageCode], falling back to Korean.
String stampAssetPath(
  String languageCode,
  AssetExists assetExists, {
  String name = 'well_done',
}) {
  final path = 'assets/stamps/$languageCode/$name.svg';
  if (assetExists(path)) {
    return path;
  }
  return 'assets/stamps/$_fallbackLanguage/$name.svg';
}

/// Path of the cheers phrase pack for [languageCode], falling back to Korean.
String cheersAssetPath(String languageCode, AssetExists assetExists) {
  final path = 'assets/cheers/$languageCode.json';
  if (assetExists(path)) {
    return path;
  }
  return 'assets/cheers/$_fallbackLanguage.json';
}
