import 'tuning.dart';

enum SaveTrigger { tick, leaveScreen, background }

/// An immutable value that decides when to write to disk.
///
/// The screen calls `afterTap` on each tap, `afterSaveStarted` the moment a write begins, and
/// `afterSaveFailed` if the write fails. Taps that arrive during a write stay pending for the next one.
class SavePolicy {
  const SavePolicy.clean() : _pendingSince = null, _inFlightSince = null;

  const SavePolicy._(this._pendingSince, this._inFlightSince);

  /// The time of the oldest tap that has not been written.
  final DateTime? _pendingSince;

  /// The time of the oldest tap in the batch being written. Restored if the write fails.
  final DateTime? _inFlightSince;

  bool get hasPending => _pendingSince != null;

  /// When there are unwritten taps, the latest time they must be written by.
  DateTime? get dueAt => _pendingSince?.add(SaveTuning.interval);

  SavePolicy afterTap(DateTime now) =>
      SavePolicy._(_pendingSince ?? now, _inFlightSince);

  /// Call right after taking the snapshot to save, before awaiting the write.
  /// Later taps are not in that write, so they start a fresh interval.
  SavePolicy afterSaveStarted() => SavePolicy._(null, _pendingSince);

  /// The write failed. Goes back to the oldest tap time so the write is retried soon.
  SavePolicy afterSaveFailed() {
    final inFlight = _inFlightSince;
    final pending = _pendingSince;
    final since = switch ((inFlight, pending)) {
      (null, _) => pending,
      (_, null) => inFlight,
      (final a?, final b?) => a.isBefore(b) ? a : b,
    };
    return SavePolicy._(since, null);
  }

  bool shouldSave(SaveTrigger trigger, DateTime now) {
    final due = dueAt;
    if (due == null) return false;
    return switch (trigger) {
      SaveTrigger.tick => !now.isBefore(due),
      SaveTrigger.leaveScreen || SaveTrigger.background => true,
    };
  }
}
