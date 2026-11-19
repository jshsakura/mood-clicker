import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/parts/water_sim.dart';
import 'package:mood_clicker/domain/tuning.dart';

WaterSim sim() => WaterSim(random: Random(7))
  ..size = const Size(390, 800)
  ..level = 0.5;

void run(WaterSim s, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    s.step(1 / 60);
  }
}

double peak(WaterSim s) => s.heights.map((h) => h.abs()).reduce(max);

void main() {
  test('a calm surface stays calm', () {
    final s = sim();
    s.step(0.016);
    expect(peak(s), 0);
  });

  test(
    'a hit in the water raises it around the finger and the wave then dies out',
    () {
      final s = sim();
      s.hit(195, insideWater: true);
      s.step(0.05);
      final middle = s.heights[WaterSim.columns ~/ 2];
      expect(middle, greaterThan(1));
      run(s, 12);
      expect(peak(s), lessThan(3));
    },
  );

  test('a hit above the water presses it down', () {
    final s = sim();
    s.hit(195, insideWater: false);
    s.step(0.05);
    expect(s.heights[WaterSim.columns ~/ 2], lessThan(-1));
  });

  test('the wave moves to the neighbors', () {
    final s = sim();
    s.kick(0, FillTuning.kick);
    s.step(0.2);
    expect(s.heights[10].abs(), greaterThan(0));
  });

  test('a stiff, noisy frame does not blow up', () {
    final s = sim();
    s.hit(100, insideWater: true, scale: 2.2);
    for (var i = 0; i < 40; i++) {
      s.step(0.05);
    }
    expect(peak(s), lessThan(200));
    expect(s.heights.every((h) => h.isFinite), isTrue);
  });

  test('the surface line follows the level and the tilt', () {
    final s = sim();
    expect(s.surfaceYAt(100), closeTo(400, 1e-3));
    s.tiltRadians = 0.3;
    // Right edge down: the water runs right, so the surface is higher on the right.
    expect(s.surfaceYAt(390), lessThan(s.surfaceYAt(0)));
    s.tiltRadians = -0.3;
    expect(s.surfaceYAt(390), greaterThan(s.surfaceYAt(0)));
    s.tiltRadians = 0.3;
    expect(s.surfaceYAt(195), closeTo(400, 1e-3));
  });

  test('a steep tilt gathers the water in the low corner and keeps its area', () {
    final s = sim()..level = 0.3;
    s.tiltRadians = 1.4;
    // The surface is held on the screen and the middle sinks below the flat height.
    expect(s.surfaceYAt(195), greaterThan(s.size.height * 0.7));
    for (var x = 0.0; x <= s.size.width; x += 10) {
      expect(s.restingYAt(x), inInclusiveRange(0, s.size.height));
    }
    var area = 0.0;
    const n = 400;
    for (var i = 0; i < n; i++) {
      area += s.size.height - s.restingYAt((i + 0.5) / n * s.size.width);
    }
    expect(area / n / s.size.height, closeTo(0.3, 0.01));
  });

  group('droplets', () {
    test(
      'a tap throws 2 to 5 droplets, twice as many when the gauge fills',
      () {
        final s = sim();
        for (var i = 0; i < 50; i++) {
          expect(s.dropletCount(power: 1), inInclusiveRange(2, 5));
          expect(s.dropletCount(power: 2.2), inInclusiveRange(4, 10));
        }
      },
    );

    test('never more than 40 at once', () {
      final s = sim();
      s.throwDroplets(100, 400, 100);
      expect(s.droplets.length, 40);
    });

    test('fly up, come down and make a small wave where they land', () {
      final s = sim();
      s.throwDroplets(195, 400, 1);
      final d = s.droplets.single;
      expect(d.vy, lessThanOrEqualTo(-220));
      expect(d.vy, greaterThanOrEqualTo(-500));
      expect(d.vx.abs(), lessThanOrEqualTo(90));
      expect(d.radius, inInclusiveRange(2, 5));
      var landed = false;
      for (var i = 0; i < 120 && !landed; i++) {
        s.step(1 / 60);
        landed = s.droplets.isEmpty;
      }
      expect(landed, isTrue);
      expect(peak(s), greaterThan(0));
    });

    test('one that leaves the screen is dropped', () {
      final s = sim();
      s.throwDroplets(1, 400, 5);
      for (final d in s.droplets) {
        d.vx = -5000;
      }
      s.step(0.1);
      expect(s.droplets, isEmpty);
    });
  });

  group('back wave', () {
    test('is the front wave from 200 ms ago, 3 columns on, at 0.75', () {
      final s = sim();
      s.kick(195, FillTuning.kick);
      s.step(1 / 60);
      final early = List<double>.of(s.heights);
      run(s, 0.25);
      final back = s.backHeights();
      expect(back.length, WaterSim.columns);
      expect(back.any((h) => h != 0), isTrue);
      // The first frame's shape is somewhere in the past, so the back wave can't be the front wave.
      expect(back, isNot(equals(s.heights)));
      expect(early.any((h) => h != 0), isTrue);
    });

    test('is flat before anything happened', () {
      final s = sim();
      run(s, 0.5);
      expect(s.backHeights().every((h) => h == 0), isTrue);
    });
  });

  group('ripple while draining', () {
    test('shakes at most 3 columns and nothing when no water was lost', () {
      final s = sim();
      s.ripple(0);
      s.step(0.016);
      expect(peak(s), 0);
      s.ripple(100);
      final moved = s.heights.where((h) => h != 0).length;
      s.step(0.016);
      expect(s.heights.where((h) => h != 0).length, greaterThan(moved));
    });

    test('a tilted surface leans to its low side', () {
      final s = sim();
      s.tiltRadians = 0.4;
      s.ripple(6);
      s.step(0.1);
      // Right side down means the water piles up on the right.
      final right = s.heights.sublist(40).reduce((a, b) => a + b);
      final left = s.heights.sublist(0, 20).reduce((a, b) => a + b);
      expect(right, greaterThan(left));
    });
  });

  group('spilling over the low edge', () {
    WaterSim spilling(double tilt) => sim()
      ..level = 0.8
      ..tiltRadians = tilt
      ..spillAt(0.2);

    test('drops leave over the right edge when the right edge is low', () {
      final s = spilling(0.9);
      for (var i = 0; i < 30; i++) {
        s.step(1 / 60);
      }
      expect(s.spillSide, 1);
      expect(s.runoff, isNotEmpty);
      expect(s.runoff.every((d) => d.x > s.size.width / 2), isTrue);
    });

    test('drops leave over the left edge when the left edge is low', () {
      final s = spilling(-0.9);
      for (var i = 0; i < 30; i++) {
        s.step(1 / 60);
      }
      expect(s.spillSide, -1);
      expect(s.runoff, isNotEmpty);
      expect(s.runoff.every((d) => d.x < s.size.width / 2), isTrue);
    });

    test('no spill means no drops, and the ones in the air fall away', () {
      final s = spilling(0.9);
      for (var i = 0; i < 30; i++) {
        s.step(1 / 60);
      }
      s.spillAt(0);
      for (var i = 0; i < 240; i++) {
        s.step(1 / 60);
      }
      expect(s.runoff, isEmpty);
    });

    test(
      'the stream fades instead of blinking when the spill flickers at capacity',
      () {
        // At capacity the spill rate alternates between a little and none from frame to frame.
        final s = spilling(0.9);
        var previous = s.spillStrength;
        var biggestJump = 0.0;
        var weakest = 1.0;
        for (var i = 0; i < 120; i++) {
          s.spillAt(i.isEven ? 0.2 : 0);
          s.step(1 / 60);
          if (i >= 30) {
            weakest = min(weakest, s.spillStrength);
            biggestJump = max(biggestJump, (s.spillStrength - previous).abs());
          }
          previous = s.spillStrength;
        }
        expect(biggestJump, lessThan(0.15));
        expect(weakest, greaterThan(0.3));
      },
    );

    test('the stream builds up and dies away over time, not in one frame', () {
      final s = spilling(0.9);
      s.step(1 / 60);
      expect(s.spillStrength, lessThan(0.5));
      for (var i = 0; i < 120; i++) {
        s.spillAt(0.2);
        s.step(1 / 60);
      }
      expect(s.spillStrength, greaterThan(0.95));
      s.spillAt(0);
      s.step(1 / 60);
      expect(s.spillStrength, greaterThan(0.9));
      for (var i = 0; i < 240; i++) {
        s.step(1 / 60);
      }
      expect(s.spillStrength, lessThan(0.02));
    });

    test('the side does not flip when the tilt jitters around level', () {
      final s = sim()
        ..level = 0.8
        ..spillAt(0.2);
      final sides = <int>{};
      for (var i = 0; i < 120; i++) {
        s.tiltRadians = i.isEven ? 0.02 : -0.02;
        s.step(1 / 60);
        sides.add(s.spillSide);
      }
      expect(sides, {0});
      expect(s.runoff, isEmpty);
    });

    test('the side holds through jitter around a real lean', () {
      final s = spilling(0.9);
      final sides = <int>{};
      for (var i = 0; i < 120; i++) {
        s.tiltRadians = 0.15 + (i.isEven ? 0.02 : -0.02);
        s.step(1 / 60);
        sides.add(s.spillSide);
      }
      expect(sides, {1});
    });

    test(
      'the side only changes after the tilt passes the margin the other way',
      () {
        final s = spilling(0.9)..step(1 / 60);
        expect(s.spillSide, 1);
        s.tiltRadians = -0.05; // just past level, inside the margin
        s.step(1 / 60);
        expect(s.spillSide, isNot(-1));
        s.tiltRadians = -0.3;
        s.step(1 / 60);
        expect(s.spillSide, -1);
      },
    );
  });
}
