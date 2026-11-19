import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_layout.dart';
import 'package:mood_clicker/domain/tuning.dart';

final _t0 = DateTime(2026, 11, 18, 12);
const _screen = Size2(390, 844);

CheerSlot _slot(
  Point<double> center, {
  String text = 'abcd',
  double size = 20,
  DateTime? at,
  CheerKind kind = CheerKind.normal,
}) => CheerSlot(
  text: text,
  center: center,
  fontSize: size,
  shownAt: at ?? _t0,
  kind: kind,
);

CheerPlacement _show(
  Point<double> tap,
  List<CheerSlot> slots, {
  String text = 'abcd',
  double size = 20,
  DateTime? now,
}) => CheerLayout.show(
  tap: tap,
  text: text,
  fontSize: size,
  slots: slots,
  now: now ?? _t0,
  screen: _screen,
  rotationDegrees: 0,
);

void main() {
  group('size', () {
    double size(
      double level, {
      CheerKind kind = CheerKind.normal,
      int len = 4,
    }) => CheerLayout.fontSizeFor(
      level: level,
      kind: kind,
      length: len,
      screenWidth: 390,
    );

    test('grows with the level: 18, 35 at half, 60 when full', () {
      expect(size(0), 18);
      expect(size(0.5), 35);
      expect(size(1), 60);
    });

    test('a rare phrase is 6 bigger, the complete phrase is 76', () {
      expect(size(0.5, kind: CheerKind.rare), 41);
      expect(size(1, kind: CheerKind.complete), 76);
    });

    test(
      'a long phrase shrinks to 60 percent of the width, the complete one to 90',
      () {
        // 12 units: 390 * 0.6 / (12 * 0.95) = 20.5
        expect(size(1, len: 12), 21);
        // 390 * 0.9 / (12 * 0.95) = 30.8
        expect(size(1, kind: CheerKind.complete, len: 12), 31);
      },
    );

    test('large text scales it before the fit', () {
      final big = CheerLayout.fontSizeFor(
        level: 0,
        kind: CheerKind.normal,
        length: 4,
        screenWidth: 390,
        textScale: 1.18,
      );
      expect(big, 21);
    });

    test('the size is a whole number of pixels', () {
      for (var i = 0; i <= 60; i++) {
        final s = size(i / 60, len: 7);
        expect(s, s.roundToDouble());
      }
    });
  });

  group('motion', () {
    test('an ordinary phrase lives 950 ms, shorter when newer ones exist', () {
      expect(CheerLayout.lifeOf(0, 1), const Duration(milliseconds: 950));
      expect(CheerLayout.lifeOf(1, 2), const Duration(milliseconds: 950));
      expect(CheerLayout.lifeOf(0, 2).inMicroseconds, 807500);
      expect(CheerLayout.lifeOf(0, 3).inMicroseconds, 665000);
      expect(CheerLayout.lifeOf(0, 9).inMicroseconds, 665000);
    });

    test('rare and complete phrases live 1400 and 1700 ms', () {
      expect(CheerLayout.maxLife(CheerKind.rare).inMilliseconds, 1400);
      expect(CheerLayout.maxLife(CheerKind.complete).inMilliseconds, 1700);
    });

    test('rise is 46 px over the life', () {
      expect(CheerLayout.riseAt(0), 0);
      expect(CheerLayout.riseAt(1), 46);
    });

    test(
      'scale starts at 0.45, overshoots to 1.035 at 35 percent, ends at 1.1',
      () {
        expect(CheerLayout.scaleAt(0), closeTo(0.45, 1e-9));
        expect(CheerLayout.scaleAt(0.35), closeTo(1.035, 1e-9));
        expect(CheerLayout.scaleAt(1), closeTo(1.1, 1e-9));
      },
    );

    test('fully visible until 60 percent, then fades to nothing', () {
      expect(CheerLayout.alphaAt(0), 1);
      expect(CheerLayout.alphaAt(0.6), 1);
      expect(CheerLayout.alphaAt(0.8), closeTo(0.5, 1e-9));
      expect(CheerLayout.alphaAt(1), closeTo(0, 1e-9));
    });

    test('a phrase is gone after its maximum life', () {
      final slots = [_slot(const Point(100, 300))];
      expect(
        CheerLayout.alive(slots, _t0.add(const Duration(milliseconds: 949))),
        hasLength(1),
      );
      expect(
        CheerLayout.alive(slots, _t0.add(const Duration(milliseconds: 950))),
        isEmpty,
      );
    });

    test('progress follows the shortened life of an ordinary phrase', () {
      final slots = [
        _slot(const Point(100, 300)),
        _slot(const Point(200, 500)),
      ];
      final now = _t0.add(const Duration(milliseconds: 403));
      // The older of two lives 807.5 ms.
      expect(CheerLayout.progress(slots[0], 0, 2, now), closeTo(0.499, 0.001));
      expect(CheerLayout.progress(slots[1], 1, 2, now), closeTo(0.424, 0.001));
    });
  });

  group('placement', () {
    test('a phrase shows 50 px above the finger', () {
      final p = _show(const Point(200, 500), const []);
      expect(p.added.center, const Point<double>(200, 450));
      expect(p.evictedOldest, isFalse);
    });

    test('the phrase stays between 150 and 700 of an 844 px screen', () {
      expect(_show(const Point(200, 100), const []).added.center.y, 150);
      expect(_show(const Point(200, 840), const []).added.center.y, 700);
    });

    test('the phrase stays on screen beside the edges', () {
      final left = _show(const Point(2, 400), const []);
      expect(left.added.bornBox.left, greaterThanOrEqualTo(0));
      final right = _show(const Point(388, 400), const []);
      expect(right.added.bornBox.right, lessThanOrEqualTo(390));
    });

    test(
      'a second tap on the same spot gets a free spot, never an overlap',
      () {
        final first = _show(const Point(200, 500), const []);
        final second = _show(const Point(200, 500), first.slots);
        expect(second.slots, hasLength(2));
        final a = first.added.bornBox;
        final b = second.added.bornBox;
        expect(a.overlaps(b), isFalse);
      },
    );

    test('a tap off to one side keeps its phrase on that side', () {
      var slots = <CheerSlot>[];
      for (var i = 0; i < 6; i++) {
        final p = _show(const Point(320, 450), slots);
        slots = p.slots;
        expect(p.added.center.x, greaterThan(195), reason: 'tap $i');
      }
      slots = <CheerSlot>[];
      for (var i = 0; i < 6; i++) {
        final p = _show(const Point(70, 450), slots);
        slots = p.slots;
        expect(p.added.center.x, lessThan(195), reason: 'tap $i');
      }
    });

    test('a tap near the middle may go either way', () {
      var slots = <CheerSlot>[];
      final sides = <bool>{};
      for (var i = 0; i < 6; i++) {
        final p = _show(const Point(200, 450), slots);
        slots = p.slots;
        sides.add(p.added.center.x > 195);
      }
      expect(sides, {true, false});
    });

    test('boxes that only touch do not block', () {
      final a = CheerLayout.boxFor(
        center: const Point(100, 100),
        length: 4,
        fontSize: 20,
      );
      final b = a.shifted(a.right - a.left, 0);
      expect(a.overlaps(b), isFalse);
    });

    test(
      'no free spot removes the oldest phrase and still shows the new one',
      () {
        // Giant phrases cover every grid spot.
        final giants = [
          for (var i = 0; i < 3; i++)
            _slot(Point(195, 425.0 + i), text: 'wwwwwwwwwwww', size: 700),
        ];
        final p = _show(const Point(200, 500), giants, now: _t0);
        expect(p.evictedOldest, isTrue);
        expect(p.slots, hasLength(3));
        expect(p.slots.first, same(giants[1]));
        expect(p.added.center, const Point<double>(200, 450));
      },
    );

    test('at most 8 phrases are kept', () {
      var slots = <CheerSlot>[];
      for (var i = 0; i < 20; i++) {
        slots = _show(
          Point(60.0 + (i % 6) * 55, 300.0 + (i % 5) * 80),
          slots,
          now: _t0,
        ).slots;
      }
      expect(slots.length, lessThanOrEqualTo(CheerTuning.maxOnScreen));
    });

    test('expired phrases do not block and are dropped', () {
      final old = _slot(const Point(200, 450));
      final now = _t0.add(const Duration(milliseconds: 1000));
      final p = _show(const Point(200, 500), [old], now: now);
      expect(p.slots, hasLength(1));
      expect(p.added.center, const Point<double>(200, 450));
    });

    test('the grid has 45 spots, the tap spot first, nearest first', () {
      final spots = CheerLayout.spotOffsets();
      expect(spots, hasLength(45));
      expect(spots.first, const Point<double>(0, 0));
      for (var i = 1; i < spots.length; i++) {
        final d0 =
            spots[i - 1].x * spots[i - 1].x + spots[i - 1].y * spots[i - 1].y;
        final d1 = spots[i].x * spots[i].x + spots[i].y * spots[i].y;
        expect(d1, greaterThanOrEqualTo(d0));
      }
    });
  });

  group('the complete phrase', () {
    test('goes to the middle at 360 of 844 and clears every other phrase', () {
      final p = CheerLayout.showComplete(
        screen: _screen,
        text: 'abcdef',
        fontSize: 76,
        now: _t0,
      );
      expect(p.slots, hasLength(1));
      expect(p.added.center, const Point<double>(195, 360));
      expect(p.added.kind, CheerKind.complete);
      expect(p.added.rotationDegrees, -4);
    });

    test('the middle follows the screen height', () {
      final p = CheerLayout.showComplete(
        screen: const Size2(390, 700),
        text: 'a',
        fontSize: 76,
        now: _t0,
      );
      expect(p.added.center.y, closeTo(360 * 700 / 844, 1e-9));
    });
  });

  group('hammering one spot', () {
    for (final gap in [40, 80, 150, 250]) {
      test(
        '30 taps on one point every $gap ms never overlap and stay under 8',
        () {
          var slots = <CheerSlot>[];
          var evictions = 0;
          for (var i = 0; i < 30; i++) {
            final now = _t0.add(Duration(milliseconds: gap * i));
            final before = CheerLayout.blockers(
              CheerLayout.alive(slots, now),
              now,
            );
            final p = CheerLayout.show(
              tap: const Point(200, 500),
              text: 'abcdef',
              fontSize: 24,
              slots: slots,
              now: now,
              screen: _screen,
              rotationDegrees: 0,
            );
            if (p.evictedOldest) {
              evictions++;
            } else {
              for (final o in before) {
                expect(p.added.bornBox.overlaps(o), isFalse, reason: 'tap $i');
              }
            }
            slots = p.slots;
            expect(slots.length, lessThanOrEqualTo(CheerTuning.maxOnScreen));
            expect(slots.last.shownAt, now, reason: 'every tap shows a phrase');
          }
          // A free spot is found almost always; eviction is the rare last resort.
          expect(evictions, lessThanOrEqualTo(4), reason: 'gap $gap');
        },
      );
    }
  });

  test('the numbers of the design', () {
    expect(CheerTuning.riseDistance, 46);
    expect(CheerTuning.spotStepX, 100);
    expect(CheerTuning.spotStepY, 70);
    expect(CheerTuning.spotColumns * CheerTuning.spotRows, 45);
    expect(CheerTuning.blockingShare, 0.7);
    expect(CheerTuning.maxOnScreen, 8);
    expect(CheerTuning.liftAboveFinger, 50);
    expect(CheerTuning.maxWidthShareComplete, 0.9);
  });
}
