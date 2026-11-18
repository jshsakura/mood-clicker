import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design/app_theme.dart';
import 'design/theme_choice.dart';
import 'design/token_preview.dart';
import 'l10n/app_localizations.g.dart';
import 'l10n/locale_resolution.dart';
import 'reminder/flutter_local_notifications_port.dart';
import 'reminder/reminder_controller.dart';
import 'reminder/reminder_port.dart';
import 'settings/records_port.dart';
import 'settings/settings.dart';
import 'settings/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = SharedPreferencesSettingsStore(prefs);
  final settings = await store.read();

  final notifications = FlutterLocalNotificationsPort();
  await notifications.initialize();
  final reminder = ReminderController(
    port: notifications,
    store: SettingsReminderSettingsStore(store),
  );
  await reminder.load();
  final records = DeviceRecordsPort();

  // Bring tonight's reminder in step with today's records.
  final locale = resolveAppLocale(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  );
  final l10n = await AppLocalizations.delegate.load(locale);
  await reminder.refresh(
    text: ReminderText(l10n.reminder_title, l10n.reminder_body),
    recordedToday: await records.hasRecordToday(),
  );

  runApp(MoodClickerApp(initialSettings: settings));
}

class MoodClickerApp extends StatefulWidget {
  const MoodClickerApp({super.key, this.initialSettings});

  /// Falls back to the defaults when absent, which keeps the preview tests
  /// unchanged.
  final Settings? initialSettings;

  @override
  State<MoodClickerApp> createState() => _MoodClickerAppState();
}

class _MoodClickerAppState extends State<MoodClickerApp> {
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? const Settings();
  }

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final palette = paletteFor(_settings.themeChoice, platform);
    return MaterialApp(
      title: 'Unknown',
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      // Like a system dark switch, a theme change is immediate. An animation would blend colors mid-frame and break contrast.
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _settings.language.locale,
      localeListResolutionCallback: (deviceLocales, supported) =>
          resolveAppLocale(deviceLocales ?? const [], supported),
      home: TokenPreview(
        choice: _settings.themeChoice,
        onChoice: (choice) =>
            setState(() => _settings = _settings.copyWith(theme: choice.name)),
      ),
    );
  }
}
