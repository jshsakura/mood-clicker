import 'dart:math';

import 'cheer.dart';
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

/// A phrase on screen: the text, where it was born, how big, and when. Immutable.
class CheerSlot {
  const CheerSlot({
    required this.text,
    required this.center,
    required this.fontSize,
    required this.shownAt,
    this.kind = CheerKind.normal,
    this.rotationDegrees = 0,
  });

  final String text;
  final Point<double> center;
  final double fontSize;
  final DateTime shownAt;
  final CheerKind kind;
  final int rotationDegrees;

  /// Length in UTF-16 units, the way the design measures a phrase.
  int get length => text.length;

  /// Where the phrase is born, before it floats up.
  CheerRect get bornBox =>
      CheerLayout.boxFor(center: center, length: length, fontSize: fontSize);
}

/// The result of one tap: the new slot list. The new phrase is last.
class CheerPlacement {
  const CheerPlacement({required this.slots, required this.evictedOldest});

  final List<CheerSlot> slots;

  /// True when no spot was free and the oldest phrase was removed to make room.
  final bool evictedOldest;

  CheerSlot get added => slots.last;
}

/// Where cheer phrases go, how big they are and how they move. Pure functions only: the screen
/// keeps the slot list and replaces it with what [show] returns. All numbers come from the
/// approved Tap canvas.
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

  /// The whole-pixel font size for a phrase of [length] units. It grows with the fill level
  /// (18 + level^1.3 * 42), a rare one is 6 bigger, the complete phrase has its own size, the
  /// large text setting scales it by [textScale], and any phrase is shrunk until its text fits
  /// in 60 percent of [screenWidth] (90 percent for the complete one).
  static double fontSizeFor({
    required double level,
    required CheerKind kind,
    required int length,
    required double screenWidth,
    double textScale = 1,
  }) {
    final wanted = switch (kind) {
      CheerKind.complete => CheerTuning.fontSizeComplete,
      CheerKind.normal => _levelSize(level),
      CheerKind.rare => _levelSize(level) + CheerTuning.fontSizeRareBonus,
    };
    final share = kind == CheerKind.complete
        ? CheerTuning.maxWidthShareComplete
        : CheerTuning.maxWidthShare;
    final scaled = wanted * textScale;
    if (length <= 0) return scaled.roundToDouble();
    final fits = screenWidth * share / (length * CheerTuning.widthPerSize);
    return min(scaled, fits).roundToDouble();
  }

  static double _levelSize(double level) =>
      (CheerTuning.fontSizeBase +
              pow(level.clamp(0.0, 1.0), CheerTuning.fontSizeExponent) *
                  CheerTuning.fontSizeSpan)
          .roundToDouble();

  /// How long a phrase of [kind] can live at most.
  static Duration maxLife(CheerKind kind) => kind.lifetime;

  /// The life of an ordinary phrase at position [index] of [count] phrases, oldest first: the
  /// newest keeps all of it, the one before 0.85 and every older one 0.7.
  static Duration lifeOf(int index, int count) {
    final newer = count - 1 - index;
    final share = switch (newer) {
      <= 0 => 1.0,
      1 => CheerTuning.previousLifetimeShare,
      _ => CheerTuning.olderLifetimeShare,
    };
    return Duration(
      microseconds: (CheerTuning.lifetime.inMicroseconds * share).round(),
    );
  }

  /// Slots that have not reached their maximum life yet, oldest first.
  static List<CheerSlot> alive(List<CheerSlot> slots, DateTime now) => [
    for (final slot in slots)
      if (_age(slot, now) < maxLife(slot.kind)) slot,
  ];

  /// How far through its life the phrase at [index] of the alive [count] phrases is, 0 to 1. A
  /// special phrase uses its own life; an ordinary one the shortened life of its position, so a
  /// newer phrase makes older ones leave sooner.
  static double progress(CheerSlot slot, int index, int count, DateTime now) {
    final life = slot.kind == CheerKind.normal
        ? lifeOf(index, count)
        : maxLife(slot.kind);
    return (_age(slot, now).inMicroseconds / life.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// How far up a phrase has floated at progress [a], in pixels.
  static double riseAt(double a) => CheerTuning.riseDistance * a;

  /// The scale at progress [a]: small at birth, a little over in the middle of the pop, then
  /// slowly growing until it is gone.
  static double scaleAt(double a) {
    final g = min(1.0, a / CheerTuning.popInShare);
    final back = 1 + 2.2 * pow(g - 1, 3) + 1.2 * pow(g - 1, 2);
    return 0.45 + 0.55 * back + 0.1 * a;
  }

  /// Fully visible until [CheerTuning.fadeStart], then fading out.
  static double alphaAt(double a) => a < CheerTuning.fadeStart
      ? 1
      : 1 - (a - CheerTuning.fadeStart) / (1 - CheerTuning.fadeStart);

  /// The boxes that block a new phrase at [now]: phrases still in the first 70 percent of their
  /// shortened life, each at the place it has floated to by now. Every given slot counts, so pass
  /// the list as the screen holds it.
  static List<CheerRect> blockers(List<CheerSlot> slots, DateTime now) => [
    for (var i = 0; i < slots.length; i++)
      if (_blocking(slots, i, now))
        slots[i].bornBox.shifted(
          0,
          -riseAt(
            _age(slots[i], now).inMicroseconds /
                lifeOf(i, slots.length).inMicroseconds,
          ),
        ),
  ];

  static bool _blocking(List<CheerSlot> slots, int i, DateTime now) =>
      _age(slots[i], now).inMicroseconds /
          lifeOf(i, slots.length).inMicroseconds <
      CheerTuning.blockingShare;

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
    // Ties keep grid order (Dart's sort is not stable, so the index breaks them).
    final order = [for (var i = 0; i < spots.length; i++) i];
    order.sort((a, b) {
      final byDistance = _distance(spots[a]).compareTo(_distance(spots[b]));
      return byDistance != 0 ? byDistance : a.compareTo(b);
    });
    return [for (final i in order) spots[i]];
  }

  static double _distance(Point<double> p) => p.x * p.x + p.y * p.y;

  static double _clamp(double v, double lo, double hi) =>
      hi < lo ? (lo + hi) / 2 : v.clamp(lo, hi);

  /// The moment the gauge becomes full: one complete phrase in the middle of the screen, and every
  /// other phrase is cleared.
  static CheerPlacement showComplete({
    required Size2 screen,
    required String text,
    required double fontSize,
    required DateTime now,
  }) {
    final center = Point<double>(
      screen.width / 2,
      screen.height * CheerTuning.completeY / CheerTuning.referenceHeight,
    );
    return CheerPlacement(
      slots: List.unmodifiable([
        CheerSlot(
          text: text,
          center: center,
          fontSize: fontSize,
          shownAt: now,
          kind: CheerKind.complete,
          rotationDegrees: CheerTuning.completeTiltDegrees,
        ),
      ]),
      evictedOldest: false,
    );
  }

  /// Handles one tap at [tap]. The phrase appears [CheerTuning.liftAboveFinger] above the
  /// finger if that spot is free, else at the nearest free spot of the grid (kept on screen, and
  /// on the tap's own side unless the tap is near the middle), else at the finger after the oldest
  /// phrase is removed. A phrase always appears.
  static CheerPlacement show({
    required Point<double> tap,
    required String text,
    required double fontSize,
    required List<CheerSlot> slots,
    required DateTime now,
    required Size2 screen,
    required int rotationDegrees,
    CheerKind kind = CheerKind.normal,
  }) {
    final aim = Point<double>(tap.x, tap.y - CheerTuning.liftAboveFinger);
    final found = _freeSpot(text, fontSize, aim, slots, now, screen);
    final center = found ?? _fallback(text, fontSize, aim, screen);
    final live = alive(slots, now);
    final kept = found != null || live.isEmpty ? live : live.sublist(1);
    final added = CheerSlot(
      text: text,
      center: center,
      fontSize: fontSize,
      shownAt: now,
      kind: kind,
      rotationDegrees: rotationDegrees,
    );
    final all = [...kept, added];
    final from = max(0, all.length - CheerTuning.maxOnScreen);
    return CheerPlacement(
      slots: List.unmodifiable(all.sublist(from)),
      evictedOldest: found == null && live.isNotEmpty,
    );
  }

  static double _half(String text, double size) =>
      text.length * size * CheerTuning.widthPerSize / 2 + 8;

  static double _minY(Size2 s) =>
      s.height * CheerTuning.spotTop / CheerTuning.referenceHeight;
  static double _maxY(Size2 s) =>
      s.height * CheerTuning.spotBottom / CheerTuning.referenceHeight;

  static Point<double> _fallback(
    String text,
    double size,
    Point<double> aim,
    Size2 screen,
  ) {
    final half = _half(text, size);
    return Point(
      _clamp(aim.x, half + 8, screen.width - half - 8),
      _clamp(aim.y, _minY(screen), _maxY(screen)),
    );
  }

  /// The first spot, nearest to [aim] first, where the phrase overlaps nothing that is still on
  /// screen. Null when there is none.
  static Point<double>? _freeSpot(
    String text,
    double size,
    Point<double> aim,
    List<CheerSlot> slots,
    DateTime now,
    Size2 screen,
  ) {
    final taken = blockers(slots, now);
    final half = _half(text, size);
    final middle = screen.width / 2;
    for (final offset in spotOffsets()) {
      final cx = _clamp(aim.x + offset.x, half + 8, screen.width - half - 8);
      // A tap off to one side keeps its phrase on that side.
      if ((aim.x - middle).abs() > CheerTuning.sideDeadZone &&
          (cx - middle) * (aim.x - middle) < 0) {
        continue;
      }
      final cy = _clamp(aim.y + offset.y, _minY(screen), _maxY(screen));
      final center = Point<double>(cx, cy);
      final box = boxFor(center: center, length: text.length, fontSize: size);
      if (taken.every((o) => !box.overlaps(o))) return center;
    }
    return null;
  }
}

/// A width and a height in pixels, so the domain does not need Flutter's Size.
class Size2 {
  const Size2(this.width, this.height);

  final double width;
  final double height;
}
