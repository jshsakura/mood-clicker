import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// 사용자가 설정에서 고르는 테마. `system` 이거나 팔레트 하나의 이름이다.
///
/// 팔레트는 design/tokens 의 테마 파일에서 생기므로 선택지도 거기서 만든다.
/// 테마 파일을 하나 더 두면 선택 단추도 저절로 하나 늘고, 이 파일은 고치지 않는다.
@immutable
class ThemeChoice {
  const ThemeChoice._(this.name);

  /// 기기의 밝기 설정을 따른다.
  static const system = ThemeChoice._('system');

  /// 팔레트 이름으로 고른다. 이름이 팔레트와 맞는지는 [paletteFor] 가 본다.
  const ThemeChoice.named(this.name);

  final String name;

  /// 선택지 전체: system, 그리고 팔레트마다 하나.
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

/// 고른 테마와 기기의 밝기 설정으로 실제로 쓸 팔레트를 정한다.
/// 팔레트에 없는 이름이면 StateError 를 던진다.
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
    orElse: () => throw StateError('테마 ${choice.name} 의 팔레트가 없습니다'),
  );
}
