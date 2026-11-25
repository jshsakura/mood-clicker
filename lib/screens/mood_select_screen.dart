import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/theme_choice.dart';
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
import '../location/coarse_location.dart';
import '../map/map_rules.dart';
import '../map/map_screen.dart';
import '../weather/weather_source.dart';
import 'how_to_play_sheet.dart';
import 'calendar_screen.dart';
import 'mood_labels.dart';
import 'tap/tap_screen.dart';

/// Five big banners, one per mood. A banner opens the tap screen at once, with no confirmation.
class MoodSelectScreen extends StatelessWidget {
  const MoodSelectScreen({super.key});

  /// The header buttons are a little smaller than the standard 44 so three of them and the
  /// title fit a 390 px wide phone with room between them.
  static const double _headerBox = 40;
  static const double _headerIcon = 20;

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
                            Wrap(
                              spacing: Space.sm,
                              runSpacing: Space.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _HeaderChip(
                                  child: Text(
                                    dayWithWeekday(locale, services.now()),
                                    style: TypeScale.label.copyWith(
                                      color: p.inkMuted,
                                    ),
                                  ),
                                ),
                                // Help and theme first: a hidden weather chip still takes a gap.
                                HowToButton(
                                  compact: true,
                                  onTap: () => showHowToPlaySheet(context),
                                ),
                                const _ThemeButton(),
                                _WeatherChip(
                                  weatherView: services.weatherView,
                                  location: services.location,
                                  weatherSource: services.weatherSource,
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              l10n.moodSelect_title,
                              style: TypeScale.display.copyWith(color: p.ink),
                            ),
                          ],
                        ),
                      ),
                      if (MapRules.available && services.mapView.value) ...[
                        PressableSurface.icon(
                          box: _headerBox,
                          iconSize: _headerIcon,
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
                        const SizedBox(width: Space.sm),
                      ],
                      PressableSurface.icon(
                        box: _headerBox,
                        iconSize: _headerIcon,
                        icon: LineIcons.calendar,
                        semanticLabel: l10n.moodSelect_openCalendar,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CalendarScreen(),
                          ),
                        ),
                      ),
                      if (services.settingsBuilder != null) ...[
                        const SizedBox(width: Space.sm),
                        PressableSurface.icon(
                          box: _headerBox,
                          iconSize: _headerIcon,
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

/// Steps the theme in the settings order (light, dark, pink, follow system) and saves it, so the
/// header needs no trip to settings for it. Sized like the help button beside it.
class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  static const List<ThemeChoice> order = [
    ThemeChoice.named('light'),
    ThemeChoice.named('dark'),
    ThemeChoice.named('pink'),
    ThemeChoice.system,
  ];

  static ThemeChoice nextAfter(ThemeChoice current) {
    final at = order.indexOf(current);
    return order[(at + 1) % order.length];
  }

  static String nameOf(AppLocalizations l10n, ThemeChoice choice) =>
      switch (choice.name) {
        'light' => l10n.settings_themeLight,
        'dark' => l10n.settings_themeDark,
        'pink' => l10n.settings_themePink,
        _ => l10n.settings_themeSystem,
      };

  Future<void> _step(AppServices services) async {
    final next = nextAfter(services.theme.value);
    services.theme.value = next;
    final store = services.settingsStore;
    if (store == null) return;
    final stored = await store.read();
    await store.write(stored.copyWith(theme: next.name));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return ValueListenableBuilder<ThemeChoice>(
      valueListenable: services.theme,
      builder: (context, current, _) => PressableSurface.icon(
        box: HowToButton.compactBox,
        iconSize: HowToButton.compactIcon,
        icon: LineIcons.theme,
        iconColor: p.inkMuted,
        outline: p.line,
        semanticLabel: l10n.moodSelect_themeLabel(nameOf(l10n, current)),
        onTap: () => _step(services),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: p.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        child: child,
      ),
    );
  }
}

class _WeatherChip extends StatefulWidget {
  const _WeatherChip({
    required this.weatherView,
    required this.location,
    required this.weatherSource,
  });

  final ValueListenable<bool> weatherView;
  final CoarseLocation? location;
  final WeatherSource? weatherSource;

  @override
  State<_WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<_WeatherChip> {
  WeatherSnapshot? _snapshot;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.weatherView.addListener(_onToggleChanged);
    _loadIfEnabled();
  }

  @override
  void didUpdateWidget(covariant _WeatherChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherView != widget.weatherView) {
      oldWidget.weatherView.removeListener(_onToggleChanged);
      widget.weatherView.addListener(_onToggleChanged);
    }
    if (oldWidget.location != widget.location ||
        oldWidget.weatherSource != widget.weatherSource ||
        oldWidget.weatherView != widget.weatherView) {
      _loadIfEnabled();
    }
  }

  @override
  void dispose() {
    widget.weatherView.removeListener(_onToggleChanged);
    super.dispose();
  }

  void _onToggleChanged() {
    if (!widget.weatherView.value) {
      if (_snapshot != null) {
        setState(() => _snapshot = null);
      }
      return;
    }
    _loadIfEnabled();
  }

  Future<void> _loadIfEnabled() async {
    if (!widget.weatherView.value || _loading) return;
    final location = widget.location;
    final source = widget.weatherSource;
    if (location == null || source == null) return;

    _loading = true;
    try {
      final coord = await location.current();
      if (!mounted || !widget.weatherView.value || coord == null) {
        if (mounted && _snapshot != null) {
          setState(() => _snapshot = null);
        }
        return;
      }
      final snap = await source.current(coord);
      if (!mounted || !widget.weatherView.value) return;
      setState(() => _snapshot = snap);
    } catch (_) {
      if (mounted && _snapshot != null) {
        setState(() => _snapshot = null);
      }
    } finally {
      _loading = false;
    }
  }

  static LineIcons _iconFor(WeatherKind kind) => switch (kind) {
    WeatherKind.clear => LineIcons.weatherClear,
    WeatherKind.partlyCloudy => LineIcons.weatherPartlyCloudy,
    WeatherKind.cloudy => LineIcons.weatherCloudy,
    WeatherKind.rain => LineIcons.weatherRain,
    WeatherKind.snow => LineIcons.weatherSnow,
  };

  static String _labelFor(AppLocalizations l10n, WeatherKind kind) =>
      switch (kind) {
        WeatherKind.clear => l10n.weather_clear,
        WeatherKind.partlyCloudy => l10n.weather_partlyCloudy,
        WeatherKind.cloudy => l10n.weather_cloudy,
        WeatherKind.rain => l10n.weather_rain,
        WeatherKind.snow => l10n.weather_snow,
      };

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;
    if (!widget.weatherView.value || snap == null) {
      return const SizedBox.shrink();
    }
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final iconSize = TypeScale.label.fontSize ?? Space.lg;
    return _HeaderChip(
      child: Semantics(
        label: '${_labelFor(l10n, snap.kind)} ${snap.tempC}\u00B0',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LineIcon(_iconFor(snap.kind), size: iconSize, color: p.inkMuted),
            const SizedBox(width: Space.xs),
            Text(
              '${snap.tempC}\u00B0',
              style: TypeScale.label.copyWith(color: p.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
