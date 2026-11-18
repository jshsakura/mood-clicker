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

/// Where cheer phrases go and how long they live. Pure functions only.
abstract final class CheerLayout {
  /// The box a phrase takes when centered on [center]. It reaches up by the rise distance.
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
      center.y - height / 2 - CheerTuning.riseDistance,
      center.x + width / 2,
      center.y + height / 2,
    );
  }

  static bool isFree(CheerRect box, Iterable<CheerRect> visible) =>
      !visible.any(box.overlaps);

  /// Whether a phrase may appear at [box]: there is room, and no visible phrase is in the way.
  /// An ordinary tap that fails this only moves the gauge.
  static bool canShow(CheerRect box, List<CheerRect> visible) =>
      hasRoom(visible.length) && isFree(box, visible);

  /// The grid of offsets the full-gauge phrase may use, nearest to the tap first.
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

  /// For the full-gauge phrase: the free box nearest to the tap, or null when all 15 spots are
  /// taken. [bounds] keeps the box on screen when given.
  static CheerRect? findSpot({
    required CheerRect wanted,
    required List<CheerRect> visible,
    CheerRect? bounds,
  }) {
    if (!hasRoom(visible.length)) return null;
    for (final offset in spotOffsets()) {
      final box = wanted.shifted(offset.x, offset.y);
      if (bounds != null && !box.isInside(bounds)) continue;
      if (isFree(box, visible)) return box;
    }
    return null;
  }

  /// The share of its lifetime a visible phrase keeps once [newerCount] newer phrases exist:
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

  static bool hasRoom(int visibleCount) =>
      visibleCount < CheerTuning.maxVisible;
}
