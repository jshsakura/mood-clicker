import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';

/// WCAG 대비. 4.5 이상이면 본문 글자로 읽힌다.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final p in allPalettes) {
    group('${p.name} palette', () {
      test('text stays readable on ground and surface', () {
        expect(contrast(p.ink, p.ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.ink, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.inkMuted, p.ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.inkMuted, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('text on accent stays readable', () {
        expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('system choice follows the device brightness', () {
    expect(paletteFor(ThemeChoice.system, Brightness.dark), darkPalette);
    expect(paletteFor(ThemeChoice.system, Brightness.light), lightPalette);
  });

  test('pink is used only when picked', () {
    expect(paletteFor(ThemeChoice.pink, Brightness.dark), pinkPalette);
  });
}
