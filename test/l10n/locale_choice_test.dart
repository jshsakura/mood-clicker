import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/l10n/locale_choice_prefs.dart';
import 'package:mood_clicker/l10n/locale_resolution.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory store for tests, matching how production code injects a store.
class MemoryLocaleChoiceStore implements LocaleChoiceStore {
  LocaleChoice _choice = LocaleChoice.system;

  @override
  Future<LocaleChoice> read() async => _choice;

  @override
  Future<void> write(LocaleChoice choice) async => _choice = choice;
}

/// Pumps the app shell with the choice applied the way main.dart does:
/// a pinned locale goes to MaterialApp.locale, system lets the device
/// locales resolve.
Future<void> pumpWithChoice(WidgetTester tester, LocaleChoice choice) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: choice.locale,
      localeListResolutionCallback: (deviceLocales, supported) =>
          resolveAppLocale(deviceLocales ?? const [], supported),
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Column(
            children: [
              Text(l10n.settings_languageSystem),
              Text(l10n.moodSelect_moodHappy),
            ],
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('system maps to a null locale, the rest pin their locale', () {
    expect(LocaleChoice.system.locale, isNull);
    expect(LocaleChoice.ko.locale, const Locale('ko'));
    expect(LocaleChoice.en.locale, const Locale('en'));
    expect(LocaleChoice.ja.locale, const Locale('ja'));
  });

  testWidgets('a pinned choice reaches the screen strings', (tester) async {
    await pumpWithChoice(tester, LocaleChoice.ko);
    expect(find.text('\uC2DC\uC2A4\uD15C \uB530\uB984'), findsOneWidget);

    await pumpWithChoice(tester, LocaleChoice.en);
    expect(find.text('System default'), findsOneWidget);

    await pumpWithChoice(tester, LocaleChoice.ja);
    expect(
      find.text('\u30B7\u30B9\u30C6\u30E0\u306B\u5F93\u3046'),
      findsOneWidget,
    );
  });

  testWidgets('the system choice follows the device language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    await pumpWithChoice(tester, LocaleChoice.system);
    expect(find.text('\uD589\uBCF5\uD574\uC694'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await pumpWithChoice(tester, LocaleChoice.system);
    expect(find.text('Happy'), findsOneWidget);
  });

  test('language names stay in their own language in every locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.settings_languageKo, '\uD55C\uAD6D\uC5B4');
      expect(l10n.settings_languageEn, 'English');
      expect(l10n.settings_languageJa, '\u65E5\u672C\u8A9E');
    }
  });

  group('memory store', () {
    test('reads system before the first write', () async {
      final store = MemoryLocaleChoiceStore();
      expect(await store.read(), LocaleChoice.system);
    });

    test('keeps the written choice', () async {
      final store = MemoryLocaleChoiceStore();
      await store.write(LocaleChoice.ja);
      expect(await store.read(), LocaleChoice.ja);
    });
  });

  group('shared preferences store', () {
    test('round trips a choice', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesLocaleChoiceStore(prefs);
      expect(await store.read(), LocaleChoice.system);
      await store.write(LocaleChoice.en);
      expect(await store.read(), LocaleChoice.en);
    });

    test('an unknown stored value reads as system', () async {
      SharedPreferences.setMockInitialValues(const {
        'locale_choice': 'klingon',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesLocaleChoiceStore(prefs);
      expect(await store.read(), LocaleChoice.system);
    });
  });
}
