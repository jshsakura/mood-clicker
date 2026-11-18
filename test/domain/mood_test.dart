import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';

void main() {
  test('draft catalog has five moods on the agreed sides', () {
    expect(Mood.values.map((m) => (m.id, m.side)), [
      ('happy', MoodSide.happy),
      ('excited', MoodSide.happy),
      ('angry', MoodSide.sad),
      ('sad', MoodSide.sad),
      ('anxious', MoodSide.sad),
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
