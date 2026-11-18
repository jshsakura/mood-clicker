import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/main.dart';

void main() {
  testWidgets('a theme switch lands in one frame, with no blended colors', (
    tester,
  ) async {
    await tester.pumpWidget(const MoodClickerApp());
    for (final target in [darkPalette, pinkPalette, lightPalette]) {
      await tester.tap(find.text(target.name));
      await tester.pump(); // 눌러서 바뀐 상태를 그리는 첫 프레임
      await tester.pump(const Duration(milliseconds: 16));

      final context = tester.element(find.byType(Scaffold));
      expect(context.palette.name, target.name);
      // 테마 전환 애니메이션이 있으면 이 프레임은 옛 색과 새 색이 섞여 있다.
      expect(context.palette.ink, target.ink);
      expect(Theme.of(context).scaffoldBackgroundColor, target.ground);
    }
  });
}
