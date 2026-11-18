import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// The fill that rises from the bottom of the tap screen. [level] is between 0 and 1.
class FillGaugeView extends StatelessWidget {
  const FillGaugeView({super.key, required this.level, this.child});

  final double level;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: ColoredBox(
        color: p.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedFractionallySizedBox(
                duration: Motion.fillRise,
                curve: Curves.easeOut,
                widthFactor: 1,
                heightFactor: level.clamp(0.0, 1.0),
                child: ColoredBox(color: p.fill),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
