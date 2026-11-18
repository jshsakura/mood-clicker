import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/fill_gauge.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/tuning.dart';

import 'cheer_fixtures.dart';

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

    test('follows the level: below half, half or more, full, complete', () {
      expect(CheerStage.of(taps(1), t0), CheerStage.low);
      expect(CheerStage.of(taps(19), t0), CheerStage.low);
      expect(CheerStage.of(taps(20), t0), CheerStage.high);
      expect(CheerStage.of(taps(39), t0), CheerStage.high);
      // The tap that fills the gauge is the complete moment; later taps are plain full.
      expect(CheerStage.of(taps(40), t0), CheerStage.complete);
      expect(CheerStage.of(taps(41), t0), CheerStage.full);
    });

    test('complete is only for the one tap that fills the gauge', () {
      var gauge = const FillGauge.empty();
      final stages = <CheerStage>[];
      for (var i = 0; i < 45; i++) {
        gauge = gauge.tap(t0);
        stages.add(CheerStage.of(gauge, t0));
      }
      expect(stages.where((s) => s == CheerStage.complete), hasLength(1));
      expect(stages[39], CheerStage.complete);
      expect(stages.skip(40), everyElement(CheerStage.full));
    });

    test('complete uses the full font size', () {
      expect(CheerStage.complete.fontSize, CheerStage.full.fontSize);
    });
  });

  group('complete bundle', () {
    test('is optional and falls back to the full bundle', () {
      final book = bookOf(3, complete: false);
      expect(
        book.bundle(Mood.happy, CheerStage.complete),
        book.bundle(Mood.happy, CheerStage.full),
      );
      expect(
        book.effectiveStage(Mood.happy, CheerStage.complete),
        CheerStage.full,
      );
    });

    test('is used when the file has it', () {
      final book = bookOf(3);
      expect(book.bundle(Mood.happy, CheerStage.complete), [
        '0c0',
        '0c1',
        '0c2',
      ]);
      expect(
        book.effectiveStage(Mood.happy, CheerStage.complete),
        CheerStage.complete,
      );
    });

    test('may be present for one mood only', () {
      final moods = moodsWith(2, complete: false);
      (moods['sad']! as Map<String, Object?>)['complete'] = ['done!'];
      final book = CheerBook.parse(fileOf(moods)).book;
      expect(book.bundle(Mood.sad, CheerStage.complete), ['done!']);
      expect(
        book.bundle(Mood.happy, CheerStage.complete),
        book.bundle(Mood.happy, CheerStage.full),
      );
    });

    test('an empty complete bundle is an error, not a silent fallback', () {
      final moods = moodsWith(2);
      (moods['sad']! as Map<String, Object?>)['complete'] = <String>[];
      expect(() => CheerBook.parse(fileOf(moods)), throwsFormatException);
    });
  });

  group('file size and loading', () {
    test('a file over the size cap is refused before parsing', () {
      final big = 'x' * (CheerTuning.maxFileBytes + 1);
      expect(() => CheerBook.parse(big), throwsFormatException);
    });

    test('measures bytes, not characters', () {
      // Each Hangul-like character below is 3 bytes in UTF-8.
      final text = '\u3042' * (CheerTuning.maxFileBytes ~/ 3 + 1);
      expect(text.length, lessThan(CheerTuning.maxFileBytes));
      expect(() => CheerBook.parse(text), throwsFormatException);
    });

    test('the shipped phrase files stay under the cap', () {
      final dir = Directory('assets/cheers');
      final files = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      );
      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          file.lengthSync(),
          lessThanOrEqualTo(CheerTuning.maxFileBytes),
          reason: file.path,
        );
      }
    });

    test(
      'parseInBackground gives the same book without blocking the caller',
      () async {
        final text = fileOf(moodsWith(40));
        final inline = CheerBook.parse(text);
        final background = await CheerBook.parseInBackground(text);
        expect(background.warnings, inline.warnings);
        for (final mood in Mood.values) {
          for (final stage in CheerStage.values) {
            expect(
              background.book.bundle(mood, stage),
              inline.book.bundle(mood, stage),
            );
          }
        }
      },
    );

    test('parseInBackground reports a bad file as FormatException', () async {
      await expectLater(
        CheerBook.parseInBackground('[]'),
        throwsFormatException,
      );
    });
  });

  test('a repeated phrase inside one bundle is a warning', () {
    final moods = moodsWith(2);
    (moods['happy']! as Map<String, Object?>)['low'] = [
      'same',
      'same',
      'other',
    ];
    final parsed = CheerBook.parse(fileOf(moods));
    expect(
      parsed.warnings.where(
        (w) => w.contains('happy/low') && w.contains('repeated'),
      ),
      hasLength(1),
    );
  });
}
