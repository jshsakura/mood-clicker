import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// One thin bar per day of the month, as tall as the taps of that day against the busiest day.
/// The picked day is the ink, other days with taps are a pale ink, a day without taps is a short
/// line. Tapping a bar picks that day.
class MonthFlowBars extends StatelessWidget {
  const MonthFlowBars({
    super.key,
    required this.taps,
    required this.picked,
    required this.onPick,
    required this.semanticLabel,
  });

  /// The taps of each day, the first entry is day 1.
  final List<int> taps;

  /// The picked day of the month (1 based), or null when another month's day is picked.
  final int? picked;
  final ValueChanged<int> onPick;
  final String Function(int day) semanticLabel;

  static const double height = 40;
  static const double gap = 3;
  static const double emptyHeight = 2;
  static const double minHeight = 3;
  static const double paleAlpha = 0.22;
  static const double cornerRadius = 2;

  /// The height of a day's bar.
  static double barHeight(int taps, int maxTaps) {
    if (taps <= 0) return emptyHeight;
    return math.max(minHeight, (taps / maxTaps * height).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxTaps = taps.fold<int>(1, math.max);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < taps.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: picked == i + 1,
                  label: semanticLabel(i + 1),
                  excludeSemantics: true,
                  onTap: () => onPick(i + 1),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(i + 1),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : gap / 2,
                        right: i == taps.length - 1 ? 0 : gap / 2,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Opacity(
                          opacity: picked == i + 1
                              ? 1
                              : (taps[i] > 0 ? paleAlpha : 1),
                          child: SizedBox(
                            height: barHeight(taps[i], maxTaps),
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: taps[i] > 0 ? p.ink : p.line,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(cornerRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
