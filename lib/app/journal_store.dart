import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../domain/mood_journal.dart';
import '../domain/mood_repository.dart';
import '../domain/save_policy.dart';

/// The one journal file of this app: the `<app support>/journal.json` of
/// path_provider. The bootstrap, the screens and the settings export all go
/// through it.
Future<File> journalFile() async {
  final folder = await getApplicationSupportDirectory();
  return File('${folder.path}/journal.json');
}

/// The journal as the screens see it. It counts taps, decides when to write with [SavePolicy] and
/// writes through the [MoodRepository]. Screens listen to it and call [recordTap] and friends.
class JournalStore extends ChangeNotifier {
  JournalStore(this.repository, {Stopwatch? stopwatch, MoodJournal? journal})
    : _watch = stopwatch ?? (Stopwatch()..start()),
      _journal = journal ?? MoodJournal.empty();

  final MoodRepository repository;
  final Stopwatch _watch;

  MoodJournal _journal;
  SavePolicy _policy = const SavePolicy.clean();

  bool _isLoaded = false;

  /// Counts the deletions. A write that was started in an older generation belongs to records that
  /// are gone: its result must not touch the new ones.
  int _generation = 0;

  /// True once [load] has run, so a launch request can wait for the real journal.
  bool get isLoaded => _isLoaded;

  MoodJournal get journal => _journal;

  /// Whether some taps wait to be written.
  bool get hasPending => _policy.hasPending;

  /// Replaces the journal right after loading. Nothing is pending.
  void load(MoodJournal journal) {
    _journal = journal;
    _isLoaded = true;
    _policy = const SavePolicy.clean();
    notifyListeners();
  }

  void recordTap(Mood mood, DateTime at) {
    _journal = _journal.withTap(mood, at);
    _policy = _policy.afterTap(_watch.elapsed);
    notifyListeners();
  }

  /// Takes taps off a mood: water the phone spilled.
  void removeTaps(DayKey day, Mood mood, int count) {
    if (count <= 0) return;
    _journal = _journal.withTapsRemoved(day, mood, count);
    _policy = _policy.afterTap(_watch.elapsed);
    notifyListeners();
  }

  /// Sets the note of a day and writes it at once. Returns false when the write failed: the
  /// note is taken back out of memory, so the calendar never shows a line the disk does not hold,
  /// and the caller keeps the draft and says so.
  Future<bool> setNote(DayKey day, {String? note, String? presetId}) async {
    final generation = _generation;
    final before = _journal.dayOf(day);
    _journal = _journal.withNote(day, note: note, presetId: presetId);
    _policy = _policy.afterTap(_watch.elapsed);
    notifyListeners();
    final written = await save(SaveTrigger.leaveScreen);
    if (!written && generation == _generation) {
      _journal = _journal.withNote(
        day,
        note: before.note,
        presetId: before.notePresetId,
      );
      notifyListeners();
    }
    return written;
  }

  /// Forgets every record: the file first, then memory, the pending taps and the screens. When the
  /// file cannot be removed this throws and nothing else changes, so memory and disk still agree
  /// and the screen can say so. Writes that were started before the delete are ignored afterwards.
  Future<void> deleteAll() async {
    await repository.clear();
    _generation++;
    _journal = MoodJournal.empty();
    _policy = const SavePolicy.clean();
    notifyListeners();
  }

  /// Writes when the policy says so for [trigger]. A failed write is kept pending and retried
  /// on the next call; it never throws to the screen. Returns false only when a write failed.
  Future<bool> save(SaveTrigger trigger) async {
    if (!_policy.shouldSave(trigger, _watch.elapsed)) return true;
    final snapshot = _journal;
    final generation = _generation;
    _policy = _policy.afterSaveStarted();
    try {
      await repository.save(snapshot);
      return true;
    } on Object catch (error) {
      // Records deleted since this write began: nothing left to retry.
      if (generation != _generation) return false;
      _policy = _policy.afterSaveFailed();
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, library: 'journal store'),
      );
      return false;
    }
  }
}
