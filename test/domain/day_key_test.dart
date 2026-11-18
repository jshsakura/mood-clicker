import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/day_key.dart';

void main() {
  test('formats as YYYY-MM-DD with zero padding', () {
    expect(DayKey.of(DateTime(2026, 3, 7, 9)).toString(), '2026-03-07');
  });

  test('the day changes at local midnight', () {
    final before = DayKey.of(DateTime(2026, 11, 18, 23, 59, 59, 999));
    final after = DayKey.of(DateTime(2026, 11, 19));
    expect(before.toString(), '2026-11-18');
    expect(after.toString(), '2026-11-19');
    expect(before < after, isTrue);
  });

  test('uses the device time zone for UTC instants', () {
    final instant = DateTime.utc(2026, 11, 18, 15, 30);
    final local = instant.toLocal();
    expect(DayKey.of(instant), DayKey.of(local));
    expect(DayKey.of(instant).day, local.day);
  });

  test('equal keys are equal and hash alike', () {
    final a = DayKey.of(DateTime(2026, 11, 18, 1));
    final b = DayKey.of(DateTime(2026, 11, 18, 22));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('parses its own output', () {
    final key = DayKey.of(DateTime(2026, 1, 2));
    expect(DayKey.tryParse(key.toString()), key);
  });

  test('rejects malformed or impossible dates', () {
    for (final s in ['2026-1-2', '2026-02-30', '2026-13-01', 'x', '']) {
      expect(DayKey.tryParse(s), isNull, reason: s);
    }
  });
}
