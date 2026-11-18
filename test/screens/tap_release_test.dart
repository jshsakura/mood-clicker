import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/breathing_ring.dart';
import 'package:mood_clicker/design/parts/dawn_wash.dart';
import 'package:mood_clicker/design/parts/settle_line.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';

import 'fake_app.dart';

const _middle = Offset(200, 500);
final _ko = lookupAppLocalizations(const Locale('ko'));

Future<TestApp> _open(WidgetTester tester, Mood mood) async {
  final app = TestApp();
  await tester.pumpWidget(app.wrap(TapScreen(mood: mood)));
  await tester.pump(const Duration(milliseconds: 16));
  return app;
}

/// One tap, then time moves on, the way the other tap tests do it.
Future<void> _tap(WidgetTester tester, TestApp app, {int gapMs = 50}) async {
  await tester.tapAt(_middle);
  app.advance(Duration(milliseconds: gapMs));
  await tester.pump(Duration(milliseconds: gapMs));
}

Future<void> _wait(WidgetTester tester, TestApp app, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left < 50 ? left : 50;
    app.advance(Duration(milliseconds: step));
    await tester.pump(Duration(milliseconds: step));
    left -= step;
  }
}

int _count(TestApp app, Mood mood) =>
    app.journal.journal.dayOf(DayKey.of(app.clock)).countOf(mood);

/// Taps until the gauge is full: the last tap is the one that fills it.
Future<void> _fill(WidgetTester tester, TestApp app) async {
  for (var i = 0; i < 60; i++) {
    await _tap(tester, app);
  }
}

