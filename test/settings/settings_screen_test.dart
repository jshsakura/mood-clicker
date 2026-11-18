import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/feel_settings.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/reminder/reminder_controller.dart';
import 'package:mood_clicker/reminder/reminder_port.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';
import 'package:mood_clicker/settings/crisis_contacts.dart';
import 'package:mood_clicker/settings/privacy_screen.dart';
import 'package:mood_clicker/settings/records_port.dart';
import 'package:mood_clicker/settings/settings.dart';
import 'package:mood_clicker/settings/settings_screen.dart';
import 'package:mood_clicker/settings/settings_store.dart';

class FakeNotificationPort implements NotificationPort {
  bool permission = true;
  int permissionRequests = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permission;
  }

  @override
  Future<void> scheduleDaily(int id, DateTime at, ReminderText text) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> initialTap() async => null;
}

class MemorySettingsStore implements SettingsStore {
  Settings settings;

  MemorySettingsStore(this.settings);

  @override
  Future<Settings> read() async => settings;

  @override
  Future<void> write(Settings value) async => settings = value;
}

class FakeRecordsPort implements RecordsPort {
  bool recordedToday = false;
  int exports = 0;
  int deletions = 0;
  ExportOutcome exportOutcome = ExportOutcome.shared;

  @override
  Future<bool> hasRecordToday() async => recordedToday;

  @override
  Future<ExportOutcome> exportJournal() async {
    exports += 1;
    return exportOutcome;
  }

  @override
  Future<void> deleteAll() async => deletions += 1;
}

class Harness {
  Harness({Settings settings = const Settings()}) {
    store = MemorySettingsStore(settings);
    port = FakeNotificationPort();
    reminder = ReminderController(
      port: port,
      store: SettingsReminderSettingsStore(store),
    );
    feel = ValueNotifier(settings.feelSettings);
    theme = ValueNotifier(settings.themeChoice);
    language = ValueNotifier(settings.language);
    records = FakeRecordsPort();
  }

  late final MemorySettingsStore store;
  late final FakeNotificationPort port;
  late final ReminderController reminder;
  late final ValueNotifier<FeelSettings> feel;
  late final ValueNotifier<ThemeChoice> theme;
  late final ValueNotifier<LocaleChoice> language;
  final mapView = ValueNotifier(Settings.mapViewDefault);
  late final FakeRecordsPort records;

