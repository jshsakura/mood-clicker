import 'dart:math';

import 'tuning.dart';

/// Water spilling out of a tilted phone, the way it spills out of a cup. Pure functions.
abstract final class Spill {
  /// The tilt limited to the angle the phone can really use, in radians.
  static double clampTilt(double radians) {
    final limit = FillTuning.tiltLimitDegrees * pi / 180;
    return radians.clamp(-limit, limit);
  }

  /// How far the high edge of the tilted surface is above the top of the screen, as a share of
  /// the screen height. Zero when it is not over the top.
  ///
  /// [level] is the fill level 0 to 1, so the middle of the surface is `level * height` up from
  /// the bottom, and the high edge is `width / 2 * tan(tilt)` higher than that.
  static double overflow({
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    if (screenHeight <= 0 || level <= 0) return 0;
    final tilt = clampTilt(tiltRadians).abs();
    final edge = level * screenHeight + screenWidth / 2 * tan(tilt);
    final over = (edge - screenHeight) / screenHeight;
    return over > 0 ? over : 0;
  }

  /// The fill level that spills per second.
  static double ratePerSecond({
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) =>
      overflow(
        level: level,
        tiltRadians: tiltRadians,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ) *
      FillTuning.spillRate;

  /// The fill level that spills during [elapsed]. Never more than the water in the cup.
  static double spilledIn(
    Duration elapsed, {
    required double level,
    required double tiltRadians,
    required double screenWidth,
    required double screenHeight,
  }) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final wanted =
        seconds *
        ratePerSecond(
          level: level,
          tiltRadians: tiltRadians,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
    return min(max(wanted, 0), max(level, 0)).toDouble();
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