void main() {
  testWidgets(
    'a full gauge of a heavy mood plays the cleansing sound, not the full one',
    (tester) async {
      final app = await _open(tester, Mood.angry);
      await _fill(tester, app);
      final ids = app.sound.played.map((p) => p.cue.id).toList();
      expect(ids.last, SoundPack.cleanseSoundId);
      expect(ids.where((id) => id == 'full'), isEmpty);
      expect(ids.where((id) => id == SoundPack.cleanseSoundId), hasLength(1));
      expect(app.sound.played.last.cue.pack, SoundPack.pentatonic);
    },
  );

  testWidgets(
    'the cleanse sound comes with the slow double haptic, never the hit',
    (tester) async {
      final app = await _open(tester, Mood.sad);
      await _fill(tester, app);
      final last = app.haptics.played.last;
      expect(last.steps, hasLength(2));
      expect(last.steps.last.delay, const Duration(milliseconds: 700));
      expect(last.ios.every((e) => e.durationMs > 0), isTrue);
    },
  );

  testWidgets('a heavy mood has no complete phrase and no shake when full', (
    tester,
  ) async {
    final app = await _open(tester, Mood.anxious);
    await _fill(tester, app);
    await tester.pump(const Duration(milliseconds: 16));
    final shake = tester
        .widgetList<Transform>(find.byType(Transform))
        .where((t) => t.transform.getTranslation().x.abs() > 0.01);
    expect(shake, isEmpty);
    expect(find.byType(DawnWash), findsOneWidget);
  });

  testWidgets('a happy mood keeps its full sound and has no dawn wash', (
    tester,
  ) async {
    final app = await _open(tester, Mood.happy);
    await _fill(tester, app);
    expect(app.sound.played.map((p) => p.cue.id), isNot(contains('cleanse')));
    expect(find.byType(DawnWash), findsNothing);
  });

  group('the steps over time', () {
    Future<TestApp> filled(WidgetTester tester) async {
      final app = await _open(tester, Mood.angry);
      await _fill(tester, app);
      return app;
    }

    testWidgets('touch is locked during the cleanse and the count stays', (
      tester,
    ) async {
      final app = await filled(tester);
      final before = _count(app, Mood.angry);
      final sounds = app.sound.played.length;
      await _wait(tester, app, 1000);
      await _tap(tester, app);
      await _wait(tester, app, 1000);
      await _tap(tester, app);
      expect(_count(app, Mood.angry), before);
      expect(app.sound.played, hasLength(sounds));
    });

    testWidgets('touch is back once the cleanse is over', (tester) async {
      final app = await filled(tester);
      await _wait(tester, app, ReleaseTuning.cleanse.inMilliseconds + 100);
      final before = _count(app, Mood.angry);
      await _tap(tester, app);
      expect(_count(app, Mood.angry), before + 1);
    });

    testWidgets('the ring and the line wait for the quiet beat', (
      tester,
    ) async {
      final app = await filled(tester);
      await _wait(tester, app, ReleaseTuning.cleanse.inMilliseconds + 300);
      expect(find.byType(BreathingRing), findsNothing);
      expect(find.byType(SettleLine), findsNothing);
      await _wait(tester, app, ReleaseTuning.stillness.inMilliseconds);
      expect(find.byType(BreathingRing), findsOneWidget);
      expect(find.text(_ko.release_settleAngry), findsOneWidget);
    });

    testWidgets('the line goes away by itself after its hold', (tester) async {
      final app = await filled(tester);
      await _wait(
        tester,
        app,
        ReleaseTuning.cleanse.inMilliseconds +
            ReleaseTuning.stillness.inMilliseconds +
            ReleaseTuning.settleLineHold.inMilliseconds +
            800,
      );
      expect(find.text(_ko.release_settleAngry), findsNothing);
    });

    testWidgets('after the cleanse the taps sound as the climbing kalimba', (
      tester,
    ) async {
      final app = await filled(tester);
      await _wait(tester, app, ReleaseTuning.cleanse.inMilliseconds + 100);
      app.sound.played.clear();
      for (var i = 0; i < 3; i++) {
        await _tap(tester, app, gapMs: 100);
      }
      expect(app.sound.played.map((p) => p.cue.id), everyElement('kalimba'));
      expect(app.sound.played.map((p) => p.pitch), [1.0, 1.122, 1.260]);
    });

    testWidgets('the order is cleanse sound, locked, then the calm tap', (
      tester,
    ) async {
      final app = await filled(tester);
      final trail = <String>[app.sound.played.last.cue.id];
      await _wait(tester, app, 1200);
      await _tap(tester, app);
      trail.add('locked:${app.sound.played.length}');
      await _wait(tester, app, ReleaseTuning.cleanse.inMilliseconds);
      await _tap(tester, app);
      trail.add(app.sound.played.last.cue.id);
      expect(trail, [
        'cleanse',
        'locked:${app.sound.played.length - 1}',
        'kalimba',
      ]);
    });
  });

  group('the approach', () {
    testWidgets(
      'the tap haptic softens from 85 percent and reaches the floor at full',
      (tester) async {
        final app = await _open(tester, Mood.sad);
        final feedback = app.services.feedback;
        for (var i = 0; i < 40; i++) {
          await _tap(tester, app);
        }
        expect(feedback.hapticEase, 1.0);
        for (var i = 0; i < 14; i++) {
          await _tap(tester, app);
        }
        expect(feedback.hapticEase, lessThan(1.0));
        expect(
          feedback.hapticEase,
          greaterThanOrEqualTo(ReleaseTuning.approachHapticFloor),
        );
      },
    );

    testWidgets('a happy mood never softens', (tester) async {
      final app = await _open(tester, Mood.happy);
      for (var i = 0; i < 55; i++) {
        await _tap(tester, app);
      }
      expect(app.services.feedback.hapticEase, 1.0);
    });

    testWidgets(
      'the settings still rule: haptics off stays silent in the cleanse',
      (tester) async {
        final app = await _open(tester, Mood.angry);
        app.services.feedback.settings = const FeedbackSettings(
          hapticsOn: false,
        );
        await _fill(tester, app);
        expect(app.haptics.played, isEmpty);
      },
    );

    testWidgets('sound off stays silent in the cleanse', (tester) async {
      final app = await _open(tester, Mood.angry);
      app.services.feedback.settings = const FeedbackSettings(soundOn: false);
      await _fill(tester, app);
      expect(app.sound.played, isEmpty);
    });
  });
}
