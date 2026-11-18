import 'dart:math';

import 'tuning.dart';

/// Water spilling out of a tilted phone, the way it spills out of a cup. Pure functions.
abstract final class Spill {
  /// The tilt limited to the angle the phone can really use, in radians.
  static double clampTilt(double radians) {
    final limit = FillTuning.tiltLimitDegrees * pi / 180;
    return radians.clamp(-limit, limit);
  }

  /// The slope of the surface for a tilt: tan of the tilt limited to
  /// [FillTuning.slopeLimitRadians]. Positive leans the right edge down.
  static double slope(double tiltRadians) {
    final limit = FillTuning.slopeLimitRadians;
    return tan(tiltRadians.clamp(-limit, limit));
  }

  /// The share of the screen that is water when the surface, `centerY` px down from the top at
  /// the middle, has the [slope] (px of height per px across). Measured at
  /// [FillTuning.areaSamples] places, with the surface kept on the screen.
  static double waterArea({
    required double centerY,
    required double slope,
    required double screenWidth,
    required double screenHeight,
  }) {
    if (screenHeight <= 0 || screenWidth <= 0) return 0;
    const n = FillTuning.areaSamples;
    var depth = 0.0;
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) / n * screenWidth;
      final y = centerY + (x - screenWidth / 2) * slope;
      depth += screenHeight - y.clamp(0.0, screenHeight);
    }
    return depth / n / screenHeight;
  }

  /// Where the middle of the surface is, in px down from the top, so that the water on the
  /// screen is exactly [level] of the screen whatever the slope. Found by halving 30 times.
  static double centerY({
    required double level,
    required double slope,
    required double screenWidth,
    required double screenHeight,
  }) {
    final reach = screenHeight + screenWidth / 2 * slope.abs();
    var low = -reach; // all water
    var high = reach; // no water
    for (var i = 0; i < 30; i++) {
      final mid = (low + high) / 2;
      final area = waterArea(
        centerY: mid,
        slope: slope,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      );
      if (area > level) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  /// The most water the screen can hold at this tilt: the high edge just touches the top.
  static double capacity({
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    final m = slope(tiltRadians);
    return waterArea(
      centerY: screenWidth / 2 * m.abs(),
      slope: m,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  /// The part of [level] that does not fit at this tilt. Zero when it fits.
  static double excess({
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    if (screenHeight <= 0 || screenWidth <= 0 || level <= 0) return 0;
    final over =
        level -
        capacity(
          tiltRadians: tiltRadians,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
    return over > 0 ? over : 0;
  }

  /// The fill level that spills per second: [FillTuning.spillRate] times the excess, but at
  /// least [FillTuning.pourMin] while there is any excess.
  static double ratePerSecond({
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    final over = excess(
      level: level,
      tiltRadians: tiltRadians,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
    if (over <= 0) return 0;
    return max(over * FillTuning.spillRate, FillTuning.pourMin);
  }

  /// The fill level that spills during [elapsed]. Never more than the excess, so the water that
  /// still fits stays in the cup.
  static double spilledIn(
    Duration elapsed, {
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    final over = excess(
      level: level,
      tiltRadians: tiltRadians,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
    if (over <= 0) return 0;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final wanted =
        seconds * max(over * FillTuning.spillRate, FillTuning.pourMin);
    return min(max(wanted, 0), over).toDouble();
  }
}

/// Counts spilled water and turns it into lost taps: one tap for every step of water
/// ([GaugeTuning.stepPerTap]). Only spilled water counts; water that faded by itself does not.
/// The part of a step not yet reached is carried over. Immutable.
class SpillLedger {
  const SpillLedger([this.carry = 0]);

  /// Spilled water that has not yet added up to one tap.
  final double carry;

  /// Adds [spilledLevel] and returns the new ledger with how many taps were lost this time.
  (SpillLedger, int) add(double spilledLevel) {
    if (spilledLevel <= 0) return (this, 0);
    final units = (carry + spilledLevel) / GaugeTuning.stepPerTap;
    final lost = (units + 1e-9).floor();
    final left = (units - lost) * GaugeTuning.stepPerTap;
    return (SpillLedger(left < 0 ? 0 : left), lost);
  }
}
