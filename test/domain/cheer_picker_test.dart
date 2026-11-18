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

  group('deck', () {
    test('uses every phrase once before any repeats', () {
      final picker = CheerPicker(Random(1));
      final book = bookOf(10);
      final picks = pickMany(picker, book, 10);
      expect(picks.toSet(), hasLength(10));
    });

    test('every deck is a full pass, deck after deck', () {
      final picker = CheerPicker(Random(2));
      final book = bookOf(37);
      final picks = pickMany(picker, book, 37 * 6);
      for (var d = 0; d < 6; d++) {
        expect(
          picks.sublist(d * 37, (d + 1) * 37).toSet(),
          hasLength(37),
          reason: 'deck $d',
        );
      }
    });

    test('the last 50 of a deck stay out of the first 50 of the next', () {
      final picker = CheerPicker(Random(3));
      final book = bookOf(200);
      final picks = pickMany(picker, book, 200 * 5);
      for (var d = 0; d < 4; d++) {
        final tail = picks
            .sublist((d + 1) * 200 - CheerTuning.deckTailSize, (d + 1) * 200)
            .toSet();
        final head = picks.sublist(
          (d + 1) * 200,
          (d + 1) * 200 + CheerTuning.deckTailSize,
        );
        expect(head.where(tail.contains), isEmpty, reason: 'boundary $d');
      }
    });

    test(
      'a small bundle keeps half of the last deck away from the next start',
      () {
        // 7 phrases: the tail kept apart is 3, so the next deck opens with 3 phrases not in it.
        final picker = CheerPicker(Random(4));
        final book = bookOf(7);
        final picks = pickMany(picker, book, 7 * 40);
        for (var d = 0; d < 39; d++) {
          final tail = picks.sublist((d + 1) * 7 - 3, (d + 1) * 7).toSet();
          final head = picks.sublist((d + 1) * 7, (d + 1) * 7 + 3);
          expect(head.where(tail.contains), isEmpty, reason: 'boundary $d');
        }
      },
    );

    test('the same phrase never comes twice in a row, even across decks', () {
      for (final size in [2, 3, 5, 8, 9, 60]) {
        final picker = CheerPicker(Random(size));
        final book = bookOf(size);
        final picks = pickMany(picker, book, size * 30);
        for (var i = 1; i < picks.length; i++) {
          expect(picks[i], isNot(picks[i - 1]), reason: 'size $size, pick $i');
        }
      }
    });

    test('a bundle of one still answers', () {
      final picker = CheerPicker(Random(5));
      final book = bookOf(1);
      expect(pickMany(picker, book, 5), everyElement('0l0'));
    });

    test('decks are separate per mood and per stage', () {
      final picker = CheerPicker(Random(6));
      final book = bookOf(6);
      final happyLow = pickMany(picker, book, 3);
      final sadHigh = pickMany(
        picker,
        book,
        6,
        mood: Mood.sad,
        stage: CheerStage.high,
      );
      expect(happyLow, everyElement(startsWith('0l')));
      expect(sadHigh, everyElement(startsWith('3h')));
      expect(sadHigh.toSet(), hasLength(6));
      // The happy/low deck was not disturbed by the other pulls.
      final restOfHappyLow = pickMany(picker, book, 3);
      expect({...happyLow, ...restOfHappyLow}, hasLength(6));
    });

    test('the same seed gives the same order', () {
      List<String> run() => pickMany(CheerPicker(Random(7)), bookOf(30), 90);
      expect(run(), run());
    });

    test('different seeds give different orders', () {
      final a = pickMany(CheerPicker(Random(8)), bookOf(30), 30);
      final b = pickMany(CheerPicker(Random(9)), bookOf(30), 30);
      expect(a, isNot(b));
    });

    test('complete falls back to the full deck when the file has none', () {
      final picker = CheerPicker(Random(10));
      final book = bookOf(5, complete: false);
      final picks = [
        picker.pick(book, Mood.happy, CheerStage.full),
        picker.pick(book, Mood.happy, CheerStage.complete),
        picker.pick(book, Mood.happy, CheerStage.full),
        picker.pick(book, Mood.happy, CheerStage.complete),
        picker.pick(book, Mood.happy, CheerStage.full),
      ];
      expect(picks.toSet(), hasLength(5));
      expect(picks, everyElement(startsWith('0f')));
    });

    test('complete uses its own deck when the file has one', () {
      final picker = CheerPicker(Random(11));
      final book = bookOf(4);
      final picks = pickMany(picker, book, 4, stage: CheerStage.complete);
      expect(picks.toSet(), hasLength(4));
      expect(picks, everyElement(startsWith('0c')));
    });
  });

  group('saved position', () {
    test('a new picker carries on with the unused part of the deck', () {
      final book = bookOf(10);
      final first = CheerPicker(Random(12));
      final seen = pickMany(first, book, 4);

      final second = CheerPicker(Random(99), saved: first.snapshot());
      final rest = pickMany(second, book, 6);
      expect({...seen, ...rest}, hasLength(10));
    });

    test('the snapshot survives a JSON round trip', () {
      final book = bookOf(10);
      final first = CheerPicker(Random(13));
      final seen = pickMany(first, book, 7);
      final saved = CheerPicker.snapshotFromJson(first.snapshotJson());
      final second = CheerPicker(Random(98), saved: saved);
      expect({...seen, ...pickMany(second, book, 3)}, hasLength(10));
    });

    test('a changed phrase file starts a fresh shuffle without error', () {
      final first = CheerPicker(Random(14));
      pickMany(first, bookOf(10), 4);
      final other = CheerBook.parse(
        fileOf({
          for (final mood in Mood.values)
            mood.id: {
              for (final stage in CheerStage.values)
                stage.id: [
                  for (var i = 0; i < 10; i++)
                    'new-${mood.index}${stage.id[0]}$i',
                ],
            },
        }),
      ).book;
      final second = CheerPicker(Random(15), saved: first.snapshot());
      expect(pickMany(second, other, 10).toSet(), hasLength(10));
    });

    test('garbage saved state is ignored', () {
      final garbage = <Object?>[
        null,
        'text',
        {'version': 9},
        {'version': 1, 'decks': 'x'},
        {
          'version': 1,
          'decks': {
            'happy/low': {'fp': 1, 'order': 'x', 'pos': 'y'},
            'sad/low': {
              'fp': 'a',
              'order': [0, 0, 1],
              'pos': 99,
            },
            'nope/low': {
              'fp': 'a',
              'order': [0],
              'pos': 0,
            },
          },
        },
      ];
      for (final g in garbage) {
        final picker = CheerPicker(
          Random(16),
          saved: CheerPicker.snapshotFromJson(g),
        );
        expect(
          pickMany(picker, bookOf(5), 5).toSet(),
          hasLength(5),
          reason: '$g',
        );
      }
    });

    test('is dirty after a pick and clean after being saved', () {
      final picker = CheerPicker(Random(17));
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
      expect(pickMany(picker, bookOf(4), 4).toSet(), hasLength(4));
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

    test('the position carries over an app restart', () async {
      final book = bookOf(12);
      final store = JsonFileCheerDeckStore(file);
      final first = await CheerPicker.open(Random(20), store);
      final seen = pickMany(first, book, 5);
      await first.persist(store);

      final second = await CheerPicker.open(
        Random(77),
        JsonFileCheerDeckStore(file),
      );
      final rest = pickMany(second, book, 7);
      expect({...seen, ...rest}, hasLength(12));
    });

    test('a corrupt file opens as a fresh picker', () async {
      await file.writeAsString('{not json');
      final picker = await CheerPicker.open(
        Random(21),
        JsonFileCheerDeckStore(file),
      );
      expect(pickMany(picker, bookOf(4), 4).toSet(), hasLength(4));
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
