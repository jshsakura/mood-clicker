import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_face.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/date_labels.dart';
import 'mood_labels.dart';
import 'tap/note_sheet.dart';

/// One day: a card with the main face and the note, the two sides side by side, and the count of
/// each mood as black bars. Bars and numbers are black and gray only; the faces are the only
/// colored thing.
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.day});

  final DayKey day;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final locale = Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.journal,
          builder: (context, _) {
            final record = services.journal.journal.dayOf(day);
            final maxCount = Mood.values
                .map(record.countOf)
                .fold(0, (a, b) => a > b ? a : b);
            final note = record.note;
            return ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                Row(
                  children: [
                    PressableSurface.icon(
                      icon: LineIcons.backHeavy,
                      semanticLabel: l10n.common_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: Space.md),
                    Text(
                      dayTitle(locale, DateTime(day.year, day.month, day.day)),
                      style: TypeScale.title.copyWith(color: p.ink),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xl),
                if (record.total == 0)
                  Text(
                    l10n.dayDetail_empty,
                    style: TypeScale.body.copyWith(color: p.inkMuted),
                  )
                else ...[
                  _FaceCard(
                    mood: record.dominantMood!,
                    total: record.total,
                    note: note,
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SideTotal(
                          label: l10n.dayDetail_happySide,
                          count: record.happyTotal,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: _SideTotal(
                          label: l10n.dayDetail_sadSide,
                          count: record.sadTotal,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  for (final mood in Mood.values)
                    if (record.countOf(mood) > 0)
                      _MoodBar(
                        mood: mood,
                        count: record.countOf(mood),
                        share: record.countOf(mood) / maxCount,
                      ),
                ],
                if (record.total > 0 && note == null) ...[
                  const SizedBox(height: Space.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => showNoteSheet(context, day),
                      child: Text(l10n.note_title),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The card at the top of a day: the face of the main mood and, under it, the note of the day.
class _FaceCard extends StatelessWidget {
  const _FaceCard({
    required this.mood,
    required this.total,
    required this.note,
  });

  final Mood mood;
  final int total;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MoodFace(mood: mood, size: 44),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  moodName(context, mood),
                  style: TypeScale.title.copyWith(color: p.ink),
                ),
              ),
              Text('$total', style: TypeScale.display.copyWith(color: p.ink)),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: Space.lg),
            Text(
              l10n.dayDetail_note,
              style: TypeScale.label.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: Space.xs),
            Text(note!, style: TypeScale.body.copyWith(color: p.ink)),
          ],
        ],
      ),
    );
  }
}

class _SideTotal extends StatelessWidget {
  const _SideTotal({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TypeScale.label.copyWith(color: p.inkMuted)),
          const SizedBox(height: Space.xs),
          Text('$count', style: TypeScale.display.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.mood,
    required this.count,
    required this.share,
  });

  final Mood mood;
  final int count;
  final double share;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          MoodFace(mood: mood, size: 26),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dayDetail_moodCount(moodName(context, mood), count),
                  style: TypeScale.label.copyWith(color: p.ink),
                ),
                const SizedBox(height: Space.xs),
                LayoutBuilder(
                  builder: (context, constraints) => Container(
                    height: 10,
                    width: constraints.maxWidth * share,
                    decoration: BoxDecoration(
                      color: p.ink,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
