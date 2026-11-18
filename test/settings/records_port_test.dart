import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/mood_repository.dart';
import 'package:mood_clicker/domain/save_policy.dart';
import 'package:mood_clicker/domain/json_file_mood_repository.dart';
import 'package:mood_clicker/settings/records_port.dart';

void main() {
  late Directory tmp;
  late File file;
  late List<String> shared;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('records');
    file = File('${tmp.path}/mood_journal.json');
    shared = [];
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  DeviceRecordsPort port({bool completes = true}) => DeviceRecordsPort(
    journalFile: () async => file,
    shareFiles: (paths) async {
      shared.addAll(paths);
      return completes;
    },
  );

  test('an empty app has no record today and nothing to export', () async {
    final empty = port();
    expect(await empty.hasRecordToday(), isFalse);
    expect(await empty.exportJournal(), ExportOutcome.nothing);
    expect(shared, isEmpty);
  });

  test('a journal with a tap today counts as recorded', () async {
    final repository = JsonFileMoodRepository(file);
    final now = DateTime.now();
    final journal = MoodJournal.empty().withTap(Mood.happy, now);
    await repository.save(journal);
    expect(await port().hasRecordToday(), isTrue);
  });

  test('export shares the journal file path', () async {
    final repository = JsonFileMoodRepository(file);
    await repository.save(
      MoodJournal.empty().withTap(Mood.sad, DateTime.now()),
    );
    final outcome = await port().exportJournal();
    expect(outcome, ExportOutcome.shared);
    expect(shared, [file.path]);
    expect(await File(file.path).exists(), isTrue);
  });

  test('a dismissed share sheet is reported as cancelled', () async {
    final repository = JsonFileMoodRepository(file);
    await repository.save(
      MoodJournal.empty().withTap(Mood.sad, DateTime.now()),
    );
    expect(
      await port(completes: false).exportJournal(),
      ExportOutcome.cancelled,
    );
  });

  test('only a finished share counts as shared', () {
    expect(shareFinished(ShareResult.unavailable), isFalse);
    expect(
      shareFinished(const ShareResult('', ShareResultStatus.dismissed)),
      isFalse,
    );
    expect(
      shareFinished(const ShareResult('', ShareResultStatus.success)),
      isTrue,
    );
  });

  test('deleteAll removes the journal file', () async {
    final repository = JsonFileMoodRepository(file);
    await repository.save(
      MoodJournal.empty().withTap(Mood.sad, DateTime.now()),
    );
    await port().deleteAll();
    expect(await file.exists(), isFalse);
  });

  group('deleting everything with a live journal store', () {
    final day = DateTime(2026, 11, 10, 12);

    Future<JournalStore> storeWithSavedTaps() async {
      final store = JournalStore(JsonFileMoodRepository(file));
      store.load(MoodJournal.empty());
      store.recordTap(Mood.happy, day);
      store.recordTap(Mood.sad, day);
      await store.save(SaveTrigger.leaveScreen);
      return store;
    }

    DeviceRecordsPort portFor(JournalStore store) => DeviceRecordsPort(
      journalFile: () async => file,
      shareFiles: (paths) async => true,
      store: store,
    );

    test('memory, disk and the calendar are all empty afterwards', () async {
      final store = await storeWithSavedTaps();
      expect(store.journal.dayOf(DayKey.of(day)).total, 2);
      await portFor(store).deleteAll();
      expect(store.journal.days, isEmpty);
      expect(store.journal.dayOf(DayKey.of(day)).total, 0);
      expect(await file.exists(), isFalse);
      expect(store.hasPending, isFalse);
    });

    test('the next save does not bring the old days back', () async {
      final store = await storeWithSavedTaps();
      await portFor(store).deleteAll();
      store.recordTap(Mood.excited, DateTime(2026, 11, 18, 9));
      await store.save(SaveTrigger.leaveScreen);
      final loaded = await JsonFileMoodRepository(file).load() as Loaded;
      expect(loaded.journal.days, hasLength(1));
      expect(loaded.journal.dayOf(DayKey.of(day)).total, 0);
    });

    test('taps still waiting to be written are dropped too', () async {
      final store = await storeWithSavedTaps();
      store.recordTap(Mood.happy, day);
      expect(store.hasPending, isTrue);
      await portFor(store).deleteAll();
      await store.save(SaveTrigger.background);
      expect(await file.exists(), isFalse);
      expect(store.journal.days, isEmpty);
    });

    test(
      'a save that is still being written does not outlive the delete',
      () async {
        final store = JournalStore(JsonFileMoodRepository(file));
        store.load(MoodJournal.empty());
        store.recordTap(Mood.happy, day);
        final saving = store.save(SaveTrigger.leaveScreen);
        await portFor(store).deleteAll();
        await saving;
        expect(await file.exists(), isFalse);
      },
    );

    test('listeners are told so the calendar redraws', () async {
      final store = await storeWithSavedTaps();
      var told = 0;
      store.addListener(() => told++);
      await portFor(store).deleteAll();
      expect(told, greaterThan(0));
    });
  });
}
