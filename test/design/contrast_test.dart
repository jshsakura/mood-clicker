import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'contrast.dart';

void main() {
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);

  test('black on white is 21', () {
    expect(contrast(black, white), closeTo(21, 1e-9));
  });

  test('same color on itself is 1', () {
    expect(contrast(white, white), closeTo(1, 1e-9));
  });

  test('a translucent color is measured as blended onto the background', () {
    const half = Color(0x80000000);
    final blended = Color.alphaBlend(half, white);
    expect(contrast(half, white), closeTo(contrast(blended, white), 1e-9));
    expect(contrast(half, white), lessThan(contrast(black, white)));
  });

  test('a fully transparent color has no contrast', () {
    expect(contrast(const Color(0x00000000), white), closeTo(1, 1e-9));
  });
}
