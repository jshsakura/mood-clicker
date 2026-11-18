import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_resolution.dart';
import 'package:mood_clicker/main.dart';

/// Pumps the same localization wiring main.dart uses and shows the localized
/// app name, so the delegates, supported locales and the fallback rule are
/// exercised end to end.
Future<void> pumpProbe(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (deviceLocales, supported) =>
          resolveAppLocale(deviceLocales ?? const [], supported),
      home: Builder(
        builder: (context) => Text(AppLocalizations.of(context).appName),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the app name resolves for each supported device locale', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    await pumpProbe(tester);
    expect(find.text('\uAE30\uBD84 \uD074\uB9AC\uCEE4'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('ja')];
    await pumpProbe(tester);
    expect(
      find.text('\u6C17\u5206\u30AF\u30EA\u30C3\u30AB\u30FC'),
      findsOneWidget,
    );
  });

  testWidgets('an unsupported device locale shows English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await pumpProbe(tester);
    expect(find.text('Mood Clicker'), findsOneWidget);
  });

  testWidgets('the real app builds with localizations wired', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await tester.pumpWidget(const MoodClickerApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
