import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/day_key.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/date_labels.dart';
import 'day_detail_screen.dart';
import 'mood_labels.dart';

/// One month at a time. Each day with taps shows its main mood; a day without taps stays empty.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _month;

  /// The first day of the month on show.
  DateTime _shown(AppServices services) {
    final now = services.now();
    return _month ?? DateTime(now.year, now.month);
  }

  void _move(AppServices services, int by) {
    final shown = _shown(services);
    setState(() => _month = DateTime(shown.year, shown.month + by));
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
    final firstWeekday = month.weekday % 7; // Sunday is 0
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekdays = weekdayLabels(locale);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.journal,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    PressableSurface.icon(
                      icon: Icons.arrow_back,
                      semanticLabel: l10n.common_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    PressableSurface.icon(
                      icon: Icons.chevron_left,
                      semanticLabel: l10n.calendar_prevMonth,
                      onTap: () => _move(services, -1),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        monthTitle(locale, month),
                        textAlign: TextAlign.center,
                        style: TypeScale.title.copyWith(color: p.ink),
                      ),
                    ),
                    PressableSurface.icon(
                      icon: Icons.chevron_right,
                      semanticLabel: l10n.calendar_nextMonth,
                      onTap: isCurrentMonth ? null : () => _move(services, 1),
                    ),
                    const Spacer(),
                    const SizedBox(width: PressableSurface.iconSize),
                  ],
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    for (final label in weekdays)
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TypeScale.label.copyWith(color: p.inkMuted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rows = ((firstWeekday + daysInMonth) / 7).ceil();
                      final cellHeight = (constraints.maxHeight / rows).clamp(
                        40.0,
                        88.0,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          for (var row = 0; row < rows; row++)
                            SizedBox(
                              height: cellHeight,
                              child: Row(
                                children: [
                                  for (var col = 0; col < 7; col++)
                                    Expanded(
                                      child: _cell(
                                        context,
                                        services,
                                        month,
                                        row * 7 + col - firstWeekday + 1,
                                        daysInMonth,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    AppServices services,
    DateTime month,
    int dayNumber,
    int daysInMonth,
  ) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final date = DateTime(month.year, month.month, dayNumber);
    final key = DayKey.of(date);
    final record = services.journal.journal.dayOf(key);
    final mood = record.dominantMood;
    final isFuture = date.isAfter(services.now());
    return Padding(
      padding: const EdgeInsets.all(2),
      child: PressableSurface(
        kind: PressableKind.card,
        radius: Radii.button,
        color: mood == null ? p.ground : null,
        semanticLabel: l10n.calendar_openDay(dayTitle(locale, date)),
        onTap: isFuture ? null : () => _open(context, key),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TypeScale.label.copyWith(color: p.inkMuted),
            ),
            if (mood != null)
              Text(moodEmoji(mood), style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, DayKey key) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DayDetailScreen(day: key)));
  }
}
