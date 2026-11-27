import 'package:geolocator/geolocator.dart';

/// Latitude and longitude rounded to one decimal place (~11 km grid).
class CoarseCoord {
  CoarseCoord({required double lat, required double lon})
    : lat = roundOneDecimal(lat),
      lon = roundOneDecimal(lon);

  final double lat;
  final double lon;

  static double roundOneDecimal(double value) => (value * 10).round() / 10;

  String get latString => lat.toStringAsFixed(1);
  String get lonString => lon.toStringAsFixed(1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoarseCoord && lat == other.lat && lon == other.lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'CoarseCoord($latString, $lonString)';
}

/// Port for obtaining the device's coarse location while the app is in use.
abstract interface class CoarseLocation {
  Future<CoarseCoord?> current();
}

/// Geolocator-backed [CoarseLocation] that requests when-in-use permission
/// and returns null if services are disabled, permission is denied, or reading fails.
class GeolocatorCoarseLocation implements CoarseLocation {
  const GeolocatorCoarseLocation();

  @override
  Future<CoarseCoord?> current() async {
    final pos = await readDevicePosition();
    return pos == null ? null : CoarseCoord(lat: pos.lat, lon: pos.lon);
  }
}

/// The device position, asking for when-in-use permission first. Null when location is off,
/// permission is denied, or reading fails. Callers coarsen it at once and drop it.
Future<({double lat, double lon})?> readDevicePosition() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (lat: pos.latitude, lon: pos.longitude);
  } catch (_) {
    return null;
  }
}
