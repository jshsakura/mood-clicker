import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/reminder/reminder_controller.dart';
import 'package:mood_clicker/reminder/reminder_port.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';
import 'package:mood_clicker/settings/crisis_contacts.dart';
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

  @override
  Future<bool> hasRecordToday() async => recordedToday;

  @override
  Future<String?> exportJournal() async {
    exports += 1;
    return '/tmp/opencode/journal.json';
  }

  @override
  Future<void> deleteAll() async => deletions += 1;
}

Future<void> pumpScreen(
  WidgetTester tester, {
  Settings initial = const Settings(),
  required ReminderController reminder,
  required SettingsStore store,
  required RecordsPort records,
  ValueChanged<Settings>? onChanged,
}) async {
  // The settings list is long; give it a tall surface so every section
  // builds and the finders see it.
  await tester.binding.setSurfaceSize(const Size(480, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(lightPalette),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: initial.language.locale,
      home: SettingsScreen(
        initial: initial,
        store: store,
        reminder: reminder,
        records: records,
        appVersion: '1.2.3',
        onChanged: onChanged,
      ),
    ),
  );
}

ReminderController controllerWith(
  FakeNotificationPort port,
  SettingsStore store,
) {
  return ReminderController(
    port: port,
    store: SettingsReminderSettingsStore(store),
  );
}

void main() {
  testWidgets('the sections render in the current locale', (tester) async {
    final store = MemorySettingsStore(const Settings());
    await pumpScreen(
      tester,
      store: store,
      reminder: controllerWith(FakeNotificationPort(), store),
      records: FakeRecordsPort(),
    );
    final l10n = lookupAppLocalizations(const Locale('ko'));
    expect(find.text(l10n.settings_theme), findsOneWidget);
    expect(find.text(l10n.settings_tapping), findsOneWidget);
    expect(find.text(l10n.settings_notifications), findsOneWidget);
    expect(find.text(l10n.settings_mindCare), findsOneWidget);
    expect(find.text(l10n.settings_records), findsOneWidget);
    expect(find.text(l10n.settings_about), findsOneWidget);
    expect(find.text(l10n.settings_privacyPending), findsOneWidget);
  });

  testWidgets('tapping a theme card persists and applies it', (tester) async {
    final store = MemorySettingsStore(const Settings());
    Settings? applied;
    final reminder = controllerWith(FakeNotificationPort(), store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
      onChanged: (settings) => applied = settings,
    );
    await tester.tap(find.text(l10n.settings_themeDark));
    await tester.pumpAndSettle();
    expect(store.settings.theme, 'dark');
    expect(applied?.theme, 'dark');
  });

  testWidgets('picking a language stores it and notifies the app', (
    tester,
  ) async {
    final store = MemorySettingsStore(const Settings());
    Settings? applied;
    final reminder = controllerWith(FakeNotificationPort(), store);
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
      onChanged: (settings) => applied = settings,
    );
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(store.settings.language, LocaleChoice.en);
    expect(applied?.language, LocaleChoice.en);
  });

  testWidgets('turning a toggle hides its detail choices', (tester) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    // Vibration is on by default, so its strength choices are visible.
    expect(find.text(l10n.settings_vibrationStrength), findsOneWidget);
    await tester.tap(find.text(l10n.settings_vibration));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settings_vibrationStrength), findsNothing);
    expect(store.settings.hapticsOn, isFalse);
  });

  testWidgets('enabling the reminder asks for permission only then', (
    tester,
  ) async {
    final port = FakeNotificationPort();
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(port, store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    expect(port.permissionRequests, 0);
    await tester.tap(find.text(l10n.settings_reminder));
    await tester.pumpAndSettle();
    expect(port.permissionRequests, 1);
    expect(store.settings.reminder.enabled, isTrue);
    expect(find.text(l10n.settings_time21), findsOneWidget);
  });

  testWidgets('a denied permission keeps the reminder off', (tester) async {
    final port = FakeNotificationPort()..permission = false;
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(port, store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    await tester.tap(find.text(l10n.settings_reminder));
    await tester.pumpAndSettle();
    expect(store.settings.reminder.enabled, isFalse);
    expect(find.text(l10n.settings_time21), findsNothing);
  });

  testWidgets('picking a reminder time reschedules', (tester) async {
    final port = FakeNotificationPort();
    final store = MemorySettingsStore(
      const Settings(reminder: ReminderSettings(enabled: true)),
    );
    final reminder = controllerWith(port, store);
    await reminder.load();
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      initial: store.settings,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    await tester.tap(find.text(l10n.settings_time22));
    await tester.pumpAndSettle();
    expect(store.settings.reminder.hour, 22);
  });

  testWidgets('the crisis sheet shows the pinned numbers and the disclaimer', (
    tester,
  ) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    final urls = <String>[];
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    // The crisis rows dial through the injected launcher; swap it in.
    await tester.tap(find.text(l10n.settings_mindCareHelp));
    await tester.pumpAndSettle();
    for (final number in crisisPhoneNumbers.values) {
      expect(find.text(number), findsOneWidget);
    }
    expect(find.text(l10n.settings_notMedical), findsOneWidget);
    expect(urls, isEmpty);
  });

  testWidgets('a crisis number dials through the injected launcher', (
    tester,
  ) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    final urls = <String>[];
    await tester.binding.setSurfaceSize(const Size(480, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(lightPalette),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          initial: const Settings(),
          store: store,
          reminder: reminder,
          records: FakeRecordsPort(),
          appVersion: '1.2.3',
          launchPhone: (url) async {
            urls.add(url);
            return true;
          },
        ),
      ),
    );
    await tester.tap(find.text(l10n.settings_mindCareHelp));
    await tester.pumpAndSettle();
    await tester.tap(find.text(crisisPhoneNumbers['suicidePrevention']!));
    await tester.pumpAndSettle();
    expect(urls, ['tel:${crisisPhoneNumbers['suicidePrevention']}']);
  });

  testWidgets('delete all asks first and only then wipes', (tester) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    final records = FakeRecordsPort();
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: records,
    );
    await tester.tap(find.text(l10n.settings_deleteAll));
    await tester.pumpAndSettle();
    expect(records.deletions, 0);
    expect(find.text(l10n.settings_deleteConfirmBody), findsOneWidget);
    await tester.tap(find.text(l10n.settings_deleteConfirmAction));
    await tester.pumpAndSettle();
    expect(records.deletions, 1);
  });

  testWidgets('export calls the records port', (tester) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    final records = FakeRecordsPort();
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: records,
    );
    await tester.tap(find.text(l10n.settings_export));
    await tester.pumpAndSettle();
    expect(records.exports, 1);
  });

  testWidgets('the about section shows the version and opens licenses', (
    tester,
  ) async {
    final store = MemorySettingsStore(const Settings());
    final reminder = controllerWith(FakeNotificationPort(), store);
    await pumpScreen(
      tester,
      store: store,
      reminder: reminder,
      records: FakeRecordsPort(),
    );
    expect(find.text('1.2.3'), findsOneWidget);
    final l10n = lookupAppLocalizations(const Locale('ko'));
    await tester.tap(find.text(l10n.settings_licenses));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
