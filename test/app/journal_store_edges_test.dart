import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/journal_store.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/domain/save_policy.dart';

import '../screens/fake_app.dart';

void main() {
  final noon = DateTime(2026, 11, 18, 12);
  final day = DayKey.of(noon);

  Future<(JournalStore, MemoryRepository)> storeWithNote(String note) async {
    final repo = MemoryRepository();
    final store = JournalStore(repo)..load(MoodJournal.empty());
    store.recordTap(Mood.happy, noon);
    await store.setNote(day, note: note);
    return (store, repo);
  }

  group('a write that was started before a delete', () {
    test('its failure does not put the old note on the new record', () async {
      final (store, repo) = await storeWithNote('first');
      final gate = Completer<void>();
      repo.saveGate = gate.future;
      final pending = store.setNote(day, note: 'second');
      await Future<void>.delayed(Duration.zero);
      repo.saveGate = null;
      await store.deleteAll();
      store.recordTap(Mood.happy, noon.add(const Duration(minutes: 1)));
      repo.saveError = Exception('disk full');
      gate.complete();
      expect(await pending, isFalse);
      expect(store.journal.dayOf(day).note, isNull);
      expect(store.journal.dayOf(day).countOf(Mood.happy), 1);
      repo.saveError = null;
      await store.save(SaveTrigger.background);
      expect(repo.saved.last.dayOf(day).note, isNull);
    });

    test('its success does not bring the old note back either', () async {
      final (store, repo) = await storeWithNote('first');
      final gate = Completer<void>();
      repo.saveGate = gate.future;
      final pending = store.setNote(day, note: 'second');
      await Future<void>.delayed(Duration.zero);
      repo.saveGate = null;
      await store.deleteAll();
      store.recordTap(Mood.happy, noon.add(const Duration(minutes: 1)));
      gate.complete();
      await pending;
      expect(store.journal.dayOf(day).note, isNull);
      await store.save(SaveTrigger.background);
      expect(repo.saved.last.dayOf(day).note, isNull);
    });
  });

  group('deleting everything when the file cannot be removed', () {
    test('memory stays and the failure reaches the caller', () async {
      final (store, repo) = await storeWithNote('keep me');
      store.recordTap(Mood.sad, noon);
      repo.clearError = Exception('read only');
      await expectLater(store.deleteAll(), throwsException);
      expect(store.journal.dayOf(day).note, 'keep me');
      expect(store.journal.dayOf(day).countOf(Mood.sad), 1);
      expect(store.hasPending, isTrue);
    });

    test(
      'a later save does not overwrite the disk with an empty journal',
      () async {
        final (store, repo) = await storeWithNote('keep me');
        repo.clearError = Exception('read only');
        await expectLater(store.deleteAll(), throwsException);
        store.recordTap(Mood.happy, noon);
        await store.save(SaveTrigger.leaveScreen);
        expect(repo.saved.last.dayOf(day).note, 'keep me');
      },
    );

    test(
      'once it works the journal is empty and the generation moved on',
      () async {
        final (store, repo) = await storeWithNote('gone');
        repo.clearError = Exception('read only');
        await expectLater(store.deleteAll(), throwsException);
        repo.clearError = null;
        await store.deleteAll();
        expect(store.journal.days, isEmpty);
      },
    );
  });
}
