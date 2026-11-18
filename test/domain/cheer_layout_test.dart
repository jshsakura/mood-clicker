import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_layout.dart';
import 'package:mood_clicker/domain/tuning.dart';

void main() {
  final t0 = DateTime(2026, 11, 18, 12);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));
  const center = Point<double>(200, 400);

  CheerRect boxAt(Point<double> c, {int length = 4, double size = 44}) =>
      CheerLayout.boxFor(center: c, length: length, fontSize: size);

  CheerPlacement tapAt(
    Point<double> point,
    List<CheerSlot> slots,
    int ms, {
    CheerRect? bounds,
  }) => CheerLayout.show(
    tap: point,
    length: 4,
    fontSize: 44,
    slots: slots,
    now: at(ms),
    bounds: bounds,
  );

  group('box', () {
    test('width and height follow the formula, centered on the tap', () {
      final box = boxAt(center);
      expect(box.right - box.left, closeTo(4 * 44 * 0.95 + 12, 1e-9));
      expect(box.bottom - box.top, closeTo(44 * 1.2, 1e-9));
      expect((box.left + box.right) / 2, closeTo(200, 1e-9));
      expect((box.top + box.bottom) / 2, closeTo(400, 1e-9));
    });

    test('stage font sizes are 38, 44 and 52', () {
      expect(CheerStage.values.map((s) => s.fontSize), [38, 44, 52, 52]);
    });
  });

  group('rise and blocking', () {
    test('a phrase floats up 46 px over its lifetime, never more', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.currentBox(slot, at(0)), slot.bornBox);
      expect(
        CheerLayout.currentBox(slot, at(400)).top,
        closeTo(slot.bornBox.top - 23, 1e-9),
      );
      expect(
        CheerLayout.currentBox(slot, at(5000)).top,
        closeTo(slot.bornBox.top - 46, 1e-9),
      );
    });

    test(
      'the future rise is not reserved: the spot above is free at first',
      () {
        final slot = CheerSlot(boxAt(center), t0);
        final above = boxAt(const Point(200, 400 - 40));
        expect(CheerLayout.blockers([slot], at(0)).any(above.overlaps), isTrue);
        // Straight above, just clear of the phrase box itself: free now.
        final clear = boxAt(Point(200, 400 - 44 * 1.2 - 1));
        expect(
          CheerLayout.blockers([slot], at(0)).any(clear.overlaps),
          isFalse,
        );
      },
    );

    test('a phrase blocks at the place it has floated to', () {
      final slot = CheerSlot(boxAt(center), t0);
      final now = CheerLayout.blockers([slot], at(400)).single;
      expect(now.top, closeTo(slot.bornBox.top - 23, 1e-9));
    });

    test('a phrase stops blocking after 70 percent of its lifetime', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.blockers([slot], at(559)), hasLength(1));
      expect(CheerLayout.blockers([slot], at(560)), isEmpty);
    });

    test('older phrases have a shorter life and stop blocking sooner', () {
      final older = CheerSlot(boxAt(center), t0);
      final newer = CheerSlot(boxAt(const Point(200, 800)), at(10));
      // The older one now has 60 percent of 800 ms = 480 ms, 70 percent of that is 336 ms.
      expect(CheerLayout.blockers([older, newer], at(335)), hasLength(2));
      expect(CheerLayout.blockers([older, newer], at(340)), hasLength(1));
    });

    test('expired phrases are dropped', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.alive([slot], at(799)), hasLength(1));
      expect(CheerLayout.alive([slot], at(800)), isEmpty);
    });

    test('lifetimes are 800, 480 and 280 ms', () {
      expect(CheerLayout.lifetimeFor(0), const Duration(milliseconds: 800));
      expect(CheerLayout.lifetimeFor(1), const Duration(milliseconds: 480));
      expect(CheerLayout.lifetimeFor(2), const Duration(milliseconds: 280));
      expect(CheerLayout.lifetimeFor(9), const Duration(milliseconds: 280));
    });
  });

  group('show', () {
    test('an empty screen puts the phrase at the tap', () {
      final result = tapAt(center, const [], 0);
      expect(result.box, boxAt(center));
      expect(result.slots, hasLength(1));
      expect(result.evictedOldest, isFalse);
    });

    test('there is no time gap: a quick second tap on a free spot shows', () {
      final first = tapAt(center, const [], 0);
      final second = tapAt(const Point(200, 800), first.slots, 10);
      expect(second.box, boxAt(const Point(200, 800)));
      expect(second.slots, hasLength(2));
    });

    test('a blocked tap moves to the nearest free grid spot', () {
      final first = tapAt(center, const [], 0);
      final second = tapAt(center, first.slots, 10);
      expect(second.evictedOldest, isFalse);
      expect(
        second.box.overlaps(CheerLayout.currentBox(first.slots.single, at(10))),
        isFalse,
      );
      final dx = second.box.left - boxAt(center).left;
      final dy = second.box.top - boxAt(center).top;
      expect([for (var c = -2; c <= 2; c++) c * 100.0], contains(dx));
      expect([for (var r = -4; r <= 4; r++) r * 70.0], contains(dy));
      // Nothing nearer was free: every closer grid spot overlaps the first phrase.
      final nearer = CheerLayout.spotOffsets().takeWhile(
        (o) => o.x != dx || o.y != dy,
      );
      for (final o in nearer) {
        expect(
          boxAt(center).shifted(o.x, o.y).overlaps(first.slots.single.bornBox),
          isTrue,
        );
      }
    });

    test('the grid has 45 spots, the tap itself first, nearest first', () {
      final spots = CheerLayout.spotOffsets();
      expect(spots, hasLength(45));
      expect(spots.first, const Point<double>(0, 0));
      expect(spots.toSet(), hasLength(45));
      final distances = [for (final p in spots) p.x * p.x + p.y * p.y];
      expect(distances, orderedEquals([...distances]..sort()));
    });

    test(
      'when nothing is free the oldest goes and the phrase takes the tap',
      () {
        final wall = CheerRect(-9999, -9999, 9999, 9999);
        final slots = [
          CheerSlot(wall, t0),
          CheerSlot(boxAt(const Point(5000, 5000)), at(1)),
        ];
        final result = tapAt(center, slots, 2);
        expect(result.evictedOldest, isTrue);
        expect(result.box, boxAt(center));
        expect(result.slots, hasLength(2));
        expect(result.slots.first.bornBox, boxAt(const Point(5000, 5000)));
        expect(result.slots.last.shownAt, at(2));
      },
    );

    test('keeps the phrase on screen when bounds are given', () {
      final first = tapAt(const Point(60, 80), const [], 0);
      const bounds = CheerRect(0, 0, 400, 800);
      final second = tapAt(
        const Point(60, 80),
        first.slots,
        10,
        bounds: bounds,
      );
      expect(second.box.isInside(bounds), isTrue);
    });

    test('never changes the list it was given', () {
      final first = tapAt(center, const [], 0);
      final before = List.of(first.slots);
      tapAt(center, first.slots, 10);
      expect(first.slots, orderedEquals(before));
      expect(() => first.slots.add(first.slots.first), throwsUnsupportedError);
    });

    test(
      'a phrase that is only floating away no longer blocks a fast tapper',
      () {
        final first = tapAt(center, const [], 0);
        final second = tapAt(center, first.slots, 600);
        // 600 ms is past 70 percent of 800 ms, so the same spot is free again.
        expect(second.box, boxAt(center));
      },
    );

    test('expired phrases leave the list', () {
      final first = tapAt(center, const [], 0);
      final second = tapAt(center, first.slots, 900);
      expect(second.slots, hasLength(1));
    });
  });

  test('every box number comes from tuning', () {
    expect(CheerTuning.riseDistance, 46);
    expect(CheerTuning.spotStepX, 100);
    expect(CheerTuning.spotStepY, 70);
    expect(CheerTuning.spotColumns * CheerTuning.spotRows, 45);
    expect(CheerTuning.blockingShare, 0.7);
  });
}
