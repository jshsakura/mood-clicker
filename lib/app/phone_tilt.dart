import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/tuning.dart';

/// The sign of the sideways acceleration per platform, as it arrives from sensors_plus.
///
/// Android reports the reaction to gravity, so a right edge that goes down makes x negative. The
/// iOS side of sensors_plus flips CoreMotion's sign on purpose (FPPStreamHandlerPlus multiplies by
/// minus gravity), so both platforms deliver the same direction. If a platform ever changes, only
/// its number here changes.
abstract final class TiltSign {
  static const double android = 1;
  static const double ios = 1;

  static double of(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => ios,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => android,
  };
}

/// How much of the tilt to trust for a reading, 0 to 1. Gravity in the screen plane is
/// sqrt(x^2 + y^2); lying flat it is near zero and the angle is only noise, so the weight is 0
/// below [FillTuning.flatBelow], 1 above [FillTuning.flatFull], and a smoothstep between.
double tiltWeight(double x, double y) {
  final inPlane = sqrt(x * x + y * y) / FillTuning.gravity;
  final t =
      ((inPlane - FillTuning.flatBelow) /
              (FillTuning.flatFull - FillTuning.flatBelow))
          .clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// The tilt angle for one accelerometer reading (x, y in m/s^2): 0 upright, positive when the
/// right edge leans down. A phone lying flat reads 0 (see [tiltWeight]).
double tiltFromAcceleration(double x, double y, {TargetPlatform? platform}) =>
    atan2(-x * TiltSign.of(platform ?? defaultTargetPlatform), y) *
    tiltWeight(x, y);
