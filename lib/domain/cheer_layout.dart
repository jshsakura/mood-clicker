import 'dart:math';

import 'tuning.dart';

/// An axis-aligned box in screen pixels.
class CheerRect {
  const CheerRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Boxes that only touch along an edge do not overlap.
  bool overlaps(CheerRect other) =>
      left < other.right &&
      other.left < right &&
      top < other.bottom &&
      other.top < bottom;

  bool isInside(CheerRect outer) =>
      left >= outer.left &&
      top >= outer.top &&
      right <= outer.right &&
      bottom <= outer.bottom;

  CheerRect shifted(double dx, double dy) =>
      CheerRect(left + dx, top + dy, right + dx, bottom + dy);

  @override
  bool operator ==(Object other) =>
      other is CheerRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'CheerRect($left, $top, $right, $bottom)';
}

/// A phrase on screen: where it was born and when. Immutable.
class CheerSlot {
  const CheerSlot(this.bornBox, this.shownAt);

  final CheerRect bornBox;
  final DateTime shownAt;
}

/// The result of one tap: the new slot list and where the new phrase goes.
class CheerPlacement {
  const CheerPlacement({
    required this.slots,
    required this.box,
    required this.evictedOldest,
  });

  /// All slots after the tap, oldest first, the new phrase last. A new list every time.
  final List<CheerSlot> slots;
  final CheerRect box;

  /// True when no spot was free and the oldest phrase was removed to make room.
  final bool evictedOldest;
}

/// Where cheer phrases go and how long they live. Pure functions only: the screen keeps the
/// slot list, replaces it with what [show] returns, and the frame loop never rewrites it.
abstract final class CheerLayout {
  /// The box a phrase takes when centered on [center].
  static CheerRect boxFor({
    required Point<double> center,
    required int length,
    required double fontSize,
  }) {
    final width =
        length * fontSize * CheerTuning.widthPerSize + CheerTuning.boxPadding;
    final height = fontSize * CheerTuning.heightPerSize;
    return CheerRect(
      center.x - width / 2,
      center.y - height / 2,
      center.x + width / 2,
      center.y + height / 2,
    );
  }

  /// How far up a phrase of the given age has floated, in pixels.
  static double riseAt(Duration age) {
    final progress = age.inMicroseconds / CheerTuning.lifetime.inMicroseconds;
    return CheerTuning.riseDistance * progress.clamp(0.0, 1.0);
  }

  /// Where the slot is drawn at [now].
  static CheerRect currentBox(CheerSlot slot, DateTime now) =>
      slot.bornBox.shifted(0, -riseAt(_age(slot, now)));

  /// The share of its lifetime a phrase keeps once [newerCount] newer phrases exist:
  /// 1 for the newest, 0.6 for the one before it, 0.35 for the one before that and older.
  static double lifetimeShare(int newerCount) => switch (newerCount) {
    <= 0 => 1,
    1 => CheerTuning.previousLifetimeShare,
    _ => CheerTuning.olderLifetimeShare,
  };

  static Duration lifetimeFor(int newerCount) => Duration(
    microseconds:
        (CheerTuning.lifetime.inMicroseconds * lifetimeShare(newerCount))
            .round(),
  );

  /// Slots that have not run out of life yet, oldest first.
  static List<CheerSlot> alive(List<CheerSlot> slots, DateTime now) => [
    for (var i = 0; i < slots.length; i++)
      if (_age(slots[i], now) < lifetimeFor(slots.length - 1 - i)) slots[i],
  ];

  /// The boxes that block a new phrase at [now]: only phrases still in the first 70 percent
  /// of their own lifetime, each at the place it has floated to by now.
  static List<CheerRect> blockers(List<CheerSlot> slots, DateTime now) => [
    for (var i = 0; i < slots.length; i++)
      if (_isBlocking(slots[i], slots.length - 1 - i, now))
        currentBox(slots[i], now),
  ];

  static bool _isBlocking(CheerSlot slot, int newerCount, DateTime now) {
    final limit =
        lifetimeFor(newerCount).inMicroseconds * CheerTuning.blockingShare;
    return _age(slot, now).inMicroseconds < limit;
  }

  static Duration _age(CheerSlot slot, DateTime now) {
    final age = now.difference(slot.shownAt);
    return age.isNegative ? Duration.zero : age;
  }

  /// Offsets of the search grid, nearest to the tap first. The tap spot itself is first.
  static List<Point<double>> spotOffsets() {
    final columns = CheerTuning.spotColumns ~/ 2;
    final rows = CheerTuning.spotRows ~/ 2;
    final spots = [
      for (var row = -rows; row <= rows; row++)
        for (var col = -columns; col <= columns; col++)
          Point<double>(
            col * CheerTuning.spotStepX,
            row * CheerTuning.spotStepY,
          ),
    ];
    // sort is stable, so ties keep grid order and the result is deterministic.
    spots.sort((a, b) => _distance(a).compareTo(_distance(b)));
    return spots;
  }

  static double _distance(Point<double> p) => p.x * p.x + p.y * p.y;

  /// Handles one tap. A phrase always appears: at the tap if it is free, else at the nearest
  /// free grid spot (kept on screen when [bounds] is given), else at the tap after the oldest
  /// phrase is removed. Expired phrases are dropped first.
  static CheerPlacement show({
    required Point<double> tap,
    required int length,
    required double fontSize,
    required List<CheerSlot> slots,
    required DateTime now,
    CheerRect? bounds,
  }) {
    final live = alive(slots, now);
    final blocking = blockers(live, now);
    final wanted = boxFor(center: tap, length: length, fontSize: fontSize);

    for (final offset in spotOffsets()) {
      final box = wanted.shifted(offset.x, offset.y);
      if (bounds != null && !box.isInside(bounds)) continue;
      if (blocking.any(box.overlaps)) continue;
      return CheerPlacement(
        slots: List.unmodifiable([...live, CheerSlot(box, now)]),
        box: box,
        evictedOldest: false,
      );
    }
    final kept = live.isEmpty ? live : live.sublist(1);
    return CheerPlacement(
      slots: List.unmodifiable([...kept, CheerSlot(wanted, now)]),
      box: wanted,
      evictedOldest: live.isNotEmpty,
    );
  }
}
