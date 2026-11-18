import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/cheer.dart';
import 'package:mood_clicker/domain/mood.dart';
import 'package:mood_clicker/screens/tap/tap_screen.dart';

import 'fake_app.dart';

/// The screen, not the picker: 200 taps on the real phrase file, and what is drawn in the frame
/// right after each tap. A phrase the screen drops would show up as a gap here.
void main() {
  testWidgets('200 taps show 200 phrases on screen, almost all different', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final book = CheerBook.parse(
      File('assets/cheers/ko.json').readAsStringSync(),
    ).book;
    final all = <String>{
      for (final stage in CheerStage.values) ...book.bundle(Mood.happy, stage),
    };
    final app = TestApp(book: book);
    await tester.pumpWidget(app.wrap(const TapScreen(mood: Mood.happy)));
    await tester.pump(const Duration(milliseconds: 16));
    final random = Random(3);
    final seen = <String>{};
    var shownTaps = 0;
    for (var i = 0; i < 200; i++) {
      final at = Offset(
        60 + random.nextInt(270).toDouble(),
        250 + random.nextInt(400).toDouble(),
      );
      await tester.tapAt(at);
      app.advance(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 20));
      final fresh = {
        for (final w in tester.widgetList<Text>(find.byType(Text)))
          if (all.contains(w.data)) w.data!,
      };
      if (fresh.isNotEmpty) shownTaps++;
      seen.addAll(fresh);
    }
    expect(shownTaps, greaterThanOrEqualTo(195));
    expect(seen.length, greaterThanOrEqualTo(150), reason: '${seen.length}');
  });
}
