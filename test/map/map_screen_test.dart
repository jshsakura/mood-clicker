import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mood_clicker/design/parts/pressable_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/design/parts/mood_face.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/map/geo.dart';
import 'package:mood_clicker/map/hex_grid.dart';
import 'package:mood_clicker/map/map_backdrop.dart';
import 'package:mood_clicker/map/map_defaults.dart';
import 'package:mood_clicker/map/map_rules.dart';
import 'package:mood_clicker/map/map_screen.dart';
import 'package:mood_clicker/map/map_source.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';

import '../screens/fake_app.dart';

class _FixedSource implements MapSource {
  _FixedSource(this.snapshot);
  final MapSnapshot snapshot;
  final List<(MapRange, List<H3CellId>)> asked = [];

  @override
  Future<MapSnapshot> load(MapRange range, List<H3CellId> cells) async {
    asked.add((range, cells));
    return snapshot;
  }
}

H3CellId _id(int n) => H3CellId('87${n.toRadixString(16).padLeft(13, '0')}');

MapSnapshot _snapshot([double happy = 0.58]) => MapSnapshot(
  cells: [
    MapCell(
      id: _id(0),
      mood: Mood.happy,
      people: 30,
      taps: 500,
      happyShare: happy,
      word: MapWord.ateWell,
    ),
    MapCell(
      id: _id(1),
      mood: Mood.sad,
      people: 9,
      taps: 100,
      happyShare: happy,
      word: MapWord.rest,
    ),
    // Under five people, must never show.
    MapCell(
      id: _id(2),
      mood: Mood.angry,
      people: 3,
      taps: 900,
      happyShare: happy,
      word: MapWord.thankful,
    ),
  ],
);

/// Three blocks in a row. Where a point sits on the fake screen is a plain function of it.
class _FakeGrid implements HexGrid {
  _FakeGrid({this.tooMany = false});

  final bool tooMany;
  final List<GeoBounds> asked = [];

  @override
  List<H3CellId> cellsIn(GeoBounds bounds, {required int limit}) {
    asked.add(bounds);
    return tooMany ? const [] : [_id(0), _id(1), _id(2)];
  }

  @override
  H3CellId cellAt(GeoPoint point) => _id(0);

  @override
  List<GeoPoint> boundary(H3CellId id) {
    final n = int.parse(id.value.substring(2), radix: 16);
    final lng = 126.1 + 0.1 * n;
    return [
      GeoPoint(37.89, lng - 0.01),
      GeoPoint(37.89, lng + 0.01),
      GeoPoint(37.91, lng + 0.01),
      GeoPoint(37.91, lng - 0.01),
    ];
  }
}

const _viewport = MapViewport(
  bounds: GeoBounds(south: 37.5, west: 126.0, north: 38.0, east: 126.5),
  zoom: 12,
);

/// What the tests can reach of the fake ground.
class _Ground {
  late MapBackdropLink link;
}

