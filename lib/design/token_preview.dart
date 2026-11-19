import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'parts/character_slot.dart';
import 'parts/fill_gauge.dart';
import '../domain/mood.dart';
import 'parts/mood_banner.dart';
import 'theme_choice.dart';
import 'tokens.g.dart';

/// Lays out the design tokens and screen parts on one screen.
/// This is where a designer sees the result of editing design/tokens.
class TokenPreview extends StatelessWidget {
  TokenPreview({
    super.key,
    required this.choice,
    required this.onChoice,
    List<ThemeChoice>? choices,
  }) : choices = choices ?? ThemeChoice.all;

  final ThemeChoice choice;

  /// Theme choice buttons. They grow by themselves when palettes are added.
  final List<ThemeChoice> choices;
  final ValueChanged<ThemeChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.xl),
          children: [
            Text(
              '디자인 토큰', // slop-ok: shown on screen to check the Korean font
              style: TypeScale.display.copyWith(color: p.ink),
            ), // slop-ok: shown on screen to check the Korean font
            const SizedBox(height: Space.lg),
            SegmentedButton<ThemeChoice>(
              segments: [
                for (final c in choices)
                  ButtonSegment(value: c, label: Text(c.name)),
              ],
              selected: {choice},
              onSelectionChanged: (s) => onChoice(s.first),
            ),
            const _Heading(
              '색', // slop-ok: shown on screen to check the Korean font
            ), // slop-ok: shown on screen to check the Korean font
            _Swatches(palette: p),
            const _Heading(
              '글자', // slop-ok: shown on screen to check the Korean font
            ), // slop-ok: shown on screen to check the Korean font
            for (final (name, style) in _typeSamples)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  '$name 오늘 기분은', // slop-ok: shown on screen to check the Korean font
                  style: style.copyWith(color: p.ink),
                ),
              ),
            const _Heading(
              '기분 배너', // slop-ok: shown on screen to check the Korean font
            ), // slop-ok: shown on screen to check the Korean font
            MoodBanner(
              label:
                  '행복해요', // slop-ok: shown on screen to check the Korean font
              mood: Mood.happy,
              countLabel: '128',
              onTap: () {},
            ),
            const SizedBox(height: Space.md),
            MoodBanner(
              label: '슬퍼요', // slop-ok: shown on screen to check the Korean font
              mood: Mood.sad,
              countLabel: '12',
              onTap: () {},
            ),
            const _Heading(
              '채움과 캐릭터 자리', // slop-ok: shown on screen to check the Korean font
            ), // slop-ok: shown on screen to check the Korean font
            SizedBox(
              height: 200,
              child: FillGaugeView(
                level: 0.6,
                child: Center(
                  child: Text(
                    '128',
                    style: TypeScale.count.copyWith(color: p.onFill),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.md,
              children: [
                for (final pose in CharacterPose.values)
                  CharacterSlot(pose: pose, size: 96),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _typeSamples = [
  ('display', TypeScale.display),
  ('title', TypeScale.title),
  ('body', TypeScale.body),
  ('label', TypeScale.label),
];

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.md),
      child: Text(
        text,
        style: TypeScale.title.copyWith(color: context.palette.inkMuted),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final colors = {
      'ground': p.ground,
      'surface': p.surface,
      'line': p.line,
      'ink': p.ink,
      'inkMuted': p.inkMuted,
      'accent': p.accent,
      'happy': p.happy,
      'sad': p.sad,
      'fill': p.fill,
      'mapLine': p.mapLine,
      'error': p.error,
    };
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final MapEntry(:key, :value) in colors.entries)
          Container(
            width: 96,
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: value,
              border: Border.all(color: p.line),
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Text(
              key,
              style: TypeScale.label.copyWith(
                color: value.computeLuminance() > 0.4
                    ? darkPalette.ground
                    : lightPalette.surface,
              ),
            ),
          ),
      ],
    );
  }
}
