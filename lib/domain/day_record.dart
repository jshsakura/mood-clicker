import 'day_key.dart';
import 'mood.dart';

class MoodTally {
  const MoodTally({required this.count, required this.lastTapAt});

  final int count;
  final DateTime lastTapAt;
}

/// 하루치 기록. 갱신하면 새 객체를 돌려준다.
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

  /// 누적 최다 기분. 동률이면 나중에 두드린 쪽, 시각도 같으면 `Mood` 선언 순서가 앞선 쪽.
  /// 기록이 없으면 null.
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
      throw ArgumentError.value(at, 'at', '$day 의 기록에 다른 날의 두드림을 넣을 수 없습니다');
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
