import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/feel_settings.dart';

void main() {
  test('defaults: effects on, large text off', () {
    const s = FeelSettings();
    expect(s.screenShake, isTrue);
    expect(s.cheerPhrases, isTrue);
    expect(s.tiltSpill, isTrue);
    expect(s.largeText, isFalse);
    expect(s.textScale, 1);
  });

  test('large text scales by 1.18', () {
    expect(const FeelSettings(largeText: true).textScale, 1.18);
  });

  test('copyWith changes one value and keeps the rest', () {
    final s = const FeelSettings().copyWith(cheerPhrases: false);
    expect(s.cheerPhrases, isFalse);
    expect(s.screenShake, isTrue);
    expect(const FeelSettings().cheerPhrases, isTrue);
  });

  test('survives a JSON round trip', () {
    const s = FeelSettings(
      screenShake: false,
      cheerPhrases: false,
      largeText: true,
      tiltSpill: false,
    );
    expect(FeelSettings.fromJson(s.toJson()), s);
  });

  test('bad input gives the defaults and never throws', () {
    for (final bad in <Object?>[
      null,
      5,
      'x',
      <Object?>[],
      {'screenShake': 'no', 'largeText': 1},
    ]) {
      expect(FeelSettings.fromJson(bad), const FeelSettings(), reason: '$bad');
    }
  });

  test('one bad value does not spoil the others', () {
    final s = FeelSettings.fromJson({
      'screenShake': false,
      'cheerPhrases': 'x',
    });
    expect(s.screenShake, isFalse);
    expect(s.cheerPhrases, isTrue);
  });
}
