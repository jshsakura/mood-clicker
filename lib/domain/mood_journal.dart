import 'day_key.dart';
import 'day_record.dart';
import 'mood.dart';

/// 모든 날의 기록. 갱신하면 새 객체를 돌려준다.
class MoodJournal {
  MoodJournal(Iterable<DayRecord> records) : _byDay = _index(records);

  MoodJournal.empty() : _byDay = const {};

  final Map<DayKey, DayRecord> _byDay;

  static Map<DayKey, DayRecord> _index(Iterable<DayRecord> records) {
    final map = <DayKey, DayRecord>{};
    for (final record in records) {
      if (map.containsKey(record.day)) {
        throw ArgumentError('같은 날짜의 기록이 둘 있습니다: ${record.day}');
      }
      map[record.day] = record;
    }
    return Map.unmodifiable(map);
  }

  /// 날짜순.
  List<DayRecord> get days {
    final sorted = _byDay.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return List.unmodifiable(sorted);
  }

  DayRecord dayOf(DayKey key) => _byDay[key] ?? DayRecord.empty(key);

  /// 두드린 시각이 속한 날(기기 시간대)에 센다.
  MoodJournal withTap(Mood mood, DateTime at) {
    final record = dayOf(DayKey.of(at)).withTap(mood, at);
    return MoodJournal([
      ..._byDay.values.where((r) => r.day != record.day),
      record,
    ]);
  }
}
