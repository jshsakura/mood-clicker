import 'package:flutter/foundation.dart';

import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../domain/mood_journal.dart';
import '../domain/mood_repository.dart';
import '../domain/save_policy.dart';

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

  MoodJournal get journal => _journal;

  /// Whether some taps wait to be written.
  bool get hasPending => _policy.hasPending;

  /// Replaces the journal right after loading. Nothing is pending.
  void load(MoodJournal journal) {
    _journal = journal;
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

  /// Sets the note of a day and writes it at once.
  Future<void> setNote(DayKey day, {String? note, String? presetId}) {
    _journal = _journal.withNote(day, note: note, presetId: presetId);
    _policy = _policy.afterTap(_watch.elapsed);
    notifyListeners();
    return save(SaveTrigger.leaveScreen);
  }

  /// Writes when the policy says so for [trigger]. A failed write is kept pending and retried
  /// on the next call; it never throws to the screen.
  Future<void> save(SaveTrigger trigger) async {
    if (!_policy.shouldSave(trigger, _watch.elapsed)) return;
    final snapshot = _journal;
    _policy = _policy.afterSaveStarted();
    try {
      await repository.save(snapshot);
    } on Object catch (error) {
      _policy = _policy.afterSaveFailed();
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, library: 'journal store'),
      );
    }
  }
}
