import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';

void main() {
  test('taps across midnight land on two days', () {
    final journal = MoodJournal.empty()
        .withTap(Mood.happy, DateTime(2026, 11, 18, 23, 59, 59, 900))
        .withTap(Mood.happy, DateTime(2026, 11, 18, 23, 59, 59, 950))
        .withTap(Mood.happy, DateTime(2026, 11, 19, 0, 0, 0, 50));
    final d18 = DayKey.of(DateTime(2026, 11, 18));
    final d19 = DayKey.of(DateTime(2026, 11, 19));
    expect(journal.dayOf(d18).countOf(Mood.happy), 2);
    expect(journal.dayOf(d19).countOf(Mood.happy), 1);
  });

  test('withTap leaves the original journal unchanged', () {
    final empty = MoodJournal.empty();
    final next = empty.withTap(Mood.sad, DateTime(2026, 11, 18, 9));
    expect(empty.days, isEmpty);
    expect(next.days, hasLength(1));
  });

  test('unknown day reads as an empty record', () {
    final key = DayKey.of(DateTime(2026, 1, 1));
    final record = MoodJournal.empty().dayOf(key);
    expect(record.day, key);
    expect(record.total, 0);
  });

  test('days come out in date order', () {
    final journal = MoodJournal.empty()
        .withTap(Mood.sad, DateTime(2026, 11, 20))
        .withTap(Mood.sad, DateTime(2026, 11, 18))
        .withTap(Mood.sad, DateTime(2026, 11, 19));
    expect(journal.days.map((d) => d.day.toString()), [
      '2026-11-18',
      '2026-11-19',
      '2026-11-20',
    ]);
  });

  test('two records for the same day are rejected', () {
    final key = DayKey.of(DateTime(2026, 11, 18));
    expect(
      () => MoodJournal([DayRecord.empty(key), DayRecord.empty(key)]),
      throwsArgumentError,
    );
  });
}
