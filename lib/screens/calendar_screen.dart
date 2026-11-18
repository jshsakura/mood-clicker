import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/calendar_day_cell.dart';
import '../design/parts/calmap_marks.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_face.dart';
import '../design/parts/month_flow_bars.dart';
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
import 'tap/note_sheet.dart';

/// Monthly calendar matching design/canvas/Calendar.dc.html: back and month arrows in the top row,
/// the month with its counts, a day grid drawn with [CalendarDayCell], the monthly flow bars and
/// the card of the picked day. table_calendar only does the paging, the swipe and the day taps.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Pending final stamp rule: single threshold constant.
  static const double _stampFullRatio = 1.0 - 1e-9;

  /// The first month the calendar shows.
  static final DateTime _firstMonth = DateTime(2020);

  /// The gap between two rows of days, and the height of the weekday row: the weekday text, the
  /// gap under it, less the room the first row already leaves above its circles.
  static const double _rowGap = 8;
  static const double _weekdayRowHeight = 23;
  static const double _captionSpacing = 0.4;

  DateTime? _month;
  DayKey? _picked;

  DateTime _shown(AppServices services) {
    final now = services.now();
    return _month ?? DateTime(now.year, now.month);
  }

  bool _isStamped(int taps) => taps * GaugeTuning.stepPerTap >= _stampFullRatio;

  void _move(AppServices services, int by) {
    final shown = _shown(services);
    final next = DateTime(shown.year, shown.month + by);
    if (next.isBefore(_firstMonth)) return;
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
    final isFirstMonth = !month.isAfter(_firstMonth);
    final firstCalendarDay = _firstMonth;
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

            final dayTaps = [
              for (var d = 1; d <= daysInMonth; d++)
                journal
                    .dayOf(DayKey.of(DateTime(month.year, month.month, d)))
                    .total,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.sm,
                    Space.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      PressableSurface.icon(
                        icon: LineIcons.chevronLeft,
                        semanticLabel: l10n.common_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (!isCurrentMonth)
                        Padding(
                          padding: const EdgeInsets.only(right: Space.sm),
                          child: PressableSurface(
                            kind: PressableKind.card,
                            radius: Radii.pill,
                            color: p.surface,
                            semanticLabel: l10n.calendar_today,
                            onTap: () {
                              final current = DateTime(now.year, now.month);
                              setState(() {
                                _month = current;
                                _picked = _defaultPicked(
                                  journal,
                                  current,
                                  services.now(),
                                );
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Space.md,
                                vertical: Space.xs,
                              ),
                              child: Text(
                                l10n.calendar_today,
                                style: TypeScale.label.copyWith(
                                  color: p.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      PressableSurface.icon(
                        icon: LineIcons.chevronLeft,
                        iconSize: 18,
                        iconColor: isFirstMonth ? p.fillEdge : p.inkMuted,
                        dimWhenOff: false,
                        semanticLabel: l10n.calendar_prevMonth,
                        onTap: isFirstMonth ? null : () => _move(services, -1),
                      ),
                      PressableSurface.icon(
                        icon: LineIcons.chevronRight,
                        iconSize: 18,
                        iconColor: isCurrentMonth ? p.fillEdge : p.inkMuted,
                        dimWhenOff: false,
                        semanticLabel: l10n.calendar_nextMonth,
                        onTap: isCurrentMonth ? null : () => _move(services, 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.gutter,
                        Space.xl,
                        Space.gutter,
                        Space.xxl,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - Space.xl - Space.xxl,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${month.year}',
                                          style: TypeScale.label.copyWith(
                                            color: p.inkMuted,
                                            letterSpacing: _captionSpacing,
                                          ),
                                        ),
                                        Text(
                                          monthLabel,
                                          style: TypeScale.display.copyWith(
                                            color: p.ink,
                                            height: 1.15,
                                            letterSpacing: -0.6,
                                          ),
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
                                        const SizedBox(width: Space.gutter),
                                        _StatColumn(
                                          value: stampedDays,
                                          unit: l10n.calendar_stampsUnit,
                                          label: l10n.calendar_stamps,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Space.xl),
                                TableCalendar<void>(
                                  firstDay: firstCalendarDay,
                                  lastDay: lastCalendarDay,
                                  focusedDay: month,
                                  headerVisible: false,
                                  startingDayOfWeek: StartingDayOfWeek.sunday,
                                  sixWeekMonthsEnforced: false,
                                  availableGestures:
                                      AvailableGestures.horizontalSwipe,
                                  rowHeight: CalendarDayCell.size + _rowGap,
                                  daysOfWeekHeight: _weekdayRowHeight,
                                  selectedDayPredicate: (d) =>
                                      d.year == picked.year &&
                                      d.month == picked.month &&
                                      d.day == picked.day,
                                  enabledDayPredicate: (d) =>
                                      d.year == month.year &&
                                      d.month == month.month,
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
                                    dowBuilder: (context, day) => Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        weekdays[day.weekday % 7],
                                        style: TypeScale.caption.copyWith(
                                          color: p.faint,
                                          letterSpacing: _captionSpacing,
                                        ),
                                      ),
                                    ),
                                    outsideBuilder:
                                        (context, day, focusedDay) =>
                                            const SizedBox.shrink(),
                                    defaultBuilder:
                                        (context, day, focusedDay) => _dayCell(
                                          context,
                                          services,
                                          dayTaps,
                                          maxTaps,
                                          day,
                                          effectivePicked: picked,
                                          isPicked: false,
                                          isToday: false,
                                        ),
                                    todayBuilder: (context, day, focusedDay) =>
                                        _dayCell(
                                          context,
                                          services,
                                          dayTaps,
                                          maxTaps,
                                          day,
                                          effectivePicked: picked,
                                          isPicked: false,
                                          isToday: true,
                                        ),
                                    selectedBuilder:
                                        (context, day, focusedDay) => _dayCell(
                                          context,
                                          services,
                                          dayTaps,
                                          maxTaps,
                                          day,
                                          effectivePicked: picked,
                                          isPicked: true,
                                          isToday: isSameDay(day, now),
                                        ),
                                    disabledBuilder:
                                        (context, day, focusedDay) =>
                                            const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: Space.xl),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.calendar_monthFlow,
                                      style: TypeScale.caption.copyWith(
                                        color: p.faint,
                                        letterSpacing: _captionSpacing,
                                      ),
                                    ),
                                    Text(
                                      l10n.calendar_tapsAxis,
                                      style: TypeScale.caption.copyWith(
                                        color: p.faint,
                                        letterSpacing: _captionSpacing,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Space.sm),
                                MonthFlowBars(
                                  taps: dayTaps,
                                  picked:
                                      picked.year == month.year &&
                                          picked.month == month.month
                                      ? picked.day
                                      : null,
                                  semanticLabel: (d) => l10n.calendar_openDay(
                                    dayTitle(
                                      locale,
                                      DateTime(month.year, month.month, d),
                                    ),
                                  ),
                                  onPick: (d) {
                                    final date = DateTime(
                                      month.year,
                                      month.month,
                                      d,
                                    );
                                    if (!date.isAfter(now)) {
                                      setState(() => _picked = DayKey.of(date));
                                    }
                                  },
                                ),
                                const SizedBox(height: Space.xl),
                                if (recordedDays == 0) ...[
                                  Text(
                                    l10n.calendar_emptyMonth,
                                    textAlign: TextAlign.center,
                                    style: TypeScale.body.copyWith(
                                      color: p.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: Space.xl),
                                ],
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
                  ),
                ),
              ],
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
    List<int> dayTaps,
    int maxTaps,
    DateTime day, {
    required DayKey effectivePicked,
    required bool isPicked,
    required bool isToday,
  }) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final key = DayKey.of(day);
    final taps = dayTaps[day.day - 1];
    final isFuture = day.isAfter(services.now());
    return CalendarDayCell(
      day: day.day,
      look: CalendarDayLook.of(
        p,
        taps: taps,
        maxTaps: maxTaps,
        isPicked: isPicked,
        isToday: isToday,
        isFuture: isFuture,
      ),
      stamped: _isStamped(taps),
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
    );
  }

  void _open(BuildContext context, DayKey key) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DayDetailScreen(day: key)));
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
                style: TypeScale.title.copyWith(color: p.ink, height: 1.2),
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

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.day,
    required this.record,
    required this.onTap,
  });

  final DayKey day;
  final DayRecord record;
  final VoidCallback? onTap;

  /// The stamp is taller than the row it sits in, so it hangs over by this much on each side.
  static const double _stampOverhang = 8;

  /// A longer note is cut after this many lines.
  static const int _noteLines = 2;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final date = DateTime(day.year, day.month, day.day);
    final dateText = dayWithWeekday(locale, date);
    final mood = record.dominantMood;
    final isStamped = record.total * GaugeTuning.stepPerTap >= 1.0 - 1e-9;
    final note = shownNote(l10n, record);

    return PressableSurface(
      kind: PressableKind.card,
      radius: Radii.panel,
      color: p.ground,
      semanticLabel: l10n.calendar_openDay(dayTitle(locale, date)),
      onTap: onTap,
      dimWhenOff: false,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.panel),
          border: Border.all(color: p.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Row(
            children: [
              if (mood != null) ...[
                MoodFace(mood: mood, size: 40),
                const SizedBox(width: Space.lg),
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
                      style: TypeScale.title.copyWith(
                        color: p.ink,
                        letterSpacing: -0.3,
                      ),
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
                        l10n.calendar_noteQuote(note),
                        maxLines: _noteLines,
                        overflow: TextOverflow.ellipsis,
                        style: TypeScale.small.copyWith(color: p.ink),
                      ),
                    ],
                  ],
                ),
              ),
              if (isStamped) ...[
                const SizedBox(width: Space.lg),
                SizedBox(
                  width: WellDoneStamp.size,
                  height: WellDoneStamp.size - 2 * _stampOverhang,
                  child: OverflowBox(
                    maxHeight: WellDoneStamp.size,
                    child: WellDoneStamp(
                      line1: l10n.calendar_stampLine1,
                      line2: l10n.calendar_stampLine2,
                      semanticLabel: l10n.calendar_stamps,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: Space.lg),
              LineIcon(LineIcons.chevronRight, size: 18, color: p.faint),
            ],
          ),
        ),
      ),
    );
  }
}
