import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/calendar_day_cell.dart';
import 'package:mood_clicker/design/parts/day_shade.dart';
import 'package:mood_clicker/design/tokens.g.dart';

import 'contrast.dart';

/// The smallest contrast of body text (WCAG AA).
const double _readable = 4.5;

void main() {
  for (final p in [lightPalette, darkPalette, pinkPalette]) {
    group(p.name, () {
      test('a day without taps is the ground, a busier day is darker', () {
        expect(DayShade.fill(p, 0, 72), p.ground);
        var last = 0.0;
        for (final taps in [1, 20, 40, 72]) {
          final distance =
              (DayShade.fill(p, taps, 72).computeLuminance() -
                      p.ground.computeLuminance())
                  .abs();
          expect(distance, greaterThan(last), reason: '$taps taps');
          last = distance;
        }
      });

      test('the busiest day is drawn at the strongest share of the ink', () {
        final busiest = DayShade.fill(p, 72, 72);
        final expected = Color.alphaBlend(
          p.ink.withValues(alpha: DayShade.maxAlpha),
          p.ground,
        );
        expect(busiest, expected);
      });

      // The number of a day must read on its own cell in every state a day can be in:
      // picked, today, both, with taps (quiet to busiest) and without.
      for (final taps in [0, 1, 20, 36, 72]) {
        for (final isPicked in [false, true]) {
          for (final isToday in [false, true]) {
            if (!isPicked && !isToday && taps == 0) continue;
            test(
              'the number reads: $taps taps, picked $isPicked, today $isToday',
              () {
                final look = CalendarDayLook.of(
                  p,
                  taps: taps,
                  maxTaps: 72,
                  isPicked: isPicked,
                  isToday: isToday,
                  isFuture: false,
                );
                expect(
                  contrast(look.number, look.fill),
                  greaterThanOrEqualTo(_readable),
                );
              },
            );
          }
        }
      }

      test('a picked day shows a ring that is not its own fill', () {
        final look = CalendarDayLook.of(
          p,
          taps: 72,
          maxTaps: 72,
          isPicked: true,
          isToday: false,
          isFuture: false,
        );
        expect(look.ring, p.ink);
        expect(contrast(look.ring!, look.fill), greaterThanOrEqualTo(3));
      });

      test(
        'today without a pick has a thin ring, a pick has a thicker one',
        () {
          final today = CalendarDayLook.of(
            p,
            taps: 0,
            maxTaps: 1,
            isPicked: false,
            isToday: true,
            isFuture: false,
          );
          final picked = CalendarDayLook.of(
            p,
            taps: 0,
            maxTaps: 1,
            isPicked: true,
            isToday: true,
            isFuture: false,
          );
          expect(today.ring, p.fillEdge);
          expect(today.ringWidth, 1);
          expect(picked.ring, p.ink);
          expect(picked.ringWidth, 1.5);
        },
      );
    });
  }
}
