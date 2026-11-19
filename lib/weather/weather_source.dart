import 'dart:convert';
import 'dart:io';

import 'package:mood_clicker/location/coarse_location.dart';

enum WeatherKind { clear, partlyCloudy, cloudy, rain, snow }

class WeatherSnapshot {
  const WeatherSnapshot({required this.kind, required this.tempC});

  final WeatherKind kind;
  final int tempC;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherSnapshot && kind == other.kind && tempC == other.tempC;

  @override
  int get hashCode => Object.hash(kind, tempC);
}

/// Port for fetching current weather at a coarse coordinate.
abstract interface class WeatherSource {
  Future<WeatherSnapshot?> current(CoarseCoord coord);
}

typedef HttpGetText =
    Future<String?> Function(Uri uri, Map<String, String> headers);

/// MET Norway Locationforecast 2.0 compact client.
///
/// Sends only 1-decimal-place coordinates, caches responses for 30 minutes,
/// and returns null quietly on any network or parse failure.
class MetNorwayWeatherSource implements WeatherSource {
  MetNorwayWeatherSource({
    HttpGetText? getText,
    DateTime Function()? now,
    this.cacheDuration = const Duration(minutes: 30),
    this.userAgent = 'mood_clicker/1.0 (https://example.com)',
  }) : _getText = getText ?? _defaultGetText,
       _now = now ?? DateTime.now;

  final HttpGetText _getText;
  final DateTime Function() _now;
  final Duration cacheDuration;
  final String userAgent;

  CoarseCoord? _cachedCoord;
  DateTime? _cachedAt;
  WeatherSnapshot? _cachedValue;

  @override
  Future<WeatherSnapshot?> current(CoarseCoord coord) async {
    final currentTime = _now();
    if (_cachedCoord == coord &&
        _cachedAt != null &&
        _cachedValue != null &&
        currentTime.difference(_cachedAt!) < cacheDuration) {
      return _cachedValue;
    }

    final uri = Uri.https(
      'api.met.no',
      '/weatherapi/locationforecast/2.0/compact',
      {'lat': coord.latString, 'lon': coord.lonString},
    );

    try {
      final body = await _getText(uri, {'User-Agent': userAgent});
      if (body == null) return null;
      final parsed = parseLocationforecast(body);
      if (parsed == null) return null;
      _cachedCoord = coord;
      _cachedAt = currentTime;
      _cachedValue = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static WeatherSnapshot? parseLocationforecast(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! Map<String, dynamic>) return null;
    final properties = decoded['properties'];
    if (properties is! Map<String, dynamic>) return null;
    final timeseries = properties['timeseries'];
    if (timeseries is! List || timeseries.isEmpty) return null;

    final first = timeseries.first;
    if (first is! Map<String, dynamic>) return null;
    final data = first['data'];
    if (data is! Map<String, dynamic>) return null;

    final instant = data['instant'];
    if (instant is! Map<String, dynamic>) return null;
    final details = instant['details'];
    if (details is! Map<String, dynamic>) return null;
    final temp = details['air_temperature'];
    if (temp is! num) return null;

    String? symbolCode;
    for (final key in const ['next_1_hours', 'next_6_hours', 'next_12_hours']) {
      final block = data[key];
      if (block is Map<String, dynamic>) {
        final summary = block['summary'];
        if (summary is Map<String, dynamic>) {
          final code = summary['symbol_code'];
          if (code is String && code.isNotEmpty) {
            symbolCode = code;
            break;
          }
        }
      }
    }
    if (symbolCode == null) return null;

    return WeatherSnapshot(
      kind: mapSymbolCode(symbolCode),
      tempC: temp.round(),
    );
  }

  static WeatherKind mapSymbolCode(String code) {
    final base = code.split('_').first;
    if (base.contains('snow') || base.contains('sleet')) {
      return WeatherKind.snow;
    }
    if (base.contains('rain') || base.contains('drizzle')) {
      return WeatherKind.rain;
    }
    if (base == 'clearsky' || base == 'fair') {
      return WeatherKind.clear;
    }
    if (base == 'partlycloudy') {
      return WeatherKind.partlyCloudy;
    }
    return WeatherKind.cloudy;
  }

  static Future<String?> _defaultGetText(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
