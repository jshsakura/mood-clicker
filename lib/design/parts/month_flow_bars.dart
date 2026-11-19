import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/mood.dart';
import '../app_theme.dart';
import '../tokens.g.dart';

/// One thin bar per day of the month, as tall as the taps of that day against the busiest day.
/// The picked day is drawn in the color of its mood, other days with taps in a paler one, a day
/// without taps is a short line. Pressing a bar (or pressing and holding) picks that day and opens
/// a bubble with its date and taps. A press anywhere else closes the bubble.
class MonthFlowBars extends StatefulWidget {
  const MonthFlowBars({
    super.key,
    required this.taps,
    required this.moods,
    required this.picked,
    required this.onPick,
    required this.label,
    this.lastDay,
  });

  /// The taps of each day, the first entry is day 1.
  final List<int> taps;

  /// The mood that colors each day's bar, null for a day without taps.
  final List<Mood?> moods;

  /// The picked day of the month (1 based), or null when another month's day is picked.
  final int? picked;
  final ValueChanged<int> onPick;

  /// The date and taps of a day, shown in the bubble and read by screen readers.
  final String Function(int day) label;

  /// The last day that can be pressed, null for all. Later days are still ahead.
  final int? lastDay;

  static const double height = 40;
  static const double gap = 3;
  static const double emptyHeight = 2;
  static const double minHeight = 3;
  static const double paleAlpha = 0.45;
  static const double cornerRadius = 2;
  static const double bubbleGap = 6;
  static const double bubbleHeight = 28;

  /// The height of a day's bar.
  static double barHeight(int taps, int maxTaps) {
    if (taps <= 0) return emptyHeight;
    return math.max(minHeight, (taps / maxTaps * height).roundToDouble());
  }

  @override
  State<MonthFlowBars> createState() => _MonthFlowBarsState();
}

class _MonthFlowBarsState extends State<MonthFlowBars> {
  int? _bubbleDay;

  bool _pressable(int day) => widget.lastDay == null || day <= widget.lastDay!;

  void _press(int day) {
    if (!_pressable(day)) return;
    setState(() => _bubbleDay = day);
    widget.onPick(day);
  }

  void _close() {
    if (_bubbleDay != null) setState(() => _bubbleDay = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final taps = widget.taps;
    final maxTaps = taps.fold<int>(1, math.max);
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / taps.length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.line)),
                ),
                child: SizedBox(
                  height: MonthFlowBars.height,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < taps.length; i++)
                        Expanded(child: _bar(p, i, maxTaps)),
                    ],
                  ),
                ),
              ),
              if (_bubbleDay != null)
                _bubble(p, _bubbleDay!, slot, constraints.maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(AppPalette p, int i, int maxTaps) {
    final day = i + 1;
    final taps = widget.taps[i];
    final mood = widget.moods[i];
    final isPicked = widget.picked == day;
    final color = taps > 0 && mood != null ? p.moodColor(mood) : p.line;
    return Semantics(
      button: true,
      selected: isPicked,
      label: widget.label(day),
      excludeSemantics: true,
      onTap: () => _press(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _press(day),
        onLongPress: () => _press(day),
        child: Padding(
          padding: EdgeInsets.only(
            left: i == 0 ? 0 : MonthFlowBars.gap / 2,
            right: i == widget.taps.length - 1 ? 0 : MonthFlowBars.gap / 2,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: isPicked ? 1 : (taps > 0 ? MonthFlowBars.paleAlpha : 1),
              child: SizedBox(
                height: MonthFlowBars.barHeight(taps, maxTaps),
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(MonthFlowBars.cornerRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The bubble above the pressed bar, kept inside the width of the bars.
  Widget _bubble(AppPalette p, int day, double slot, double width) {
    final center = slot * (day - 0.5);
    return Positioned(
      left: 0,
      right: 0,
      bottom: MonthFlowBars.height + MonthFlowBars.bubbleGap,
      height: MonthFlowBars.bubbleHeight,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: CustomSingleChildLayout(
            delegate: _BubbleLayout(center),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.ink,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.xs,
                ),
                child: Text(
                  widget.label(day),
                  maxLines: 1,
                  style: TypeScale.label.copyWith(color: p.ground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the bubble centered on [center], moved in when it would leave the width.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout(this.center);

  final double center;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = (center - childSize.width / 2)
        .clamp(0.0, math.max(0.0, size.width - childSize.width))
        .toDouble();
    return Offset(left, size.height - childSize.height);
  }

  @override
  bool shouldRelayout(_BubbleLayout old) => old.center != center;
}
