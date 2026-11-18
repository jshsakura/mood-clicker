import 'package:flutter/painting.dart';

import '../../domain/tuning.dart';
import '../tokens.g.dart';

/// How dark a calendar day is drawn, from its number of taps. Gray only: the faces carry the
/// colors, and no mood gets a color of its own here, so a low mood is never drawn in red.
///
/// A day is [steps] shades. The first tap already shows, and a full gauge (60 taps) or more is
/// the darkest.
abstract final class DayShade {
  static const int steps = 4;

  /// 0 for a day without taps, then 1 to [steps].
  static int stepOf(int taps) {
    if (taps <= 0) return 0;
    final share = (taps * GaugeTuning.stepPerTap).clamp(0.0, 1.0);
    return (share * steps).ceil().clamp(1, steps);
  }

  /// The fill of a day cell: the ground color for an empty day, then a ramp from the surface
  /// color toward the muted ink.
  static Color fill(AppPalette p, int taps) {
    final step = stepOf(taps);
    if (step == 0) return p.ground;
    return Color.lerp(p.surface, p.inkMuted, step / steps * 0.75)!;
  }

  /// The color of the day number on that fill.
  static Color onFill(AppPalette p, int taps) {
    final shade = fill(p, taps);
    return _contrast(shade, p.ink) >= _contrast(shade, p.ground)
        ? p.ink
        : p.ground;
  }

  static double _contrast(Color a, Color b) {
    final high = a.computeLuminance() > b.computeLuminance() ? a : b;
    final low = identical(high, a) ? b : a;
    return (high.computeLuminance() + 0.05) / (low.computeLuminance() + 0.05);
  }
}
