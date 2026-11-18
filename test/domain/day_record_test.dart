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
      () => record.tallies[Mood.happy] = MoodTally(
        count: 1,
        lastTapAt: t0,
        lastOrder: 1,
      ),
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

  test('a tie on count and on last tap time resolves by tap order', () {
    final first = MoodTally(count: 2, lastTapAt: t0, lastOrder: 1);
    final second = MoodTally(count: 2, lastTapAt: t0, lastOrder: 2);
    final forward = DayRecord(day, {Mood.happy: first, Mood.sad: second});
    final backward = DayRecord(day, {Mood.sad: second, Mood.happy: first});
    expect(forward.dominantMood, Mood.sad);
    expect(backward.dominantMood, Mood.sad);
  });

  test('"later" is the order of taps, not the clock', () {
    // The clock was set back between the two taps: the sad tap came last in order,
    // although its timestamp is earlier.
    final record = DayRecord.empty(
      day,
    ).withTap(Mood.happy, at(100)).withTap(Mood.sad, at(50));
    expect(record.dominantMood, Mood.sad);
  });

  test('tap order keeps counting up across moods', () {
    final record = tapAll([(Mood.happy, 0), (Mood.sad, 1), (Mood.happy, 2)]);
    expect(record.tallies[Mood.happy]!.lastOrder, 3);
    expect(record.tallies[Mood.sad]!.lastOrder, 2);
  });

  group('note of the day', () {
    test('a new record has no note and no preset', () {
      final record = DayRecord.empty(day);
      expect(record.note, isNull);
      expect(record.notePresetId, isNull);
    });

    test(
      'withNote sets a trimmed note and a preset id, leaving the old record alone',
      () {
        final old = DayRecord.empty(day).withTap(Mood.happy, t0);
        final next = old.withNote(note: '  good day  ', presetId: 'good_day');
        expect(next.note, 'good day');
        expect(next.notePresetId, 'good_day');
        expect(old.note, isNull);
        expect(next.countOf(Mood.happy), 1);
      },
    );

    test('a blank note becomes no note', () {
      final record = DayRecord.empty(day).withNote(note: '   ');
      expect(record.note, isNull);
    });

    test('a note may be exactly 40 characters, 41 is refused', () {
      expect(DayRecord.empty(day).withNote(note: 'a' * 40).note, hasLength(40));
      expect(
        () => DayRecord.empty(day).withNote(note: 'a' * 41),
        throwsArgumentError,
      );
    });

    test('characters are counted as people see them, not as code units', () {
      final forty = '\u{1F600}' * 40;
      expect(DayRecord.empty(day).withNote(note: forty).note, forty);
      expect(
        () => DayRecord.empty(day).withNote(note: '\u{1F600}' * 41),
        throwsArgumentError,
      );
    });

    test('line breaks and control characters are refused', () {
      for (final bad in ['a\nb', 'a\rb', 'a\tb', 'a\u0000b']) {
        expect(
          () => DayRecord.empty(day).withNote(note: bad),
          throwsArgumentError,
          reason: bad,
        );
      }
    });

    test('a preset id must be a short lowercase id', () {
      for (final ok in ['a', 'good_day', 'p12', 'x' * 32]) {
        expect(DayRecord.empty(day).withNote(presetId: ok).notePresetId, ok);
      }
      for (final bad in ['', 'Good', 'a b', 'a-b', 'x' * 33, '\ud55c\uae00']) {
        expect(
          () => DayRecord.empty(day).withNote(presetId: bad),
          throwsArgumentError,
          reason: bad,
        );
      }
    });

    test('withNote replaces both values, so clearing is possible', () {
      final set = DayRecord.empty(day).withNote(note: 'hi', presetId: 'hello');
      final cleared = set.withNote();
      expect(cleared.note, isNull);
      expect(cleared.notePresetId, isNull);
    });

    test('taps keep the note', () {
      final record = DayRecord.empty(
        day,
      ).withNote(note: 'hi', presetId: 'hello').withTap(Mood.sad, t0);
      expect(record.note, 'hi');
      expect(record.notePresetId, 'hello');
    });

    test(
      'the note is asked for once: only after filling the gauge and while there is none',
      () {
        final record = DayRecord.empty(day).withTap(Mood.happy, t0);
        expect(record.shouldAskNote(filledThisVisit: true), isTrue);
        expect(record.shouldAskNote(filledThisVisit: false), isFalse);
        expect(
          record.withNote(note: 'x').shouldAskNote(filledThisVisit: true),
          isFalse,
        );
        expect(
          record.withNote(presetId: 'x').shouldAskNote(filledThisVisit: true),
          isFalse,
        );
      },
    );
  });

  group('spilled taps', () {
    test('take taps off one mood and leave the others', () {
      final record = tapAll([
        (Mood.happy, 0),
        (Mood.happy, 1),
        (Mood.happy, 2),
        (Mood.sad, 3),
      ]);
      final next = record.withTapsRemoved(Mood.happy, 2);
      expect(next.countOf(Mood.happy), 1);
      expect(next.countOf(Mood.sad), 1);
      expect(record.countOf(Mood.happy), 3);
    });

    test('never go below zero, and an emptied mood leaves the record', () {
      final record = tapAll([(Mood.happy, 0), (Mood.sad, 1)]);
      final next = record.withTapsRemoved(Mood.happy, 5);
      expect(next.countOf(Mood.happy), 0);
      expect(next.tallies.containsKey(Mood.happy), isFalse);
      expect(next.dominantMood, Mood.sad);
    });

    test(
      'removing from a mood with no taps, or zero taps, changes nothing',
      () {
        final record = tapAll([(Mood.happy, 0)]);
        expect(identical(record.withTapsRemoved(Mood.sad, 3), record), isTrue);
        expect(
          identical(record.withTapsRemoved(Mood.happy, 0), record),
          isTrue,
        );
      },
    );

    test('a negative count is refused', () {
      expect(
        () => tapAll([(Mood.happy, 0)]).withTapsRemoved(Mood.happy, -1),
        throwsArgumentError,
      );
    });

    test('tap order and the note are kept', () {
      final record = tapAll([
        (Mood.happy, 0),
        (Mood.happy, 1),
        (Mood.sad, 2),
      ]).withNote(note: 'hi', presetId: 'hello');
      final next = record.withTapsRemoved(Mood.happy, 1);
      expect(next.tallies[Mood.sad]!.lastOrder, 3);
      expect(next.tallies[Mood.happy]!.lastOrder, 2);
      expect(next.note, 'hi');
      expect(next.notePresetId, 'hello');
    });
  });
}
