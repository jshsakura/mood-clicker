import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'preview_host.dart';

void main() {
  testWidgets('a theme switch lands in one frame, with no blended colors', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewHost());
    for (final target in [darkPalette, pinkPalette, lightPalette]) {
      await tester.tap(find.text(target.name));
      await tester
          .pump(); // the first frame that draws the state changed by the tap
      await tester.pump(const Duration(milliseconds: 16));

      final context = tester.element(find.byType(Scaffold));
      expect(context.palette.name, target.name);
      // With a theme transition animation this frame would blend the old and new colors.
      expect(context.palette.ink, target.ink);
      expect(Theme.of(context).scaffoldBackgroundColor, target.ground);
    }
  });
}
