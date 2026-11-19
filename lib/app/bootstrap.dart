import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cheer.dart';
import '../domain/cheer_picker.dart';
import '../domain/json_file_mood_repository.dart';
import '../domain/mood.dart';
import '../feedback/feedback_controller.dart';
import '../feedback/soloud_sound.dart';
import '../feedback/system_haptics.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/asset_paths.dart';
import '../l10n/locale_resolution.dart';
import '../reminder/flutter_local_notifications_port.dart';
import '../reminder/reminder_controller.dart';
import '../reminder/reminder_port.dart';
import '../settings/records_port.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_store.dart';
import '../surfaces/home_widget_adapters.dart';
import '../surfaces/native_surfaces.dart';
import 'app_services.dart';
import 'journal_store.dart';
import 'seen_hints.dart';
import 'settings_hub.dart';

/// The tilt of the phone as an angle: 0 upright, positive when the right edge leans down.
/// The accelerometer reads the direction opposite to gravity, so a right edge that goes down
/// makes x negative. The sign needs a check on a real device.
Stream<double> phoneTilt() =>
    accelerometerEventStream().map((event) => atan2(-event.x, event.y));

/// Builds the real services: files in the app's own folder, the phone's haptics, sound and tilt.
Future<AppServices> createServices({WidgetBuilder? settingsBuilder}) async {
  final folder = await getApplicationSupportDirectory();
  final journal = JournalStore(JsonFileMoodRepository(await journalFile()));
  final deckStore = JsonFileCheerDeckStore(
    File('${folder.path}/cheer_decks.json'),
  );
  final sound = SoloudSound();
  // The sound engine starts on its own; a failure leaves the app silent, never stuck.
  unawaited(sound.init());

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets().toSet();
  final books = <String, Future<CheerBook>>{};

  // Every persisted setting in one store; the feel, theme and language
  // notifiers start from it and the settings screen keeps them in step.
  final prefs = await SharedPreferences.getInstance();
  final settingsStore = SharedPreferencesSettingsStore(prefs);
  final feedback = FeedbackController(haptics: SystemHaptics(), sound: sound);
  final hub = await SettingsHub.open(store: settingsStore, feedback: feedback);

  final notifications = FlutterLocalNotificationsPort();
  await notifications.initialize();
  final reminder = ReminderController(
    port: notifications,
    store: SettingsReminderSettingsStore(settingsStore),
  );
  await reminder.load();
  final records = DeviceRecordsPort(store: journal);
  final resolvedLocale = resolveAppLocale(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  );
  final l10n = await AppLocalizations.delegate.load(resolvedLocale);
  // Bring tonight's reminder in step with today's records.
  await reminder.refresh(
    text: ReminderText(l10n.reminder_title, l10n.reminder_body),
    recordedToday: await records.hasRecordToday(),
  );

  final info = await PackageInfo.fromPlatform();
  WidgetBuilder screen =
      settingsBuilder ??
      (context) => SettingsScreen(
        store: settingsStore,
        feel: hub.feel,
        theme: hub.theme,
        language: hub.language,
        mapView: hub.mapView,
        onApplied: hub.apply,
        reminder: reminder,
        records: records,
        appVersion: info.version,
      );

  return AppServices(
    journal: journal,
    feedback: feedback,
    loadCheers: (code) => books.putIfAbsent(code, () async {
      final path = cheersAssetPath(code, assets.contains);
      final text = await rootBundle.loadString(path);
      return (await CheerBook.parseInBackground(text)).book;
    }),
    cheerPicker: await CheerPicker.open(Random(), deckStore),
    deckStore: deckStore,
    feel: hub.feel,
    tilt: phoneTilt,
    theme: hub.theme,
    language: hub.language,
    mapView: hub.mapView,
    settingsStore: settingsStore,
    hints: SharedPreferencesSeenHints(prefs),
    reminder: reminder,
    records: records,
    appVersion: info.version,
    settingsBuilder: screen,
    surfaces: NativeSurfaces(
      widget: HomeWidgetPublisher(),
      shortcuts: QuickActionsShortcuts(),
      links: HomeWidgetLaunchLinks(),
      // The app replaces this once it is running (see SurfaceSync).
      onLaunchMood: (Mood _) {},
    ),
  );
}
