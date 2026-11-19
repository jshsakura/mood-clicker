import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/spill.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  const w = 390.0;
  const h = 844.0;
  double capacity(double tilt) =>
      Spill.capacity(tiltRadians: tilt, screenWidth: w, screenHeight: h);
  double excess(double level, double tilt) => Spill.excess(
    level: level,
    tiltRadians: tilt,
    screenWidth: w,
    screenHeight: h,
  );
  double spilled(double level, double tilt, Duration d) => Spill.spilledIn(
    d,
    level: level,
    tiltRadians: tilt,
    screenWidth: w,
    screenHeight: h,
  );
  double deg(double d) => d * pi / 180;

  group('water area', () {
    test('a level surface holds the level share', () {
      expect(
        Spill.waterArea(
          centerY: h * 0.7,
          slope: 0,
          screenWidth: w,
          screenHeight: h,
        ),
        closeTo(0.3, 1e-9),
      );
    });

    test(
      'the surface is found so that the area equals the level, at any tilt',
      () {
        for (final tilt in [0.0, 0.4, -0.9, 1.3]) {
          for (final level in [0.05, 0.3, 0.6, 0.95]) {
            final m = Spill.slope(tilt);
            final c = Spill.centerY(
              level: level,
              slope: m,
              screenWidth: w,
              screenHeight: h,
            );
            final area = Spill.waterArea(
              centerY: c,
              slope: m,
              screenWidth: w,
              screenHeight: h,
            );
            expect(
              area,
              closeTo(level, 1e-6),
              reason: 'level $level tilt $tilt',
            );
          }
        }
      },
    );

    test('a level phone keeps the middle at the old height', () {
      final c = Spill.centerY(
        level: 0.4,
        slope: 0,
        screenWidth: w,
        screenHeight: h,
      );
      expect(c, closeTo(h * 0.6, 1e-3));
    });

    test(
      'a steep tilt gathers the water in the low corner: the middle sinks',
      () {
        double centerAt(double tilt) => Spill.centerY(
          level: 0.3,
          slope: Spill.slope(tilt),
          screenWidth: w,
          screenHeight: h,
        );
        expect(centerAt(deg(70)), greaterThan(centerAt(0)));
      },
    );

    test('no screen means no area instead of a crash', () {
      expect(
        Spill.waterArea(centerY: 0, slope: 1, screenWidth: w, screenHeight: 0),
        0,
      );
    });
  });

  group('slope and tilt limit', () {
    test('the slope is minus the tangent of the tilt limited to 1.48 rad', () {
      expect(Spill.slope(0.5), closeTo(-tan(0.5), 1e-12));
      expect(Spill.slope(3), closeTo(-tan(1.48), 1e-12));
      expect(Spill.slope(-3), closeTo(tan(1.48), 1e-12));
    });

    test('the phone tilt is limited to 85 degrees', () {
      final limit = 85 * pi / 180;
      expect(Spill.clampTilt(2), closeTo(limit, 1e-12));
      expect(Spill.clampTilt(-2), closeTo(-limit, 1e-12));
    });
  });

  group('capacity', () {
    test('a level phone holds everything', () {
      expect(capacity(0), closeTo(1, 1e-9));
    });

    test('a tilted phone holds less, and the same either way', () {
      expect(capacity(deg(30)), lessThan(1));
      expect(capacity(deg(60)), lessThan(capacity(deg(30))));
      expect(capacity(-deg(60)), closeTo(capacity(deg(60)), 1e-12));
    });

    test('at the 85 degree limit it is about 0.098', () {
      expect(capacity(1.48), closeTo(0.098, 0.001));
      expect(capacity(2.5), closeTo(0.098, 0.001));
    });
  });

  group('excess and spill', () {
    test('a level phone spills nothing, however full', () {
      expect(excess(1, 0), 0);
      expect(spilled(1, 0, const Duration(seconds: 5)), 0);
    });

    test('water that fits at the tilt spills nothing', () {
      expect(excess(capacity(deg(60)) - 0.01, deg(60)), 0);
      expect(spilled(0.1, deg(30), const Duration(seconds: 5)), 0);
    });

    test('the excess is the level over the capacity', () {
      expect(excess(0.8, deg(60)), closeTo(0.8 - capacity(deg(60)), 1e-12));
    });

    test('an empty cup spills nothing at any tilt', () {
      expect(excess(0, deg(85)), 0);
    });

    test('the rate is 1.2 times the excess, but at least 0.08 a second', () {
      final tilt = deg(60);
      final big = excess(0.9, tilt);
      expect(big * 1.2, greaterThan(0.08));
      expect(
        Spill.ratePerSecond(
          level: 0.9,
          tiltRadians: tilt,
          screenWidth: w,
          screenHeight: h,
        ),
        closeTo(big * 1.2, 1e-12),
      );
      final level = capacity(tilt) + 0.01;
      expect(
        Spill.ratePerSecond(
          level: level,
          tiltRadians: tilt,
          screenWidth: w,
          screenHeight: h,
        ),
        0.08,
      );
    });

    test('spilled water over a time is rate times time', () {
      final tilt = deg(60);
      expect(
        spilled(0.9, tilt, const Duration(milliseconds: 100)),
        closeTo(excess(0.9, tilt) * 1.2 * 0.1, 1e-12),
      );
    });

    test('it never spills more than the excess, so some water stays', () {
      final tilt = deg(85);
      final left = 0.5 - spilled(0.5, tilt, const Duration(seconds: 60));
      expect(left, closeTo(capacity(tilt), 1e-12));
      expect(left, greaterThan(0));
    });

    test(
      'a bit over the capacity still pours at the minimum rate, up to the excess',
      () {
        final tilt = deg(60);
        final level = capacity(tilt) + 0.001;
        expect(
          spilled(level, tilt, const Duration(seconds: 1)),
          closeTo(0.001, 1e-12),
        );
        expect(
          spilled(capacity(tilt) + 0.2, tilt, const Duration(milliseconds: 10)),
          closeTo(0.2 * 1.2 * 0.01, 1e-12),
        );
      },
    );

    test('no screen height means no spill instead of a crash', () {
      expect(
        Spill.excess(level: 1, tiltRadians: 1, screenWidth: w, screenHeight: 0),
        0,
      );
    });
  });

  group('ledger', () {
    const step = 1 / 60;

    test('one step of spilled water is one lost tap', () {
      final (ledger, lost) = const SpillLedger().add(step);
      expect(lost, 1);
      expect(ledger.carry, closeTo(0, 1e-12));
    });

    test('less than a step is carried over until it adds up', () {
      var ledger = const SpillLedger();
      var lost = 0;
      for (var i = 0; i < 10; i++) {
        final (next, n) = ledger.add(step / 4);
        ledger = next;
        lost += n;
      }
      expect(lost, 2);
      expect(ledger.carry, closeTo(step / 2, 1e-12));
    });

    test('a big spill loses several taps at once', () {
      final (ledger, lost) = const SpillLedger().add(step * 3.5);
      expect(lost, 3);
      expect(ledger.carry, closeTo(step / 2, 1e-12));
    });

    test('nothing spilled loses nothing, and a negative value is ignored', () {
      expect(const SpillLedger(0.001).add(0).$2, 0);
      final (ledger, lost) = const SpillLedger(0.001).add(-1);
      expect(lost, 0);
      expect(ledger.carry, 0.001);
    });

    test('the total of many small adds equals the total divided by a step', () {
      var ledger = const SpillLedger();
      var lost = 0;
      for (var i = 0; i < 600; i++) {
        final (next, n) = ledger.add(0.001);
        ledger = next;
        lost += n;
      }
      // 0.6 of water is 36 steps.
      expect(lost, 36);
    });
  });

  test('the tuning the spill uses is the agreed 85 degrees and rate 1.2', () {
    expect(FillTuning.tiltLimitDegrees, 85);
    expect(FillTuning.spillRate, 1.2);
    expect(FillTuning.pourMin, 0.08);
  });

  group('low side hysteresis', () {
    test('level and near level pick no side', () {
      expect(Spill.lowSide(0), 0);
      expect(Spill.lowSide(deg(1)), 0);
      expect(Spill.lowSide(deg(-1.5)), 0);
    });

    test('a real lean picks its side without history', () {
      expect(Spill.lowSide(deg(10)), 1);
      expect(Spill.lowSide(deg(-10)), -1);
    });

    test('a side is kept between the off and on margins', () {
      expect(Spill.lowSide(deg(3), current: 1), 1);
      expect(Spill.lowSide(deg(-3), current: 1), 1);
      expect(Spill.lowSide(deg(3), current: -1), -1);
      expect(Spill.lowSide(deg(3), current: 0), 0);
    });

    test('inside the off margin the side is dropped', () {
      expect(Spill.lowSide(deg(1), current: 1), 0);
      expect(Spill.lowSide(deg(-1), current: -1), 0);
    });

    test('noise around level never flips the side', () {
      var side = 0;
      for (var i = 0; i < 200; i++) {
        side = Spill.lowSide(deg(i.isEven ? 1.5 : -1.5), current: side);
        expect(side, 0);
      }
    });

    test('the other side needs the tilt past the on margin', () {
      expect(Spill.lowSide(deg(-3.9), current: 1), 1);
      expect(Spill.lowSide(deg(-4.1), current: 1), -1);
    });
  });
}
