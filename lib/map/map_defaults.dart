import 'geo.dart';

/// Where the map starts and which map it draws. One place to change them.
abstract final class MapDefaults {
  /// Where the map starts until the device position is wired in: near Seoul City Hall, rounded
  /// to two decimals on purpose (about a kilometer, no exact place).
  static const GeoPoint startCenter = GeoPoint(37.57, 126.98);
  static const double startZoom = 12;

  /// Below this zoom the view is too wide for blocks of one kilometer: the grid stays off.
  static const double minGridZoom = 10.5;

  /// More blocks than this in view means the same: the grid stays off.
  static const int maxBlocks = 700;

  /// OpenFreeMap styles, no key. Positron is the light, lines-first one; Dark is its night
  /// counterpart.
  static const String lightStyle =
      'https://tiles.openfreemap.org/styles/positron';
  static const String darkStyle = 'https://tiles.openfreemap.org/styles/dark';

  /// The credit the map must show in its corner.
  static const String attribution =
      '© OpenFreeMap © OpenStreetMap contributors';
}
