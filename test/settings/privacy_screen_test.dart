import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/settings/privacy_policy.dart';
import 'package:mood_clicker/settings/privacy_screen.dart';

void main() {
  test('each language maps to its document, others to English', () {
    expect(privacyDocPath(const Locale('ko')), 'docs/privacy-policy/ko.md');
    expect(privacyDocPath(const Locale('en')), 'docs/privacy-policy/en.md');
    expect(privacyDocPath(const Locale('ja')), 'docs/privacy-policy/ja.md');
    expect(privacyDocPath(const Locale('fr')), 'docs/privacy-policy/en.md');
  });

  testWidgets('the shipped Korean document renders', (tester) async {
    await _pump(tester, const Locale('ko'));
    expect(
      find.text('\uAC1C\uC778\uC815\uBCF4 \uCC98\uB9AC\uBC29\uCE68'),
      findsWidgets,
    );
    // The draft notice stays visible at the top.
    expect(
      find.textContaining('\uBC95\uB960 \uAC80\uD1A0 \uC804 \uCD08\uC548'),
      findsOneWidget,
    );
    expect(find.textContaining('journal.json'), findsOneWidget);
    expect(find.textContaining('109'), findsWidgets);
  });

  testWidgets('the shipped English document renders', (tester) async {
    await _pump(tester, const Locale('en'));
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.textContaining('stay on the device'), findsOneWidget);
    expect(find.textContaining('not a medical device'), findsOneWidget);
  });

  testWidgets('the shipped Japanese document renders', (tester) async {
    await _pump(tester, const Locale('ja'));
    // The header title and the document heading share the same words.
    expect(
      find.text('\u30D7\u30E9\u30A4\u30D0\u30B7\u30FC\u30DD\u30EA\u30B7\u30FC'),
      findsWidgets,
    );
    expect(find.textContaining('journal.json'), findsOneWidget);
  });

  testWidgets('an unsupported locale reads the English document', (
    tester,
  ) async {
    await _pump(tester, const Locale('fr'));
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, Locale locale) async {
  // Read the shipped files synchronously: widget tests run in a fake async
  // zone where neither the asset bundle nor file IO completes twice.
  final docs = {
    for (final code in ['ko', 'en', 'ja'])
      'docs/privacy-policy/$code.md': File(
        'docs/privacy-policy/$code.md',
      ).readAsStringSync(),
  };
  final widget = PrivacyScreen(
    locale: locale,
    loadDoc: (path) async => docs[path]!,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(lightPalette),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );
  await tester.pumpAndSettle();
}
