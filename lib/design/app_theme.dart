import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Builds the app-wide ThemeData from one palette.
/// Screen code never names colors directly; it uses `context.palette` and TypeScale.
ThemeData buildTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.error,
    onError: p.onError,
    surface: p.surface,
    onSurface: p.ink,
    outline: p.line,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.ground,
    fontFamily: TypeScale.body.fontFamily,
    textTheme: TextTheme(
      displayLarge: TypeScale.count,
      headlineMedium: TypeScale.display,
      titleLarge: TypeScale.title,
      bodyLarge: TypeScale.body,
      bodyMedium: TypeScale.body,
      labelLarge: TypeScale.label,
      labelMedium: TypeScale.label,
    ).apply(bodyColor: p.ink, displayColor: p.ink),
    dividerColor: p.line,
    splashFactory: NoSplash.splashFactory,
    extensions: [p],
  );
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
