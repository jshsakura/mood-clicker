import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/calmap_marks.dart';
import '../design/parts/day_shade.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_face.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/day_key.dart';
import '../domain/day_record.dart';
import '../domain/mood_journal.dart';
import '../domain/tuning.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/date_labels.dart';
import 'day_detail_screen.dart';
import 'mood_labels.dart';

/// Monthly calendar matching Calendar.dc.html with back-only top bar,
/// month-adjacent plain chevrons + swipe navigation, table_calendar grid,
/// fl_chart monthly flow bars, and selected-day summary card.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _month;
  DayKey? _picked;

  DateTime _shown(AppServices services) {
    final now = services.now();
    return _month ?? DateTime(now.year, now.month);
  }

  bool _isStamped(int taps) => taps * GaugeTuning.stepPerTap >= 1.0 - 1e-9;

  void _move(AppServices services, int by) {
    final shown = _shown(services);
    final next = DateTime(shown.year, shown.month + by);
    setState(() {
      _month = next;
      _picked = _defaultPicked(services.journal.journal, next, services.now());
    });
  }

  DayKey _defaultPicked(MoodJournal journal, DateTime month, DateTime now) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final todayKey = DayKey.of(now);
    if (todayKey.year == month.year &&
        todayKey.month == month.month &&
        journal.dayOf(todayKey).total > 0) {
      return todayKey;
    }
    for (var d = daysInMonth; d >= 1; d--) {
      final k = DayKey.of(DateTime(month.year, month.month, d));
      if (journal.dayOf(k).total > 0) return k;
    }
    if (todayKey.year == month.year && todayKey.month == month.month) {
      return todayKey;
    }
    return DayKey.of(DateTime(month.year, month.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final locale = Localizations.localeOf(context);
    final month = _shown(services);
    final now = services.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekdays = weekdayLabels(locale);
    final firstCalendarDay = DateTime(2020, 1, 1);
    final lastCalendarDay = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.journal,
          builder: (context, _) {
            final journal = services.journal.journal;
            final picked =
                _picked ?? _defaultPicked(journal, month, services.now());
            var recordedDays = 0;
            var stampedDays = 0;
            var maxTaps = 1;
            for (var d = 1; d <= daysInMonth; d++) {
              final rec = journal.dayOf(
                DayKey.of(DateTime(month.year, month.month, d)),
              );
              if (rec.total > 0) recordedDays++;
              if (_isStamped(rec.total)) stampedDays++;
              if (rec.total > maxTaps) maxTaps = rec.total;
            }
            final pickedRecord = journal.dayOf(picked);
            final monthLabel = DateFormat.MMMM(
              locale.toLanguageTag(),
            ).format(month);

            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - Space.lg - Space.xl,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PressableSurface.icon(
                              icon: LineIcons.back,
                              semanticLabel: l10n.common_back,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: Space.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${month.year}',
                                    style: TypeScale.label.copyWith(
                                      color: p.inkMuted,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PlainChevronButton(
                                        icon: LineIcons.chevronLeft,
                                        semanticLabel: l10n.calendar_prevMonth,
                                        color: p.inkMuted,
                                        onTap: () => _move(services, -1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Space.xs,
                                        ),
                                        child: Text(
                                          monthLabel,
                                          style: TypeScale.display.copyWith(
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      _PlainChevronButton(
                                        icon: LineIcons.chevronRight,
                                        semanticLabel: l10n.calendar_nextMonth,
                                        color: isCurrentMonth
                                            ? p.fillEdge
                                            : p.inkMuted,
                                        onTap: isCurrentMonth
                                            ? null
                                            : () => _move(services, 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _StatColumn(
                                    value: recordedDays,
                                    unit: l10n.calendar_daysUnit,
                                    label: l10n.calendar_recordedDays,
                                  ),
                                  const SizedBox(width: Space.lg),
                                  _StatColumn(
                                    value: stampedDays,
                                    unit: l10n.calendar_stampsUnit,
                                    label: l10n.calendar_stamps,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.lg),
                          TableCalendar<void>(
                            firstDay: firstCalendarDay,
                            lastDay: lastCalendarDay,
                            focusedDay: month,
                            headerVisible: false,
                            startingDayOfWeek: StartingDayOfWeek.sunday,
                            sixWeekMonthsEnforced: false,
                            availableGestures:
                                AvailableGestures.horizontalSwipe,
                            rowHeight: 48,
                            daysOfWeekHeight: 24,
                            selectedDayPredicate: (d) =>
                                d.year == picked.year &&
                                d.month == picked.month &&
                                d.day == picked.day,
                            enabledDayPredicate: (d) =>
                                d.year == month.year && d.month == month.month,
                            onPageChanged: (focused) {
                              final next = DateTime(
                                focused.year,
                                focused.month,
                              );
                              setState(() {
                                _month = next;
                                _picked = _defaultPicked(
                                  journal,
                                  next,
                                  services.now(),
                                );
                              });
                            },
                            calendarBuilders: CalendarBuilders<void>(
                              dowBuilder: (context, day) => Center(
                                child: Text(
                                  weekdays[day.weekday % 7],
                                  style: TypeScale.label.copyWith(
                                    color: p.faint,
                                  ),
                                ),
                              ),
                              outsideBuilder: (context, day, focusedDay) =>
                                  const SizedBox.shrink(),
                              defaultBuilder: (context, day, focusedDay) =>
                                  _dayCell(
                                    context,
                                    services,
                                    journal,
                                    day,
                                    effectivePicked: picked,
                                    isPicked: false,
                                    isToday: false,
                                  ),
                              todayBuilder: (context, day, focusedDay) =>
                                  _dayCell(
                                    context,
                                    services,
                                    journal,
                                    day,
                                    effectivePicked: picked,
                                    isPicked: false,
                                    isToday: true,
                                  ),
                              selectedBuilder: (context, day, focusedDay) =>
                                  _dayCell(
                                    context,
                                    services,
                                    journal,
                                    day,
                                    effectivePicked: picked,
                                    isPicked: true,
                                    isToday: isSameDay(day, now),
                                  ),
                              disabledBuilder: (context, day, focusedDay) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: Space.lg),
                          _MonthlyFlowChart(
                            month: month,
                            daysInMonth: daysInMonth,
                            maxTaps: maxTaps,
                            journal: journal,
                            picked: picked,
                            onPickDay: (d) {
                              final date = DateTime(month.year, month.month, d);
                              if (!date.isAfter(now)) {
                                setState(() => _picked = DayKey.of(date));
                              }
                            },
                          ),
                          const SizedBox(height: Space.lg),
                        ],
                      ),
                      _SelectedDayCard(
                        day: picked,
                        record: pickedRecord,
                        onTap: pickedDateIsFuture(picked, now)
                            ? null
                            : () => _open(context, picked),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool pickedDateIsFuture(DayKey key, DateTime now) =>
      DateTime(key.year, key.month, key.day).isAfter(now);

  Widget _dayCell(
    BuildContext context,
    AppServices services,
    MoodJournal journal,
    DateTime day, {
    required DayKey effectivePicked,
    required bool isPicked,
    required bool isToday,
  }) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final key = DayKey.of(day);
    final record = journal.dayOf(key);
    final taps = record.total;
    final isFuture = day.isAfter(services.now());
    final isStamped = _isStamped(taps);
    final fillColor = DayShade.fill(p, taps);
    final textColor = isFuture
        ? p.fillEdge
        : (taps == 0 ? p.inkMuted : DayShade.onFill(p, taps));
    final ringColor = isPicked ? p.ink : (isToday ? p.fillEdge : null);
    final ringWidth = isPicked ? 1.5 : 1.0;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ringColor != null
                  ? Border.all(color: ringColor, width: ringWidth)
                  : null,
            ),
            child: SizedBox.square(
              dimension: 42,
              child: PressableSurface(
                kind: PressableKind.icon,
                radius: Radii.pill,
                color: fillColor,
                semanticLabel: l10n.calendar_openDay(dayTitle(locale, day)),
                onTap: isFuture
                    ? null
                    : () {
                        if (effectivePicked == key) {
                          _open(context, key);
                        } else {
                          setState(() => _picked = key);
                        }
                      },
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TypeScale.body.copyWith(
                      color: textColor,
                      fontWeight: isPicked || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isStamped)
            const Positioned(right: -2, top: -2, child: SmallStampBadge()),
        ],
      ),
    );
  }

  void _open(BuildContext context, DayKey key) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DayDetailScreen(day: key)));
  }
}

class _PlainChevronButton extends StatelessWidget {
  const _PlainChevronButton({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final LineIcons icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 40,
          child: Center(child: LineIcon(icon, size: 18, color: color)),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.unit,
    required this.label,
  });

  final int value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$value',
                style: TypeScale.title.copyWith(color: p.ink),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: TypeScale.label.copyWith(color: p.inkMuted),
                ),
            ],
          ),
        ),
        Text(label, style: TypeScale.label.copyWith(color: p.inkMuted)),
      ],
    );
  }
}

