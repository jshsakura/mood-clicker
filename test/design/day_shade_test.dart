import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/day_shade.dart';
import 'package:mood_clicker/design/tokens.g.dart';

void main() {
  test('steps: none, then four, the darkest from a full gauge on', () {
    expect(DayShade.stepOf(0), 0);
    expect(DayShade.stepOf(1), 1);
    expect(DayShade.stepOf(15), 1);
    expect(DayShade.stepOf(16), 2);
    expect(DayShade.stepOf(45), 3);
    expect(DayShade.stepOf(46), 4);
    expect(DayShade.stepOf(60), 4);
    expect(DayShade.stepOf(500), 4);
  });

  for (final p in [lightPalette, darkPalette, pinkPalette]) {
    test(
      '${p.name}: the shades are gray steps that only darken toward the ink',
      () {
        expect(DayShade.fill(p, 0), p.ground);
        var last = -1.0;
        for (final taps in [1, 16, 31, 46]) {
          final color = DayShade.fill(p, taps);
          final distance =
              (color.computeLuminance() - p.surface.computeLuminance()).abs();
          expect(distance, greaterThanOrEqualTo(last));
          last = distance;
        }
      },
    );

    test('${p.name}: the number stays readable on every shade', () {
      for (final taps in [1, 16, 31, 46]) {
        final fill = DayShade.fill(p, taps);
        final on = DayShade.onFill(p, taps);
        final hi = fill.computeLuminance() > on.computeLuminance() ? fill : on;
        final lo = hi == fill ? on : fill;
        final ratio =
            (hi.computeLuminance() + 0.05) / (lo.computeLuminance() + 0.05);
        expect(ratio, greaterThan(3), reason: '${p.name} at $taps taps');
      }
    });
  }
}
