import 'tuning.dart';

/// An immutable value for how hard the user is tapping, from 0 to 1. It never reads the clock; callers pass the time.
class FillGauge {
  const FillGauge.empty() : _level = 0, _lastTapAt = null, justFilled = false;

  const FillGauge._(this._level, this._lastTapAt, {this.justFilled = false});

  /// The level right after the last tap.
  final double _level;
  final DateTime? _lastTapAt;

  /// True only on the value returned by the tap that took the gauge from not full to full.
  /// Use it to play the one-time full effect. It is false on every later value.
  final bool justFilled;

  static const double _epsilon = 1e-9;

  double valueAt(DateTime now) {
    final last = _lastTapAt;
    if (last == null) return 0;
    final elapsed = now.difference(last);
    if (elapsed <= GaugeTuning.grace) return _level;
    final decaySeconds =
        (elapsed - GaugeTuning.grace).inMicroseconds /
        Duration.microsecondsPerSecond;
    final value = _level - decaySeconds * GaugeTuning.decayPerSecond;
    if (value < _epsilon) return 0;
    return value > 1 ? 1 : value;
  }

  bool isFullAt(DateTime now) => _isFull(valueAt(now));

  FillGauge tap(DateTime now) {
    final last = _lastTapAt;
    final at = (last != null && now.isBefore(last)) ? last : now;
    final before = valueAt(at);
    final next = before + GaugeTuning.stepPerTap;
    final level = next > 1 ? 1.0 : next;
    final filled = _isFull(level) && !_isFull(before);
    return FillGauge._(level, at, justFilled: filled);
  }

  /// The gauge after [amount] of water spilled out of the phone. Only the level drops: the time
  /// of the last tap stays, so the grace time and the decay carry on as before.
  FillGauge spilled(double amount) {
    if (amount <= 0) return this;
    final next = _level - amount;
    return FillGauge._(next < 0 ? 0 : next, _lastTapAt);
  }

  static bool _isFull(double level) => level >= 1 - _epsilon;

  /// When the level reaches 0 if the taps stop now. Null when already empty.
  DateTime? get emptiesAt {
    final last = _lastTapAt;
    if (last == null || _level <= 0) return null;
    final decayMicros =
        (_level / GaugeTuning.decayPerSecond * Duration.microsecondsPerSecond)
            .round();
    return last.add(GaugeTuning.grace + Duration(microseconds: decayMicros));
  }
}
