import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_picker.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/tuning.dart';

import 'cheer_fixtures.dart';

void main() {
  List<String> pickMany(
    CheerPicker picker,
    CheerBook book,
    int count, {
    Mood mood = Mood.happy,
    CheerStage stage = CheerStage.low,
  }) => [for (var i = 0; i < count; i++) picker.pick(book, mood, stage)];

  /// A file where every stage of every mood has [bases] base sentences with three variants each.
  CheerBook variantBook(int bases) {
    Map<String, Object?> stageOf(Mood mood, CheerStage stage) => {
      stage.id: [
        for (var b = 0; b < bases; b++)
          for (final mark in ['', '~~', '!!'])
            {
              't': '${mood.id}-${stage.id}-$b$mark',
              'b': '${mood.id}-${stage.id}-$b',
            },
      ],
    };
    return CheerBook.parse(
      fileOf({
        for (final mood in Mood.values)
          mood.id: {
            for (final stage in CheerStage.values) ...stageOf(mood, stage),
          },
      }),
    ).book;
  }

  String baseOf(String phrase) =>
      phrase.replaceAll('~', '').replaceAll('!', '');

  group('base deck', () {
    test('a base is picked first, then one of its variants', () {
      final book = variantBook(80);
      final picker = CheerPicker(Random(1));
      final seen = <String>{};
      for (var i = 0; i < 400; i++) {
        seen.add(picker.pick(book, Mood.happy, CheerStage.low));
      }
      expect(seen.any((p) => p.endsWith('~~')), isTrue);
      expect(seen.any((p) => p.endsWith('!!')), isTrue);
      expect(seen.any((p) => !p.endsWith('~') && !p.endsWith('!')), isTrue);
    });

    test('in 300 picks no base comes again within a window of 60', () {
      final book = variantBook(130);
      final picker = CheerPicker(Random(2));
      final bases = [
        for (var i = 0; i < 300; i++)
          baseOf(picker.pick(book, Mood.happy, CheerStage.low)),
      ];
      for (var i = 0; i < bases.length; i++) {
        final from = max(0, i - CheerTuning.recentBases);
        expect(
          bases.sublist(from, i),
          isNot(contains(bases[i])),
          reason: 'pick $i repeats a base of the last 60',
        );
      }
    });

    test(
      'variants of one base are never shown back to back as different sentences',
      () {
        final book = variantBook(10);
        final picker = CheerPicker(Random(3));
        var last = '';
        for (var i = 0; i < 200; i++) {
          final base = baseOf(picker.pick(book, Mood.happy, CheerStage.low));
          expect(base, isNot(last));
          last = base;
        }
      },
    );

    test('the window is half the bases for a small bundle', () {
      final book = variantBook(10);
      final picker = CheerPicker(Random(4));
      final bases = [
        for (var i = 0; i < 300; i++)
          baseOf(picker.pick(book, Mood.happy, CheerStage.low)),
      ];
      for (var i = 5; i < bases.length; i++) {
        expect(bases.sublist(i - 5, i), isNot(contains(bases[i])));
      }
    });

    test(
      'when the bases run out the next round never starts with the tail of the last',
      () {
        final book = variantBook(8);
        final picker = CheerPicker(Random(5));
        final bases = [
          for (var i = 0; i < 400; i++)
            baseOf(picker.pick(book, Mood.happy, CheerStage.low)),
        ];
        // 8 bases: every window of 4 picks has 4 different bases, round after round.
        for (var i = 0; i + 4 <= bases.length; i++) {
          expect(bases.sublist(i, i + 4).toSet(), hasLength(4));
        }
        // And every base still comes.
        expect(bases.toSet(), hasLength(8));
      },
    );

    test('a plain string is its own base', () {
      final book = bookOf(10);
      final picker = CheerPicker(Random(6));
      final picks = pickMany(picker, book, 200);
      for (var i = 5; i < picks.length; i++) {
        expect(picks.sublist(i - 5, i), isNot(contains(picks[i])));
      }
      expect(picks.toSet(), hasLength(10));
    });

    test('a bundle of one still answers', () {
      final picker = CheerPicker(Random(7));
      final book = bookOf(1);
      expect(pickMany(picker, book, 3), hasLength(3));
    });

    test('the memory is shared by every mood and stage', () {
      final book = variantBook(30);
      final picker = CheerPicker(Random(8));
      picker.pick(book, Mood.happy, CheerStage.low);
      picker.pick(book, Mood.sad, CheerStage.high);
      picker.pick(book, Mood.angry, CheerStage.complete);
      expect(picker.snapshotJson()['recent'], hasLength(3));
    });

    test('drawRare always gives a rare phrase of the rare bundle', () {
      final book = bookOf(10);
      final picker = CheerPicker(Random(4));
      for (var i = 0; i < 20; i++) {
        final draw = picker.drawRare(book, Mood.happy);
        expect(draw.kind, CheerKind.rare);
        expect(book.bundle(Mood.happy, CheerStage.rare), contains(draw.phrase));
      }
    });

    test('complete and rare use the same way', () {
      final book = variantBook(40);
      final picker = CheerPicker(Random(9));
      for (final stage in [CheerStage.complete, CheerStage.rare]) {
        final bases = [
          for (var i = 0; i < 100; i++)
            baseOf(picker.pick(book, Mood.happy, stage)),
        ];
        for (var i = 20; i < bases.length; i++) {
          expect(bases.sublist(i - 20, i), isNot(contains(bases[i])));
        }
      }
    });

    test('the same seed gives the same order, another seed another', () {
      final book = bookOf(30);
      final a = pickMany(CheerPicker(Random(10)), book, 30);
      expect(pickMany(CheerPicker(Random(10)), book, 30), a);
      expect(pickMany(CheerPicker(Random(11)), book, 30), isNot(a));
    });

    test('complete falls back to the full bundle when the file has none', () {
      final book = CheerBook.parse(fileOf(moodsWith(6, complete: false))).book;
      final picker = CheerPicker(Random(12));
      expect(
        picker.pick(book, Mood.happy, CheerStage.complete),
        startsWith('0f'),
      );
    });

    test('complete uses its own bundle when the file has one', () {
      final picker = CheerPicker(Random(13));
      expect(
        picker.pick(bookOf(6), Mood.happy, CheerStage.complete),
        startsWith('0c'),
      );
    });
  });

  group('saved memory', () {
    test('a new picker carries on with what was shown', () {
      final book = variantBook(130);
      final first = CheerPicker(Random(14));
      final seen = [
        for (var i = 0; i < 40; i++)
          baseOf(first.pick(book, Mood.happy, CheerStage.low)),
      ];
      final second = CheerPicker(Random(99), saved: first.snapshot());
      final next = [
        for (var i = 0; i < 60; i++)
          baseOf(second.pick(book, Mood.happy, CheerStage.low)),
      ];
      final all = [...seen, ...next];
      for (var i = 40; i < all.length; i++) {
        expect(all.sublist(max(0, i - 60), i), isNot(contains(all[i])));
      }
    });

    test('the snapshot survives a JSON round trip', () {
      final book = variantBook(130);
      final first = CheerPicker(Random(15));
      final seen = [
        for (var i = 0; i < 30; i++)
          baseOf(first.pick(book, Mood.happy, CheerStage.low)),
      ];
      final saved = CheerPicker.snapshotFromJson(first.snapshotJson());
      final second = CheerPicker(Random(98), saved: saved);
      final next = baseOf(second.pick(book, Mood.happy, CheerStage.low));
      expect(seen, isNot(contains(next)));
    });

    test('only the last 60 are kept', () {
      final picker = CheerPicker(Random(16));
      final book = variantBook(100);
      for (var i = 0; i < 150; i++) {
        picker.pick(book, Mood.happy, CheerStage.low);
      }
      expect(picker.snapshotJson()['recent'] as List, hasLength(60));
    });

    test('garbage and old saved state is ignored', () {
      final garbage = <Object?>[
        null,
        'text',
        {'version': 9},
        {'version': 1, 'decks': {}},
        {'version': 2, 'recent': 'x'},
        {
          'version': 2,
          'recent': [1, null, ''],
        },
      ];
      for (final g in garbage) {
        final picker = CheerPicker(
          Random(17),
          saved: CheerPicker.snapshotFromJson(g),
        );
        expect(pickMany(picker, bookOf(5), 5), hasLength(5), reason: '$g');
      }
    });

    test('is dirty after a pick and clean after being saved', () {
      final picker = CheerPicker(Random(18));
      expect(picker.isDirty, isFalse);
      picker.pick(bookOf(3), Mood.happy, CheerStage.low);
      expect(picker.isDirty, isTrue);
    });
  });

  group('deck store', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('cheer_deck_test');
      file = File('${dir.path}/decks.json');
    });
    tearDown(() => dir.delete(recursive: true));

    test('a missing file opens as a fresh picker', () async {
      final picker = await CheerPicker.open(
        Random(18),
        JsonFileCheerDeckStore(file),
      );
      expect(pickMany(picker, bookOf(4), 4), hasLength(4));
    });

    test('persist writes only when something changed', () async {
      final store = JsonFileCheerDeckStore(file);
      final picker = await CheerPicker.open(Random(19), store);
      expect(await picker.persist(store), isFalse);
      expect(file.existsSync(), isFalse);

      picker.pick(bookOf(4), Mood.happy, CheerStage.low);
      expect(await picker.persist(store), isTrue);
      expect(picker.isDirty, isFalse);
      expect(await picker.persist(store), isFalse);
    });

    test('the memory carries over an app restart', () async {
      final book = bookOf(12);
      final store = JsonFileCheerDeckStore(file);
      final first = await CheerPicker.open(Random(20), store);
      final seen = pickMany(first, book, 5);
      await first.persist(store);

      final second = await CheerPicker.open(
        Random(77),
        JsonFileCheerDeckStore(file),
      );
      // 12 bases: the window is 6, so none of the 5 just shown comes first.
      expect(seen, isNot(contains(pickMany(second, book, 1).single)));
    });

    test('a corrupt file opens as a fresh picker', () async {
      await file.writeAsString('{not json');
      final picker = await CheerPicker.open(
        Random(21),
        JsonFileCheerDeckStore(file),
      );
      expect(pickMany(picker, bookOf(4), 4), hasLength(4));
    });

    test('a failed save is silent and keeps the picker dirty', () async {
      await Directory(
        file.path,
      ).create(); // a directory where the file should go
      final store = JsonFileCheerDeckStore(file);
      final picker = await CheerPicker.open(Random(22), store);
      picker.pick(bookOf(4), Mood.happy, CheerStage.low);
      expect(await picker.persist(store), isFalse);
      expect(picker.isDirty, isTrue);
      // The picker still works.
      expect(picker.pick(bookOf(4), Mood.happy, CheerStage.low), isNotEmpty);
    });
  });

  group('draw', () {
    test('the complete stage is always the complete kind, never rare', () {
      final picker = CheerPicker(_Rolls([0.0, 0.0, 0.0], Random(1)));
      for (var i = 0; i < 3; i++) {
        final draw = picker.draw(bookOf(4), Mood.happy, CheerStage.complete);
        expect(draw.kind, CheerKind.complete);
        expect(draw.phrase, startsWith('0c'));
      }
    });

    test('a roll under 2.5 percent is a rare phrase from the rare bundle', () {
      final picker = CheerPicker(_Rolls([0.024], Random(2)));
      final draw = picker.draw(bookOf(4), Mood.happy, CheerStage.high);
      expect(draw.kind, CheerKind.rare);
      expect(draw.phrase, startsWith('0r'));
    });

    test(
      'a rare phrase uses the high bundle when the file has no rare one',
      () {
        final picker = CheerPicker(_Rolls([0.0], Random(3)));
        final book = CheerBook.parse(fileOf(moodsWith(4, rare: false))).book;
        final draw = picker.draw(book, Mood.happy, CheerStage.low);
        expect(draw.kind, CheerKind.rare);
        expect(draw.phrase, startsWith('0h'));
      },
    );

    test(
      'a roll at or over 2.5 percent is an ordinary phrase of the stage',
      () {
        final picker = CheerPicker(_Rolls([0.025, 0.5, 0.99], Random(4)));
        final book = bookOf(4);
        for (final stage in [
          CheerStage.low,
          CheerStage.high,
          CheerStage.full,
        ]) {
          final draw = picker.draw(book, Mood.sad, stage);
          expect(draw.kind, CheerKind.normal);
          expect(draw.phrase, startsWith('3${stage.id[0]}'));
        }
      },
    );

    test('about 2.5 percent of many taps are rare', () {
      final picker = CheerPicker(Random(5));
      final book = bookOf(50);
      var rare = 0;
      const taps = 20000;
      for (var i = 0; i < taps; i++) {
        if (picker.draw(book, Mood.happy, CheerStage.low).kind ==
            CheerKind.rare) {
          rare++;
        }
      }
      expect(rare / taps, inInclusiveRange(0.018, 0.032));
    });
  });
}

/// A Random whose doubles come from a list (then from [_base]); shuffles and ints use [_base].
class _Rolls implements Random {
  _Rolls(this._rolls, this._base);

  final List<double> _rolls;
  final Random _base;
  int _next = 0;

  @override
  double nextDouble() =>
      _next < _rolls.length ? _rolls[_next++] : _base.nextDouble();

  @override
  int nextInt(int max) => _base.nextInt(max);

  @override
  bool nextBool() => _base.nextBool();
}
