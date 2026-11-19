import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/how_to_button.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_banner.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../feedback/feedback_kind.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/date_labels.dart';
import '../map/map_rules.dart';
import '../map/map_screen.dart';
import 'how_to_play_sheet.dart';
import 'calendar_screen.dart';
import 'mood_labels.dart';
import 'tap/tap_screen.dart';

/// Five big banners, one per mood. A banner opens the tap screen at once, with no confirmation.
class MoodSelectScreen extends StatelessWidget {
  const MoodSelectScreen({super.key});

  void _open(BuildContext context, Mood mood) {
    final services = AppScope.of(context);
    services.feedback.trigger(FeedbackKind.select, mood.id);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TapScreen(mood: mood)));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final locale = Localizations.localeOf(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([services.journal, services.mapView]),
          builder: (context, _) {
            final today = DayKey.of(services.now());
            final record = services.journal.journal.dayOf(today);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.lg,
                Space.xl,
                Space.xxl,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayWithWeekday(locale, services.now()),
                              style: TypeScale.label.copyWith(
                                color: p.inkMuted,
                              ),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              l10n.moodSelect_title,
                              style: TypeScale.display.copyWith(color: p.ink),
                            ),
                          ],
                        ),
                      ),
                      HowToButton(onTap: () => showHowToPlaySheet(context)),
                      if (MapRules.available && services.mapView.value) ...[
                        PressableSurface.icon(
                          icon: LineIcons.map,
                          semanticLabel: l10n.map_openLabel,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MapScreen(
                                justRecorded: lastRecordedMood(record),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                      ],
                      PressableSurface.icon(
                        icon: LineIcons.calendar,
                        semanticLabel: l10n.moodSelect_openCalendar,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CalendarScreen(),
                          ),
                        ),
                      ),
                      if (services.settingsBuilder != null) ...[
                        const SizedBox(width: Space.xs),
                        PressableSurface.icon(
                          icon: LineIcons.settings,
                          semanticLabel: l10n.settings_title,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: services.settingsBuilder!,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  for (final mood in Mood.values) ...[
                    Expanded(
                      child: MoodBanner(
                        label: moodName(context, mood),
                        mood: mood,
                        countLabel: l10n.tap_todayCount(record.countOf(mood)),
                        onTap: () => _open(context, mood),
                      ),
                    ),
                    if (mood != Mood.values.last)
                      const SizedBox(height: Space.md),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
