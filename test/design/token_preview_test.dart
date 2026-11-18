import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/main.dart';

void main() {
  testWidgets('switching to pink repaints the screen with the pink ground', (
    tester,
  ) async {
    await tester.pumpWidget(const MoodClickerApp());
    await tester.tap(find.text('pink'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(context.palette.name, pinkPalette.name);
    expect(Theme.of(context).scaffoldBackgroundColor, pinkPalette.ground);
  });

  testWidgets('every theme renders the preview without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(const MoodClickerApp());
    for (final name in ['light', 'dark', 'pink']) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