  Future<bool> launchPhone(String url) async => true;
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required Harness harness,
  SettingsFunction? customize,
  String? deviceCountryCode,
}) async {
  // The settings list is long; give it a tall surface so every section
  // builds and the finders see it.
  await tester.binding.setSurfaceSize(const Size(480, 3600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.localesTestValue = [
    deviceCountryCode == null
        ? const Locale('ko')
        : Locale('ko', deviceCountryCode),
  ];
  tester.platformDispatcher.localeTestValue =
      tester.platformDispatcher.locales.first;
  var screen = SettingsScreen(
    store: harness.store,
    feel: harness.feel,
    theme: harness.theme,
    language: harness.language,
    mapView: harness.mapView,
    reminder: harness.reminder,
    records: harness.records,
    appVersion: '1.2.3',
    launchPhone: harness.launchPhone,
  );
  if (customize != null) {
    screen = customize(screen);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(lightPalette),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
  // Let the screen read the store.
  await tester.pump();
}

typedef SettingsFunction = SettingsScreen Function(SettingsScreen screen);

void main() {
  testWidgets('the sections render in the current locale', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    expect(find.text(l10n.settings_theme), findsOneWidget);
    expect(find.text(l10n.settings_tapping), findsOneWidget);
    expect(find.text(l10n.settings_notifications), findsOneWidget);
    expect(find.text(l10n.settings_mindCare), findsOneWidget);
    expect(find.text(l10n.settings_records), findsOneWidget);
    expect(find.text(l10n.settings_about), findsOneWidget);
  });

  testWidgets('tapping a theme card persists it and moves the app notifier', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_themeDark));
    await tester.pumpAndSettle();
    expect(harness.store.settings.theme, 'dark');
    expect(harness.theme.value, const ThemeChoice.named('dark'));
  });

  testWidgets(
    'the map switch starts on, persists its change and moves the notifier',
    (tester) async {
      final harness = Harness();
      await pumpScreen(tester, harness: harness);
      final l10n = lookupAppLocalizations(const Locale('ko'));
      expect(harness.mapView.value, isTrue);
      final label = find.text(l10n.settings_mapView);
      await tester.ensureVisible(label);
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(harness.store.settings.mapView, isFalse);
      expect(harness.mapView.value, isFalse);
    },
  );

  testWidgets('picking a language persists it and moves the app notifier', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(harness.store.settings.language, LocaleChoice.en);
    expect(harness.language.value, LocaleChoice.en);
  });

  testWidgets('turning the cheers off reaches the feel notifier', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_cheers));
    await tester.pumpAndSettle();
    expect(harness.feel.value.cheerPhrases, isFalse);
    expect(harness.store.settings.cheersOn, isFalse);
  });

  testWidgets('turning a toggle off hides its detail choices', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    // Vibration is on by default, so its strength choices are visible.
    expect(find.text(l10n.settings_strengthNormal), findsOneWidget);
    await tester.tap(find.text(l10n.settings_vibration));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settings_strengthNormal), findsNothing);
    expect(harness.store.settings.hapticsOn, isFalse);
  });

  testWidgets('enabling the reminder asks for permission only then', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    expect(harness.port.permissionRequests, 0);
    await tester.tap(find.text(l10n.settings_reminder));
    await tester.pumpAndSettle();
    expect(harness.port.permissionRequests, 1);
    expect(harness.store.settings.reminder.enabled, isTrue);
    expect(find.text(l10n.settings_time21), findsOneWidget);
  });

  testWidgets('a denied permission keeps the reminder off', (tester) async {
    final harness = Harness()..port.permission = false;
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_reminder));
    await tester.pumpAndSettle();
    expect(harness.store.settings.reminder.enabled, isFalse);
    expect(find.text(l10n.settings_time21), findsNothing);
  });

  testWidgets('picking a reminder time reschedules', (tester) async {
    final harness = Harness(
      settings: const Settings(reminder: ReminderSettings(enabled: true)),
    );
    await harness.reminder.load();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_time22));
    await tester.pumpAndSettle();
    expect(harness.store.settings.reminder.hour, 22);
  });

  testWidgets('the crisis sheet shows the pinned Korean numbers', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_mindCareHelp));
    await tester.pumpAndSettle();
    // 109 and 1577-0199 are rows; 112 and 119 stay in the footnote.
    expect(find.text(crisisPhoneNumbers['suicidePrevention']!), findsOneWidget);
    expect(
      find.text(crisisPhoneNumbers['mentalHealthCenter']!),
      findsOneWidget,
    );
    expect(find.text(l10n.settings_mindCareFootnote), findsOneWidget);
    expect(find.text(l10n.settings_mindCareIntro), findsOneWidget);
  });

  testWidgets('a crisis number dials through the launcher', (tester) async {
    final harness = Harness();
    final urls = <String>[];
    await pumpScreen(
      tester,
      harness: harness,
      customize: (screen) {
        urls.clear();
        return SettingsScreen(
          store: harness.store,
          feel: harness.feel,
          theme: harness.theme,
          language: harness.language,
          mapView: harness.mapView,
          reminder: harness.reminder,
          records: harness.records,
          appVersion: '1.2.3',
          launchPhone: (url) async {
            urls.add(url);
            return true;
          },
        );
      },
    );
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_mindCareHelp));
    await tester.pumpAndSettle();
    await tester.tap(find.text(crisisPhoneNumbers['suicidePrevention']!));
    await tester.pumpAndSettle();
    expect(urls, ['tel:${crisisPhoneNumbers['suicidePrevention']}']);
  });

  testWidgets('the Japan region swaps in the Japanese numbers', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness, deviceCountryCode: 'JP');
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_mindCareHelp));
    await tester.pumpAndSettle();
    for (final number in japanCrisisPhoneNumbers.values) {
      expect(find.text(number), findsOneWidget);
    }
    for (final number in crisisPhoneNumbers.values) {
      expect(find.text(number), findsNothing);
    }
  });

  testWidgets('delete all asks first and only then wipes', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_deleteAll));
    await tester.pumpAndSettle();
    expect(harness.records.deletions, 0);
    expect(find.text(l10n.settings_deleteConfirmBody), findsOneWidget);
    await tester.tap(find.text(l10n.settings_deleteConfirmAction));
    await tester.pumpAndSettle();
    expect(harness.records.deletions, 1);
  });

  testWidgets('export calls the records port and toasts', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_export));
    await tester.pumpAndSettle();
    expect(harness.records.exports, 1);
    expect(find.text(l10n.settings_exportDone), findsOneWidget);
  });

  testWidgets('export with no records says so and does not claim success', (
    tester,
  ) async {
    final harness = Harness();
    harness.records.exportOutcome = ExportOutcome.nothing;
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_export));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settings_exportEmpty), findsOneWidget);
    expect(find.text(l10n.settings_exportDone), findsNothing);
  });

  testWidgets('a cancelled share sheet shows no toast', (tester) async {
    final harness = Harness();
    harness.records.exportOutcome = ExportOutcome.cancelled;
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_export));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settings_exportDone), findsNothing);
    expect(find.text(l10n.settings_exportEmpty), findsNothing);
  });

  testWidgets('the back button stays while the list scrolls', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.bySemanticsLabel(l10n.common_back), findsOneWidget);
    expect(
      tester.getTopLeft(find.bySemanticsLabel(l10n.common_back)).dy,
      lessThan(80),
    );
  });

  testWidgets('the privacy row opens the policy screen', (tester) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_privacy));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  testWidgets('the about section shows the version and opens licenses', (
    tester,
  ) async {
    final harness = Harness();
    await pumpScreen(tester, harness: harness);
    expect(find.text('1.2.3'), findsOneWidget);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_licenses));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
