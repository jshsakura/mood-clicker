import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/breathing_ring.dart';
import 'package:mood_clicker/design/parts/dawn_wash.dart';
import 'package:mood_clicker/design/parts/settle_line.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/tuning.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/app_localizations_en.g.dart';
import 'package:mood_clicker/l10n/app_localizations_ja.g.dart';
import 'package:mood_clicker/l10n/app_localizations_ko.g.dart';

Widget host(Widget child, {bool reduce = false}) => MaterialApp(
  theme: buildTheme(lightPalette),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

Rect ringBox(WidgetTester tester) => tester.getRect(
  find.descendant(
    of: find.byType(BreathingRingView),
    matching: find.byType(DecoratedBox),
  ),
);

Color ringColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(BreathingRingView),
      matching: find.byType(DecoratedBox),
    ),
  );
  return ((box.decoration as ShapeDecoration).shape as CircleBorder).side.color;
}

void main() {
  group('breath', () {
    test(
      'is empty at the start, full after the inhale, empty after the exhale',
      () {
        expect(breathAt(Duration.zero), 0);
        expect(breathAt(ReleaseTuning.inhale), closeTo(1, 1e-9));
        expect(
          breathAt(ReleaseTuning.inhale + ReleaseTuning.exhale),
          closeTo(0, 1e-9),
        );
      },
    );

    test(
      'grows during the inhale, shrinks during the exhale, then repeats',
      () {
        double at(int ms) => breathAt(Duration(milliseconds: ms));
        expect(at(1000), lessThan(at(2000)));
        expect(at(2000), lessThan(at(3500)));
        expect(at(5000), greaterThan(at(8000)));
        expect(at(8000), greaterThan(at(9500)));
        expect(at(12000), closeTo(at(2000), 1e-9));
      },
    );

    test('the exhale is longer than the inhale', () {
      expect(ReleaseTuning.exhale, greaterThan(ReleaseTuning.inhale));
    });
  });

  group('breathing ring', () {
    testWidgets('grows and shrinks on its own', (tester) async {
      await tester.pumpWidget(host(const BreathingRing(diameter: 200)));
      final start = ringBox(tester).width;
      await tester.pump(ReleaseTuning.inhale);
      final full = ringBox(tester).width;
      await tester.pump(ReleaseTuning.exhale);
      final end = ringBox(tester).width;
      expect(full, greaterThan(start));
      expect(full, closeTo(200, 1));
      expect(end, closeTo(start, 1));
    });

    testWidgets('with reduced motion the size stays and the brightness moves', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const BreathingRing(diameter: 200), reduce: true),
      );
      final size = ringBox(tester).width;
      final dim = ringColor(tester).a;
      await tester.pump(ReleaseTuning.inhale);
      expect(ringBox(tester).width, size);
      expect(ringColor(tester).a, greaterThan(dim));
    });

    testWidgets('is described once for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const BreathingRing(diameter: 200)));
      expect(
        find.bySemanticsLabel(AppLocalizationsKo().release_breathingRing),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('dawn wash', () {
    DawnWashPainter painter(double progress) => DawnWashPainter(
      progress: progress,
      water: lightPalette.fill,
      yellow: lightPalette.dawnYellow,
      mint: lightPalette.dawnMint,
      peach: lightPalette.dawnPeach,
    );

    test('repaints only when something it draws changes', () {
      expect(painter(0.5).shouldRepaint(painter(0.5)), isFalse);
      expect(painter(0.5).shouldRepaint(painter(0.6)), isTrue);
    });

    testWidgets('fills its parent and draws at every progress', (tester) async {
      for (final progress in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(host(DawnWash(progress: progress)));
        expect(tester.takeException(), isNull);
      }
    });

    test(
      'every theme has the three dawn colors and dark ones are not glaring',
      () {
        for (final palette in allPalettes) {
          for (final c in [
            palette.dawnYellow,
            palette.dawnMint,
            palette.dawnPeach,
          ]) {
            expect(c.a, 1);
          }
        }
        for (final palette in allPalettes.where((p) => p.name == 'dark')) {
          for (final c in [
            palette.dawnYellow,
            palette.dawnMint,
            palette.dawnPeach,
          ]) {
            expect(c.computeLuminance(), lessThan(0.15));
          }
        }
      },
    );
  });

  group('settle line', () {
    test('only the heavy moods get a line, each in its own words', () {
      for (final l10n in [
        AppLocalizationsKo(),
        AppLocalizationsEn(),
        AppLocalizationsJa(),
      ]) {
        expect(settleLineFor(l10n, Mood.happy), isNull);
        expect(settleLineFor(l10n, Mood.excited), isNull);
        final lines = {
          for (final m in [Mood.angry, Mood.sad, Mood.anxious])
            settleLineFor(l10n, m),
        };
        expect(lines.length, 3);
        expect(lines, isNot(contains(null)));
      }
    });

    test('the Korean lines do not claim the mood is gone or better', () {
      const claims = ['풀렸', '나아', '나았', '치료', '해소', '사라']; // slop-ok
      final ko = AppLocalizationsKo();
      for (final m in [Mood.angry, Mood.sad, Mood.anxious]) {
        final line = settleLineFor(ko, m)!;
        for (final claim in claims) {
          expect(line.contains(claim), isFalse, reason: '$m: $claim');
        }
      }
    });

    testWidgets('floats up, stays four seconds, then is gone', (tester) async {
      await tester.pumpWidget(host(const SettleLine(text: 'line')));
      expect(find.text('line'), findsOneWidget);
      await tester.pump(Motion.page);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        closeTo(1, 1e-9),
      );
      await tester.pump(ReleaseTuning.settleLineHold ~/ 2);
      expect(find.text('line'), findsOneWidget);
      await tester.pump(
        ReleaseTuning.settleLineHold ~/ 2 + Motion.page + Motion.page,
      );
      expect(find.text('line'), findsNothing);
    });

    testWidgets('with reduced motion it fades without moving', (tester) async {
      await tester.pumpWidget(
        host(const SettleLine(text: 'line'), reduce: true),
      );
      await tester.pump(Motion.page ~/ 2);
      final move = tester.widget<Transform>(
        find
            .ancestor(of: find.text('line'), matching: find.byType(Transform))
            .first,
      );
      expect(move.transform.getTranslation().y, 0);
    });
  });
}
