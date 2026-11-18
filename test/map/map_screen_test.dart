import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/map/map_rules.dart';
import 'package:mood_clicker/map/map_screen.dart';
import 'package:mood_clicker/map/map_source.dart';
import 'package:mood_clicker/screens/mood_select_screen.dart';

import '../screens/fake_app.dart';

class _FixedSource implements MapSource {
  _FixedSource(this.snapshot);
  final MapSnapshot snapshot;

  @override
  Future<MapSnapshot> load(MapRange range) async => snapshot;
}

H3CellId _id(int n) => H3CellId('87${n.toRadixString(16).padLeft(13, '0')}');

MapSnapshot _snapshot([double happy = 0.58]) => MapSnapshot(
  viewer: _id(0),
  cells: [
    MapCell(
      id: _id(0),
      eastKm: 0,
      northKm: 0,
      people: 30,
      taps: 500,
      happyShare: happy,
      word: MapWord.ateWell,
    ),
    MapCell(
      id: _id(1),
      eastKm: 1,
      northKm: -1,
      people: 9,
      taps: 100,
      happyShare: happy,
      word: MapWord.rest,
    ),
    // Under five people, must never show.
    MapCell(
      id: _id(2),
      eastKm: 2,
      northKm: -2,
      people: 3,
      taps: 900,
      happyShare: happy,
      word: MapWord.thankful,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  RatioPolicy ratio = const RatioPolicy(),
  Mood? just,
  double happy = 0.58,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = TestApp();
  await tester.pumpWidget(
    app.wrap(
      MapScreen(
        source: _FixedSource(_snapshot(happy)),
        ratio: ratio,
        justRecorded: just,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows words for blocks of five or more, never the small one', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(ko.map_wordAteWell), findsOneWidget);
    expect(find.text(ko.map_wordRest), findsOneWidget);
    expect(find.text(ko.map_wordThankful), findsNothing);
  });

  testWidgets('a bigger tap count draws a bigger word', (tester) async {
    await _pump(tester);
    double size(String t) => tester.widget<Text>(find.text(t)).style!.fontSize!;
    expect(size(ko.map_wordAteWell), 20);
    expect(size(ko.map_wordRest), lessThan(size(ko.map_wordAteWell)));
    expect(size(ko.map_wordRest), greaterThanOrEqualTo(11));
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
    await tester.tap(find.text(ko.map_wordRest));
    await tester.pump();
    expect(find.text('"${ko.map_wordRest}"'), findsOneWidget);
    expect(find.text(ko.map_tapsLine(100)), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('the range switch reloads the map', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(ko.map_rangeWeek));
    await tester.pump();
    expect(find.text(ko.map_wordAteWell), findsOneWidget);
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
              child: MapScreen(source: _FixedSource(_snapshot())),
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
      final app = TestApp();
      await tester.pumpWidget(
        app.wrap(
          MapScreen(
            source: _FixedSource(MapSnapshot(viewer: _id(0), cells: const [])),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(ko.map_empty), findsOneWidget);

      await tester.pumpWidget(
        app.wrap(
          const MapScreen(key: ValueKey('sample'), source: SampleMapSource()),
        ),
      );
      await tester.pump();
      expect(find.text(ko.map_sampleNotice), findsOneWidget);
    });

    testWidgets('sheet handle collapses and expands the sheet', (tester) async {
      await _pump(tester);
      expect(find.text(ko.map_explain), findsOneWidget);
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      expect(find.text(ko.map_explain), findsNothing);
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      expect(find.text(ko.map_explain), findsOneWidget);
    });

    testWidgets('tapping empty background clears picked neighborhood', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text(ko.map_wordRest));
      await tester.pump();
      expect(find.text(ko.map_pickedPlace), findsOneWidget);
      await tester.tapAt(const Offset(20, 200));
      await tester.pump();
      expect(find.text(ko.map_pickedPlace), findsNothing);
    });
  });
}
