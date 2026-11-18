import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/fill_gauge.dart';
import 'package:mood_clicker/domain/mood.dart';

Map<String, Object?> moodsWith(int size) => {
  for (final mood in Mood.values)
    mood.id: <String, Object?>{
      for (final stage in CheerStage.values)
        stage.id: <Object?>[
          for (var i = 0; i < size; i++) '${mood.index}${stage.id[0]}$i',
        ],
    },
};

String fileOf(Map<String, Object?> moods) =>
    jsonEncode({'version': 1, 'moods': moods});

CheerBook bookOf(int size) => CheerBook.parse(fileOf(moodsWith(size))).book;

void main() {
  group('parse', () {
    test('reads every mood and stage', () {
      final book = bookOf(3);
      expect(book.bundle(Mood.sad, CheerStage.full), ['3f0', '3f1', '3f2']);
    });

    test('rejects a wrong version and non-object roots', () {
      expect(() => CheerBook.parse('[]'), throwsFormatException);
      expect(
        () => CheerBook.parse('{"version":2,"moods":{}}'),
        throwsFormatException,
      );
    });

    test('rejects an unknown mood id', () {
      final moods = moodsWith(2)..['bored'] = moodsWith(2)['happy'];
      expect(() => CheerBook.parse(fileOf(moods)), throwsFormatException);
    });

    test('rejects an empty bundle, a missing stage and a missing mood', () {
      final empty = moodsWith(2);
      (empty['happy']! as Map)['low'] = <String>[];
      expect(() => CheerBook.parse(fileOf(empty)), throwsFormatException);

      final noStage = moodsWith(2);
      (noStage['happy']! as Map).remove('full');
      expect(() => CheerBook.parse(fileOf(noStage)), throwsFormatException);

      final noMood = moodsWith(2)..remove('anxious');
      expect(() => CheerBook.parse(fileOf(noMood)), throwsFormatException);
    });

    test('rejects blank or non-string phrases', () {
      final blank = moodsWith(2);
      (blank['happy']! as Map)['low'] = ['ok', '  '];
      expect(() => CheerBook.parse(fileOf(blank)), throwsFormatException);

      final number = moodsWith(2);
      (number['happy']! as Map)['low'] = ['ok', 3];
      expect(() => CheerBook.parse(fileOf(number)), throwsFormatException);
    });

    test('warns, but still loads, for a phrase over 12 characters', () {
      final moods = moodsWith(2);
      (moods['happy']! as Map)['low'] = ['short', 'x' * 13, 'y' * 12];
      final parsed = CheerBook.parse(fileOf(moods));
      expect(parsed.warnings, hasLength(1));
      expect(parsed.warnings.single, contains('happy/low'));
      expect(parsed.book.bundle(Mood.happy, CheerStage.low), hasLength(3));
    });

    test('counts characters, not bytes, for the length warning', () {
      final moods = moodsWith(2);
      (moods['happy']! as Map)['low'] = ['\u{1F600}' * 12, 'a'];
      expect(CheerBook.parse(fileOf(moods)).warnings, isEmpty);
    });
  });

  group('stage', () {
    final t0 = DateTime(2026, 11, 18, 12);
    FillGauge taps(int n) {
      var g = const FillGauge.empty();
      for (var i = 0; i < n; i++) {
        g = g.tap(t0);
      }
      return g;
    }

    test('follows the level: below half, half or more, full', () {
      expect(CheerStage.of(taps(1), t0), CheerStage.low);
      expect(CheerStage.of(taps(19), t0), CheerStage.low);
      expect(CheerStage.of(taps(20), t0), CheerStage.high);
      expect(CheerStage.of(taps(39), t0), CheerStage.high);
      expect(CheerStage.of(taps(40), t0), CheerStage.full);
    });
  });

  group('picker', () {
    test('only picks from the bundle of the asked mood and stage', () {
      final picker = CheerPicker(Random(1));
      final book = bookOf(4);
      for (var i = 0; i < 30; i++) {
        expect(
          picker.pick(book, Mood.angry, CheerStage.high),
          startsWith('2h'),
        );
      }
    });

    test('a bundle of 8 or fewer never repeats the phrase just before', () {
      final picker = CheerPicker(Random(2));
      final book = bookOf(8);
      String? last;
      for (var i = 0; i < 300; i++) {
        final phrase = picker.pick(book, Mood.happy, CheerStage.low);
        expect(phrase, isNot(last));
        last = phrase;
      }
    });

    test('a bundle of one still answers', () {
      final picker = CheerPicker(Random(3));
      final book = bookOf(1);
      expect(picker.pick(book, Mood.sad, CheerStage.low), '3l0');
      expect(picker.pick(book, Mood.sad, CheerStage.low), '3l0');
    });

    test('a bigger bundle never repeats within the last 8 picks', () {
      final picker = CheerPicker(Random(4));
      final book = bookOf(12);
      final picks = [
        for (var i = 0; i < 400; i++)
          picker.pick(book, Mood.excited, CheerStage.high),
      ];
      for (var i = 0; i < picks.length; i++) {
        final window = picks.sublist(max(0, i - 8), i);
        expect(window, isNot(contains(picks[i])), reason: 'pick $i');
      }
    });

    test('a bundle of 9 uses every phrase over time', () {
      final picker = CheerPicker(Random(5));
      final book = bookOf(9);
      final seen = {
        for (var i = 0; i < 200; i++)
          picker.pick(book, Mood.happy, CheerStage.low),
      };
      expect(seen, hasLength(9));
    });

    test('the same seed gives the same sequence', () {
      List<String> run() {
        final picker = CheerPicker(Random(7));
        final book = bookOf(10);
        return [
          for (var i = 0; i < 20; i++)
            picker.pick(book, Mood.happy, CheerStage.low),
        ];
      }

      expect(run(), run());
    });
  });
}
