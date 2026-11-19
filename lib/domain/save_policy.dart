import 'tuning.dart';

enum SaveTrigger { tick, leaveScreen, background }

/// An immutable value that decides when to write to disk.
///
/// Every time is monotonic: the elapsed time of an injected `Stopwatch`, never the wall clock.
/// Setting the device clock back or forward cannot delay or hasten a save.
///
/// The screen calls `afterTap` on each tap, `afterSaveStarted` the moment a write begins, and
/// `afterSaveFailed` if the write fails. Taps that arrive during a write stay pending for the next one.
class SavePolicy {
  const SavePolicy.clean() : _pendingSince = null, _inFlightSince = null;

  const SavePolicy._(this._pendingSince, this._inFlightSince);

  /// The time of the oldest tap that has not been written.
  final Duration? _pendingSince;

  /// The time of the oldest tap in the batch being written. Restored if the write fails.
  final Duration? _inFlightSince;

  bool get hasPending => _pendingSince != null;

  /// When there are unwritten taps, the latest time they must be written by.
  Duration? get dueAt {
    final since = _pendingSince;
    return since == null ? null : since + SaveTuning.interval;
  }

  SavePolicy afterTap(Duration now) =>
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
      (final a?, final b?) => a < b ? a : b,
    };
    return SavePolicy._(since, null);
  }

  bool shouldSave(SaveTrigger trigger, Duration now) {
    final due = dueAt;
    if (due == null) return false;
    return switch (trigger) {
      SaveTrigger.tick => now >= due,
      SaveTrigger.leaveScreen || SaveTrigger.background => true,
    };
  }
}
