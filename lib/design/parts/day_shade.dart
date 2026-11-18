import 'package:flutter/painting.dart';

import '../tokens.g.dart';

/// How dark a calendar day is drawn, from its taps against the busiest day of the month, as in
/// the approved sketch: the ink laid over the ground at 5% for the quietest day up to 27% for
/// the busiest one. Gray only: the faces carry the colors, and no mood gets a color of its own
/// here, so a low mood is never drawn in red.
abstract final class DayShade {
  static const double minAlpha = 0.05;
  static const double maxAlpha = 0.27;

  /// The fill of a day cell as an opaque color: the ground for a day without taps, then the ink
  /// over the ground. [maxTaps] is the most taps of any day in the month.
  static Color fill(AppPalette p, int taps, int maxTaps) {
    if (taps <= 0) return p.ground;
    final strength = (taps / (maxTaps < 1 ? 1 : maxTaps)).clamp(0.0, 1.0);
    final alpha = minAlpha + strength * (maxAlpha - minAlpha);
    return Color.alphaBlend(p.ink.withValues(alpha: alpha), p.ground);
  }
}
