import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'parts/character_slot.dart';
import 'parts/fill_gauge.dart';
import 'parts/mood_banner.dart';
import 'theme_choice.dart';
import 'tokens.g.dart';

/// 디자인 토큰과 화면 부품을 한 화면에 늘어놓는다.
/// 디자이너가 design/tokens 를 고친 결과를 바로 확인하는 곳이다.
class TokenPreview extends StatelessWidget {
  const TokenPreview({super.key, required this.choice, required this.onChoice});

  final ThemeChoice choice;
  final ValueChanged<ThemeChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.xl),
          children: [
            Text('디자인 토큰', style: TypeScale.display.copyWith(color: p.ink)),
            const SizedBox(height: Space.lg),
            SegmentedButton<ThemeChoice>(
              segments: [
                for (final c in ThemeChoice.values)
                  ButtonSegment(value: c, label: Text(c.name)),
              ],
              selected: {choice},
              onSelectionChanged: (s) => onChoice(s.first),
            ),
            const _Heading('색'),
            _Swatches(palette: p),
            const _Heading('글자'),
            for (final (name, style) in _typeSamples)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  '$name 오늘 기분은',
                  style: style.copyWith(color: p.ink),
                ),
              ),
            const _Heading('기분 배너'),
            MoodBanner(
              label: '행복해요',
              emoji: '😊',
              isHappySide: true,
              todayCount: 128,
              onTap: () {},
            ),
            const SizedBox(height: Space.md),
            MoodBanner(
              label: '슬퍼요',
              emoji: '😢',
              isHappySide: false,
              todayCount: 12,
              onTap: () {},
            ),
            const _Heading('채움과 캐릭터 자리'),
            SizedBox(
              height: 200,
              child: FillGaugeView(
                level: 0.6,
                child: Center(
                  child: Text(
                    '128',
                    style: TypeScale.count.copyWith(color: p.ink),
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
