import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';

import 'time_zone.dart';

/// 서머타임이 있는 시간대(미국 동부)에서도 날짜는 기기의 자정에 바뀐다.
/// 그날의 길이가 23시간이나 25시간이어도 한 날로 센다.
void main() {
  const zone = 'America/New_York';
  final supported = hasDaylightSaving(zone);
  final skip = supported ? null : '이 환경에는 $zone 시간대 데이터가 없습니다';

  List<String> keysOfHours(DateTime startUtc, int hours) => [
    for (var h = 0; h < hours; h++)
      DayKey.of(startUtc.add(Duration(hours: h))).toString(),
  ];

  test('spring forward: the 23 hour day is one day', () {
    withTimeZone(zone, () {
      // 2026-03-08 00:00 EST 는 05:00Z. 02:00 에 한 시간 건너뛰어 그날은 23시간이다.
      final start = DateTime.utc(2026, 3, 8, 5);
      final keys = keysOfHours(start, 24);
      expect(keys.take(23).toSet(), {'2026-03-08'});
      expect(keys[23], '2026-03-09');
    });
  }, skip: skip);

  test('fall back: the 25 hour day is one day', () {
    withTimeZone(zone, () {
      // 2026-11-01 00:00 EDT 는 04:00Z. 02:00 EDT 가 01:00 EST 로 돌아가 그날은 25시간이다.
      final start = DateTime.utc(2026, 11, 1, 4);
      final keys = keysOfHours(start, 26);
      expect(keys.take(25).toSet(), {'2026-11-01'});
      expect(keys[25], '2026-11-02');
    });
  }, skip: skip);

  test('the boundary is local midnight, not the UTC date', () {
    withTimeZone(zone, () {
      // 03:59Z 는 UTC 로는 3월 9일이지만 뉴욕은 아직 8일 23:59 다.
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
