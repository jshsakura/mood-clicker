import 'day_key.dart';
import 'mood.dart';

class MoodTally {
  const MoodTally({
    required this.count,
    required this.lastTapAt,
    required this.lastOrder,
  });

  final int count;

  /// When the last tap happened by the device clock. Informational only.
  final DateTime lastTapAt;

  /// The serial number of the last tap within its day: 1 for the first tap of the day, counting up
  /// across all moods. "Later" always means a higher serial, so a clock set back cannot reorder taps.
  final int lastOrder;
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

  /// The mood with the most taps. A tie goes to the one tapped last, judged by tap order and not by
  /// the clock. Null when there are no records.
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
      a.count > b.count || (a.count == b.count && a.lastOrder > b.lastOrder);

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
    final order =
        tallies.values.fold(0, (m, t) => t.lastOrder > m ? t.lastOrder : m) + 1;
    return DayRecord(day, {
      ...tallies,
      mood: MoodTally(
        count: (old?.count ?? 0) + 1,
        lastTapAt: last,
        lastOrder: order,
      ),
    });
  }
}