Future<_Ground> _pumpMap(
  WidgetTester tester, {
  MapSource? source,
  HexGrid? grid,
  RatioPolicy ratio = const RatioPolicy(),
  Mood? just,
  double happy = 0.58,
  MapViewport viewport = _viewport,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ground = _Ground();
  final app = TestApp();
  await tester.pumpWidget(
    app.wrap(
      palette: dark ? darkPalette : lightPalette,
      MapScreen(
        source: source ?? _FixedSource(_snapshot(happy)),
        grid: grid ?? _FakeGrid(),
        ratio: ratio,
        justRecorded: just,
        backdrop: (context, link) {
          ground.link = link;
          link.project = (points) async => [
            for (final p in points)
              Offset((p.lng - 126) * 1000, (38 - p.lat) * 1000),
          ];
          return GestureDetector(
            key: const Key('fakeGround'),
            behavior: HitTestBehavior.opaque,
            onTap: link.onTapGround,
          );
        },
      ),
    ),
  );
  await tester.pump();
  ground.link.onViewport(viewport);
  await tester.pump();
  await tester.pump();
  return ground;
}

Future<void> _pump(
  WidgetTester tester, {
  RatioPolicy ratio = const RatioPolicy(),
  Mood? just,
  double happy = 0.58,
}) => _pumpMap(tester, ratio: ratio, just: just, happy: happy);

void main() {
  testWidgets('shows a face and a head count for blocks of five or more', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    // The block under five people never shows, whoever sent it.
    expect(find.text('3'), findsNothing);
    final faces = tester.widgetList<MoodFace>(find.byType(MoodFace)).toList();
    expect([for (final f in faces) f.mood], [Mood.happy, Mood.sad]);
  });

  testWidgets('the screen asks the source for the blocks in view', (
    tester,
  ) async {
    final source = _FixedSource(_snapshot());
    final grid = _FakeGrid();
    await _pumpMap(tester, source: source, grid: grid);
    expect(grid.asked.single.south, 37.5);
    expect(source.asked.single.$1, MapRange.today);
    expect(source.asked.single.$2, [_id(0), _id(1), _id(2)]);
  });

  testWidgets('the dark theme asks the ground for the dark style', (
    tester,
  ) async {
    final light = await _pumpMap(tester);
    expect(light.link.dark, isFalse);
    await tester.pumpWidget(const SizedBox());
    final dark = await _pumpMap(tester, dark: true);
    expect(dark.link.dark, isTrue);
    expect(MapDefaults.darkStyle, isNot(MapDefaults.lightStyle));
    expect(MapDefaults.lightStyle, contains('tiles.openfreemap.org'));
  });

  testWidgets('the credit of the map is in its corner', (tester) async {
    await _pump(tester);
    expect(find.text(MapDefaults.attribution), findsOneWidget);
    expect(MapDefaults.attribution, contains('OpenStreetMap'));
    expect(MapDefaults.attribution, contains('OpenFreeMap'));
  });

  testWidgets('the outlines handed to the ground are the shown blocks only', (
    tester,
  ) async {
    final ground = await _pumpMap(tester);
    expect([for (final h in ground.link.hexes.value) h.id], [_id(0), _id(1)]);
    expect(ground.link.hexes.value.first.ring, hasLength(4));
  });

  testWidgets('faces step aside while the map moves and return when it stops', (
    tester,
  ) async {
    final ground = await _pumpMap(tester);
    ground.link.onMoving();
    await tester.pump();
    expect(find.byType(MoodFace), findsNothing);
    ground.link.onViewport(_viewport);
    await tester.pump();
    await tester.pump();
    expect(find.byType(MoodFace), findsNWidgets(2));
  });

  testWidgets('a view that is too wide draws no grid and asks to zoom in', (
    tester,
  ) async {
    final source = _FixedSource(_snapshot());
    final grid = _FakeGrid();
    await _pumpMap(
      tester,
      source: source,
      grid: grid,
      viewport: const MapViewport(
        bounds: GeoBounds(south: 30, west: 120, north: 40, east: 130),
        zoom: MapDefaults.minGridZoom - 1,
      ),
    );
    expect(find.text(ko.map_zoomIn), findsOneWidget);
    expect(find.byType(MoodFace), findsNothing);
    expect(source.asked, isEmpty);
    expect(grid.asked, isEmpty);
    expect(find.text(ko.map_sampleNotice), findsNothing);
  });

  testWidgets('too many blocks in view asks to zoom in as well', (
    tester,
  ) async {
    await _pumpMap(tester, grid: _FakeGrid(tooMany: true));
    expect(find.text(ko.map_zoomIn), findsOneWidget);
    expect(find.byType(MoodFace), findsNothing);
  });

  testWidgets('ratio off: title and explanation only, no bar', (tester) async {
    await _pump(tester, ratio: const RatioPolicy(show: false));
    expect(find.text(ko.map_nearby), findsOneWidget);
    expect(find.text(ko.map_explain), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('ratio on by default: the ratio title and the bar show', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(ko.map_happySide(58)), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  group('ratio switches', () {
    testWidgets('together style: a line, no numbers, no bar (happy side)', (
      tester,
    ) async {
      await _pump(tester, ratio: const RatioPolicy(style: RatioStyle.together));
      expect(find.text(ko.map_togetherHappy), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text(ko.map_peopleLine(39)), findsNothing);
      expect(find.textContaining(ko.map_happySide(58)), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('together style on the sad side', (tester) async {
      await _pump(
        tester,
        ratio: const RatioPolicy(style: RatioStyle.together),
        happy: 0.3,
      );
      expect(find.text(ko.map_togetherSad), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('percent style names the bigger side with its number', (
      tester,
    ) async {
      await _pump(tester, happy: 0.3);
      expect(find.text(ko.map_sadSide(70)), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('hiding after a heavy mood hides the ratio', (tester) async {
      for (final heavy in [Mood.sad, Mood.anxious, Mood.angry]) {
        await _pump(
          tester,
          ratio: const RatioPolicy(hideAfterHeavyMood: true),
          just: heavy,
        );
        expect(find.text(ko.map_nearby), findsOneWidget, reason: heavy.id);
        expect(find.textContaining('%'), findsNothing);
        expect(find.byType(ClipRRect), findsNothing);
      }
    });

    testWidgets('hiding after a heavy mood keeps it for a light mood', (
      tester,
    ) async {
      await _pump(
        tester,
        ratio: const RatioPolicy(hideAfterHeavyMood: true),
        just: Mood.happy,
      );
      expect(find.text(ko.map_happySide(58)), findsOneWidget);
    });

    testWidgets('the switch off keeps the ratio even after a heavy mood', (
      tester,
    ) async {
      await _pump(tester, just: Mood.sad);
      expect(find.text(ko.map_happySide(58)), findsOneWidget);
    });

    testWidgets('together style also hides after a heavy mood when asked', (
      tester,
    ) async {
      await _pump(
        tester,
        ratio: const RatioPolicy(
          style: RatioStyle.together,
          hideAfterHeavyMood: true,
        ),
        just: Mood.anxious,
      );
      expect(find.text(ko.map_togetherHappy), findsNothing);
      expect(find.text(ko.map_nearby), findsOneWidget);
    });
  });

  testWidgets('picking a place shows its word and taps, with ratio off too', (
    tester,
  ) async {
    await _pump(tester, ratio: const RatioPolicy(show: false));
    await tester.tap(find.text('9'));
    await tester.pump();
    expect(find.text('"${ko.map_wordRest}"'), findsOneWidget);
    expect(find.text(ko.map_tapsLine(100)), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('the range switch reloads the map', (tester) async {
    final source = _FixedSource(_snapshot());
    await _pumpMap(tester, source: source);
    await tester.tap(find.text(ko.map_rangeWeek));
    await tester.pump();
    await tester.pump();
    expect(
      [for (final a in source.asked) a.$1],
      [MapRange.today, MapRange.week],
    );
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('the range switch takes keyboard focus and a screen reader tap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    tester.semantics.tap(find.semantics.byLabel(ko.map_rangeWeek));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel(ko.map_rangeWeek)),
      isSemantics(isSelected: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(PressableSurface),
        matching: find.byType(Focus),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  group('entry point', () {
    testWidgets('shown by default', (tester) async {
      final app = TestApp();
      await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
      expect(app.services.mapView.value, isTrue);
      expect(find.bySemanticsLabel(ko.map_openLabel), findsOneWidget);
    });

    testWidgets('hidden while the switch is off', (tester) async {
      final app = TestApp();
      app.services.mapView.value = false;
      await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
      expect(find.byTooltip(ko.map_openLabel), findsNothing);
      expect(find.bySemanticsLabel(ko.map_openLabel), findsNothing);
    });

    testWidgets('shows once the switch is on and opens the map', (
      tester,
    ) async {
      final app = TestApp();
      app.services.mapView.value = false;
      await tester.pumpWidget(app.wrap(const MoodSelectScreen()));
      app.services.mapView.value = true;
      await tester.pump();
      expect(find.bySemanticsLabel(ko.map_openLabel), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ko.map_openLabel));
      await tester.pump();
      await tester.pump();
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets(
      'back button and range toggle sit in the top row under SafeArea',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final app = TestApp();
        await tester.pumpWidget(
          app.wrap(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(top: 44),
              ),
              child: MapScreen(
                source: _FixedSource(_snapshot()),
                grid: _FakeGrid(),
                backdrop: (_, _) => const SizedBox.expand(),
              ),
            ),
          ),
        );
        final backRect = tester.getRect(find.bySemanticsLabel(ko.common_back));
        final todayRect = tester.getRect(find.text(ko.map_rangeToday));
        final weekRect = tester.getRect(find.text(ko.map_rangeWeek));
        expect(backRect.top, greaterThanOrEqualTo(44));
        expect(backRect.bottom, lessThan(140));
        expect(backRect.left, lessThan(60));
        expect(todayRect.top, greaterThanOrEqualTo(44));
        expect(todayRect.bottom, lessThan(140));
        expect(weekRect.right, greaterThan(330));
      },
    );

    testWidgets('empty map and SampleMapSource show distinct notices', (
      tester,
    ) async {
      await _pumpMap(
        tester,
        source: _FixedSource(MapSnapshot(cells: const [])),
      );
      expect(find.text(ko.map_empty), findsOneWidget);

      await _pumpMap(tester, source: const SampleMapSource());
      expect(find.text(ko.map_sampleNotice), findsOneWidget);
    });

    testWidgets('sheet handle collapses and expands the sheet', (tester) async {
      await _pump(tester);
      expect(find.text(ko.map_explain), findsOneWidget);
      await tester.tap(find.byKey(const Key('sheetHandle')));
      await tester.pump();
      expect(find.text(ko.map_explain), findsNothing);
      await tester.tap(find.byKey(const Key('sheetHandle')));
      await tester.pump();
      expect(find.text(ko.map_explain), findsOneWidget);
    });

    testWidgets('a slow drag down past the distance folds the sheet too', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text(ko.map_explain), findsOneWidget);
      final handle = find.byKey(const Key('sheetHandle'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      for (var i = 0; i < 22; i++) {
        await gesture.moveBy(const Offset(0, 5));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pump();
      expect(find.text(ko.map_explain), findsNothing);
    });

    testWidgets('a short slow drag leaves the sheet open', (tester) async {
      await _pump(tester);
      final handle = find.byKey(const Key('sheetHandle'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, 5));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pump();
      expect(find.text(ko.map_explain), findsOneWidget);
    });

    testWidgets('tapping empty background clears picked neighborhood', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('9'));
      await tester.pump();
      expect(find.text(ko.map_pickedPlace), findsOneWidget);
      await tester.tapAt(const Offset(20, 500));
      await tester.pump();
      expect(find.text(ko.map_pickedPlace), findsNothing);
    });
  });
}
