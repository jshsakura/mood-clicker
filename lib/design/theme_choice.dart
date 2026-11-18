import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// 사용자가 설정에서 고르는 테마.
enum ThemeChoice { system, light, dark, pink }

/// 고른 테마와 기기의 밝기 설정으로 실제로 쓸 팔레트를 정한다.
AppPalette paletteFor(ThemeChoice choice, Brightness platform) {
  return switch (choice) {
    ThemeChoice.system =>
      platform == Brightness.dark ? darkPalette : lightPalette,
    ThemeChoice.light => lightPalette,
    ThemeChoice.dark => darkPalette,
    ThemeChoice.pink => pinkPalette,
  };
}
