import 'day_key.dart';
import 'mood.dart';

class MoodTally {
  const MoodTally({required this.count, required this.lastTapAt});

  final int count;
  final DateTime lastTapAt;
}

/// One day of records. Updating returns a new object.
class DayRecord {
  DayRecord(this.day, Map<Mood, MoodTally> tallies)
    : tallies = Map.unmodifiable(tallies);

  DayRecord.empty(DayKey day) : this(day, const {});

  final DayKey day;
  final Map<Mood, MoodTally> tallies;

  int countOf(Mood mood) => tallies[mood]?.count ?? 0;

  int get total => tallies.values.fold(0, (sum, t) => sum + t.count);

  int get happyTotal => _totalOf(MoodSide.happy);

  int get sadTotal => _totalOf(MoodSide.sad);

  int _totalOf(MoodSide side) => tallies.entries
      .where((e) => e.key.side == side)
      .fold(0, (sum, e) => sum + e.value.count);

  /// The mood with the most taps. A tie goes to the one tapped later; if the times match too,
  /// to the one declared first in `Mood`. Null when there are no records.
  Mood? get dominantMood {
    Mood? best;
    for (final mood in Mood.values) {
      final tally = tallies[mood];
      if (tally == null) continue;
      final current = best == null ? null : tallies[best];
      if (current == null || _beats(tally, current)) best = mood;
    }
    return best;
  }

  static bool _beats(MoodTally a, MoodTally b) =>
      a.count > b.count ||
      (a.count == b.count && a.lastTapAt.isAfter(b.lastTapAt));

  DayRecord withTap(Mood mood, DateTime at) {
    if (DayKey.of(at) != day) {
      throw ArgumentError.value(
        at,
        'at',
        'a tap on another day cannot go into the record of $day',
      );
    }
    final old = tallies[mood];
    final last = (old != null && old.lastTapAt.isAfter(at))
        ? old.lastTapAt
        : at;
    return DayRecord(day, {
      ...tallies,
      mood: MoodTally(count: (old?.count ?? 0) + 1, lastTapAt: last),
    });
  }
}
