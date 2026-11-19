import 'mood.dart';
import 'tuning.dart';

/// Whether a full gauge of [mood] lets the water go (angry, sad, anxious) instead of celebrating.
bool hasRelease(Mood mood) => switch (mood) {
  Mood.angry || Mood.sad || Mood.anxious => true,
  Mood.happy || Mood.excited => false,
};

/// The three stages after the gauge of a heavy mood fills.
enum ReleasePhase {
  /// Tapping. From [ReleaseTuning.approachAt] on, the frame says it is approaching.
  release,

  /// The dawn wash after the gauge is full. Tapping goes on through it.
  cleanse,

  /// The wash has run its course. The one line shows until the level falls again.
  settle,
}

/// What the screen draws at one moment.
class ReleaseFrame {
  const ReleaseFrame({
    required this.phase,
    this.approaching = false,
    this.approach = 0,
    this.cleanse = 0,
    this.blend = 0,
  });

  final ReleasePhase phase;

  /// In release, the level is at or past [ReleaseTuning.approachAt].
  final bool approaching;

  /// 0 at [ReleaseTuning.approachAt], 1 at a full gauge. Always 0 outside release.
  final double approach;

  /// How far the cleanse has gone, 0 to 1. It stays 1 in the settle.
  final double cleanse;

  /// How far the dawn light has dissolved into the settled screen, 0 to 1.
  final double blend;
}

/// The state machine behind the release flow. An immutable value that never reads the clock: callers
/// pass the level of the gauge and the time, and ask for the frame at a time.
class ReleaseFlow {
  const ReleaseFlow.start() : _level = 0, _cleanseStart = null;

  const ReleaseFlow._(this._level, this._cleanseStart);

  final double _level;

  /// When the cleanse began. Null while tapping. The settle is whatever follows the cleanse in time.
  final DateTime? _cleanseStart;

  /// The flow after the gauge showed [level] at [now].
  ReleaseFlow withLevel(double level, DateTime now) {
    final start = _cleanseStart;
    if (start == null) {
      return level >= 1
          ? ReleaseFlow._(level, now)
          : ReleaseFlow._(level, null);
    }
    final settled = _elapsed(start, now) >= ReleaseTuning.cleanse;
    if (settled && level < FillTuning.rearm) return ReleaseFlow._(level, null);
    return ReleaseFlow._(level, start);
  }

  ReleaseFrame frameAt(DateTime now) {
    final start = _cleanseStart;
    if (start == null) {
      final approach =
          ((_level - ReleaseTuning.approachAt) / (1 - ReleaseTuning.approachAt))
              .clamp(0.0, 1.0);
      return ReleaseFrame(
        phase: ReleasePhase.release,
        approaching: _level >= ReleaseTuning.approachAt,
        approach: approach,
      );
    }
    final elapsed = _elapsed(start, now);
    if (elapsed < ReleaseTuning.cleanse) {
      return ReleaseFrame(
        phase: ReleasePhase.cleanse,
        cleanse: _ratio(elapsed, ReleaseTuning.cleanse),
      );
    }
    final settled = elapsed - ReleaseTuning.cleanse;
    return ReleaseFrame(
      phase: ReleasePhase.settle,
      cleanse: 1,
      blend: _ratio(settled, ReleaseTuning.crossfade),
    );
  }

  /// Time since [start], never negative, so a clock that moves back reads as the start.
  static Duration _elapsed(DateTime start, DateTime now) =>
      now.isBefore(start) ? Duration.zero : now.difference(start);

  static double _ratio(Duration part, Duration whole) =>
      (part.inMicroseconds / whole.inMicroseconds).clamp(0.0, 1.0);
}
