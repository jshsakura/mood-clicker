import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/water_sim.dart';

void main() {
  test(
    'droplets drift to the middle while the water gathers, and not otherwise',
    () {
      double meanOffset(double gather) {
        final sim = WaterSim()
          ..size = const Size(400, 800)
          ..level = 0.5
          ..gather = gather;
        sim.droplets
          ..clear()
          ..addAll([Droplet(60, 100, 0, -50, 3), Droplet(340, 100, 0, -50, 3)]);
        for (var i = 0; i < 20; i++) {
          sim.step(0.016);
        }
        return sim.droplets.fold<double>(
              0,
              (sum, d) => sum + (d.x - 200).abs(),
            ) /
            sim.droplets.length;
      }

      expect(meanOffset(1), lessThan(meanOffset(0)));
    },
  );

  test('a tap lands nearer the middle while it gathers', () {
    double edgeHeight(double gather) {
      final sim = WaterSim()
        ..size = const Size(400, 800)
        ..level = 0.5
        ..gather = gather;
      sim.hit(20, insideWater: true);
      for (var i = 0; i < 4; i++) {
        sim.step(0.016);
      }
      return sim.heights.first.abs();
    }

    expect(edgeHeight(1), lessThan(edgeHeight(0)));
  });
}
