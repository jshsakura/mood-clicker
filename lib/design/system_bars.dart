import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.g.dart';

/// The phone's status and navigation bars for [palette]. The bars are clear so the app's own
/// ground runs to the top and bottom edges, and their icons are dark on a light ground and
/// light on a dark one.
SystemUiOverlayStyle systemBarsFor(AppPalette palette) {
  final icons = palette.brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: icons,
    systemNavigationBarIconBrightness: icons,
    // iOS reads the brightness of what sits behind the bar, not the icon color.
    statusBarBrightness: palette.brightness,
  );
}
