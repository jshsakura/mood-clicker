import 'geo.dart';
import 'map_rules.dart';

/// The hexagon grid of the map: which blocks lie in a box and where their corners are. The real
/// one is H3 (h3_grid.dart); tests use a fake.
abstract interface class HexGrid {
  /// The blocks with their centers inside [bounds], at most [limit]. Empty when there would be
  /// more.
  List<H3CellId> cellsIn(GeoBounds bounds, {required int limit});

  /// The corners of a block, in order around it.
  List<GeoPoint> boundary(H3CellId id);

  /// The block a point lies in.
  H3CellId cellAt(GeoPoint point);
}

/// The middle of a block, from its corners.
GeoPoint centerOf(List<GeoPoint> ring) {
  var lat = 0.0;
  var lng = 0.0;
  for (final point in ring) {
    lat += point.lat;
    lng += point.lng;
  }
  return GeoPoint(lat / ring.length, lng / ring.length);
}
