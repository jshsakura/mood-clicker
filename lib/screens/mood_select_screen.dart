import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
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
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.moodSelect_today} ${dayTitle(locale, services.now())}',
                          style: TypeScale.title.copyWith(color: p.ink),
                        ),
                      ),
                      PressableSurface.icon(
                        icon: Icons.calendar_month_outlined,
                        semanticLabel: l10n.moodSelect_openCalendar,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CalendarScreen(),
                          ),
                        ),
                      ),
                      if (services.mapView.value) ...[
                        const SizedBox(width: Space.sm),
                        PressableSurface.icon(
                          icon: Icons.map_outlined,
                          semanticLabel: l10n.map_openLabel,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MapScreen(
                                justRecorded: lastRecordedMood(record),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (services.settingsBuilder != null) ...[
                        const SizedBox(width: Space.sm),
                        PressableSurface.icon(
                          icon: Icons.settings_outlined,
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
                  const SizedBox(height: Space.lg),
                  for (final mood in Mood.values) ...[
                    Expanded(
                      child: MoodBanner(
                        label: moodName(context, mood),
                        emoji: moodEmoji(mood),
                        todayCount: record.countOf(mood),
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
