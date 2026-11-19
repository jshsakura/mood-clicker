import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/settings/crisis_contacts.dart';
import 'package:mood_clicker/settings/crisis_sheet.dart';

/// Pumps a bare app with the crisis sheet opening from a button, so the
/// launcher can be injected.
Future<void> pumpSheet(
  WidgetTester tester, {
  required Future<bool> Function(String url) launchPhone,
  Locale locale = const Locale('ko', 'KR'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.localeTestValue = locale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final l10n = lookupAppLocalizations(const Locale('ko'));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(lightPalette),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () =>
                  showCrisisSheet(context, launchPhone: launchPhone),
              child: Text(l10n.settings_mindCareHelp),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(l10n.settings_mindCareHelp));
  await tester.pumpAndSettle();
}

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));

  testWidgets('a Korean row dials through tel', (tester) async {
    final urls = <String>[];
    await pumpSheet(
      tester,
      launchPhone: (url) async {
        urls.add(url);
        return true;
      },
    );
    await tester.tap(find.text(crisisPhoneNumbers['suicidePrevention']!));
    await tester.pumpAndSettle();
    expect(urls, ['tel:${crisisPhoneNumbers['suicidePrevention']}']);
  });

  testWidgets('the United States gets 988 by call and by text', (tester) async {
    final urls = <String>[];
    await pumpSheet(
      tester,
      locale: const Locale('en', 'US'),
      launchPhone: (url) async {
        urls.add(url);
        return true;
      },
    );
    await tester.tap(find.text(usCrisisLine).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(usCrisisLine).last);
    await tester.pumpAndSettle();
    expect(urls, ['tel:$usCrisisLine', 'sms:$usCrisisLine']);
  });

  testWidgets('a refused launcher copies the number and says so', (
    tester,
  ) async {
    var copied = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = call.arguments['text'] as String;
        }
        if (call.method == 'Clipboard.getData') return {'text': copied};
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await pumpSheet(tester, launchPhone: (url) async => false);
    await tester.tap(find.text(crisisPhoneNumbers['suicidePrevention']!));
    await tester.pumpAndSettle();
    expect(find.text(ko.settings_mindCareCopyFallback), findsOneWidget);
    expect(copied, crisisPhoneNumbers['suicidePrevention']);
  });

  testWidgets('a directory row opens the web page', (tester) async {
    final urls = <String>[];
    // No region: the sheet shows the directory row instead of any number.
    await pumpSheet(
      tester,
      locale: const Locale('ko'),
      launchPhone: (url) async {
        urls.add(url);
        return true;
      },
    );
    await tester.tap(find.text(ko.settings_mindCareFindHelpline));
    await tester.pumpAndSettle();
    expect(urls, [helplineDirectoryUrl]);
  });
}
