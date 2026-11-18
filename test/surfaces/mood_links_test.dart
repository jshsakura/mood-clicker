import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/surfaces/mood_links.dart';

void main() {
  test('every mood round-trips through its widget link', () {
    for (final mood in Mood.values) {
      expect(moodFromUri(tapUri(mood)), mood);
    }
  });

  test('every mood round-trips through its shortcut type', () {
    for (final mood in Mood.values) {
      expect(moodFromShortcutType(shortcutTypeFor(mood)), mood);
    }
  });

  test('shortcut types are unique', () {
    final types = Mood.values.map(shortcutTypeFor).toSet();
    expect(types.length, Mood.values.length);
  });

  test('the link without a mood opens the app only', () {
    expect(moodFromUri(tapUri(null)), isNull);
  });

  test('links of other apps, other hosts and unknown moods are ignored', () {
    expect(moodFromUri(Uri.parse('https://example.com/tap/happy')), isNull);
    expect(moodFromUri(Uri.parse('moodclicker://other/happy')), isNull);
    expect(moodFromUri(Uri.parse('moodclicker://tap/unknown')), isNull);
    expect(moodFromUri(Uri.parse('moodclicker://tap/happy/extra')), isNull);
    expect(moodFromUri(null), isNull);
  });

  test('unknown shortcut types are ignored', () {
    expect(moodFromShortcutType('tap_nothing'), isNull);
    expect(moodFromShortcutType('happy'), isNull);
  });
}
