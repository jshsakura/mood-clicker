import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/day_record.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/surfaces/widget_snapshot.dart';

void main() {
  final noon = DateTime(2030, 3, 4, 12);

  test('an empty day has no mood and a zero count', () {
    final s = WidgetSnapshot.fromRecord(DayRecord.empty(DayKey.of(noon)));
    expect(s.mood, isNull);
    expect(s.count, 0);
    expect(s.day, '2030-03-04');
  });

  test('the dominant mood and the total tap count come from the record', () {
    var r = DayRecord.empty(DayKey.of(noon));
    for (var i = 0; i < 3; i++) {
      r = r.withTap(Mood.sad, noon);
    }
    r = r.withTap(Mood.happy, noon);
    final s = WidgetSnapshot.fromRecord(r);
    expect(s.mood, Mood.sad);
    expect(s.count, 4);
  });

  test('a tie goes to the mood tapped last, as in the record', () {
    var r = DayRecord.empty(DayKey.of(noon));
    r = r.withTap(Mood.sad, noon).withTap(Mood.happy, noon);
    expect(WidgetSnapshot.fromRecord(r).mood, Mood.happy);
  });

  test('equal snapshots compare equal', () {
    final r = DayRecord.empty(DayKey.of(noon)).withTap(Mood.happy, noon);
    expect(WidgetSnapshot.fromRecord(r), WidgetSnapshot.fromRecord(r));
    expect(
      WidgetSnapshot.fromRecord(r),
      isNot(WidgetSnapshot.fromRecord(r.withTap(Mood.happy, noon))),
    );
  });

  test('the widget data map holds only what the native side reads', () {
    final r = DayRecord.empty(DayKey.of(noon)).withTap(Mood.excited, noon);
    expect(WidgetSnapshot.fromRecord(r).toData(), {
      'day': '2030-03-04',
      'mood': 'excited',
      'count': 1,
      'link': 'moodclicker://tap/excited',
    });
    expect(
      WidgetSnapshot.fromRecord(
        DayRecord.empty(DayKey.of(noon)),
      ).toData()['mood'],
      '',
    );
  });
}
