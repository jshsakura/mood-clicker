import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/token_preview.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'preview_host.dart';

void main() {
  testWidgets('switching to pink repaints the screen with the pink ground', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewHost());
    await tester.tap(find.text('pink'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(context.palette.name, pinkPalette.name);
    expect(Theme.of(context).scaffoldBackgroundColor, pinkPalette.ground);
  });

  testWidgets('every theme renders the preview without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewHost());
    for (final name in allPalettes.map((p) => p.name)) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a button is shown for system and for every palette', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewHost());
    for (final label in ['system', ...allPalettes.map((p) => p.name)]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a palette added later shows up as a button', (tester) async {
    final mint = lightPalette.copyWith(name: 'mint');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(lightPalette),
        home: TokenPreview(
          choice: ThemeChoice.system,
          choices: ThemeChoice.fromPalettes([...allPalettes, mint]),
          onChoice: (_) {},
        ),
      ),
    );
    expect(find.text('mint'), findsOneWidget);
  });
}
