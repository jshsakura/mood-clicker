import 'package:flutter/material.dart';

import '../../domain/tuning.dart';
import '../../l10n/app_localizations.g.dart';
import '../app_theme.dart';
import '../tokens.g.dart';

/// How full a breath is at [elapsed] since the start, from 0 (empty) to 1 (full): it grows for
/// [ReleaseTuning.inhale], shrinks for [ReleaseTuning.exhale], and repeats.
double breathAt(Duration elapsed) {
  final cycle = ReleaseTuning.inhale + ReleaseTuning.exhale;
  final inCycle = Duration(
    microseconds: elapsed.inMicroseconds % cycle.inMicroseconds,
  );
  if (inCycle < ReleaseTuning.inhale) {
    return Curves.easeInOut.transform(
      inCycle.inMicroseconds / ReleaseTuning.inhale.inMicroseconds,
    );
  }
  final out =
      (inCycle - ReleaseTuning.inhale).inMicroseconds /
      ReleaseTuning.exhale.inMicroseconds;
  return 1 - Curves.easeInOut.transform(out);
}

/// One still picture of the ring at a [fullness] from 0 to 1. [diameter] is the size when full.
///
/// With [reduceMotion] the size stays put and only the brightness follows the breath.
class BreathingRingView extends StatelessWidget {
  const BreathingRingView({
    super.key,
    required this.fullness,
    required this.diameter,
    this.reduceMotion = false,
  });

  /// The smallest the ring gets, as a share of [diameter].
  static const double minScale = 0.6;

  /// The brightness range of the ring line. Reduced motion uses all of it, otherwise it is steady.
  static const double dimAlpha = 0.35;
  static const double fullAlpha = 0.9;

  final double fullness;
  final double diameter;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = fullness.clamp(0.0, 1.0);
    final scale = reduceMotion ? 1.0 : minScale + (1 - minScale) * f;
    final alpha = reduceMotion
        ? dimAlpha + (fullAlpha - dimAlpha) * f
        : fullAlpha;
    return SizedBox.square(
      dimension: diameter,
      child: Center(
        child: SizedBox.square(
          dimension: diameter * scale,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: CircleBorder(
                side: BorderSide(
                  color: p.inkMuted.withValues(alpha: alpha),
                  width: Space.xs,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The breathing ring: a circle that grows for 4 seconds and shrinks for 6, with no words, so a
/// person can follow it or not. With the reduced motion setting it changes brightness, not size.
class BreathingRing extends StatefulWidget {
  const BreathingRing({super.key, required this.diameter});

  final double diameter;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: ReleaseTuning.inhale + ReleaseTuning.exhale,
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final cycle = _clock.duration!;
    return Semantics(
      label: AppLocalizations.of(context).release_breathingRing,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => BreathingRingView(
          fullness: breathAt(cycle * _clock.value),
          diameter: widget.diameter,
          reduceMotion: reduce,
        ),
      ),
    );
  }
}
