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
  });

  group('rise and blocking', () {
    test('a phrase floats up 46 px over its lifetime, never more', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.currentBox(slot, at(0)), slot.bornBox);
      expect(
        CheerLayout.currentBox(slot, at(475)).top,
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
      final now = CheerLayout.blockers([slot], at(475)).single;
      expect(now.top, closeTo(slot.bornBox.top - 23, 1e-9));
    });

    test('a phrase stops blocking after 70 percent of its lifetime', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.blockers([slot], at(664)), hasLength(1));
      expect(CheerLayout.blockers([slot], at(665)), isEmpty);
    });

    test('older phrases have a shorter life and stop blocking sooner', () {
      final older = CheerSlot(boxAt(center), t0);
      final newer = CheerSlot(boxAt(const Point(200, 800)), at(10));
      // The older one now has 85 percent of 950 ms = 807.5 ms; 70 percent of that is 565.25 ms.
      expect(CheerLayout.blockers([older, newer], at(565)), hasLength(2));
      expect(CheerLayout.blockers([older, newer], at(566)), hasLength(1));
    });

    test('expired phrases are dropped', () {
      final slot = CheerSlot(boxAt(center), t0);
      expect(CheerLayout.alive([slot], at(949)), hasLength(1));
      expect(CheerLayout.alive([slot], at(950)), isEmpty);
    });

    test('lifetimes are 950 ms, then 85 percent, then 70 percent', () {
      expect(CheerLayout.lifetimeFor(0), const Duration(milliseconds: 950));
      expect(CheerLayout.lifetimeFor(1), const Duration(microseconds: 807500));
      expect(CheerLayout.lifetimeFor(2), const Duration(milliseconds: 665));
      expect(CheerLayout.lifetimeFor(9), const Duration(milliseconds: 665));
    });

    test('complete lives 1700 ms and rare 1400 ms before the shrink', () {
      expect(
        CheerLayout.lifetimeFor(0, kind: CheerKind.complete),
        const Duration(milliseconds: 1700),
      );
      expect(
        CheerLayout.lifetimeFor(0, kind: CheerKind.rare),
        const Duration(milliseconds: 1400),
      );
      expect(
        CheerLayout.lifetimeFor(1, kind: CheerKind.rare),
        const Duration(milliseconds: 1190),
      );
    });

    test('a rare phrase floats up over its own, longer life', () {
      final slot = CheerSlot(boxAt(center), t0, kind: CheerKind.rare);
      expect(
        CheerLayout.currentBox(slot, at(700)).top,
        closeTo(slot.bornBox.top - 23, 1e-9),
      );
      expect(CheerLayout.alive([slot], at(1399)), hasLength(1));
      expect(CheerLayout.alive([slot], at(1400)), isEmpty);
    });
  });

  group('font size', () {
    double size(
      double level, {
      CheerKind kind = CheerKind.normal,
      int length = 4,
      double width = 400,
    }) => CheerLayout.fontSizeFor(
      level: level,
      kind: kind,
      length: length,
      screenWidth: width,
    );

    test('grows from 18 to 60 with the fill, slowly at first', () {
      expect(size(0), 18);
      expect(size(0.5), closeTo(35.05, 0.01));
      expect(size(1), 60);
      expect(size(2), 60);
      expect(size(-1), 18);
      expect(size(0.25), lessThan(25));
    });

    test('a rare phrase is 6 bigger', () {
      expect(size(0, kind: CheerKind.rare, width: 1000), 24);
      expect(size(1, kind: CheerKind.rare, width: 1000), 66);
      // On a 400 px screen the 60 percent cap holds it back: 4 characters fit at 60.
      expect(size(1, kind: CheerKind.rare), 60);
    });

    test('the complete phrase is 76', () {
      expect(size(1, kind: CheerKind.complete, length: 3), 76);
    });

    test(
      'a long phrase is shrunk to fit in 60 percent of the screen width',
      () {
        final fitted = size(1, length: 12, width: 390);
        final box = boxAt(const Point(195, 400), length: 12, size: fitted);
        expect(box.right - box.left, closeTo(390 * 0.6, 1e-9));
        expect(fitted, lessThan(60));
      },
    );

    test('a phrase that already fits keeps its size', () {
      expect(size(0.5, length: 2, width: 400), closeTo(35.05, 0.01));
    });

    test('the complete phrase is also kept inside 60 percent', () {
      final fitted = size(1, kind: CheerKind.complete, length: 12, width: 390);
      final box = boxAt(const Point(195, 400), length: 12, size: fitted);
      expect(box.right - box.left, lessThanOrEqualTo(390 * 0.6 + 1e-9));
    });
  });

  group('complete moment', () {
    test('shows one phrase at the center and clears all others', () {
      final others = tapAt(center, const [], 0);
      final more = tapAt(const Point(200, 800), others.slots, 10);
      final result = CheerLayout.showComplete(
        center: const Point(195, 422),
        length: 4,
        fontSize: 76,
        now: at(20),
      );
      expect(more.slots, hasLength(2));
      expect(result.slots, hasLength(1));
      expect(result.slots.single.kind, CheerKind.complete);
      expect(result.box, boxAt(const Point(195, 422), size: 76));
    });
  });

  group('side of the screen', () {
    const centerX = 200.0;
    CheerPlacement tap(double x, List<CheerSlot> slots, int ms) =>
        CheerLayout.show(
          tap: Point(x, 400),
          length: 4,
          fontSize: 44,
          slots: slots,
          now: at(ms),
          screenCenterX: centerX,
        );

    double middle(CheerRect r) => (r.left + r.right) / 2;

    test('a left tap keeps its phrase on the left, even when pushed away', () {
      var slots = <CheerSlot>[];
      for (var i = 0; i < 12; i++) {
        final result = tap(40, slots, i * 5);
        expect(middle(result.box), lessThan(centerX), reason: 'tap $i');
        slots = result.slots;
      }
    });

    test('a right tap keeps its phrase on the right', () {
      var slots = <CheerSlot>[];
      for (var i = 0; i < 12; i++) {
        final result = tap(360, slots, i * 5);
        expect(middle(result.box), greaterThan(centerX), reason: 'tap $i');
        slots = result.slots;
      }
    });

    test('a tap inside the 60 px center zone may use either side', () {
      var slots = <CheerSlot>[];
      final sides = <bool>{};
      for (var i = 0; i < 20; i++) {
        final result = tap(centerX + 30, slots, i * 5);
        sides.add(middle(result.box) < centerX);
        slots = result.slots;
      }
      expect(sides, {true, false});
    });

    test('without a screen center there is no side rule', () {
      final result = CheerLayout.show(
        tap: const Point(40, 400),
        length: 4,
        fontSize: 44,
        slots: const [],
        now: t0,
      );
      expect(result.box, boxAt(const Point(40, 400)));
    });
  });

  test('a rare phrase is stored as rare', () {
    final result = CheerLayout.show(
      tap: center,
      length: 4,
      fontSize: 44,
      slots: const [],
      now: t0,
      kind: CheerKind.rare,
    );
    expect(result.slots.single.kind, CheerKind.rare);
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
        final second = tapAt(center, first.slots, 700);
        // 700 ms is past 70 percent of 950 ms, so the same spot is free again.
        expect(second.box, boxAt(center));
      },
    );

    test('expired phrases leave the list', () {
      final first = tapAt(center, const [], 0);
      final second = tapAt(center, first.slots, 1000);
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
