import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/spill.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  const w = 390.0;
  const h = 844.0;
  double overflow(double level, double tilt) => Spill.overflow(
    level: level,
    tiltRadians: tilt,
    screenWidth: w,
    screenHeight: h,
  );

  group('overflow', () {
    test('a level phone spills nothing, however full', () {
      expect(overflow(0.5, 0), 0);
      expect(overflow(1, 0), 0);
    });

    test('an edge that stays under the top spills nothing', () {
      // Half full: the middle is at 422 px, the edge rises 195 * tan(30 deg) = 112 px more.
      expect(overflow(0.5, 30 * pi / 180), 0);
    });

    test(
      'spills by how far the high edge is over the top, as a share of the height',
      () {
        final tilt = 60 * pi / 180;
        final edge = 0.8 * h + 195 * tan(tilt);
        expect(overflow(0.8, tilt), closeTo((edge - h) / h, 1e-9));
        expect(overflow(0.8, tilt), greaterThan(0));
      },
    );

    test('left and right tilt spill the same', () {
      final tilt = 60 * pi / 180;
      expect(overflow(0.8, -tilt), overflow(0.8, tilt));
    });

    test('a fuller cup spills more at the same tilt', () {
      final tilt = 50 * pi / 180;
      expect(overflow(0.9, tilt), greaterThan(overflow(0.6, tilt)));
    });

    test('an empty cup spills nothing at any tilt', () {
      expect(overflow(0, 85 * pi / 180), 0);
    });

    test('the tilt is limited to 85 degrees', () {
      final limit = 85 * pi / 180;
      expect(Spill.clampTilt(2), closeTo(limit, 1e-12));
      expect(Spill.clampTilt(-2), closeTo(-limit, 1e-12));
      expect(overflow(0.5, 1.5), overflow(0.5, 2.5));
    });

    test('no screen height means no spill instead of a crash', () {
      expect(
        Spill.overflow(
          level: 1,
          tiltRadians: 1,
          screenWidth: w,
          screenHeight: 0,
        ),
        0,
      );
    });
  });

  group('rate', () {
    test('is 2 times the overflow share per second', () {
      final tilt = 60 * pi / 180;
      final rate = Spill.ratePerSecond(
        level: 0.8,
        tiltRadians: tilt,
        screenWidth: w,
        screenHeight: h,
      );
      expect(rate, closeTo(overflow(0.8, tilt) * 2, 1e-9));
    });

    test('spilled water over a time never exceeds what is in the cup', () {
      final spilled = Spill.spilledIn(
        const Duration(seconds: 30),
        level: 0.3,
        tiltRadians: 80 * pi / 180,
        screenWidth: w,
        screenHeight: h,
      );
      expect(spilled, 0.3);
    });

    test('spilled water is rate times time when the cup holds enough', () {
      final tilt = 60 * pi / 180;
      final rate = Spill.ratePerSecond(
        level: 0.9,
        tiltRadians: tilt,
        screenWidth: w,
        screenHeight: h,
      );
      final spilled = Spill.spilledIn(
        const Duration(milliseconds: 100),
        level: 0.9,
        tiltRadians: tilt,
        screenWidth: w,
        screenHeight: h,
      );
      expect(spilled, closeTo(rate * 0.1, 1e-12));
    });

    test('a level phone spills nothing over time', () {
      expect(
        Spill.spilledIn(
          const Duration(seconds: 5),
          level: 1,
          tiltRadians: 0,
          screenWidth: w,
          screenHeight: h,
        ),
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

  test('the tuning the spill uses is the agreed 85 degrees and rate 2', () {
    expect(FillTuning.tiltLimitDegrees, 85);
    expect(FillTuning.spillRate, 2);
  });
}
