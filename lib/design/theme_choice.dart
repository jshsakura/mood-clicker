import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// The theme a user picks in settings: `system` or the name of one palette.
///
/// Palettes come from the theme files in design/tokens, so the choices are built from them too.
/// Adding one more theme file adds a choice button by itself; this file stays as it is.
@immutable
class ThemeChoice {
  const ThemeChoice._(this.name);

  /// Follows the device brightness setting.
  static const system = ThemeChoice._('system');

  /// Picks by palette name. [paletteFor] checks that the name matches a palette.
  const ThemeChoice.named(this.name);

  final String name;

  /// All choices: system, then one per palette.
  static List<ThemeChoice> fromPalettes(Iterable<AppPalette> palettes) => [
    system,
    for (final p in palettes) ThemeChoice.named(p.name),
  ];

  static final List<ThemeChoice> all = fromPalettes(allPalettes);

  @override
  bool operator ==(Object other) => other is ThemeChoice && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'ThemeChoice($name)';
}

/// Decides the palette to use from the chosen theme and the device brightness.
/// Throws a StateError when the name matches no palette.
AppPalette paletteFor(
  ThemeChoice choice,
  Brightness platform, {
  List<AppPalette> palettes = allPalettes,
}) {
  if (choice == ThemeChoice.system) {
    return platform == Brightness.dark ? darkPalette : lightPalette;
  }
  return palettes.firstWhere(
    (p) => p.name == choice.name,
    orElse: () => throw StateError('no palette for theme ${choice.name}'),
  );
}
