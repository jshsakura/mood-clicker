import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
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

void main() {
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
