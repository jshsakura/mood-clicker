import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_resolution.dart';
import 'package:mood_clicker/app/app.dart';
import '../screens/fake_app.dart';

/// Pumps the same localization wiring main.dart uses and shows the localized
/// strings, so the delegates, supported locales and the fallback rule are
/// exercised end to end. It shows the Back label, because the app name is the
/// same placeholder in every language.
Future<void> pumpProbe(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (deviceLocales, supported) =>
          resolveAppLocale(deviceLocales ?? const [], supported),
      home: Builder(
        builder: (context) => Text(AppLocalizations.of(context).common_back),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('strings resolve for each supported device locale', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    await pumpProbe(tester);
    expect(find.text('\uB4A4\uB85C'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    await pumpProbe(tester);
    expect(find.text('\u623B\u308B'), findsOneWidget);
  });

  testWidgets('an unsupported device locale shows English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await pumpProbe(tester);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('the real app builds with localizations wired', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    final app = TestApp();
    await tester.pumpWidget(MoodClickerApp(services: app.services));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
