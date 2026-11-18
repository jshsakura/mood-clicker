import 'tuning.dart';

/// Tracks whether the gauge has stayed in the band just below full long enough to earn the one
/// reward of that gauge. An immutable value; callers pass the level and the time.
///
/// The reward comes once. After it, the next one waits until the level has fallen below
/// [HoldTuning.rearm]. Leaving the band, by falling out or by filling up, restarts the count.
class HoldReward {
  const HoldReward() : _enteredAt = null, _armed = true;

  const HoldReward._(this._enteredAt, this._armed);

  final DateTime? _enteredAt;
  final bool _armed;

  /// The state after seeing [level] at [now], and whether the reward is earned right now.
  (HoldReward, bool) update(double level, DateTime now) {
    final armed = _armed || level < HoldTuning.rearm;
    final inBand = level >= HoldTuning.from && level < 1;
    if (!inBand) return (HoldReward._(null, armed), false);
    if (!armed) return (HoldReward._(null, false), false);
    final entered = _enteredAt ?? now;
    if (now.difference(entered) >= HoldTuning.duration) {
      return (const HoldReward._(null, false), true);
    }
    return (HoldReward._(entered, true), false);
  }
}
