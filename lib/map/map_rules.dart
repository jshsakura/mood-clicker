/// The privacy rules of the map, in one place. Everything that reaches the map screen has been
/// through these: places are blocks of about one kilometer, a block with fewer than [minPeople]
/// people is dropped, and an exact position never leaves [GridCell.snap].
library;

import 'package:flutter/foundation.dart';

import '../domain/day_record.dart';
import '../domain/mood.dart';

abstract final class MapRules {
  /// Whether the map is in the app at all. Until a server exists the blocks are made up
  /// (SampleMapSource), and the sheet says so.
  static const bool available = true;

  /// H3 resolution of a block. At 7 a hexagon is about 1.2 km on a side, the "about one
  /// kilometer" block of the screen text.
  static const int h3Resolution = 7;

  /// A block with fewer people than this is hidden.
  static const int minPeople = 5;

  /// Whether the sheet shows the happy and sad ratio, like the weather of a place. Never a rank,
  /// and never a line that sets one place or person against another.
  static const bool showMoodRatio = true;

  /// How the ratio reads when it shows. One line to change once the owner picks.
  static const RatioStyle ratioStyle = RatioStyle.percent;

  /// Hides the ratio right after a heavy mood (sad, anxious, angry) was recorded.
  static const bool hideRatioAfterHeavyMood = false;
}

/// The two ways to tell the ratio of a place.
enum RatioStyle {
  /// "58% on the happy side".
  percent,

  /// No numbers, a line about not being alone: "you are not the only one feeling low today".
  together,
}

/// The three switches around the ratio, bundled so a test can try every combination. The
/// defaults are the constants of [MapRules].
@immutable
class RatioPolicy {
  const RatioPolicy({
    this.show = MapRules.showMoodRatio,
    this.style = MapRules.ratioStyle,
    this.hideAfterHeavyMood = MapRules.hideRatioAfterHeavyMood,
  });

  final bool show;
  final RatioStyle style;
  final bool hideAfterHeavyMood;

  /// Whether the ratio shows for someone whose latest record today is [justRecorded].
  bool visible(Mood? justRecorded) {
    if (!show) return false;
    if (hideAfterHeavyMood && justRecorded?.side == MoodSide.sad) return false;
    return true;
  }
}

/// The mood tapped last today, or null for a day without taps.
Mood? lastRecordedMood(DayRecord day) {
  Mood? last;
  var order = 0;
  for (final entry in day.tallies.entries) {
    if (entry.value.lastOrder > order) {
      order = entry.value.lastOrder;
      last = entry.key;
    }
  }
  return last;
}

/// The id of one H3 block, as the text H3 gives it (15 hex digits at resolution 7). It is only a
/// name for a block: nothing finer than the block fits in it.
@immutable
class H3CellId {
  H3CellId(this.value) {
    if (!isValid(value)) {
      throw FormatException('not an H3 cell id at resolution 7', value);
    }
  }

  final String value;

  /// Checks the header of the 64-bit index: a cell (mode 1) at [MapRules.h3Resolution].
  static bool isValid(String value) {
    if (!RegExp(r'^[0-9a-f]{15}$').hasMatch(value)) return false;
    final full = value.padLeft(16, '0');
    return full.startsWith('08') &&
        full[2] == MapRules.h3Resolution.toRadixString(16);
  }

  @override
  bool operator ==(Object other) => other is H3CellId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// How far back the map looks.
enum MapRange { today, week }

/// One word picked from the prepared sentences. Only the id travels, never typed text.
enum MapWord {
  smiled,
  rest,
  ateWell,
  betterThanExpected,
  tomorrowToo,
  thankful,
}

/// What the map knows about one block.
@immutable
class MapCell {
  const MapCell({
    required this.id,
    required this.mood,
    required this.people,
    required this.taps,
    required this.happyShare,
    required this.word,
  });

  final H3CellId id;

  /// The mood that stands for the block today: the face the map draws on it.
  final Mood mood;
  final int people;
  final int taps;

  /// 0 to 1, the share of people on the happy side.
  final double happyShare;
  final MapWord word;
}

/// What the screen draws. The constructor drops every block under the minimum, so a snapshot
/// can never carry one, whoever built it.
@immutable
class MapSnapshot {
  MapSnapshot({required Iterable<MapCell> cells})
    : cells = List.unmodifiable(
        cells.where((c) => c.people >= MapRules.minPeople),
      );

  final List<MapCell> cells;

  /// People in the shown blocks only, so a hidden block cannot be told from the total.
  int get people => cells.fold(0, (sum, c) => sum + c.people);

  int get taps => cells.fold(0, (sum, c) => sum + c.taps);

  /// Share of happy people over the shown blocks, 0 to 1. Null when nothing is shown.
  double? get happyShare {
    if (people == 0) return null;
    return cells.fold(0.0, (sum, c) => sum + c.happyShare * c.people) / people;
  }
}
