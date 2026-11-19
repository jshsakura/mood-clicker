import 'package:flutter/material.dart';

import '../../domain/mood.dart';
import '../tokens.g.dart';
import 'calmap_marks.dart';
import 'day_shade.dart';
import 'pressable_surface.dart';

/// The colors and weight of one calendar day. Kept apart from the widget so a test can check
/// that the number reads on every fill, theme and state.
class CalendarDayLook {
  const CalendarDayLook({
    required this.fill,
    required this.number,
    required this.ring,
    required this.ringWidth,
    required this.bold,
    required this.isPicked,
  });

  /// The cell color, opaque. The ground for a day without taps.
  final Color fill;

  /// The color of the day number.
  final Color number;

  /// The inset ring of the picked day or today, or null.
  final Color? ring;
  final double ringWidth;
  final bool bold;
  final bool isPicked;

  static const double pickedRingWidth = 1.5;
  static const double todayRingWidth = 1;

  /// A future day is dimmed. A day that is picked, today or has taps shows its number in the ink,
  /// so it reads on every shade. A past day without taps is quiet.
  factory CalendarDayLook.of(
    AppPalette p, {
    required int taps,
    required int maxTaps,
    required Mood? mood,
    required bool isPicked,
    required bool isToday,
    required bool isFuture,
  }) {
    final marked = isPicked || isToday;
    final Color number;
    if (isFuture) {
      number = p.fillEdge;
    } else if (marked || taps > 0) {
      number = p.ink;
    } else {
      number = p.faint;
    }
    return CalendarDayLook(
      fill: DayShade.fill(p, taps, maxTaps, mood),
      number: number,
      ring: isPicked ? p.ink : (isToday ? p.fillEdge : null),
      ringWidth: isPicked ? pickedRingWidth : todayRingWidth,
      bold: marked,
      isPicked: isPicked,
    );
  }
}

/// One day of the month grid: a 42 px circle with the number, an inset ring when picked or today,
/// and a small stamp on the corner of a day with a full gauge. Pressable when [onTap] is set.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.look,
    required this.stamped,
    required this.semanticLabel,
    required this.onTap,
  });

  final int day;
  final CalendarDayLook look;
  final bool stamped;
  final String semanticLabel;
  final VoidCallback? onTap;

  static const double size = 42;
  static const double stampOffset = -3;

  @override
  Widget build(BuildContext context) {
    final number = Center(
      child: Text(
        '$day',
        style: TypeScale.cell.copyWith(
          color: look.number,
          fontWeight: look.bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
    final Widget disc = onTap == null
        ? Semantics(
            label: semanticLabel,
            excludeSemantics: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: look.fill,
                shape: BoxShape.circle,
              ),
              child: number,
            ),
          )
        : PressableSurface(
            kind: PressableKind.icon,
            color: look.fill,
            semanticLabel: semanticLabel,
            selected: look.isPicked,
            onTap: onTap,
            child: number,
          );
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: disc),
            if (look.ring != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: look.ring!,
                        width: look.ringWidth,
                      ),
                    ),
                  ),
                ),
              ),
            if (stamped)
              const Positioned(
                right: stampOffset,
                top: stampOffset,
                child: IgnorePointer(child: SmallStampBadge()),
              ),
          ],
        ),
      ),
    );
  }
}
