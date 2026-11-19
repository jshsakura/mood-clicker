/// The pure decision core of the evening reminder: given the settings, the
/// clock and whether today already has a record, say what to schedule.
library;

import 'reminder_settings.dart';

/// What the reminder system should do right now.
sealed class ReminderPlan {
  const ReminderPlan();
}

/// Clear the pending reminder.
class CancelReminder extends ReminderPlan {
  const CancelReminder();
}

/// Start (or restart) the daily series at [at], device local time.
class ScheduleReminder extends ReminderPlan {
  const ScheduleReminder(this.at);

  final DateTime at;
}

/// Next local occurrence of the reminder time strictly after [now].
DateTime nextOccurrence(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// A day that already has a record gets no reminder, so the series starts
/// the next day. A reminder left off is always a cancel.
ReminderPlan planReminder({
  required ReminderSettings settings,
  required DateTime now,
  required bool recordedToday,
}) {
  if (!settings.enabled) {
    return const CancelReminder();
  }
  final next = nextOccurrence(now, settings.hour, settings.minute);
  final laterToday =
      next.year == now.year && next.month == now.month && next.day == now.day;
  if (recordedToday && laterToday) {
    return ScheduleReminder(
      DateTime(
        next.year,
        next.month,
        next.day + 1,
        settings.hour,
        settings.minute,
      ),
    );
  }
  return ScheduleReminder(next);
}
