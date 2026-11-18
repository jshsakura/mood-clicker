import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/l10n/locale_choice.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';
import 'package:mood_clicker/settings/settings.dart';
import 'package:mood_clicker/settings/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemorySettingsStore implements SettingsStore {
  Settings settings = const Settings();

  @override
  Future<Settings> read() async => settings;

  @override
  Future<void> write(Settings value) async => settings = value;
}

void main() {
  test(
    'a person who saved the basic pack keeps it, a new one gets the default',
    () async {
      SharedPreferences.setMockInitialValues({'settings.soundPack': 'basic'});
      final saved = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      expect((await saved.read()).soundPack, SoundPack.basic);
      SharedPreferences.setMockInitialValues({});
      final fresh = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      expect((await fresh.read()).soundPack, SoundPack.defaultPack);
      expect(SoundPack.defaultPack, SoundPack.pentatonic);
    },
  );

  test('defaults cover every section', () {
    const settings = Settings();
    expect(settings.theme, 'light');
    expect(settings.language, LocaleChoice.system);
    expect(settings.hapticsOn, isTrue);
    expect(settings.hapticStrength, HapticStrength.normal);
    expect(settings.soundOn, isTrue);
    expect(settings.soundPack, SoundPack.pentatonic);
    expect(settings.cheersOn, isTrue);
    expect(settings.cheerSize, CheerSize.normal);
    expect(settings.shakeOnFull, isTrue);
    // The canvas default: pouring is part of the toy, so it starts on.
    expect(settings.tiltToPour, isTrue);
    expect(settings.reminder, const ReminderSettings());
    expect(settings.mapContribute, isFalse);
    expect(settings.mapComment, isFalse);
    // The map is a core feature, so its entry starts on.
    expect(settings.mapView, isTrue);
    expect(Settings.mapViewDefault, isTrue);
  });

  test('themeChoice resolves the stored name', () {
    expect(const Settings().themeChoice, const ThemeChoice.named('light'));
    expect(const Settings(theme: 'system').themeChoice, ThemeChoice.system);
    expect(
      const Settings(theme: 'pink').themeChoice,
      const ThemeChoice.named('pink'),
    );
  });

  group('shared preferences store', () {
    test('reads defaults from an empty store', () async {
      SharedPreferences.setMockInitialValues(const {});
      final store = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      expect(await store.read(), const Settings());
    });

    test('round trips every field', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesSettingsStore(prefs);
      const next = Settings(
        theme: 'dark',
        language: LocaleChoice.ja,
        hapticsOn: false,
        hapticStrength: HapticStrength.strong,
        soundOn: false,
        soundPack: SoundPack.basic,
        cheersOn: false,
        cheerSize: CheerSize.large,
        shakeOnFull: false,
        tiltToPour: false,
        reminder: ReminderSettings(enabled: true, hour: 22),
        mapView: false,
        mapContribute: true,
        mapComment: true,
      );
      await store.write(next);
      expect(await store.read(), next);
    });

    test('keeps the reminder keys the reminder subsystem shipped', () async {
      // An install that set the reminder before the settings screen exists
      // must keep its alarm.
      SharedPreferences.setMockInitialValues(const {
        'reminder.enabled': true,
        'reminder.minutes': 20 * 60,
      });
      final store = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      final settings = await store.read();
      expect(settings.reminder.enabled, isTrue);
      expect(settings.reminder.hour, 20);
    });

    test('unknown stored values fall back to the defaults', () async {
      SharedPreferences.setMockInitialValues(const {
        'settings.theme': 'neon',
        'settings.hapticStrength': 'extreme',
        'settings.language': 'klingon',
      });
      final store = SharedPreferencesSettingsStore(
        await SharedPreferences.getInstance(),
      );
      final settings = await store.read();
      expect(settings.theme, 'light');
      expect(settings.hapticStrength, HapticStrength.normal);
      expect(settings.language, LocaleChoice.system);
    });
  });

  group('reminder adapter over the settings store', () {
    test('reads and writes the reminder slice only', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesSettingsStore(prefs);
      await store.write(
        const Settings(
          theme: 'pink',
          reminder: ReminderSettings(enabled: true),
        ),
      );
      final adapter = SettingsReminderSettingsStore(store);

      expect(await adapter.read(), const ReminderSettings(enabled: true));

      await adapter.write(
        const ReminderSettings(enabled: true, hour: 22, minute: 30),
      );
      final settings = await store.read();
      expect(settings.theme, 'pink');
      expect(
        settings.reminder,
        const ReminderSettings(enabled: true, hour: 22, minute: 30),
      );
    });
  });
}
