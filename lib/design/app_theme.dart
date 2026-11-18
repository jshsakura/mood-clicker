import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// 팔레트 하나로 앱 전체의 ThemeData 를 만든다.
/// 화면 코드는 색을 직접 쓰지 않고 `context.palette` 와 TypeScale 을 쓴다.
ThemeData buildTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.error,
    onError: p.onAccent,
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
