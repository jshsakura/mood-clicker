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
    // Taps needed to fill the gauge, and to reach half of it.
    final full = (1 / GaugeTuning.stepPerTap).round();
    final half = full ~/ 2;
    FillGauge taps(int n) {
      var g = const FillGauge.empty();
      for (var i = 0; i < n; i++) {
        g = g.tap(t0);
      }
      return g;
    }

    test('follows the level: below half, half or more, full, complete', () {
      expect(CheerStage.of(taps(1), t0), CheerStage.low);
      expect(CheerStage.of(taps(half - 1), t0), CheerStage.low);
      expect(CheerStage.of(taps(half), t0), CheerStage.high);
      expect(CheerStage.of(taps(full - 1), t0), CheerStage.high);
      // The tap that fills the gauge is the complete moment; later taps are plain full.
      expect(CheerStage.of(taps(full), t0), CheerStage.complete);
      expect(CheerStage.of(taps(full + 1), t0), CheerStage.full);
    });

    test('complete is only for the one tap that fills the gauge', () {
      var gauge = const FillGauge.empty();
      final stages = <CheerStage>[];
      for (var i = 0; i < full + 5; i++) {
        gauge = gauge.tap(t0);
        stages.add(CheerStage.of(gauge, t0));
      }
      expect(stages.where((s) => s == CheerStage.complete), hasLength(1));
      expect(stages[full - 1], CheerStage.complete);
      expect(stages.skip(full), everyElement(CheerStage.full));
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

  group('rare bundle', () {
    test('is optional and falls back to the high bundle', () {
      final moods = moodsWith(3, rare: false);
      final book = CheerBook.parse(fileOf(moods)).book;
      expect(book.effectiveStage(Mood.sad, CheerStage.rare), CheerStage.high);
      expect(
        book.bundle(Mood.sad, CheerStage.rare),
        book.bundle(Mood.sad, CheerStage.high),
      );
    });

    test('is used when the file has it', () {
      final book = bookOf(3);
      expect(book.bundle(Mood.sad, CheerStage.rare), ['3r0', '3r1', '3r2']);
    });

    test('an empty rare bundle is an error', () {
      final moods = moodsWith(2);
      (moods['sad']! as Map<String, Object?>)['rare'] = <String>[];
      expect(() => CheerBook.parse(fileOf(moods)), throwsFormatException);
    });

    test('the stage of a gauge is never rare', () {
      var gauge = const FillGauge.empty();
      final t = DateTime(2026, 11, 18, 12);
      for (var i = 0; i < 65; i++) {
        gauge = gauge.tap(t);
        expect(CheerStage.of(gauge, t), isNot(CheerStage.rare));
      }
    });
  });

  test('lifetimes by kind and the rare chance are the agreed numbers', () {
    expect(CheerKind.normal.lifetime, const Duration(milliseconds: 950));
    expect(CheerKind.rare.lifetime, const Duration(milliseconds: 1400));
    expect(CheerKind.complete.lifetime, const Duration(milliseconds: 1700));
    expect(CheerTuning.rareChance, 0.025);
  });

  group('entries with a base id', () {
    test('an entry may be {t, b}; the text is shown and the base is kept', () {
      final moods = moodsWith(2);
      (moods['happy']! as Map<String, Object?>)['low'] = [
        'plain',
        {'t': 'Yay!', 'b': 'yay'},
        {'t': 'Yay yay', 'b': 'yay'},
        {'t': 'No base'},
      ];
      final book = CheerBook.parse(fileOf(moods)).book;
      expect(book.bundle(Mood.happy, CheerStage.low), [
        'plain',
        'Yay!',
        'Yay yay',
        'No base',
      ]);
      expect(book.bases(Mood.happy, CheerStage.low), [
        null,
        'yay',
        'yay',
        null,
      ]);
    });

    test('the length warning and the repeat warning use the text', () {
      final moods = moodsWith(2);
      (moods['happy']! as Map<String, Object?>)['low'] = [
        {'t': 'x' * 13, 'b': 'a'},
        {'t': 'same', 'b': 'a'},
        {'t': 'same', 'b': 'b'},
      ];
      final warnings = CheerBook.parse(fileOf(moods)).warnings;
      expect(warnings.where((w) => w.contains('longer')), hasLength(1));
      expect(warnings.where((w) => w.contains('repeated')), hasLength(1));
    });

    test(
      'a bad entry is refused: no text, blank text, wrong types, blank base',
      () {
        for (final bad in <Object?>[
          {'b': 'x'},
          {'t': '  ', 'b': 'x'},
          {'t': 5},
          {'t': 'ok', 'b': 5},
          {'t': 'ok', 'b': ' '},
          7,
          <Object?>[],
        ]) {
          final moods = moodsWith(2);
          (moods['happy']! as Map<String, Object?>)['low'] = ['fine', bad];
          expect(
            () => CheerBook.parse(fileOf(moods)),
            throwsFormatException,
            reason: '$bad',
          );
        }
      },
    );

    test('plain strings still give no base', () {
      final book = bookOf(2);
      expect(book.bases(Mood.sad, CheerStage.low), [null, null]);
    });
  });
}
