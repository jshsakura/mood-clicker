/// The boundary between the reminder logic and the notification plugin.
library;

/// Notification text, resolved per locale by the caller from the ARB keys
/// reminder_title and reminder_body.
class ReminderText {
  const ReminderText(this.title, this.body);

  final String title;
  final String body;
}

/// Payload of the reminder notification. Tapping it opens mood select.
const String moodSelectPayload = 'mood_select';

abstract interface class NotificationPort {
  /// Prepares the plugin. Runs once before anything else.
  Future<void> initialize();

  /// Asks for notification permission. The app asks only here, and only
  /// when the user turns the reminder on.
  Future<bool> requestPermission();

  /// Schedules the daily reminder series to start at [at] (device local
  /// time), replacing the plan already stored under [id].
  Future<void> scheduleDaily(int id, DateTime at, ReminderText text);

  /// Clears the reminder stored under [id].
  Future<void> cancel(int id);

  /// Payloads of notification taps while the app runs.
  Stream<String> get taps;

  /// Payload of the notification that launched the app, if any.
  Future<String?> initialTap();
}
