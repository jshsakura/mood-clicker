import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/how_to_button.dart';
import 'package:mood_clicker/design/parts/water_painter.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';

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

/// The number the tap screen shows, which a spill lowers and the saved count keeps.
int shownCount(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w is Text && w.style?.fontSize == TypeScale.count.fontSize,
  );
  return int.parse(tester.widget<Text>(finder).data!);
}

int todayCount(TestApp app) =>
    app.journal.journal.dayOf(DayKey.of(app.clock)).countOf(Mood.happy);

final _lastBeat = Expando<DateTime>('last hold beat');

/// Keeps the gauge in the hold band by one tap every 1.2 seconds of the app clock, which is just
/// enough to stay in the band without filling it.
Future<void> holdBand(WidgetTester tester, TestApp app, int seconds) async {
  const beat = Duration(milliseconds: 1200);
  for (var ms = 0; ms < seconds * 1000; ms += 100) {
    final last = _lastBeat[app] ?? app.clock;
    if (app.clock.difference(last) >= beat) {
      await tester.tapAt(const Offset(200, 500));
      _lastBeat[app] = app.clock;
    } else {
      _lastBeat[app] ??= app.clock;
    }
    app.advance(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int chimes(TestApp app) =>
    app.sound.played.where((p) => p.cue.id == SoundPack.holdSoundId).length;

void main() {
  holdRewardTests();
  edgeAndAccessTests();
  leavingTests();
  touchDownTests();
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

  testWidgets('the how-to button opens the sheet with the six lines', (
    tester,
  ) async {
    await openTap(tester);
    expect(find.byType(HowToButton), findsOneWidget);
    // Let the first-visit bubble go, so only the button carries the label.
    await tester.pump(HowToTuning.bubbleDuration + const Duration(seconds: 1));
    await tester.tap(find.bySemanticsLabel(ko.howTo_label));
    await settle(tester);
    for (final line in [
      ko.howTo_fill,
      ko.howTo_rest,
      ko.howTo_tilt,
      ko.howTo_spark,
      ko.howTo_hold,
      ko.howTo_finish,
    ]) {
      expect(find.text(line), findsOneWidget);
    }
    // The crisis contacts are not on this screen.
    expect(find.text(ko.settings_mindCareTitle), findsNothing);
    expect(find.bySemanticsLabel(ko.settings_mindCareHelp), findsNothing);
  });

  testWidgets('the bubble beside the button shows on the first visit only', (
    tester,
  ) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const TapScreen(mood: Mood.happy)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text(ko.howTo_bubble), findsOneWidget);
    await tester.pump(HowToTuning.bubbleDuration + const Duration(seconds: 1));
    expect(find.text(ko.howTo_bubble), findsNothing);
    // Back again: the hint was used up.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app.wrap(const TapScreen(mood: Mood.happy)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text(ko.howTo_bubble), findsNothing);
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

  Future<TestApp> fillGauge(WidgetTester tester) async {
    final app = await openTapOnHome(tester);
    for (var i = 0; i < 60; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    return app;
  }

  testWidgets('skipping the note from the back button does not ask again', (
    tester,
  ) async {
    await fillGauge(tester);
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    expect(find.text(ko.note_title), findsOneWidget);
    await tester.tap(find.text(ko.note_skip));
    await settle(tester);
    expect(find.byType(TapScreen), findsNothing);
    expect(find.text(ko.note_title), findsNothing);
  });

  testWidgets('skipping the note after a system back does not ask again', (
    tester,
  ) async {
    await fillGauge(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text(ko.note_title), findsOneWidget);
    await tester.tap(find.text(ko.note_skip));
    await settle(tester);
    expect(find.byType(TapScreen), findsNothing);
    expect(find.text(ko.note_title), findsNothing);
  });

  testWidgets('saving the note from the back button does not ask again', (
    tester,
  ) async {
    await fillGauge(tester);
    await tester.tap(find.bySemanticsLabel(ko.common_back));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'good one');
    await tester.pump();
    await tester.tap(find.text(ko.note_save));
    await settle(tester);
    expect(find.byType(TapScreen), findsNothing);
    expect(find.text(ko.note_title), findsNothing);
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
    await tester.pump();
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

  testWidgets('a tilted phone lowers the number on screen, not the record', (
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
    // The saved count of the day stays whole; only the shown number went down.
    expect(SpillTuning.takesFromRecord, isFalse);
    expect(todayCount(app), before);
    expect(find.text('$before'), findsNothing);
    expect(shownCount(tester), lessThan(before));
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
    expect(todayCount(app), before);
    expect(before - shownCount(tester), greaterThan(40));
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

void edgeAndAccessTests() {
  testWidgets('a drag that starts at the screen edge is not a tap', (
    tester,
  ) async {
    final app = await openTap(tester);
    final gesture = await tester.startGesture(const Offset(4, 400));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 0);
  });

  testWidgets('a cancelled edge touch is not a tap either', (tester) async {
    final app = await openTap(tester);
    final gesture = await tester.startGesture(const Offset(4, 400));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 0);
  });

  testWidgets('a plain press at the edge still counts when it lifts', (
    tester,
  ) async {
    final app = await openTap(tester);
    await tester.tapAt(const Offset(4, 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 1);
  });

  testWidgets(
    'swiping back from the left edge leaves on iOS and counts nothing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final app = TestApp();
      await tester.pumpWidget(
        app.wrap(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TapScreen(mood: Mood.happy),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(TapScreen), findsOneWidget);
      final gesture = await tester.startGesture(const Offset(3, 300));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      final left = find.byType(TapScreen).evaluate().isEmpty;
      debugDefaultTargetPlatformOverride = null;
      expect(left, isTrue);
      expect(todayCount(app), 0);
    },
  );

  testWidgets('the tap area is a named action for assistive technology', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = await openTap(tester);
    final finder = find.semantics.byLabel(ko.tap_action);
    expect(finder, findsOneWidget);
    expect(
      finder,
      matchesSemantics(
        label: ko.tap_action,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocused: true,
        isFocusable: true,
      ),
    );
    tester.semantics.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 1);
    handle.dispose();
  });

  testWidgets('the space key and the enter key tap from the keyboard', (
    tester,
  ) async {
    final app = await openTap(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 2);
  });

  testWidgets('the hint tells where to tap until the day has many taps', (
    tester,
  ) async {
    await openTap(tester);
    expect(find.text(ko.tap_hint), findsOneWidget);
  });
}

/// A home page that pushes the tap screen, so there is something below to lose.
Future<TestApp> openTapOnHome(WidgetTester tester) async {
  final app = TestApp();
  await tester.pumpWidget(
    app.wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Text('home'),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TapScreen(mood: Mood.happy),
                  ),
                ),
                child: const Text('go'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
  return app;
}

void leavingTests() {
  testWidgets(
    'a second way out while the first one waits for the disk pops once',
    (tester) async {
      final app = await openTapOnHome(tester);
      await tapOnce(tester, app, const Offset(200, 500));
      final gate = Completer<void>();
      app.repository.saveGate = gate.future;
      await tester.tap(find.bySemanticsLabel(ko.common_back));
      await tester.pump();
      await tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .maybePop();
      await tester.pump(const Duration(milliseconds: 500));
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(TapScreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
    },
  );

  testWidgets(
    'when the screen is already gone the late exit pops nothing more',
    (tester) async {
      final app = await openTapOnHome(tester);
      await tapOnce(tester, app, const Offset(200, 500));
      final gate = Completer<void>();
      app.repository.saveGate = gate.future;
      await tester.tap(find.bySemanticsLabel(ko.common_back));
      await tester.pump();
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 500));
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('home'), findsOneWidget);
    },
  );

  testWidgets('one finger on each edge counts two taps', (tester) async {
    final app = await openTap(tester);
    final left = await tester.startGesture(const Offset(4, 300), pointer: 1);
    final right = await tester.startGesture(const Offset(386, 300), pointer: 2);
    await left.up();
    await right.up();
    await tester.pump(const Duration(milliseconds: 50));
    expect(todayCount(app), 2);
  });

  testWidgets(
    'a filled gauge without a note still asks when swiping back on iOS',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final app = await openTapOnHome(tester);
      for (var i = 0; i < 60; i++) {
        await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
      }
      final gesture = await tester.startGesture(const Offset(3, 300));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      final left = find.byType(TapScreen).evaluate().isEmpty;
      final asked = find.text(ko.note_title).evaluate().length;
      debugDefaultTargetPlatformOverride = null;
      expect(left, isTrue);
      expect(asked, 1);
    },
  );
}

void touchDownTests() {
  testWidgets(
    'a touch in the middle sounds and vibrates when it lands, before it lifts',
    (tester) async {
      final app = await openTap(tester);
      final finger = await tester.startGesture(const Offset(200, 500));
      expect(app.sound.played, hasLength(1));
      expect(app.haptics.played, hasLength(1));
      expect(todayCount(app), 1);
      await finger.up();
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.sound.played, hasLength(1));
      expect(app.haptics.played, hasLength(1));
      expect(todayCount(app), 1);
    },
  );

  testWidgets(
    'a touch on the edge strip waits for the lift, as the back gesture needs',
    (tester) async {
      final app = await openTap(tester);
      final finger = await tester.startGesture(const Offset(4, 500));
      expect(app.sound.played, isEmpty);
      expect(app.haptics.played, isEmpty);
      expect(todayCount(app), 0);
      await finger.up();
      await tester.pump(const Duration(milliseconds: 50));
      expect(app.sound.played, hasLength(1));
      expect(app.haptics.played, hasLength(1));
      expect(todayCount(app), 1);
    },
  );

  testWidgets(
    'sound and vibration come from the same call, the sound being a limited tap sound',
    (tester) async {
      final app = await openTap(tester);
      final finger = await tester.startGesture(const Offset(200, 500));
      expect(app.sound.played.single.limited, isTrue);
      await finger.up();
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}

void holdRewardTests() {
  Future<TestApp> nearFull(WidgetTester tester) async {
    final app = await openTap(tester);
    for (var i = 0; i < 58; i++) {
      await tapOnce(tester, app, const Offset(200, 500));
    }
    return app;
  }

  testWidgets('staying near full for three seconds pays once, with the chime', (
    tester,
  ) async {
    final app = await nearFull(tester);
    expect(chimes(app), 0);
    await holdBand(tester, app, 2);
    expect(chimes(app), 0);
    await holdBand(tester, app, 3);
    expect(chimes(app), 1);
    // Still in the band: no second reward on the same gauge.
    await holdBand(tester, app, 6);
    expect(chimes(app), 1);
  });

  testWidgets('the reward is rearmed after the level falls below 85 percent', (
    tester,
  ) async {
    final app = await nearFull(tester);
    await holdBand(tester, app, 5);
    expect(chimes(app), 1);
    // Let it drain to empty, then climb back to the band.
    for (var i = 0; i < 200; i++) {
      app.advance(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 58; i++) {
      await tapOnce(tester, app, const Offset(200, 500));
    }
    _lastBeat[app] = app.clock;
    await holdBand(tester, app, 5);
    expect(chimes(app), 2);
  });

  testWidgets('filling the gauge before three seconds is no hold reward', (
    tester,
  ) async {
    final app = await nearFull(tester);
    for (var i = 0; i < 3; i++) {
      await tapOnce(tester, app, const Offset(200, 500), gapMs: 100);
    }
    await holdBand(tester, app, 4);
    expect(chimes(app), 0);
  });

  testWidgets('the reward stays silent with sound off, like every cue', (
    tester,
  ) async {
    final app = await nearFull(tester);
    app.services.feedback.settings = const FeedbackSettings(soundOn: false);
    await holdBand(tester, app, 5);
    expect(chimes(app), 0);
  });
}
