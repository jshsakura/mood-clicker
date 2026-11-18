import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/app.dart';
import 'package:mood_clicker/app/settings_hub.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/feedback/feedback_controller.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/reminder/reminder_controller.dart';
import 'package:mood_clicker/settings/settings.dart';
import 'package:mood_clicker/settings/settings_screen.dart';
import 'package:mood_clicker/settings/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feedback/fakes.dart';
import '../screens/fake_app.dart';
import '../settings/settings_screen_test.dart'
    show FakeNotificationPort, FakeRecordsPort;

/// Opens the settings the way the real bootstrap does, on mock shared preferences.
Future<
  ({SettingsStore store, SettingsHub hub, FakeHaptics haptics, FakeSound sound})
>
_open() async {
  final store = SharedPreferencesSettingsStore(
    await SharedPreferences.getInstance(),
  );
  final haptics = FakeHaptics();
  final sound = FakeSound();
  final feedback = FeedbackController(haptics: haptics, sound: sound);
  final hub = await SettingsHub.open(store: store, feedback: feedback);
  return (store: store, hub: hub, haptics: haptics, sound: sound);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'a language picked in settings repaints the app, stays saved and is restored on the next start',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ko')];
      tester.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.binding.setSurfaceSize(const Size(480, 3600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final first = await _open();
      final app = TestApp(
        feedback: first.hub.feedback,
        language: first.hub.language,
        theme: first.hub.theme,
        feelNotifier: first.hub.feel,
        mapView: first.hub.mapView,
        settingsBuilder: (_) => SettingsScreen(
          store: first.store,
          feel: first.hub.feel,
          theme: first.hub.theme,
          language: first.hub.language,
          mapView: first.hub.mapView,
          onApplied: first.hub.apply,
          reminder: ReminderController(
            port: FakeNotificationPort(),
            store: SettingsReminderSettingsStore(first.store),
          ),
          records: FakeRecordsPort(),
          appVersion: '1.0.0',
        ),
      );
      await tester.pumpWidget(MoodClickerApp(services: app.services));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(ko.settings_title));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ko.settings_languageEn));
      await tester.pumpAndSettle();
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, const Locale('en'));
      expect(find.text('Settings'), findsWidgets);

      // The next start reads the same preferences and comes up in English.
      final second = await _open();
      expect(second.hub.language.value, LocaleChoice.en);
    },
  );

  testWidgets(
    'theme, haptics and sound picked in settings are applied now and restored next start',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 3600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = await _open();
      expect(first.hub.feedback.settings.hapticsOn, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(lightPalette),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: SettingsScreen(
            store: first.store,
            feel: first.hub.feel,
            theme: first.hub.theme,
            language: first.hub.language,
            mapView: first.hub.mapView,
            onApplied: first.hub.apply,
            reminder: ReminderController(
              port: FakeNotificationPort(),
              store: SettingsReminderSettingsStore(first.store),
            ),
            records: FakeRecordsPort(),
            appVersion: '1.0.0',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(ko.settings_themeDark));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ko.settings_strengthStrong));
      await tester.pumpAndSettle();
      expect(first.hub.theme.value, const ThemeChoice.named('dark'));
      expect(
        first.hub.feedback.settings.hapticScale,
        HapticStrength.strong.scale,
      );

      final second = await _open();
      expect(second.hub.theme.value, const ThemeChoice.named('dark'));
      expect(second.hub.feedback.settings.hapticScale, 1.4);
      expect(second.hub.feedback.settings.hapticsOn, isTrue);
    },
  );

  test(
    'turning haptics and sound off in the stored settings silences the controller',
    () async {
      SharedPreferences.setMockInitialValues({
        'settings.hapticsOn': false,
        'settings.soundOn': false,
      });
      final opened = await _open();
      opened.hub.feedback.trigger(FeedbackKind.tap, 'happy');
      expect(opened.haptics.played, isEmpty);
      expect(opened.sound.played, isEmpty);
    },
  );

  test('the haptic strength scales what the controller plays', () async {
    final normal = await _open();
    normal.hub.feedback.trigger(FeedbackKind.select, 'happy');
    SharedPreferences.setMockInitialValues({'settings.hapticStrength': 'weak'});
    final weak = await _open();
    weak.hub.feedback.trigger(FeedbackKind.select, 'happy');
    expect(normal.haptics.played, isNotEmpty);
    expect(weak.haptics.played, isNotEmpty);
    final normalPeak = normal.haptics.played.single.ios.first.intensity;
    final weakPeak = weak.haptics.played.single.ios.first.intensity;
    expect(weakPeak, lessThan(normalPeak));
  });
}
