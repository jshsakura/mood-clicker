import 'mood_journal.dart';

sealed class LoadResult {
  const LoadResult();
}

class Loaded extends LoadResult {
  const Loaded(this.journal);
  final MoodJournal journal;
}

/// The file exists but cannot be read. The caller must not delete it and must tell the user.
class LoadFailed extends LoadResult {
  const LoadFailed(this.reason);
  final String reason;
}

abstract interface class MoodRepository {
  Future<LoadResult> load();

  /// A failed write throws. Returns false when the file already holds the same content and the
  /// write is skipped, true when it wrote. Overlapping calls are written one at a time.
  Future<bool> save(MoodJournal journal);

  /// Removes every stored record. It runs after the writes that were already started, so a
  /// write in flight cannot bring the file back.
  Future<void> clear();
}
