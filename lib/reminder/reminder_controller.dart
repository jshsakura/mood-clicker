/// Owns the evening reminder schedule.
library;

import 'reminder_planner.dart';
import 'reminder_port.dart';
import 'reminder_settings.dart';

/// One reminder exists, so one id.
const int reminderNotificationId = 1;

/// The settings screen calls [enable], [disable] and [setTime]. The app
/// calls [refresh] on start, on resume and after every journal save, so a
/// day that already has a record skips its reminder. [NotificationPort.taps]
/// feeds the tap handling that opens mood select.
class ReminderController {
  ReminderController({required this.port, required this.store});

  final NotificationPort port;
  final ReminderSettingsStore store;

  ReminderSettings _settings = const ReminderSettings();

  ReminderSettings get settings => _settings;

  /// Loads the persisted settings. Call once before anything else.
  Future<void> load() async {
    _settings = await store.read();
  }

  /// Turns the reminder on. Permission is asked only here; when it is
  /// denied the setting stays off and this returns false.
  Future<bool> enable(
    ReminderText text, {
    required bool recordedToday,
    DateTime? now,
  }) async {
    if (!await port.requestPermission()) {
      return false;
    }
    _settings = _settings.copyWith(enabled: true);
    await store.write(_settings);
    await refresh(text: text, recordedToday: recordedToday, now: now);
    return true;
  }

  /// Turns the reminder off and clears the pending notification.
  Future<void> disable() async {
    _settings = _settings.copyWith(enabled: false);
    await store.write(_settings);
    await port.cancel(reminderNotificationId);
  }

  /// Moves the reminder time and reschedules.
  Future<void> setTime(
    int hour,
    int minute,
    ReminderText text, {
    required bool recordedToday,
    DateTime? now,
  }) async {
    _settings = _settings.copyWith(hour: hour, minute: minute);
    await store.write(_settings);
    await refresh(text: text, recordedToday: recordedToday, now: now);
  }

  /// Re-evaluates the plan. The old notification is cancelled first so a
  /// replaced id never lingers on the platform side.
  Future<void> refresh({
    required ReminderText text,
    required bool recordedToday,
    DateTime? now,
  }) async {
    final plan = planReminder(
      settings: _settings,
      now: now ?? DateTime.now(),
      recordedToday: recordedToday,
    );
    await port.cancel(reminderNotificationId);
    if (plan is ScheduleReminder) {
      await port.scheduleDaily(reminderNotificationId, plan.at, text);
    }
  }
}
