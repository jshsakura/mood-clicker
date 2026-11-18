import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/mood.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(int s) => t0.add(Duration(seconds: s));
  final day = DayKey.of(t0);

  DayRecord tapAll(List<(Mood, int)> taps) {
    var record = DayRecord.empty(day);
    for (final (mood, s) in taps) {
      record = record.withTap(mood, at(s));
    }
    return record;
  }

  test('empty day has no dominant mood and zero totals', () {
    final record = DayRecord.empty(day);
    expect(record.dominantMood, isNull);
    expect(record.total, 0);
    expect(record.countOf(Mood.happy), 0);
  });

  test('withTap returns a new record and leaves the old one alone', () {
    final empty = DayRecord.empty(day);
    final once = empty.withTap(Mood.sad, t0);
    expect(empty.countOf(Mood.sad), 0);
    expect(once.countOf(Mood.sad), 1);
    expect(once.tallies[Mood.sad]!.lastTapAt, t0);
  });

  test('tallies cannot be mutated from outside', () {
    final record = DayRecord.empty(day).withTap(Mood.sad, t0);
    expect(
      () => record.tallies[Mood.happy] = MoodTally(count: 1, lastTapAt: t0),
      throwsUnsupportedError,
    );
  });

  test('dominant mood is the one with the most taps', () {
    final record = tapAll([
      (Mood.happy, 0),
      (Mood.angry, 1),
      (Mood.angry, 2),
      (Mood.happy, 3),
      (Mood.angry, 4),
    ]);
    expect(record.dominantMood, Mood.angry);
  });

  test('a tie goes to the mood tapped most recently', () {
    final record = tapAll([
      (Mood.anxious, 0),
      (Mood.happy, 1),
      (Mood.happy, 2),
      (Mood.anxious, 3),
    ]);
    expect(record.dominantMood, Mood.anxious);
  });

  test('happy and sad totals are summed by side', () {
    final record = tapAll([
      (Mood.happy, 0),
      (Mood.excited, 1),
      (Mood.excited, 2),
      (Mood.angry, 3),
      (Mood.sad, 4),
      (Mood.anxious, 5),
      (Mood.anxious, 6),
    ]);
    expect(record.happyTotal, 3);
    expect(record.sadTotal, 4);
    expect(record.total, 7);
  });

  test('an out-of-order tap does not move lastTapAt backwards', () {
    final record = DayRecord.empty(
      day,
    ).withTap(Mood.happy, at(10)).withTap(Mood.happy, at(5));
    expect(record.countOf(Mood.happy), 2);
    expect(record.tallies[Mood.happy]!.lastTapAt, at(10));
  });

  test('a tap from another day is rejected', () {
    expect(
      () => DayRecord.empty(day).withTap(Mood.happy, DateTime(2026, 11, 19)),
      throwsArgumentError,
    );
  });

  test(
    'a tie on count and on last tap time resolves the same way every time',
    () {
      // 같은 시각에 같은 횟수면 선언 순서가 앞선 기분이다. 맵에 넣은 순서와 상관없다.
      final a = MoodTally(count: 2, lastTapAt: t0);
      final forward = DayRecord(day, {Mood.happy: a, Mood.sad: a});
      final backward = DayRecord(day, {Mood.sad: a, Mood.happy: a});
      expect(forward.dominantMood, Mood.happy);
      expect(backward.dominantMood, Mood.happy);
    },
  );
}
