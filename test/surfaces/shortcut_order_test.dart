import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/domain/mood_journal.dart';
import 'package:mood_clicker/surfaces/shortcut_order.dart';

MoodJournal taps(MoodJournal j, Mood mood, DateTime day, int n) {
  for (var i = 0; i < n; i++) {
    j = j.withTap(mood, DateTime(day.year, day.month, day.day, 12));
  }
  return j;
}

void main() {
  final today = DayKey.of(DateTime(2030, 3, 20));
  DateTime ago(int days) => DateTime(2030, 3, 20 - days);

  test('without records the order is happy, excited, angry, sad', () {
    expect(shortcutOrder(MoodJournal.empty(), today), [
      Mood.happy,
      Mood.excited,
      Mood.angry,
      Mood.sad,
    ]);
  });

  test('moods are ordered by how often they were picked', () {
    var j = MoodJournal.empty();
    j = taps(j, Mood.anxious, ago(0), 5);
    j = taps(j, Mood.sad, ago(3), 3);
    j = taps(j, Mood.angry, ago(9), 1);
    expect(shortcutOrder(j, today), [
      Mood.anxious,
      Mood.sad,
      Mood.angry,
      Mood.happy,
    ]);
  });

  test('counts add up across days', () {
    var j = MoodJournal.empty();
    j = taps(j, Mood.excited, ago(1), 2);
    j = taps(j, Mood.excited, ago(2), 2);
    j = taps(j, Mood.happy, ago(0), 3);
    expect(shortcutOrder(j, today).first, Mood.excited);
  });

  test('a tie goes to the default order', () {
    var j = MoodJournal.empty();
    j = taps(j, Mood.sad, ago(0), 2);
    j = taps(j, Mood.excited, ago(0), 2);
    expect(shortcutOrder(j, today).take(2), [Mood.excited, Mood.sad]);
  });

  test('moods never picked fill the rest in the default order', () {
    final j = taps(MoodJournal.empty(), Mood.anxious, ago(0), 1);
    expect(shortcutOrder(j, today), [
      Mood.anxious,
      Mood.happy,
      Mood.excited,
      Mood.angry,
    ]);
  });

  test('the window is today and the 13 days before it', () {
    final inside = taps(MoodJournal.empty(), Mood.anxious, ago(13), 9);
    expect(shortcutOrder(inside, today).first, Mood.anxious);
    final outside = taps(MoodJournal.empty(), Mood.anxious, ago(14), 9);
    expect(
      shortcutOrder(outside, today),
      shortcutOrder(MoodJournal.empty(), today),
    );
  });

  test('the window crosses month and year ends', () {
    final newYear = DayKey.of(DateTime(2031, 1, 5));
    var j = taps(MoodJournal.empty(), Mood.anxious, DateTime(2030, 12, 24), 4);
    expect(shortcutOrder(j, newYear).first, Mood.anxious);
    j = taps(MoodJournal.empty(), Mood.anxious, DateTime(2030, 12, 22), 4);
    expect(shortcutOrder(j, newYear).first, Mood.happy);
  });

  test('days after today, from a clock set back, are not counted', () {
    final j = taps(MoodJournal.empty(), Mood.anxious, DateTime(2030, 3, 25), 9);
    expect(shortcutOrder(j, today).first, Mood.happy);
  });

  test('the number of shortcuts and the window can be changed', () {
    var j = taps(MoodJournal.empty(), Mood.anxious, ago(5), 1);
    expect(shortcutOrder(j, today, limit: 5), hasLength(5));
    expect(shortcutOrder(j, today, limit: 2), [Mood.anxious, Mood.happy]);
    expect(shortcutOrder(j, today, days: 5).first, Mood.happy);
    j = taps(j, Mood.sad, ago(2), 1);
    expect(shortcutOrder(j, today, days: 3).first, Mood.sad);
  });

  test('the result has no repeats', () {
    final j = taps(MoodJournal.empty(), Mood.sad, ago(0), 2);
    final order = shortcutOrder(j, today, limit: 5);
    expect(order.toSet(), hasLength(order.length));
  });
}
