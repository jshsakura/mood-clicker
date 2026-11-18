import '../domain/day_record.dart';
import '../domain/mood.dart';
import 'mood_links.dart';

/// What the home screen widget shows: the mood of the day and how many taps there were.
/// It is read from a [DayRecord] and never writes back.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.day,
    required this.mood,
    required this.count,
  });

  factory WidgetSnapshot.fromRecord(DayRecord record) => WidgetSnapshot(
    day: record.day.toString(),
    mood: record.dominantMood,
    count: record.total,
  );

  final String day;

  /// Null when nothing was tapped today.
  final Mood? mood;
  final int count;

  /// The keys the native widgets read. An empty `mood` means no tap yet.
  Map<String, Object> toData() => {
    'day': day,
    'mood': mood?.id ?? '',
    'count': count,
    'link': tapUri(mood).toString(),
  };

  @override
  bool operator ==(Object other) =>
      other is WidgetSnapshot &&
      other.day == day &&
      other.mood == mood &&
      other.count == count;

  @override
  int get hashCode => Object.hash(day, mood, count);
}
