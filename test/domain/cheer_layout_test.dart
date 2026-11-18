import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_layout.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  const center = Point<double>(200, 400);
  CheerRect boxAt(Point<double> c, {int length = 4, double size = 44}) =>
      CheerLayout.boxFor(center: c, length: length, fontSize: size);

  group('box', () {
    test('width, height and rise follow the agreed formula', () {
      final box = boxAt(center);
      const width = 4 * 44 * 0.95 + 16;
      const height = 44 * 1.25;
      expect(box.right - box.left, closeTo(width, 1e-9));
      expect(box.bottom - box.top, closeTo(height + 46, 1e-9));
      expect((box.left + box.right) / 2, closeTo(200, 1e-9));
      expect(box.bottom, closeTo(400 + height / 2, 1e-9));
    });

    test('stage font sizes are 38, 44 and 52', () {
      expect(CheerStage.values.map((s) => s.fontSize), [38, 44, 52]);
    });
  });

  group('free spot test', () {
    test('an empty screen is free', () {
      expect(CheerLayout.canShow(boxAt(center), const []), isTrue);
    });

    test('a tap inside a visible phrase, or its rise track, is blocked', () {
      final shown = boxAt(center);
      expect(CheerLayout.canShow(boxAt(center), [shown]), isFalse);
      // Directly above, 30 px up: inside the 46 px rise track.
      expect(
        CheerLayout.canShow(boxAt(const Point(200, 370)), [shown]),
        isFalse,
      );
    });

    test('a tap far enough away is free, and touching edges do not count', () {
      final shown = boxAt(center);
      expect(
        CheerLayout.canShow(boxAt(const Point(200, 700)), [shown]),
        isTrue,
      );
      final next = shown.shifted(shown.right - shown.left, 0);
      expect(CheerLayout.canShow(next, [shown]), isTrue);
    });

    test('a long phrase blocks more width than a short one', () {
      final wide = boxAt(center, length: 12);
      final tap = boxAt(const Point(200 + 150, 400), length: 1, size: 38);
      expect(CheerLayout.isFree(tap, [wide]), isFalse);
      expect(CheerLayout.isFree(tap, [boxAt(center, length: 2)]), isTrue);
    });

    test('with 8 phrases visible nothing new is shown', () {
      final visible = [
        for (var i = 0; i < 8; i++) boxAt(Point(100.0 + i * 400, 100)),
      ];
      expect(
        CheerLayout.canShow(boxAt(const Point(5000, 900)), visible),
        isFalse,
      );
      expect(CheerLayout.hasRoom(7), isTrue);
      expect(CheerLayout.hasRoom(8), isFalse);
    });
  });

  group('findSpot for the full gauge', () {
    test('the grid has 15 spots, the tap itself first', () {
      final spots = CheerLayout.spotOffsets();
      expect(spots, hasLength(15));
      expect(spots.first, const Point<double>(0, 0));
      expect(spots.toSet(), hasLength(15));
      expect(spots.map((p) => p.x).toSet(), {-120.0, 0.0, 120.0});
      expect(spots.map((p) => p.y).toSet(), {-180.0, -90.0, 0.0, 90.0, 180.0});
    });

    test('uses the tap spot when it is free', () {
      final wanted = boxAt(center, size: 52);
      expect(CheerLayout.findSpot(wanted: wanted, visible: const []), wanted);
    });

    test('moves to the nearest free spot when the tap spot is taken', () {
      final wanted = boxAt(center, size: 52);
      final blocker = boxAt(center, size: 52);
      final spot = CheerLayout.findSpot(wanted: wanted, visible: [blocker]);
      expect(spot, isNotNull);
      expect(CheerLayout.isFree(spot!, [blocker]), isTrue);
      final dx = spot.left - wanted.left;
      final dy = spot.top - wanted.top;
      // The nearest offsets are the 90 px vertical ones, before the 120 px horizontal ones,
      // but those are inside the blocker's rise track, so a farther one wins.
      expect(dx * dx + dy * dy, greaterThan(0));
      expect([-120.0, 0.0, 120.0], contains(dx));
      expect([-180.0, -90.0, 0.0, 90.0, 180.0], contains(dy));
    });

    test('returns null when all 15 spots are taken', () {
      final wanted = boxAt(center, size: 52);
      final blocker = CheerRect(-9999, -9999, 9999, 9999);
      expect(CheerLayout.findSpot(wanted: wanted, visible: [blocker]), isNull);
    });

    test('skips spots that fall off the screen', () {
      final wanted = boxAt(const Point(60, 80), size: 52);
      const bounds = CheerRect(0, 0, 400, 800);
      final spot = CheerLayout.findSpot(
        wanted: wanted,
        visible: [wanted],
        bounds: bounds,
      );
      expect(spot, isNotNull);
      expect(spot!.isInside(bounds), isTrue);
    });

    test('gives up when 8 phrases are already visible', () {
      final visible = [
        for (var i = 0; i < 8; i++) boxAt(Point(100.0 + i * 400, 100)),
      ];
      expect(
        CheerLayout.findSpot(
          wanted: boxAt(const Point(5000, 900)),
          visible: visible,
        ),
        isNull,
      );
    });
  });

  group('lifetime', () {
    test('the newest keeps all of it, then 60 percent, then 35 percent', () {
      expect(CheerLayout.lifetimeShare(0), 1);
      expect(CheerLayout.lifetimeShare(1), 0.6);
      expect(CheerLayout.lifetimeShare(2), 0.35);
      expect(CheerLayout.lifetimeShare(7), 0.35);
    });

    test('lifetimes are 800, 480 and 280 ms', () {
      expect(CheerLayout.lifetimeFor(0), const Duration(milliseconds: 800));
      expect(CheerLayout.lifetimeFor(1), const Duration(milliseconds: 480));
      expect(CheerLayout.lifetimeFor(2), const Duration(milliseconds: 280));
    });
  });

  test(
    'there is no time gap rule: a quick second tap on a free spot shows',
    () {
      final first = boxAt(center);
      final second = boxAt(const Point(200, 800));
      expect(CheerLayout.canShow(second, [first]), isTrue);
      expect(CheerTuning.maxVisible, 8);
    },
  );
}
