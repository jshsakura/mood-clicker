import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/reminder/reminder_planner.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';

void main() {
  const on = ReminderSettings(enabled: true);
  const onAt2030 = ReminderSettings(enabled: true, hour: 20, minute: 30);

  group('nextOccurrence', () {
    test('before the time it lands today', () {
      final now = DateTime(2026, 11, 18, 8, 0);
      expect(nextOccurrence(now, 21, 0), DateTime(2026, 11, 18, 21, 0));
    });

    test('after the time it lands tomorrow', () {
      final now = DateTime(2026, 11, 18, 22, 0);
      expect(nextOccurrence(now, 21, 0), DateTime(2026, 11, 19, 21, 0));
    });

    test('exactly at the time counts as passed', () {
      final now = DateTime(2026, 11, 18, 21, 0);
      expect(nextOccurrence(now, 21, 0), DateTime(2026, 11, 19, 21, 0));
    });

    test('just after midnight still lands today', () {
      final now = DateTime(2026, 11, 18, 0, 1);
      expect(nextOccurrence(now, 21, 0), DateTime(2026, 11, 18, 21, 0));
    });
  });

  group('planReminder', () {
    test('a disabled reminder always cancels', () {
      final plan = planReminder(
        settings: const ReminderSettings(),
        now: DateTime(2026, 11, 18, 8, 0),
        recordedToday: false,
      );
      expect(plan, isA<CancelReminder>());
    });

    test('a free day uses tonight', () {
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 11, 18, 8, 0),
        recordedToday: false,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 11, 18, 21, 0),
        ),
      );
    });

    test('a recorded day skips to tomorrow', () {
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 11, 18, 8, 0),
        recordedToday: true,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 11, 19, 21, 0),
        ),
      );
    });

    test('a day recorded after the slot stays on tomorrow', () {
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 11, 18, 22, 0),
        recordedToday: true,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 11, 19, 21, 0),
        ),
      );
    });

    test('a custom time is honored', () {
      final plan = planReminder(
        settings: onAt2030,
        now: DateTime(2026, 11, 18, 20, 0),
        recordedToday: false,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 11, 18, 20, 30),
        ),
      );
    });

    test('the plan crosses a month boundary', () {
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 11, 30, 22, 0),
        recordedToday: false,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 12, 1, 21, 0),
        ),
      );
    });

    test('the plan crosses a year boundary', () {
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 12, 31, 22, 0),
        recordedToday: false,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2027, 1, 1, 21, 0),
        ),
      );
    });

    test('a passed slot never repeats the same day', () {
      // The reminder already fired at 21:00; a refresh at 21:05 (still no
      // record) must not schedule a second one for tonight.
      final plan = planReminder(
        settings: on,
        now: DateTime(2026, 11, 18, 21, 5),
        recordedToday: false,
      );
      expect(
        plan,
        isA<ScheduleReminder>().having(
          (p) => p.at,
          'at',
          DateTime(2026, 11, 19, 21, 0),
        ),
      );
    });
  });
}
