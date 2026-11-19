/// One store for every settings value, backed by shared preferences.
///
/// The reminder keeps the keys the reminder subsystem already shipped
/// (reminder.enabled, reminder.minutes); everything else lives under
/// settings.*. Unknown stored values fall back to the defaults.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../design/theme_choice.dart';
import '../feedback/feedback_settings.dart';
import '../l10n/locale_choice.dart';
import '../reminder/reminder_settings.dart';
import 'settings.dart';

abstract interface class SettingsStore {
  Future<Settings> read();

  Future<void> write(Settings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _theme = 'settings.theme';
  static const String _language = 'settings.language';
  static const String _hapticsOn = 'settings.hapticsOn';
  static const String _hapticStrength = 'settings.hapticStrength';
  static const String _soundOn = 'settings.soundOn';
  static const String _soundPack = 'settings.soundPack';
  static const String _cheersOn = 'settings.cheersOn';
  static const String _cheerSize = 'settings.cheerSize';
  static const String _shakeOnFull = 'settings.shakeOnFull';
  static const String _tiltToPour = 'settings.tiltToPour';
  static const String _mapView = 'settings.mapView';
  static const String _mapContribute = 'settings.mapContribute';
  static const String _mapComment = 'settings.mapComment';

  @override
  Future<Settings> read() async {
    return Settings(
      theme: _named(_prefs.getString(_theme), _themeNames, 'light'),
      language: _choice(_prefs.getString(_language)),
      hapticsOn: _prefs.getBool(_hapticsOn) ?? true,
      hapticStrength: HapticStrength.values.byName(
        _named(_prefs.getString(_hapticStrength), [
          for (final v in HapticStrength.values) v.name,
        ], HapticStrength.normal.name),
      ),
      soundOn: _prefs.getBool(_soundOn) ?? true,
      soundPack: SoundPack.values.byName(
        _named(_prefs.getString(_soundPack), [
          for (final v in SoundPack.values) v.name,
        ], SoundPack.defaultPack.name),
      ),
      cheersOn: _prefs.getBool(_cheersOn) ?? true,
      cheerSize: CheerSize.values.byName(
        _named(_prefs.getString(_cheerSize), [
          for (final v in CheerSize.values) v.name,
        ], CheerSize.normal.name),
      ),
      shakeOnFull: _prefs.getBool(_shakeOnFull) ?? true,
      tiltToPour: _prefs.getBool(_tiltToPour) ?? true,
      reminder: ReminderSettings(
        enabled: _prefs.getBool(_reminderEnabled) ?? false,
        hour: (_prefs.getInt(_reminderMinutes) ?? _defaultMinutes) ~/ 60,
        minute: (_prefs.getInt(_reminderMinutes) ?? _defaultMinutes) % 60,
      ),
      mapView: _prefs.getBool(_mapView) ?? Settings.mapViewDefault,
      mapContribute: _prefs.getBool(_mapContribute) ?? false,
      mapComment: _prefs.getBool(_mapComment) ?? false,
    );
  }

  @override
  Future<void> write(Settings settings) async {
    await _prefs.setString(_theme, settings.theme);
    await _prefs.setString(_language, settings.language.name);
    await _prefs.setBool(_hapticsOn, settings.hapticsOn);
    await _prefs.setString(_hapticStrength, settings.hapticStrength.name);
    await _prefs.setBool(_soundOn, settings.soundOn);
    await _prefs.setString(_soundPack, settings.soundPack.name);
    await _prefs.setBool(_cheersOn, settings.cheersOn);
    await _prefs.setString(_cheerSize, settings.cheerSize.name);
    await _prefs.setBool(_shakeOnFull, settings.shakeOnFull);
    await _prefs.setBool(_tiltToPour, settings.tiltToPour);
    await _prefs.setBool(_mapView, settings.mapView);
    await _prefs.setBool(_mapContribute, settings.mapContribute);
    await _prefs.setBool(_mapComment, settings.mapComment);
    await _prefs.setBool(_reminderEnabled, settings.reminder.enabled);
    await _prefs.setInt(
      _reminderMinutes,
      settings.reminder.hour * 60 + settings.reminder.minute,
    );
  }

  static const String _reminderEnabled = 'reminder.enabled';
  static const String _reminderMinutes = 'reminder.minutes';
  static const int _defaultMinutes = 21 * 60;

  static final List<String> _themeNames = [
    for (final choice in ThemeChoice.all) choice.name,
  ];

  static LocaleChoice _choice(String? name) {
    for (final choice in LocaleChoice.values) {
      if (choice.name == name) return choice;
    }
    return LocaleChoice.system;
  }

  /// A stored enum value counts only when the name still exists.
  static String _named(String? stored, List<String> names, String fallback) {
    return names.contains(stored) ? stored! : fallback;
  }
}

/// Lets the reminder controller read and write the reminder slice of
/// [SettingsStore] without a second storage.
class SettingsReminderSettingsStore implements ReminderSettingsStore {
  SettingsReminderSettingsStore(this._store);

  final SettingsStore _store;

  @override
  Future<ReminderSettings> read() async => (await _store.read()).reminder;

  @override
  Future<void> write(ReminderSettings settings) async {
    final current = await _store.read();
    await _store.write(current.copyWith(reminder: settings));
  }
}
