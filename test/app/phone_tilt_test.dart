import 'dart:math';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/phone_tilt.dart';
import 'package:mood_clicker/design/parts/water_sim.dart';
import 'package:mood_clicker/domain/spill.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  // Fake readings as sensors_plus delivers them on both platforms: a right edge that leans down
  // makes x negative (the iOS side flips CoreMotion's sign to match Android).
  const rightDown = (x: -4.0, y: 8.9);
  const leftDown = (x: 4.0, y: 8.9);

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    group('on $platform', () {
      double tilt(({double x, double y}) r) =>
          tiltFromAcceleration(r.x, r.y, platform: platform);

      test(
        'upright reads zero, right edge down is positive, left negative',
        () {
          expect(tiltFromAcceleration(0, 9.8, platform: platform), 0);
          expect(tilt(rightDown), greaterThan(0));
          expect(tilt(leftDown), lessThan(0));
        },
      );

      test('tilting right sends the water to the right', () {
        final sim = WaterSim()
          ..size = const Size(390, 844)
          ..level = 0.5
          ..tiltRadians = tilt(rightDown);
        expect(sim.surfaceYAt(380), lessThan(sim.surfaceYAt(10)));
        expect(Spill.lowSide(sim.tiltRadians), 1);
      });

      test('tilting left sends the water to the left', () {
        final sim = WaterSim()
          ..size = const Size(390, 844)
          ..level = 0.5
          ..tiltRadians = tilt(leftDown);
        expect(sim.surfaceYAt(10), lessThan(sim.surfaceYAt(380)));
        expect(Spill.lowSide(sim.tiltRadians), -1);
      });
    });
  }

  group('lying flat', () {
    test('a flat phone reads zero tilt and spills nothing', () {
      expect(tiltFromAcceleration(0, 0), 0);
      expect(tiltFromAcceleration(0, 0, platform: TargetPlatform.iOS), 0);
      expect(
        Spill.excess(
          level: 0.9,
          tiltRadians: tiltFromAcceleration(0, 0),
          screenWidth: 390,
          screenHeight: 844,
        ),
        0,
      );
    });

    test('noise on a flat phone never tilts the water or spills it', () {
      final noise = Random(5);
      for (var i = 0; i < 500; i++) {
        final x = (noise.nextDouble() - 0.5) * 0.8;
        final y = (noise.nextDouble() - 0.5) * 0.8;
        final tilt = tiltFromAcceleration(x, y);
        expect(tilt, 0, reason: 'x=$x y=$y');
        expect(
          Spill.excess(
            level: 0.9,
            tiltRadians: tilt,
            screenWidth: 390,
            screenHeight: 844,
          ),
          0,
        );
      }
    });

    test('upright, a lean to the right still tilts to the right', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          tiltFromAcceleration(-4, 8.9, platform: platform),
          closeTo(atan2(4, 8.9), 1e-9),
        );
        expect(tiltFromAcceleration(4, 8.9, platform: platform), lessThan(0));
      }
    });

    test('laying the phone down slowly eases the tilt smoothly to zero', () {
      // The phone leans 30 degrees right of upright while it tips back onto its back: gravity in
      // the screen plane shrinks from 1 g to 0 as the screen turns to face up.
      const lean = 30 * pi / 180;
      var last = double.infinity;
      var biggestStep = 0.0;
      double? prev;
      for (var back = 0; back <= 90; back++) {
        final inPlane = cos(back * pi / 180) * FillTuning.gravity;
        final x = -sin(lean) * inPlane;
        final y = cos(lean) * inPlane;
        final z = sin(back * pi / 180) * FillTuning.gravity;
        expect(z, greaterThanOrEqualTo(0));
        final tilt = tiltFromAcceleration(x, y);
        expect(tilt, lessThanOrEqualTo(last + 1e-12));
        last = tilt;
        if (prev != null) biggestStep = max(biggestStep, (tilt - prev).abs());
        prev = tilt;
      }
      expect(last, 0);
      expect(
        tiltFromAcceleration(-sin(lean) * 9.8, cos(lean) * 9.8),
        greaterThan(0.4),
      );
      // No jump bigger than 4 degrees from one degree of laying down.
      expect(biggestStep, lessThan(4 * pi / 180));
    });

    test('the weight is 0 flat, 1 upright, and rises without a jump', () {
      expect(tiltWeight(0, 0), 0);
      expect(tiltWeight(0, FillTuning.gravity), 1);
      var before = 0.0;
      for (var g = 0.0; g <= 1.0; g += 0.01) {
        final w = tiltWeight(0, g * FillTuning.gravity);
        expect(w, greaterThanOrEqualTo(before));
        expect(w - before, lessThan(0.06));
        before = w;
      }
    });
  });
}
