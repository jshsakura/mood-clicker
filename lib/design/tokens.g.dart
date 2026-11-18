// 생성 파일이다. 손대지 않는다.
// design/tokens/*.json 을 고친 뒤 python3 tool/gen_tokens.py 를 돌린다.
// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.name,
    required this.brightness,
    required this.ground,
    required this.surface,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.happy,
    required this.sad,
    required this.fill,
    required this.mapGround,
    required this.mapLine,
    required this.error,
  });

  final String name;
  final Brightness brightness;
  final Color ground;
  final Color surface;
  final Color line;
  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color onAccent;
  final Color happy;
  final Color sad;
  final Color fill;
  final Color mapGround;
  final Color mapLine;
  final Color error;

  @override
  AppPalette copyWith({
    String? name,
    Brightness? brightness,
    Color? ground,
    Color? surface,
    Color? line,
    Color? ink,
    Color? inkMuted,
    Color? accent,
    Color? onAccent,
    Color? happy,
    Color? sad,
    Color? fill,
    Color? mapGround,
    Color? mapLine,
    Color? error,
  }) {
    return AppPalette(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      ground: ground ?? this.ground,
      surface: surface ?? this.surface,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      happy: happy ?? this.happy,
      sad: sad ?? this.sad,
      fill: fill ?? this.fill,
      mapGround: mapGround ?? this.mapGround,
      mapLine: mapLine ?? this.mapLine,
      error: error ?? this.error,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      name: t < 0.5 ? name : other.name,
      brightness: t < 0.5 ? brightness : other.brightness,
      ground: Color.lerp(ground, other.ground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      happy: Color.lerp(happy, other.happy, t)!,
      sad: Color.lerp(sad, other.sad, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      mapGround: Color.lerp(mapGround, other.mapGround, t)!,
      mapLine: Color.lerp(mapLine, other.mapLine, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

const AppPalette darkPalette = AppPalette(
  name: 'dark',
  brightness: Brightness.dark,
  ground: Color(0xFF121216),
  surface: Color(0xFF222228),
  line: Color(0xFF383840),
  ink: Color(0xFFECECF0),
  inkMuted: Color(0xFFA0A0AA),
  accent: Color(0xFFFFC23D),
  onAccent: Color(0xFF16161A),
  happy: Color(0xFFFFC23D),
  sad: Color(0xFF7A9CFF),
  fill: Color(0xFFFFC23D),
  mapGround: Color(0xFF121216),
  mapLine: Color(0xFF383840),
  error: Color(0xFFF0685C),
);

const AppPalette lightPalette = AppPalette(
  name: 'light',
  brightness: Brightness.light,
  ground: Color(0xFFF6F6F8),
  surface: Color(0xFFFFFFFF),
  line: Color(0xFFE2E2E8),
  ink: Color(0xFF16161A),
  inkMuted: Color(0xFF62626C),
  accent: Color(0xFFFFC23D),
  onAccent: Color(0xFF16161A),
  happy: Color(0xFFF2A900),
  sad: Color(0xFF4C6FE0),
  fill: Color(0xFFFFC23D),
  mapGround: Color(0xFFF6F6F8),
  mapLine: Color(0xFFD4D4DC),
  error: Color(0xFFD9473B),
);

const AppPalette pinkPalette = AppPalette(
  name: 'pink',
  brightness: Brightness.light,
  ground: Color(0xFFFFF1F5),
  surface: Color(0xFFFFFFFF),
  line: Color(0xFFF6D3DF),
  ink: Color(0xFF3A1E2B),
  inkMuted: Color(0xFF80505F),
  accent: Color(0xFFFF6FA3),
  onAccent: Color(0xFF3A1E2B),
  happy: Color(0xFFFF6FA3),
  sad: Color(0xFF9B8CFF),
  fill: Color(0xFFFF8FB8),
  mapGround: Color(0xFFFFF1F5),
  mapLine: Color(0xFFF2C2D3),
  error: Color(0xFFD9473B),
);

const List<AppPalette> allPalettes = [darkPalette, lightPalette, pinkPalette];

abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double card = 24;
  static const double button = 16;
  static const double pill = 999;
}

abstract final class TypeScale {
  static const TextStyle display = TextStyle(fontFamily: 'Pretendard', fontSize: 34, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle title = TextStyle(fontFamily: 'Pretendard', fontSize: 22, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle body = TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle label = TextStyle(fontFamily: 'Pretendard', fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle count = TextStyle(fontFamily: 'Pretendard', fontSize: 56, fontWeight: FontWeight.w700, height: 1);
}

abstract final class Motion {
  static const Duration tap = Duration(milliseconds: 90);
  static const Duration fillRise = Duration(milliseconds: 120);
  static const Duration page = Duration(milliseconds: 240);
}
