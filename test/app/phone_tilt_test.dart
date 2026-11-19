import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/app/phone_tilt.dart';
import 'package:mood_clicker/design/parts/water_sim.dart';

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
        expect(sim.spillSide, 1);
      });

      test('tilting left sends the water to the left', () {
        final sim = WaterSim()
          ..size = const Size(390, 844)
          ..level = 0.5
          ..tiltRadians = tilt(leftDown);
        expect(sim.surfaceYAt(10), lessThan(sim.surfaceYAt(380)));
        expect(sim.spillSide, -1);
      });
    });
  }
}
