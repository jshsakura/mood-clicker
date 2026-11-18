import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';

import 'time_zone.dart';

/// In a time zone with daylight saving (US Eastern) the day still changes at local midnight.
/// A day that lasts 23 or 25 hours still counts as one day.
void main() {
  const zone = 'America/New_York';
  final supported = hasDaylightSaving(zone);
  final skip = supported
      ? null
      : 'no time zone data for $zone in this environment';

  List<String> keysOfHours(DateTime startUtc, int hours) => [
    for (var h = 0; h < hours; h++)
      DayKey.of(startUtc.add(Duration(hours: h))).toString(),
  ];

  test('spring forward: the 23 hour day is one day', () {
    withTimeZone(zone, () {
      // 2026-03-08 00:00 EST is 05:00Z. The clock skips an hour at 02:00, so that day has 23 hours.
      final start = DateTime.utc(2026, 3, 8, 5);
      final keys = keysOfHours(start, 24);
      expect(keys.take(23).toSet(), {'2026-03-08'});
      expect(keys[23], '2026-03-09');
    });
  }, skip: skip);

  test('fall back: the 25 hour day is one day', () {
    withTimeZone(zone, () {
      // 2026-11-01 00:00 EDT is 04:00Z. 02:00 EDT falls back to 01:00 EST, so that day has 25 hours.
      final start = DateTime.utc(2026, 11, 1, 4);
      final keys = keysOfHours(start, 26);
      expect(keys.take(25).toSet(), {'2026-11-01'});
      expect(keys[25], '2026-11-02');
    });
  }, skip: skip);

  test('the boundary is local midnight, not the UTC date', () {
    withTimeZone(zone, () {
      // 03:59Z is March 9 in UTC, but it is still 23:59 on the 8th in New York.
      expect(
        DayKey.of(DateTime.utc(2026, 3, 9, 3, 59)).toString(),
        '2026-03-08',
      );
      expect(DayKey.of(DateTime.utc(2026, 3, 9, 4)).toString(), '2026-03-09');
    });
  }, skip: skip);

  test('a tap is counted on the local day it happened', () {
    withTimeZone(zone, () {
      final late = DateTime.utc(2026, 3, 9, 3, 59);
      final journal = MoodJournal.empty().withTap(Mood.happy, late);
      expect(journal.days.single.day.toString(), '2026-03-08');
    });
  }, skip: skip);
}
