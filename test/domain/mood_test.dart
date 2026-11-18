import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';

void main() {
  test('draft catalog has five moods on the agreed sides', () {
    expect(Mood.values.map((m) => (m.label, m.side)), [
      ('행복해요', MoodSide.happy),
      ('설레요', MoodSide.happy),
      ('화나요', MoodSide.sad),
      ('슬퍼요', MoodSide.sad),
      ('불안해요', MoodSide.sad),
    ]);
  });

  test('ids are unique and round-trip through byId', () {
    final ids = Mood.values.map((m) => m.id).toSet();
    expect(ids, hasLength(Mood.values.length));
    for (final mood in Mood.values) {
      expect(Mood.byId(mood.id), mood);
    }
  });

  test('byId returns null for an unknown id', () {
    expect(Mood.byId('bored'), isNull);
  });
}
