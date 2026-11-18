import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/help_button.dart';
import 'package:mood_clicker/design/parts/water_painter.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';

import 'fake_app.dart';

Future<TestApp> openTap(
  WidgetTester tester, {
  FeelSettings feel = const FeelSettings(),
}) async {
  final app = TestApp(feel: feel);
  await tester.pumpWidget(app.wrap(const TapScreen(mood: Mood.happy)));
  await tester.pump(const Duration(milliseconds: 16));
  return app;
}

Future<void> tapOnce(
  WidgetTester tester,
  TestApp app,
  Offset at, {
  int gapMs = 50,
}) async {
  await tester.tapAt(at);
  app.advance(Duration(milliseconds: gapMs));
  await tester.pump(Duration(milliseconds: gapMs));
}

/// The tap screen's ticker never stops, so pumpAndSettle would wait forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

int todayCount(TestApp app) =>
    app.journal.journal.dayOf(DayKey.of(app.clock)).countOf(Mood.happy);

void main() {
  testWidgets('every pointer down counts one tap and feeds back', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 3; i++) {
      await tapOnce(tester, app, const Offset(200, 500));
    }
    expect(todayCount(app), 3);
    expect(app.haptics.played, isNotEmpty);
    expect(app.sound.played.length, 3);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(ko.tap_todayLabel), findsOneWidget);
  });

  testWidgets('the tap counts when the finger lands, before it lifts', (
    tester,
  ) async {
    final app = await openTap(tester);
    final gesture = await tester.startGesture(const Offset(200, 500));
    expect(todayCount(app), 1);
    await gesture.up();
  });

  testWidgets('the help button opens the crisis sheet', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('ko', 'KR')];
    tester.platformDispatcher.localeTestValue = const Locale('ko', 'KR');
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final app = TestApp();
    await tester.pumpWidget(
      app.wrap(TapScreen(mood: Mood.happy, launchPhone: (url) async => true)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(HelpButton), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(ko.settings_mindCareHelp));
    await settle(tester);
    expect(find.text(ko.settings_mindCareTitle), findsOneWidget);
  });

  testWidgets('a tap on the back button is not a tap on the screen', (
    tester,
  ) async {
    final app = await openTap(tester);
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await tester.pump();
    expect(todayCount(app), 0);
  });

  testWidgets(
    'a phrase shows where the finger landed, on that side of the screen',
    (tester) async {
      final app = await openTap(tester);
      await tester.pump(const Duration(milliseconds: 16));
      await tapOnce(tester, app, const Offset(60, 400), gapMs: 16);
      final phrase = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('0'),
      );
      expect(phrase, findsWidgets);
      final x = tester.getCenter(phrase.first).dx;
      expect(x, lessThan(195));
    },
  );

  testWidgets('phrases are off when the setting is off', (tester) async {
    final app = await openTap(
      tester,
      feel: const FeelSettings(cheerPhrases: false),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tapOnce(tester, app, const Offset(200, 400), gapMs: 16);
    final phrase = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').startsWith('0'),
    );
    expect(phrase, findsNothing);
  });

  testWidgets('a phrase is gone after its life', (tester) async {
    final app = await openTap(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tapOnce(tester, app, const Offset(200, 400), gapMs: 16);
    await tapOnce(tester, app, const Offset(200, 400), gapMs: 1200);
    await tester.pump(const Duration(milliseconds: 16));
    final phrase = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').startsWith('0'),
    );
    expect(phrase.evaluate().length, lessThanOrEqualTo(1));
  });

  testWidgets('leaving writes the journal', (tester) async {
    final app = await openTap(tester);
    await tapOnce(tester, app, const Offset(200, 500));
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    expect(app.repository.saved, isNotEmpty);
  });

  testWidgets('filling the gauge asks for a note when leaving, once', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    expect(find.text(ko.note_title), findsOneWidget);
    await tester.tap(find.text(ko.note_skip));
    await settle(tester);
    expect(find.byType(TapScreen), findsNothing);
  });

  testWidgets('the complete shake stays inside a clipped frame', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    final frame = find.descendant(
      of: find.byType(TapScreen),
      matching: find.byType(ClipRect),
    );
    expect(frame, findsWidgets);
    final screen = tester.getRect(find.byType(Scaffold));
    for (final box in tester.widgetList<ClipRect>(frame)) {
      expect(box, isNotNull);
    }
    expect(tester.getRect(frame.first), screen);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<WaterPainter>()
        .single;
    expect(painter.bleed, CompleteTuning.shakeAmplitude);
  });

  testWidgets('leaving without filling asks nothing', (tester) async {
    final app = await openTap(tester);
    for (var i = 0; i < 10; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    expect(find.text(ko.note_title), findsNothing);
  });

  testWidgets('a note typed in the sheet is kept on the day', (tester) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'good one');
    await tester.tap(find.text(ko.note_save));
    await settle(tester);
    final record = app.journal.journal.dayOf(DayKey.of(app.clock));
    expect(record.note, 'good one');
    expect(record.notePresetId, isNull);
  });

  testWidgets('a picked preset keeps its id until the text is edited', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    await tester.tap(find.text(ko.note_presetProud));
    await tester.pump();
    await tester.tap(find.text(ko.note_save));
    await settle(tester);
    final record = app.journal.journal.dayOf(DayKey.of(app.clock));
    expect(record.notePresetId, 'proud');
    expect(record.note, ko.note_presetProud);
  });

  testWidgets('a tilted phone spills water and takes taps away', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 50; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    final before = todayCount(app);
    app.tiltEvents.add(1.3);
    for (var i = 0; i < 90; i++) {
      app.advance(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(todayCount(app), lessThan(before));
  });

  testWidgets('no spill when tilt spill is off', (tester) async {
    final app = await openTap(
      tester,
      feel: const FeelSettings(tiltSpill: false),
    );
    for (var i = 0; i < 50; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    final before = todayCount(app);
    app.tiltEvents.add(1.3);
    for (var i = 0; i < 90; i++) {
      app.advance(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(todayCount(app), before);
  });

  testWidgets('a level phone spills nothing however full', (tester) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    final before = todayCount(app);
    app.tiltEvents.add(0);
    for (var i = 0; i < 30; i++) {
      app.advance(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(todayCount(app), before);
  });

  testWidgets('a fully tilted phone keeps a little water and spills the rest', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    final before = todayCount(app);
    app.tiltEvents.add(1.48);
    for (var i = 0; i < 100; i++) {
      app.advance(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final spilled = before - todayCount(app);
    expect(spilled, greaterThan(40));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<WaterPainter>()
        .single;
    expect(painter.sim.level, greaterThan(0.05));
  });

  testWidgets('tapping a full gauge nudges the water only 0.3 as hard', (
    tester,
  ) async {
    final app = await openTap(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    final countAtFull = todayCount(app);
    for (var i = 0; i < 20; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 30);
    }
    expect(todayCount(app), countAtFull + 20);
    expect(FillTuning.fullKick, lessThan(1));
  });
}
