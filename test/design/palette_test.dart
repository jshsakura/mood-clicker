import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/tokens.g.dart';

import 'contrast.dart';

/// 팔레트의 색 이름. 아래 쌍 표가 이 이름으로 색을 고른다.
final _roles = <String, Color Function(AppPalette)>{
  'ground': (p) => p.ground,
  'surface': (p) => p.surface,
  'ink': (p) => p.ink,
  'inkMuted': (p) => p.inkMuted,
  'accent': (p) => p.accent,
  'onAccent': (p) => p.onAccent,
  'error': (p) => p.error,
  'fill': (p) => p.fill,
  'happy': (p) => p.happy,
  'sad': (p) => p.sad,
  'mapGround': (p) => p.mapGround,
  'mapLine': (p) => p.mapLine,
};

/// 글자 4.5, 큰 글자 3, 그림 3. WCAG 2 의 기준이다.
const _text = 4.5;
const _largeText = 3.0;
const _graphic = 3.0;

/// 화면에서 실제로 마주 놓이는 색 쌍. 새 쌍이 생기면 여기에 더한다.
const _pairs = <(String fg, String bg, double min, String use)>[
  ('ink', 'ground', _text, '본문'),
  ('ink', 'surface', _text, '카드 위 본문'),
  ('inkMuted', 'ground', _text, '보조 글자'),
  ('inkMuted', 'surface', _text, '카드 위 보조 글자'),
  ('onAccent', 'accent', _text, '강조색 단추 위 글자'),
  ('onAccent', 'error', _text, '오류색 위 글자(테마의 onError)'),
  ('ink', 'fill', _largeText, '차오른 채움 위 큰 숫자(56px 굵게)'),
  ('happy', 'surface', _graphic, '행복 쪽 배너의 띠'),
  ('sad', 'surface', _graphic, '슬픔 쪽 배너의 띠'),
  ('fill', 'surface', _graphic, '채움과 빈 바닥의 구분'),
  ('mapLine', 'mapGround', _graphic, '지도의 선'),
];

/// 지금 값에서 기준에 못 미치는 쌍. 키는 '팔레트/글자색/바탕색'.
/// 색을 고치면 이 목록에서 지운다. 아직 실패하는 것만 남아 있는지는 아래 테스트가 지킨다.
/// 값 변경은 design/tokens 쪽이라 이 테스트에서는 건드리지 않는다.
const _knownFailures = <String, String>{
  'dark/ink/fill':
      '짙은 바탕용 밝은 글자색이 밝은 노랑 채움 위에 올라 1.37이다. 채움 위용 글자색(onFill)이 필요하다',
  'dark/mapLine/mapGround': '지도 선이 바탕과 거의 같다(1.61). 장식선이면 기준을 낮추는 결정이 필요하다',
  'light/onAccent/error':
      'onError 로 쓰는 글자색이 오류 빨강 위에서 4.22이다. onError 짝 색이 필요하다',
  'light/happy/surface': '밝은 바탕의 행복 띠가 1.85이다',
  'light/fill/surface': '채움과 빈 바닥이 1.48이라 얼마나 찼는지 구분이 약하다',
  'light/mapLine/mapGround': '지도 선이 바탕과 거의 같다(1.47). 장식선이면 기준을 낮추는 결정이 필요하다',
  'pink/onAccent/error':
      'onError 로 쓰는 글자색이 오류 빨강 위에서 3.51이다. onError 짝 색이 필요하다',
  'pink/happy/surface': '행복 띠가 2.61이다',
  'pink/sad/surface': '슬픔 띠가 2.77이다',
  'pink/fill/surface': '채움과 빈 바닥이 2.13이다',
  'pink/mapLine/mapGround': '지도 선이 바탕과 거의 같다(1.43). 장식선이면 기준을 낮추는 결정이 필요하다',
};

void main() {
  for (final p in allPalettes) {
    group('${p.name} palette', () {
      test('text colors are opaque', () {
        // 반투명 글자색은 배경에 따라 대비가 달라져 한 번의 검사로 보장할 수 없다.
        for (final c in [p.ink, p.inkMuted, p.onAccent]) {
          expect(c.a, 1.0);
        }
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
          reason: '${entry.key} 은 이제 통과합니다($ratio). _knownFailures 에서 지웁니다',
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
