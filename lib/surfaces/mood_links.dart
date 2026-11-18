import '../domain/mood.dart';

/// The link scheme the home screen widget opens. The same text is written in the Android manifest
/// and the iOS URL types, so change all three together.
const String appLinkScheme = 'moodclicker';
const String _tapHost = 'tap';
const String _shortcutPrefix = 'tap_';

/// The link a widget tap opens. Without a mood it only opens the app.
Uri tapUri(Mood? mood) => Uri(
  scheme: appLinkScheme,
  host: _tapHost,
  path: mood == null ? '' : '/${mood.id}',
);

/// The mood a link asks for. Null for links of other apps, other hosts, unknown moods and the
/// link without a mood.
Mood? moodFromUri(Uri? uri) {
  if (uri == null || uri.scheme != appLinkScheme || uri.host != _tapHost) {
    return null;
  }
  final parts = uri.pathSegments;
  if (parts.length != 1) return null;
  return Mood.byId(parts.single);
}

/// The id of the app icon shortcut of a mood. Unique per mood.
String shortcutTypeFor(Mood mood) => '$_shortcutPrefix${mood.id}';

Mood? moodFromShortcutType(String type) {
  if (!type.startsWith(_shortcutPrefix)) return null;
  return Mood.byId(type.substring(_shortcutPrefix.length));
}
