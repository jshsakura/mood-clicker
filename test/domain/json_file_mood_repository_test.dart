import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/json_file_mood_repository.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mood_repo_test');
    file = File('${dir.path}/data/journal.json');
  });

  tearDown(() => dir.delete(recursive: true));

  MoodJournal loaded(LoadResult result) => switch (result) {
    Loaded(:final journal) => journal,
    LoadFailed(:final reason) => fail('expected Loaded, got $reason'),
  };

  test('a missing file loads as an empty journal', () async {
    final result = await JsonFileMoodRepository(file).load();
    expect(loaded(result).days, isEmpty);
  });

  test('saved journal loads back with counts and last tap times', () async {
    final tapAt = DateTime(2026, 11, 18, 21, 5, 3, 250);
    final journal = MoodJournal.empty()
        .withTap(Mood.happy, tapAt)
        .withTap(Mood.happy, tapAt)
        .withTap(Mood.anxious, DateTime(2026, 11, 19, 8));
    final repo = JsonFileMoodRepository(file);

    await repo.save(journal);
    final back = loaded(await repo.load());

    final d18 = back.dayOf(DayKey.of(tapAt));
    expect(d18.countOf(Mood.happy), 2);
    expect(d18.tallies[Mood.happy]!.lastTapAt.isAtSameMomentAs(tapAt), isTrue);
    expect(back.days, hasLength(2));
    expect(
      back.dayOf(DayKey.of(DateTime(2026, 11, 19))).dominantMood,
      Mood.anxious,
    );
  });

  test(
    'saving replaces the previous contents and leaves no temp file',
    () async {
      final repo = JsonFileMoodRepository(file);
      await repo.save(
        MoodJournal.empty().withTap(Mood.sad, DateTime(2026, 1, 1)),
      );
      await repo.save(MoodJournal.empty());

      expect(loaded(await repo.load()).days, isEmpty);
      expect(file.parent.listSync().map((e) => e.path), [file.path]);
    },
  );

  group('a broken file is reported and kept', () {
    final cases = {
      'not json': '{oops',
      'wrong shape': '[1, 2, 3]',
      'unknown version': '{"version": 99, "days": {}}',
      'bad date key': '{"version": 1, "days": {"2026-02-30": {}}}',
      'unknown mood':
          '{"version": 1, "days": {"2026-11-18": {"bored": {"count": 1, "lastTapAt": "2026-11-18T03:00:00.000Z"}}}}',
      'negative count':
          '{"version": 1, "days": {"2026-11-18": {"happy": {"count": -1, "lastTapAt": "2026-11-18T03:00:00.000Z"}}}}',
      'bad timestamp':
          '{"version": 1, "days": {"2026-11-18": {"happy": {"count": 1, "lastTapAt": "soon"}}}}',
    };
    for (final MapEntry(key: name, value: content) in cases.entries) {
      test(name, () async {
        await file.parent.create(recursive: true);
        await file.writeAsString(content);

        final result = await JsonFileMoodRepository(file).load();

        expect(result, isA<LoadFailed>());
        expect(await file.readAsString(), content);
      });
    }

    test('invalid utf-8', () async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0xff, 0xfe, 0x00]);
      expect(await JsonFileMoodRepository(file).load(), isA<LoadFailed>());
      expect(await file.readAsBytes(), [0xff, 0xfe, 0x00]);
    });
  });

  group('writes', () {
    final tapAt = DateTime(2026, 11, 18, 12);
    MoodJournal oneTap() => MoodJournal.empty().withTap(Mood.happy, tapAt);

    test('the first save writes', () async {
      expect(await JsonFileMoodRepository(file).save(oneTap()), isTrue);
    });

    test('a save with the same content is skipped', () async {
      final repo = JsonFileMoodRepository(file);
      await repo.save(oneTap());
      final past = DateTime(2020);
      await file.setLastModified(past);

      expect(await repo.save(oneTap()), isFalse);
      expect(await file.lastModified(), past);
    });

    test('a save with new content writes again', () async {
      final repo = JsonFileMoodRepository(file);
      await repo.save(oneTap());
      final more = oneTap().withTap(Mood.happy, tapAt);
      expect(await repo.save(more), isTrue);
      expect(loaded(await repo.load()).dayOf(DayKey.of(tapAt)).total, 2);
    });

    test('the same content is skipped even by a new repository', () async {
      await JsonFileMoodRepository(file).save(oneTap());
      expect(await JsonFileMoodRepository(file).save(oneTap()), isFalse);
    });

    test(
      'equal journals encode the same whatever order the map was built in',
      () async {
        final repo = JsonFileMoodRepository(file);
        final day = DayKey.of(tapAt);
        final happy = MoodTally(count: 1, lastTapAt: tapAt, lastOrder: 1);
        final sad = MoodTally(count: 1, lastTapAt: tapAt, lastOrder: 2);
        final a = MoodJournal([
          DayRecord(day, {Mood.happy: happy, Mood.sad: sad}),
        ]);
        final b = MoodJournal([
          DayRecord(day, {Mood.sad: sad, Mood.happy: happy}),
        ]);
        await repo.save(a);
        expect(await repo.save(b), isFalse);
      },
    );

    test('a file changed behind our back is written again', () async {
      final repo = JsonFileMoodRepository(file);
      await repo.save(oneTap());
      await file.writeAsString('{"version": 1, "days": {}}');
      expect(await repo.save(oneTap()), isTrue);
    });

    test('saves started together are written one after another', () async {
      final repo = JsonFileMoodRepository(file);
      var journal = MoodJournal.empty();
      final saves = <Future<bool>>[];
      for (var i = 0; i < 6; i++) {
        journal = journal.withTap(Mood.happy, tapAt.add(Duration(seconds: i)));
        saves.add(repo.save(journal));
      }
      await Future.wait(saves);

      expect(loaded(await repo.load()).dayOf(DayKey.of(tapAt)).total, 6);
      expect(file.parent.listSync().map((e) => e.path), [file.path]);
    });
  });

  group('an unreadable file', () {
    test('is copied aside so a later save cannot destroy it', () async {
      await file.parent.create(recursive: true);
      await file.writeAsString('{oops');
      final repo = JsonFileMoodRepository(file);

      expect(await repo.load(), isA<LoadFailed>());
      await repo.save(MoodJournal.empty());

      final backup = File('${file.path}.unreadable');
      expect(await backup.readAsString(), '{oops');
      expect(loaded(await repo.load()).days, isEmpty);
    });

    test('every different unreadable original is kept, numbered', () async {
      await file.parent.create(recursive: true);
      for (final text in ['{first', '{second', '{third']) {
        await file.writeAsString(text);
        await JsonFileMoodRepository(file).load();
      }
      String read(String suffix) =>
          File('${file.path}$suffix').readAsStringSync();
      expect(read('.unreadable'), '{first');
      expect(read('.unreadable.2'), '{second');
      expect(read('.unreadable.3'), '{third');
    });

    test('the same unreadable content is not copied again', () async {
      await file.parent.create(recursive: true);
      await file.writeAsString('{same');
      for (var i = 0; i < 3; i++) {
        await JsonFileMoodRepository(file).load();
      }
      expect(File('${file.path}.unreadable.2').existsSync(), isFalse);
    });

    test('a date that is not on the calendar fails the load', () async {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '{"version":1,"days":{"2026-02-31":'
        '{"happy":{"count":1,"lastTapAt":"2026-02-01T00:00:00.000Z"}}}}',
      );
      expect(await JsonFileMoodRepository(file).load(), isA<LoadFailed>());
    });
  });

  group('concurrent repositories on one file', () {
    test('writes never collide on a shared temp file', () async {
      final a = JsonFileMoodRepository(file);
      final b = JsonFileMoodRepository(file);
      final base = DateTime(2026, 11, 18, 12);
      var journal = MoodJournal.empty();
      final saves = <Future<Object?>>[];
      Future<Object?> attempt(Future<bool> save) =>
          save.then<Object?>((v) => v, onError: (Object e) => e);
      for (var i = 0; i < 20; i++) {
        journal = journal.withTap(Mood.happy, base.add(Duration(seconds: i)));
        saves.add(attempt(a.save(journal)));
        saves.add(attempt(b.save(journal)));
      }
      final results = await Future.wait(saves);
      expect(results.whereType<Object>().where((r) => r is! bool), isEmpty);
      expect(file.parent.listSync().map((e) => e.path), [file.path]);
      expect(await JsonFileMoodRepository(file).load(), isA<Loaded>());
    });

    test('a failed write leaves no temp file behind', () async {
      await file.parent.create(recursive: true);
      // A directory where the target file should go makes the rename fail.
      await Directory(file.path).create();
      final repo = JsonFileMoodRepository(file);
      final journal = MoodJournal.empty().withTap(
        Mood.happy,
        DateTime(2026, 11, 18, 12),
      );
      await expectLater(
        repo.save(journal),
        throwsA(isA<FileSystemException>()),
      );
      final leftovers = file.parent
          .listSync()
          .map((e) => e.path)
          .where((p) => p != file.path);
      expect(leftovers, isEmpty);
    });
  });

  group('tap order', () {
    test('survives a save and load, even when the clock went back', () async {
      final repo = JsonFileMoodRepository(file);
      final day = DateTime(2026, 11, 18, 12);
      final journal = MoodJournal.empty()
          .withTap(Mood.happy, day.add(const Duration(seconds: 100)))
          .withTap(Mood.sad, day.add(const Duration(seconds: 50)));
      await repo.save(journal);
      final record = loaded(await repo.load()).dayOf(DayKey.of(day));
      expect(record.dominantMood, Mood.sad);
    });

    test('a file saved before tap order existed loads in time order', () async {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '{"version":1,"days":{"2026-11-18":{'
        '"happy":{"count":1,"lastTapAt":"2026-11-18T03:00:00.000Z"},'
        '"sad":{"count":1,"lastTapAt":"2026-11-18T03:00:05.000Z"}}}}',
      );
      final record = loaded(
        await JsonFileMoodRepository(file).load(),
      ).days.single;
      expect(record.dominantMood, Mood.sad);
      expect(
        record.tallies[Mood.sad]!.lastOrder,
        greaterThan(record.tallies[Mood.happy]!.lastOrder),
      );
    });
  });
}
