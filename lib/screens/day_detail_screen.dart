import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_face.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../domain/mood_journal.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/date_labels.dart';
import 'mood_labels.dart';
import 'tap/note_sheet.dart';

/// Day detail screen matching DayDetail.dc.html: dominant mood card,
/// five mood bars, happy/sad side cards, and fl_chart weekly stacked bars.
class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.day});

  final DayKey day;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final locale = Localizations.localeOf(context);
    final date = DateTime(day.year, day.month, day.day);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.journal,
          builder: (context, _) {
            final journal = services.journal.journal;
            final record = journal.dayOf(day);
            final maxCount = Mood.values
                .map(record.countOf)
                .fold(0, (a, b) => a > b ? a : b);
            final note = shownNote(l10n, record);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.lg,
                    Space.lg,
                    Space.sm,
                  ),
                  child: Row(
                    children: [
                      PressableSurface.icon(
                        icon: LineIcons.backHeavy,
                        semanticLabel: l10n.common_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          dayTitle(locale, date),
                          style: TypeScale.title.copyWith(color: p.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      Space.md,
                      Space.lg,
                      Space.xl,
                    ),
                    children: [
                      if (record.total == 0)
                        Text(
                          l10n.dayDetail_empty,
                          style: TypeScale.body.copyWith(color: p.inkMuted),
                        )
                      else ...[
                        _SummaryCard(
                          mood: record.dominantMood!,
                          note: note,
                          onEditNote: () => showNoteSheet(context, day),
                        ),
                        const SizedBox(height: Space.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.sm,
                          ),
                          child: Column(
                            children: [
                              for (final mood in Mood.values)
                                _MoodBarRow(
                                  mood: mood,
                                  count: record.countOf(mood),
                                  share: maxCount > 0
                                      ? record.countOf(mood) / maxCount
                                      : 0,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        Row(
                          children: [
                            Expanded(
                              child: _SideTotalCard(
                                label: l10n.dayDetail_happySide,
                                count: record.happyTotal,
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: _SideTotalCard(
                                label: l10n.dayDetail_sadSide,
                                count: record.sadTotal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xl),
                        _WeekReviewChart(day: date, journal: journal),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.mood,
    required this.note,
    required this.onEditNote,
  });

  final Mood mood;
  final String? note;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dayDetail_moodHeading,
                      style: TypeScale.label.copyWith(color: p.inkMuted),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      moodName(context, mood),
                      style: TypeScale.display.copyWith(color: p.ink),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      l10n.dayDetail_dominantCaption,
                      style: TypeScale.label.copyWith(color: p.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              MoodFace(mood: mood, size: 44),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              if (note != null)
                Expanded(
                  child: Text(
                    '"$note"',
                    style: TypeScale.body.copyWith(color: p.ink),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: Space.sm),
              PressableSurface(
                kind: PressableKind.card,
                radius: Radii.pill,
                color: p.ground,
                semanticLabel: note == null
                    ? l10n.dayDetail_addNote
                    : l10n.dayDetail_editNote,
                onTap: onEditNote,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xs,
                  ),
                  child: Text(
                    note == null
                        ? l10n.dayDetail_addNote
                        : l10n.dayDetail_editNote,
                    style: TypeScale.label.copyWith(color: p.ink),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodBarRow extends StatelessWidget {
  const _MoodBarRow({
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
    final label = moodName(context, mood);
    final barColor = mood.side == MoodSide.happy ? p.ink : p.mapLine;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dayDetail_moodCount(label, count),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: TypeScale.body.copyWith(color: p.ink)),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: Container(
                  height: 12,
                  color: p.surface,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: share.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$count',
                textAlign: TextAlign.right,
                style: TypeScale.label.copyWith(color: p.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideTotalCard extends StatelessWidget {
  const _SideTotalCard({required this.label, required this.count});

  final String label;
  final int count;

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
          Text('$count', style: TypeScale.display.copyWith(color: p.ink)),
        ],
      ),
    );
  }
}

class _WeekReviewChart extends StatelessWidget {
  const _WeekReviewChart({required this.day, required this.journal});

  final DateTime day;
  final MoodJournal journal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final weekdays = weekdayLabels(locale);
    final sunday = day.subtract(Duration(days: day.weekday % 7));

    var maxTotal = 1.0;
    final totals = <({double happy, double sad})>[];
    for (var i = 0; i < 7; i++) {
      final d = sunday.add(Duration(days: i));
      final rec = journal.dayOf(DayKey.of(d));
      final h = rec.happyTotal.toDouble();
      final s = rec.sadTotal.toDouble();
      totals.add((happy: h, sad: s));
      maxTotal = math.max(maxTotal, h + s);
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < 7; i++) {
      final t = totals[i];
      final sum = t.happy + t.sad;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sum,
              width: 28,
              borderRadius: BorderRadius.circular(6),
              rodStackItems: [
                if (t.happy > 0) BarChartRodStackItem(0, t.happy, p.ink),
                if (t.sad > 0) BarChartRodStackItem(t.happy, sum, p.mapLine),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dayDetail_weekReview,
          style: TypeScale.body.copyWith(
            color: p.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Space.md),
        SizedBox(
          height: 112,
          child: BarChart(
            BarChartData(
              maxY: maxTotal * 1.05,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= weekdays.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Text(
                          weekdays[idx],
                          style: TypeScale.label.copyWith(color: p.inkMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }
}
