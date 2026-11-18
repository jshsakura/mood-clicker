import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';

import 'contrast.dart';

/// Palette color names. The pair table below picks colors by these names.
final _roles = <String, Color Function(AppPalette)>{
  'ground': (p) => p.ground,
  'surface': (p) => p.surface,
  'ink': (p) => p.ink,
  'inkMuted': (p) => p.inkMuted,
  'accent': (p) => p.accent,
  'onAccent': (p) => p.onAccent,
  'error': (p) => p.error,
  'fill': (p) => p.fill,
  'onFill': (p) => p.onFill,
  'happy': (p) => p.happy,
  'sad': (p) => p.sad,
  'mapGround': (p) => p.mapGround,
  'mapLine': (p) => p.mapLine,
};

/// Text 4.5, large text 3, graphics 3: the WCAG 2 thresholds.
const _text = 4.5;
const _largeText = 3.0;
const _graphic = 3.0;

/// Color pairs that really meet on screen. Add a pair here when a new one appears.
///
/// Pairs left out on purpose:
/// - fill/surface: the fill is a large area and the number is shown separately, so no contrast with the empty ground is required.
/// - mapLine/mapGround: map lines are decorative, so no contrast is required.
const _pairs = <(String fg, String bg, double min, String use)>[
  ('ink', 'ground', _text, 'body text'),
  ('ink', 'surface', _text, 'body text on a card'),
  ('inkMuted', 'ground', _text, 'secondary text'),
  ('inkMuted', 'surface', _text, 'secondary text on a card'),
  ('onAccent', 'accent', _text, 'text on an accent button'),
  ('onFill', 'fill', _largeText, 'large number on a risen fill (56px bold)'),
  ('happy', 'surface', _graphic, 'stripe of the happy side banner'),
  ('sad', 'surface', _graphic, 'stripe of the sad side banner'),
];

/// Pairs that miss the threshold with today's values. The key is 'palette/foreground/background'.
/// Remove an entry here once its color is fixed. A test below checks that only still-failing pairs remain.
/// Changing values belongs to design/tokens, so this test never touches them.
const _knownFailures = <String, String>{};

void main() {
  for (final p in allPalettes) {
    group('${p.name} palette', () {
      test('text colors are opaque', () {
        // A translucent text color changes contrast with the background, so one check cannot guarantee it.
        for (final c in [p.ink, p.inkMuted, p.onAccent]) {
          expect(c.a, 1.0);
        }
      });

      test('the theme onError is opaque and reads on the error color', () {
        // The color Material really draws on top of the error color.
        final scheme = buildTheme(p).colorScheme;
        expect(scheme.onError.a, 1.0);
        expect(scheme.error.a, 1.0);
        expect(
          contrast(scheme.onError, scheme.error),
          greaterThanOrEqualTo(_text),
        );
      });

      for (final (fg, bg, min, use) in _pairs) {
        final key = '${p.name}/$fg/$bg';
        test('$fg on $bg reads at $min or more ($use)', () {
          final ratio = contrast(_roles[fg]!(p), _roles[bg]!(p));
          expect(ratio, greaterThanOrEqualTo(min));
        }, skip: _knownFailures[key]);
      }
    });
  }

  group('known failures list', () {
    test('only names pairs and palettes that exist', () {
      final keys = {
        for (final p in allPalettes)
          for (final (fg, bg, _, _) in _pairs) '${p.name}/$fg/$bg',
      };
      for (final key in _knownFailures.keys) {
        expect(keys, contains(key));
      }
    });

    test('every entry still fails, so fixed ones get removed', () {
      for (final entry in _knownFailures.entries) {
        final [name, fg, bg] = entry.key.split('/');
        final p = allPalettes.firstWhere((p) => p.name == name);
        final min = _pairs.firstWhere((t) => t.$1 == fg && t.$2 == bg).$3;
        final ratio = contrast(_roles[fg]!(p), _roles[bg]!(p));
        expect(
          ratio,
          lessThan(min),
          reason:
              '${entry.key} now passes ($ratio). Remove it from _knownFailures',
        );
      }
    });
  });

  group('theme choice', () {
    test('system choice follows the device brightness', () {
      expect(paletteFor(ThemeChoice.system, Brightness.dark), darkPalette);
      expect(paletteFor(ThemeChoice.system, Brightness.light), lightPalette);
    });

    test('pink is used only when picked', () {
      expect(
        paletteFor(ThemeChoice.named('pink'), Brightness.dark),
        pinkPalette,
      );
    });

    test('there is one choice per palette, plus system', () {
      expect(ThemeChoice.all.first, ThemeChoice.system);
      expect(
        ThemeChoice.all.skip(1).map((c) => c.name).toList(),
        allPalettes.map((p) => p.name).toList(),
      );
    });

    test('every choice resolves to the palette of the same name', () {
      for (final p in allPalettes) {
        expect(paletteFor(ThemeChoice.named(p.name), Brightness.light), p);
      }
    });

    test('a palette added later gets a choice too', () {
      final mint = lightPalette.copyWith(name: 'mint');
      final palettes = [...allPalettes, mint];
      final choices = ThemeChoice.fromPalettes(palettes);
      expect(choices.map((c) => c.name), contains('mint'));
      expect(
        paletteFor(
          ThemeChoice.named('mint'),
          Brightness.light,
          palettes: palettes,
        ),
        mint,
      );
    });

    test('an unknown choice fails loudly', () {
      expect(
        () => paletteFor(ThemeChoice.named('nope'), Brightness.light),
        throwsStateError,
      );
    });
  });
}
