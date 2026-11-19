import 'package:h3_flutter/h3_flutter.dart';

import 'geo.dart';
import 'hex_grid.dart';
import 'map_rules.dart';

/// The H3 grid at [MapRules.h3Resolution], through the native H3 library.
class H3Grid implements HexGrid {
  H3Grid() : _h3 = _loadNow();

  /// The native library loads at once on the phones; only the web build would answer later.
  static H3 _loadNow() {
    final loaded = const H3Factory().load();
    if (loaded is H3) return loaded;
    throw UnsupportedError('H3 loads asynchronously on this platform');
  }

  final H3 _h3;

  @override
  List<H3CellId> cellsIn(GeoBounds bounds, {required int limit}) {
    final ring = [
      GeoCoord(lon: bounds.west, lat: bounds.south),
      GeoCoord(lon: bounds.east, lat: bounds.south),
      GeoCoord(lon: bounds.east, lat: bounds.north),
      GeoCoord(lon: bounds.west, lat: bounds.north),
    ];
    final cells = _h3.polygonToCells(
      perimeter: ring,
      resolution: MapRules.h3Resolution,
    );
    if (cells.length > limit) return const [];
    return [for (final cell in cells) H3CellId(cell.toRadixString(16))];
  }

  @override
  List<GeoPoint> boundary(H3CellId id) => [
    for (final c in _h3.cellToBoundary(BigInt.parse(id.value, radix: 16)))
      GeoPoint(c.lat, c.lon),
  ];
}
