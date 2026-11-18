import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(() async {
    await loadGoldenFonts();
  });

  test('every font family in pubspec.yaml is loaded for the goldens', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final families = RegExp(
      r'^\s+- family:\s*(\S+)',
      multiLine: true,
    ).allMatches(pubspec).map((m) => m.group(1)!).toSet();
    expect(families, isNotEmpty);
    expect(goldenFonts.keys.toSet(), families);
  });

  test('the font files exist', () {
    for (final path in goldenFonts.values.expand((p) => p)) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  double widthOf(String text, String family) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: family, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  test('Pretendard draws real glyphs, not the square test font', () {
    // 기본 글꼴 Ahem 은 모든 글자가 글자 크기와 같은 정사각형이라 'iiii' 가 80 이 된다.
    expect(widthOf('iiii', 'Pretendard'), lessThan(60));
    expect(widthOf('iiii', 'Baloo2'), lessThan(60));
  });
}
