import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/cheer_picker.dart';
import 'package:mood_clicker/domain/fill_gauge.dart';
import 'package:mood_clicker/domain/mood.dart';

/// The numbers a person sees: how many different phrases come out of 200 taps on the real
/// phrase files, tapping five times a second like a hand does.
({int phrases, int bases, int rare, int complete}) _play(
  CheerBook book,
  Mood mood,
  int taps,
  int seed, {
  Duration every = const Duration(milliseconds: 200),
}) {
  final picker = CheerPicker(Random(seed));
  var gauge = const FillGauge.empty();
  var now = DateTime(2026, 11, 18, 12);
  final phrases = <String>{};
  final bases = <String>{};
  var rare = 0;
  var complete = 0;
  for (var i = 0; i < taps; i++) {
    now = now.add(every);
    gauge = gauge.tap(now);
    final stage = CheerStage.of(gauge, now);
    final draw = picker.draw(book, mood, stage);
    phrases.add(draw.phrase);
    final used = book.effectiveStage(mood, switch (draw.kind) {
      CheerKind.complete => CheerStage.complete,
      CheerKind.rare => CheerStage.rare,
      CheerKind.normal => stage,
    });
    final list = book.bundle(mood, used);
    final at = list.indexOf(draw.phrase);
    bases.add(
      '${mood.id}/${used.id}/${book.bases(mood, used)[at] ?? draw.phrase}',
    );
    if (draw.kind == CheerKind.rare) rare++;
    if (draw.kind == CheerKind.complete) complete++;
  }
  return (
    phrases: phrases.length,
    bases: bases.length,
    rare: rare,
    complete: complete,
  );
}

void main() {
  final text = File('assets/cheers/ko.json').readAsStringSync();
  final book = CheerBook.parse(text).book;

  test('200 taps on the real happy phrases show many different phrases', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final r = _play(book, Mood.happy, 200, seed);
      debugPrint('happy seed $seed: $r');
      // The canvas reference showed 273 different phrases in 300 taps.
      expect(r.phrases, greaterThanOrEqualTo(150), reason: 'seed $seed: $r');
      expect(r.bases, greaterThanOrEqualTo(100), reason: 'seed $seed: $r');
    }
  });

  test('every mood shows a good spread of phrases', () {
    for (final mood in Mood.values) {
      final r = _play(book, mood, 200, 7);
      debugPrint('${mood.id}: $r');
      // The three heavier moods have about 60 phrases per stage, so 200 taps cannot show more
      // than the files hold. They must still use most of what is there.
      expect(r.phrases, greaterThanOrEqualTo(90), reason: '${mood.id}: $r');
    }
  });

  test(
    'the complete phrase comes once per fill, and rare ones now and then',
    () {
      final r = _play(book, Mood.happy, 200, 11);
      expect(r.complete, 1);
      expect(r.rare, inInclusiveRange(1, 15));
    },
  );
}
