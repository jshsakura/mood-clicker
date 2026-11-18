import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/app.dart';
import 'package:mood_clicker/design/theme_choice.dart';

import '../screens/fake_app.dart';

void main() {
  testWidgets('picking a theme repaints the running app', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(MoodClickerApp(services: app.services));
    await tester.pump(const Duration(milliseconds: 600));
    Color ground() => Theme.of(
      tester.element(find.byType(Navigator)),
    ).scaffoldBackgroundColor;
    final light = ground();

    app.services.theme.value = const ThemeChoice.named('dark');
    await tester.pump();
    final dark = ground();

    app.services.theme.value = const ThemeChoice.named('pink');
    await tester.pump();

    expect(dark, isNot(light));
    expect(ground(), isNot(dark));
    expect(ground(), isNot(light));
  });
}
