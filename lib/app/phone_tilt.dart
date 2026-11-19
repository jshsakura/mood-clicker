import 'dart:math';

import 'package:flutter/foundation.dart';

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

/// The tilt angle for one accelerometer reading (x, y in m/s^2): 0 upright, positive when the
/// right edge leans down.
double tiltFromAcceleration(double x, double y, {TargetPlatform? platform}) =>
    atan2(-x * TiltSign.of(platform ?? defaultTargetPlatform), y);
