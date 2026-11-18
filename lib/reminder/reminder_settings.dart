/// Evening reminder settings: off by default, 21:00 when turned on.
library;

import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 21,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);

  @override
  String toString() => 'ReminderSettings($enabled, $hour:$minute)';
}

/// Reads and writes the reminder settings. Shared preferences back it in
/// production; tests inject a memory version.
abstract interface class ReminderSettingsStore {
  Future<ReminderSettings> read();

  Future<void> write(ReminderSettings settings);
}

/// Stores the reminder as a bool switch plus minutes since midnight.
class SharedPreferencesReminderSettingsStore implements ReminderSettingsStore {
  SharedPreferencesReminderSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _enabledKey = 'reminder.enabled';
  static const String _minutesKey = 'reminder.minutes';
  static const int _defaultMinutes = 21 * 60;

  @override
  Future<ReminderSettings> read() async {
    final minutes = _prefs.getInt(_minutesKey) ?? _defaultMinutes;
    return ReminderSettings(
      enabled: _prefs.getBool(_enabledKey) ?? false,
      hour: minutes ~/ 60,
      minute: minutes % 60,
    );
  }

  @override
  Future<void> write(ReminderSettings settings) async {
    await _prefs.setBool(_enabledKey, settings.enabled);
    await _prefs.setInt(_minutesKey, settings.hour * 60 + settings.minute);
  }
}
