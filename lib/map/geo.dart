import 'package:flutter/foundation.dart';

/// A point on the earth in degrees. It exists only on the device, to draw blocks: nothing that
/// leaves the device carries one (see MapSource).
@immutable
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// The box of the earth the map shows.
@immutable
class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;
}

/// What the map shows right now: the box and the zoom level.
@immutable
class MapViewport {
  const MapViewport({required this.bounds, required this.zoom});

  final GeoBounds bounds;
  final double zoom;
}
