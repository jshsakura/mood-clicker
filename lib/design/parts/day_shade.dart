import 'package:flutter/painting.dart';

import '../../domain/mood.dart';
import '../app_theme.dart';
import '../tokens.g.dart';

/// How strong a calendar day is drawn, from its taps against the busiest day of the month: the
/// color of the day's mood laid over the ground at 5% for the quietest day up to 27% for the
/// busiest one. The number on it stays the ink.
abstract final class DayShade {
  static const double minAlpha = 0.05;
  static const double maxAlpha = 0.27;

  /// The fill of a day cell as an opaque color: the ground for a day without taps, then the color
  /// of [mood] over the ground. [maxTaps] is the most taps of any day in the month.
  static Color fill(AppPalette p, int taps, int maxTaps, Mood? mood) {
    if (taps <= 0) return p.ground;
    final strength = (taps / (maxTaps < 1 ? 1 : maxTaps)).clamp(0.0, 1.0);
    final alpha = minAlpha + strength * (maxAlpha - minAlpha);
    return Color.alphaBlend(
      (mood == null ? p.ink : p.moodColor(mood)).withValues(alpha: alpha),
      p.ground,
    );
  }
}
