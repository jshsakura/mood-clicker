import 'day_key.dart';
import 'day_record.dart';
import 'mood.dart';

/// The records of every day. Updating returns a new object.
class MoodJournal {
  MoodJournal(Iterable<DayRecord> records) : _byDay = _index(records);

  MoodJournal.empty() : _byDay = const {};

  final Map<DayKey, DayRecord> _byDay;

  static Map<DayKey, DayRecord> _index(Iterable<DayRecord> records) {
    final map = <DayKey, DayRecord>{};
    for (final record in records) {
      if (map.containsKey(record.day)) {
        throw ArgumentError('two records for the same day: ${record.day}');
      }
      map[record.day] = record;
    }
    return Map.unmodifiable(map);
  }

  /// In date order.
  List<DayRecord> get days {
    final sorted = _byDay.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return List.unmodifiable(sorted);
  }

  DayRecord dayOf(DayKey key) => _byDay[key] ?? DayRecord.empty(key);

  /// Counts the tap on the day it happened in (device time zone).
  MoodJournal withTap(Mood mood, DateTime at) {
    final record = dayOf(DayKey.of(at)).withTap(mood, at);
    return MoodJournal([
      ..._byDay.values.where((r) => r.day != record.day),
      record,
    ]);
  }

  /// Sets the note and preset id of a day that already has taps. The note belongs to a day the
  /// user actually tapped, so a day with no record is refused.
  MoodJournal withNote(DayKey day, {String? note, String? presetId}) {
    final record = _byDay[day];
    if (record == null) {
      throw ArgumentError.value(
        day,
        'day',
        'no taps on this day to attach a note to',
      );
    }
    return MoodJournal([
      ..._byDay.values.where((r) => r.day != day),
      record.withNote(note: note, presetId: presetId),
    ]);
  }

  /// Takes taps off one mood of a day: water the phone spilled.
  MoodJournal withTapsRemoved(DayKey day, Mood mood, int count) {
    final record = _byDay[day];
    if (record == null) return this;
    return MoodJournal([
      ..._byDay.values.where((r) => r.day != day),
      record.withTapsRemoved(mood, count),
    ]);
  }
}
