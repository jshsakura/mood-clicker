import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/app_services.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/line_icon.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/cheer_picker.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/location/coarse_location.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';
import 'package:mood_clicker/weather/weather_source.dart';

import '../domain/cheer_fixtures.dart';
import '../feedback/fakes.dart';
import '../screens/fake_app.dart';

class _FakeCoarseLocation implements CoarseLocation {
  _FakeCoarseLocation(this.coord);

  final CoarseCoord? coord;
  int calls = 0;

  @override
  Future<CoarseCoord?> current() async {
    calls++;
    return coord;
  }
}

class _FakeWeatherSource implements WeatherSource {
  _FakeWeatherSource(this.snapshot);

  final WeatherSnapshot? snapshot;
  int calls = 0;
  CoarseCoord? lastCoord;

  @override
  Future<WeatherSnapshot?> current(CoarseCoord coord) async {
    calls++;
    lastCoord = coord;
    return snapshot;
  }
}

Future<AppServices> _makeServices({
  CoarseLocation? location,
  WeatherSource? weatherSource,
  ValueNotifier<bool>? weatherView,
}) async {
  final journal = JournalStore(MemoryRepository());
  final deck = MemoryDeckStore();
  return AppServices(
    journal: journal,
    feedback: FeedbackController(haptics: FakeHaptics(), sound: FakeSound()),
    loadCheers: (_) async => bookOf(20),
    cheerPicker: CheerPicker(Random(1)),
    deckStore: deck,
    feel: ValueNotifier(const FeelSettings()),
    tilt: () => const Stream<double>.empty(),
    theme: ValueNotifier(const ThemeChoice.named('light')),
    location: location,
    weatherSource: weatherSource,
    weatherView: weatherView,
    now: () => DateTime(2026, 11, 18),
  );
}

Widget _wrap(AppServices services) {
  return AppScope(
    services: services,
    child: MaterialApp(
      theme: buildTheme(lightPalette),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MoodSelectScreen(),
    ),
  );
}

String _metNorwaySample({
  double temp = 18.4,
  String symbolCode = 'clearsky_day',
}) {
  return jsonEncode({
    'properties': {
      'timeseries': [
        {
          'data': {
            'instant': {
              'details': {'air_temperature': temp},
            },
            'next_1_hours': {
              'summary': {'symbol_code': symbolCode},
            },
          },
        },
      ],
    },
  });
}

void main() {
  test('CoarseCoord rounds lat and lon to one decimal place', () {
    final coord = CoarseCoord(lat: 37.5665, lon: 126.9780);
    expect(coord.lat, 37.6);
    expect(coord.lon, 127.0);
    expect(coord.latString, '37.6');
    expect(coord.lonString, '127.0');
  });

  test(
    'MetNorwayWeatherSource sends 1-decimal coords and caches 30 minutes',
    () async {
      var clock = DateTime(2026, 11, 18, 9, 0);
      Uri? requestedUri;
      Map<String, String>? requestedHeaders;
      var httpCalls = 0;

      final source = MetNorwayWeatherSource(
        now: () => clock,
        getText: (uri, headers) async {
          httpCalls++;
          requestedUri = uri;
          requestedHeaders = headers;
          return _metNorwaySample(temp: 12.6, symbolCode: 'lightrain');
        },
      );

      final coord = CoarseCoord(lat: 35.1234, lon: 129.0756);
      final first = await source.current(coord);
      expect(first, const WeatherSnapshot(kind: WeatherKind.rain, tempC: 13));
      expect(requestedUri?.host, 'api.met.no');
      expect(requestedUri?.queryParameters, {'lat': '35.1', 'lon': '129.1'});
      expect(requestedHeaders?['User-Agent'], contains('mood_clicker'));
      expect(httpCalls, 1);

      clock = clock.add(const Duration(minutes: 29));
      final cached = await source.current(coord);
      expect(cached, first);
      expect(httpCalls, 1);

      clock = clock.add(const Duration(minutes: 2));
      await source.current(coord);
      expect(httpCalls, 2);
    },
  );

  test('MetNorwayWeatherSource returns null quietly on failure', () async {
    final source = MetNorwayWeatherSource(getText: (_, _) async => null);
    final res = await source.current(CoarseCoord(lat: 0.0, lon: 0.0));
    expect(res, isNull);
  });

  testWidgets(
    'shows date chip and weather chip when location and weather succeed',
    (tester) async {
      final location = _FakeCoarseLocation(
        CoarseCoord(lat: 37.56, lon: 126.97),
      );
      final weather = _FakeWeatherSource(
        const WeatherSnapshot(kind: WeatherKind.clear, tempC: 18),
      );
      final services = await _makeServices(
        location: location,
        weatherSource: weather,
      );

      await tester.pumpWidget(_wrap(services));
      await tester.pumpAndSettle();

      expect(find.text('18\u00B0'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is LineIcon && w.icon == LineIcons.weatherClear,
        ),
        findsOneWidget,
      );
      expect(location.calls, 1);
      expect(weather.calls, 1);
      expect(weather.lastCoord, CoarseCoord(lat: 37.6, lon: 127.0));
    },
  );

  testWidgets('hides weather chip quietly when weather fails', (tester) async {
    final location = _FakeCoarseLocation(CoarseCoord(lat: 37.5, lon: 127.0));
    final weather = _FakeWeatherSource(null);
    final services = await _makeServices(
      location: location,
      weatherSource: weather,
    );

    await tester.pumpWidget(_wrap(services));
    await tester.pumpAndSettle();

    expect(find.textContaining('\u00B0'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is LineIcon && w.icon.name.startsWith('weather'),
      ),
      findsNothing,
    );
  });

  testWidgets('makes 0 location and weather requests when weatherView is off', (
    tester,
  ) async {
    final location = _FakeCoarseLocation(CoarseCoord(lat: 37.5, lon: 127.0));
    final weather = _FakeWeatherSource(
      const WeatherSnapshot(kind: WeatherKind.cloudy, tempC: 9),
    );
    final weatherView = ValueNotifier(false);
    final services = await _makeServices(
      location: location,
      weatherSource: weather,
      weatherView: weatherView,
    );

    await tester.pumpWidget(_wrap(services));
    await tester.pumpAndSettle();

    expect(location.calls, 0);
    expect(weather.calls, 0);
    expect(find.text('9\u00B0'), findsNothing);

    weatherView.value = true;
    await tester.pumpAndSettle();

    expect(location.calls, 1);
    expect(weather.calls, 1);
    expect(find.text('9\u00B0'), findsOneWidget);
  });
}
