import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/parts/line_icon.dart';
import 'package:mood_clicker/design/parts/mood_face.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/domain/mood.dart';

Widget _host(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: buildTheme(lightPalette),
  darkTheme: buildTheme(darkPalette),
  themeMode: mode,
  home: Scaffold(body: Center(child: child)),
);

String _svg(String file) => File('assets/icons/$file.svg').readAsStringSync();

void main() {
  group('icon files', () {
    test('every icon file exists and draws with currentColor on a 24 grid', () {
      for (final icon in LineIcons.values) {
        final text = _svg(icon.file);
        expect(text, contains('viewBox="0 0 24 24"'), reason: icon.file);
        expect(text, contains('stroke="currentColor"'), reason: icon.file);
        expect(text, contains('fill="none"'), reason: icon.file);
        expect(
          text,
          isNot(contains('#')),
          reason: '${icon.file} has a fixed color',
        );
      }
    });

    test('stroke widths are the ones of the approved screens', () {
      final widths = {
        LineIcons.back: '1.8',
        LineIcons.backHeavy: '2',
        LineIcons.check: '2',
        LineIcons.map: '1.8',
        LineIcons.calendar: '1.8',
        LineIcons.settings: '1.8',
        LineIcons.chevronLeft: '1.8',
        LineIcons.chevronRight: '1.8',
        LineIcons.chevronRightHeavy: '2',
      };
      widths.forEach((icon, width) {
        expect(
          _svg(icon.file),
          contains('stroke-width="$width"'),
          reason: icon.file,
        );
      });
    });

    test('the drawings are the paths of the approved screens', () {
      // Back is an arrow with a shaft, so it never reads as the month chevron.
      expect(_svg('back'), contains('M19 12H5M11 6l-6 6 6 6'));
      expect(_svg('back_heavy'), contains('M19 12H5M11 6l-6 6 6 6'));
      expect(_svg('map'), contains('M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z'));
      expect(
        _svg('calendar'),
        contains('rect x="3.5" y="5" width="17" height="15" rx="3"'),
      );
      expect(_svg('settings'), contains('M12 2.5v3M12 18.5v3'));
      expect(_svg('chevron_left'), contains('M15 6l-6 6 6 6'));
      expect(_svg('chevron_right'), contains('M9 6l6 6-6 6'));
    });

    test(
      'a mood face is a circle, two dots, an optional brow and a mouth at 1.6',
      () {
        for (final mood in Mood.values) {
          final text = _svg('mood_${mood.id}');
          expect(
            text,
            contains('<circle cx="12" cy="12" r="10"'),
            reason: mood.id,
          );
          expect(text, contains('stroke-width="1.6"'), reason: mood.id);
          expect(text, contains('M9 10h.01M15 10h.01'), reason: mood.id);
          expect(text, contains('stroke-width="2.4"'), reason: mood.id);
        }
        expect(
          _svg('mood_happy'),
          contains('M8 14c1.2 1.6 2.6 2.4 4 2.4s2.8-.8 4-2.4'),
        );
        expect(_svg('mood_excited'), contains('M7.5 7.5l2-1M16.5 7.5l-2-1'));
        expect(_svg('mood_angry'), contains('M7.5 7.5l3 1.5M16.5 7.5l-3 1.5'));
        expect(_svg('mood_sad'), contains('M8 9l2.5-1.2M16 9l-2.5-1.2'));
        expect(_svg('mood_anxious'), contains('M8 15.5c.7-.7 1.3-.7 2 0'));
      },
    );
  });

  group('LineIcon', () {
    testWidgets('draws at the given size in the given color', (tester) async {
      await tester.pumpWidget(
        _host(
          const LineIcon(LineIcons.back, size: 18, color: Color(0xFF123456)),
        ),
      );
      await tester.pump();
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(picture.width, 18);
      expect(picture.height, 18);
      expect(
        picture.colorFilter,
        const ColorFilter.mode(Color(0xFF123456), BlendMode.srcIn),
      );
    });

    testWidgets('defaults to 22 and the ink color of the theme', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const LineIcon(LineIcons.map)));
      await tester.pump();
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final ink = lightPalette.ink;
      expect(picture.width, 22);
      expect(picture.colorFilter, ColorFilter.mode(ink, BlendMode.srcIn));
    });
  });

  group('MoodFace', () {
    testWidgets(
      'happy and excited use the happy color, the others the sad color',
      (tester) async {
        final palette = lightPalette;
        final expected = {
          Mood.happy: palette.happy,
          Mood.excited: palette.happy,
          Mood.angry: palette.sad,
          Mood.sad: palette.sad,
          Mood.anxious: palette.sad,
        };
        for (final mood in Mood.values) {
          await tester.pumpWidget(_host(MoodFace(mood: mood, size: 36)));
          await tester.pump();
          final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
          expect(picture.width, 36, reason: mood.id);
          expect(
            picture.colorFilter,
            ColorFilter.mode(expected[mood]!, BlendMode.srcIn),
            reason: mood.id,
          );
        }
      },
    );

    testWidgets('follows the theme palette', (tester) async {
      await tester.pumpWidget(
        _host(const MoodFace(mood: Mood.happy), mode: ThemeMode.dark),
      );
      await tester.pump();
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final dark = darkPalette.happy;
      expect(picture.colorFilter, ColorFilter.mode(dark, BlendMode.srcIn));
    });
  });
}
