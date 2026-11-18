import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../domain/mood_journal.dart';

/// How many days back the picks count, today included.
const int shortcutWindowDays = 14;

/// How many shortcuts the icon menu shows. iOS and most Android launchers show four.
const int shortcutLimit = 4;

/// The moods to offer as icon shortcuts, most picked first.
///
/// Counts the taps of the last [days] days (today and the days before it). Moods with the same
/// count, and moods never picked, keep the default order of [Mood.values], so with no records the
/// result is happy, excited, angry, sad. Days after [today], from a clock set back, are ignored.
List<Mood> shortcutOrder(
  MoodJournal journal,
  DayKey today, {
  int days = shortcutWindowDays,
  int limit = shortcutLimit,
}) {
  final first = _daysBefore(today, days - 1);
  final counts = {for (final mood in Mood.values) mood: 0};
  for (final record in journal.days) {
    if (record.day < first || today < record.day) continue;
    for (final mood in Mood.values) {
      counts[mood] = counts[mood]! + record.countOf(mood);
    }
  }
  final ranked = [...Mood.values]
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.index.compareTo(b.index);
    });
  return ranked.take(limit).toList();
}

/// The calendar day [n] days before [day]. Computed in UTC, which has no daylight saving gaps.
DayKey _daysBefore(DayKey day, int n) {
  final d = DateTime.utc(day.year, day.month, day.day - n);
  return DayKey.tryParse(
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}',
  )!;
}