class _MonthlyFlowChart extends StatelessWidget {
  const _MonthlyFlowChart({
    required this.month,
    required this.daysInMonth,
    required this.maxTaps,
    required this.journal,
    required this.picked,
    required this.onPickDay,
  });

  final DateTime month;
  final int daysInMonth;
  final int maxTaps;
  final MoodJournal journal;
  final DayKey picked;
  final ValueChanged<int> onPickDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final groups = <BarChartGroupData>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final taps = journal
          .dayOf(DayKey.of(DateTime(month.year, month.month, d)))
          .total;
      final isPicked =
          picked.year == month.year &&
          picked.month == month.month &&
          picked.day == d;
      final strength = taps / maxTaps;
      final barHeight = taps > 0 ? math.max(3.0, strength * 40.0) : 2.0;
      final barColor = taps == 0
          ? p.line
          : (isPicked ? p.ink : p.ink.withValues(alpha: 0.22));
      groups.add(
        BarChartGroupData(
          x: d,
          barRods: [
            BarChartRodData(
              toY: barHeight,
              width: 6,
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.calendar_monthFlow,
              style: TypeScale.label.copyWith(color: p.faint),
            ),
            Text(
              l10n.calendar_tapsAxis,
              style: TypeScale.label.copyWith(color: p.faint),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 44,
          child: BarChart(
            BarChartData(
              maxY: 42,
              minY: 0,
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 2,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: p.line)),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                ),
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions &&
                      response?.spot != null) {
                    onPickDay(response!.spot!.touchedBarGroup.x);
                  }
                },
              ),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.day,
    required this.record,
    required this.onTap,
  });

  final DayKey day;
  final DayRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final dateText = dayTitle(locale, DateTime(day.year, day.month, day.day));
    final mood = record.dominantMood;
    final isStamped = record.total * GaugeTuning.stepPerTap >= 1.0 - 1e-9;
    final note = record.note;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: p.line),
      ),
      child: PressableSurface(
        kind: PressableKind.card,
        radius: Radii.card,
        color: p.ground,
        semanticLabel: l10n.calendar_openDay(dateText),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              if (mood != null) ...[
                MoodFace(mood: mood, size: 40),
                const SizedBox(width: Space.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateText,
                      style: TypeScale.label.copyWith(color: p.inkMuted),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      mood != null
                          ? moodName(context, mood)
                          : l10n.dayDetail_empty,
                      style: TypeScale.title.copyWith(color: p.ink),
                    ),
                    if (record.total > 0) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        l10n.calendar_tappedTimes(record.total),
                        style: TypeScale.label.copyWith(color: p.ink2),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        '"$note"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypeScale.label.copyWith(color: p.ink),
                      ),
                    ],
                  ],
                ),
              ),
              if (isStamped) ...[
                WellDoneStamp(
                  line1: l10n.calendar_stampLine1,
                  line2: l10n.calendar_stampLine2,
                  semanticLabel: l10n.calendar_stamps,
                ),
                const SizedBox(width: Space.sm),
              ],
              LineIcon(LineIcons.chevronRight, size: 18, color: p.faint),
            ],
          ),
        ),
      ),
    );
  }
}
