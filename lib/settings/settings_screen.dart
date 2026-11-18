import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/app_theme.dart';
import '../design/parts/pressable_surface.dart';
import '../design/theme_choice.dart';
import '../design/tokens.g.dart';
import '../feedback/feedback_settings.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/locale_choice.dart';
import '../reminder/reminder_controller.dart';
import '../reminder/reminder_port.dart';
import 'crisis_contacts.dart';
import 'records_port.dart';
import 'settings.dart';
import 'settings_store.dart';

/// The settings screen.
///
/// Every write goes through the [SettingsStore] the screen was given (the
/// reminder slice through the [ReminderController], because only it may ask
/// for notification permission), and [onChanged] lets the app shell apply
/// theme and language immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initial,
    required this.store,
    required this.reminder,
    required this.records,
    required this.appVersion,
    this.onChanged,
    this.launchPhone = launchPhoneCall,
  });

  final Settings initial;
  final SettingsStore store;
  final ReminderController reminder;
  final RecordsPort records;

  /// Shown in the About section.
  final String appVersion;

  /// Notified after every persisted change.
  final ValueChanged<Settings>? onChanged;

  /// Opens a tel: url. Injected for tests.
  final Future<bool> Function(String url) launchPhone;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

Future<bool> launchPhoneCall(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  Future<void> _save(Settings next) async {
    await widget.store.write(next);
    setState(() => _settings = next);
    widget.onChanged?.call(next);
  }

  void _saveReminderSlice() {
    setState(
      () => _settings = _settings.copyWith(reminder: widget.reminder.settings),
    );
    widget.onChanged?.call(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          _SectionHeading(l10n.settings_theme),
          _ThemeCards(
            selected: _settings.theme,
            onPick: (name) => _save(_settings.copyWith(theme: name)),
          ),
          _SectionHeading(l10n.settings_language),
          _LanguageChoices(
            selected: _settings.language,
            onPick: (choice) => _save(_settings.copyWith(language: choice)),
          ),
          _SectionHeading(l10n.settings_tapping),
          _ToggleRow(
            label: l10n.settings_vibration,
            value: _settings.hapticsOn,
            onChanged: (on) => _save(_settings.copyWith(hapticsOn: on)),
          ),
          if (_settings.hapticsOn)
            _ChoiceRow(
              label: l10n.settings_vibrationStrength,
              options: [
                (HapticStrength.weak, l10n.settings_strengthWeak),
                (HapticStrength.normal, l10n.settings_strengthNormal),
                (HapticStrength.strong, l10n.settings_strengthStrong),
              ],
              selected: _settings.hapticStrength,
              onPick: (strength) =>
                  _save(_settings.copyWith(hapticStrength: strength)),
            ),
          _ToggleRow(
            label: l10n.settings_sound,
            value: _settings.soundOn,
            onChanged: (on) => _save(_settings.copyWith(soundOn: on)),
          ),
          if (_settings.soundOn)
            _ChoiceRow(
              label: l10n.settings_soundPack,
              options: [
                for (final pack in SoundPack.available)
                  (
                    pack,
                    pack == SoundPack.basic
                        ? l10n.settings_soundPackBasic
                        : pack.name,
                  ),
              ],
              selected: _settings.soundPack,
              onPick: (pack) => _save(_settings.copyWith(soundPack: pack)),
            ),
          _ToggleRow(
            label: l10n.settings_cheers,
            value: _settings.cheersOn,
            onChanged: (on) => _save(_settings.copyWith(cheersOn: on)),
          ),
          if (_settings.cheersOn)
            _ChoiceRow(
              label: l10n.settings_cheersSize,
              options: [
                (CheerSize.normal, l10n.settings_cheersNormal),
                (CheerSize.large, l10n.settings_cheersLarge),
              ],
              selected: _settings.cheerSize,
              onPick: (size) => _save(_settings.copyWith(cheerSize: size)),
            ),
          _ToggleRow(
            label: l10n.settings_shakeOnFull,
            value: _settings.shakeOnFull,
            onChanged: (on) => _save(_settings.copyWith(shakeOnFull: on)),
          ),
          _ToggleRow(
            label: l10n.settings_tiltToPour,
            value: _settings.tiltToPour,
            onChanged: (on) => _save(_settings.copyWith(tiltToPour: on)),
          ),
          _SectionHeading(l10n.settings_notifications),
          _ReminderCard(
            enabled: _settings.reminder.enabled,
            hour: _settings.reminder.hour,
            onToggle: _toggleReminder,
            onPickTime: _pickReminderTime,
          ),
          _SectionHeading(l10n.settings_mindCare),
          _ActionRow(
            label: l10n.settings_mindCareHelp,
            onTap: () => showCrisisSheet(context, widget.launchPhone),
          ),
          _SectionHeading(l10n.settings_map),
          _ToggleRow(
            label: l10n.settings_mapContribute,
            value: _settings.mapContribute,
            onChanged: (on) => _save(_settings.copyWith(mapContribute: on)),
          ),
          _ToggleRow(
            label: l10n.settings_mapComment,
            value: _settings.mapComment,
            subtitle: l10n.settings_mapCommentNote,
            onChanged: (on) => _save(_settings.copyWith(mapComment: on)),
          ),
          _SectionHeading(l10n.settings_records),
          _ActionRow(label: l10n.settings_export, onTap: _exportRecords),
          _ActionRow(
            label: l10n.settings_deleteAll,
            onTap: _confirmDeleteAll,
            destructive: true,
          ),
          _SectionHeading(l10n.settings_about),
          _ValueRow(label: l10n.settings_version, value: widget.appVersion),
          _ActionRow(
            label: l10n.settings_licenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: widget.appVersion,
            ),
          ),
          _ValueRow(
            label: l10n.settings_privacy,
            value: l10n.settings_privacyPending,
          ),
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }

  Future<void> _toggleReminder(bool on) async {
    final l10n = AppLocalizations.of(context);
    final text = ReminderText(l10n.reminder_title, l10n.reminder_body);
    if (on) {
      final recordedToday = await widget.records.hasRecordToday();
      final granted = await widget.reminder.enable(
        text,
        recordedToday: recordedToday,
      );
      if (!granted) {
        // The switch stays off; the system dialog already explained why.
        return;
      }
    } else {
      await widget.reminder.disable();
    }
    _saveReminderSlice();
  }

  Future<void> _pickReminderTime(int hour) async {
    final l10n = AppLocalizations.of(context);
    final text = ReminderText(l10n.reminder_title, l10n.reminder_body);
    await widget.reminder.setTime(
      hour,
      0,
      text,
      recordedToday: await widget.records.hasRecordToday(),
    );
    _saveReminderSlice();
  }

  Future<void> _exportRecords() async {
    await widget.records.exportJournal();
  }

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => _ConfirmSheet(
        title: l10n.settings_deleteConfirmTitle,
        body: l10n.settings_deleteConfirmBody,
        actionLabel: l10n.settings_deleteConfirmAction,
        cancelLabel: l10n.common_cancel,
      ),
    );
    if (confirmed ?? false) {
      await widget.records.deleteAll();
    }
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.md),
      child: Text(
        label,
        style: TypeScale.label.copyWith(color: context.palette.inkMuted),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: InkWell(
        // The whole row toggles; the switch itself still answers directly.
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TypeScale.body.copyWith(color: context.palette.ink),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TypeScale.label.copyWith(
                        color: context.palette.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Space.md, bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TypeScale.label.copyWith(color: context.palette.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          SegmentedButton<T>(
            segments: [
              for (final (value, text) in options)
                ButtonSegment(value: value, label: Text(text)),
            ],
            selected: {selected},
            onSelectionChanged: (values) => onPick(values.first),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.palette.error : context.palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: PressableSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(label, style: TypeScale.body.copyWith(color: color)),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TypeScale.body.copyWith(color: context.palette.ink),
            ),
          ),
          Text(
            value,
            style: TypeScale.body.copyWith(color: context.palette.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ThemeCards extends StatelessWidget {
  const _ThemeCards({required this.selected, required this.onPick});

  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The canvas order: light, dark, pink, then follow system.
    final choices = [
      (ThemeChoice.named('light'), l10n.settings_themeLight),
      (ThemeChoice.named('dark'), l10n.settings_themeDark),
      (ThemeChoice.named('pink'), l10n.settings_themePink),
      (ThemeChoice.system, l10n.settings_themeSystem),
    ];
    return Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: [
        for (final (choice, label) in choices)
          PressableSurface(
            onTap: () => onPick(choice.name),
            selected: selected == choice.name,
            padding: const EdgeInsets.all(Space.md),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  _ThemeSwatch(choice: choice),
                  const SizedBox(height: Space.sm),
                  Text(
                    label,
                    style: TypeScale.label.copyWith(color: context.palette.ink),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.choice});

  final ThemeChoice choice;

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final palette = choice == ThemeChoice.system
        ? paletteFor(choice, platform)
        : paletteFor(choice, Brightness.light);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: palette.ground,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: context.palette.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: Space.sm, height: Space.lg, color: palette.happy),
          const SizedBox(width: Space.sm),
          Container(width: Space.sm, height: Space.lg, color: palette.sad),
          const SizedBox(width: Space.sm),
          Container(width: Space.sm, height: Space.lg, color: palette.accent),
        ],
      ),
    );
  }
}

class _LanguageChoices extends StatelessWidget {
  const _LanguageChoices({required this.selected, required this.onPick});

  final LocaleChoice selected;
  final ValueChanged<LocaleChoice> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: [
        for (final (choice, label) in [
          (LocaleChoice.system, l10n.settings_languageSystem),
          (LocaleChoice.ko, l10n.settings_languageKo),
          (LocaleChoice.en, l10n.settings_languageEn),
          (LocaleChoice.ja, l10n.settings_languageJa),
        ])
          PressableSurface(
            onTap: () => onPick(choice),
            selected: selected == choice,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            child: Text(
              label,
              style: TypeScale.body.copyWith(color: context.palette.ink),
            ),
          ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.hour,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final int hour;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleRow(
          label: l10n.settings_reminder,
          value: enabled,
          onChanged: onToggle,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(left: Space.md),
            child: _ChoiceRow<int>(
              label: l10n.settings_reminderTime,
              options: [
                (20, l10n.settings_time20),
                (21, l10n.settings_time21),
                (22, l10n.settings_time22),
              ],
              selected: hour,
              onPick: onPickTime,
            ),
          ),
      ],
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.cancelLabel,
  });

  final String title;
  final String body;
  final String actionLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TypeScale.title.copyWith(color: palette.ink)),
            const SizedBox(height: Space.md),
            Text(body, style: TypeScale.body.copyWith(color: palette.ink)),
            const SizedBox(height: Space.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
                const SizedBox(width: Space.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    actionLabel,
                    style: TypeScale.body.copyWith(color: palette.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The crisis contacts sheet of the mind care section.
Future<void> showCrisisSheet(
  BuildContext context,
  Future<bool> Function(String url) launchPhone,
) async {
  final l10n = AppLocalizations.of(context);
  final entries = <(String, String, String)>[
    (
      l10n.settings_mindCareCenter,
      crisisPhoneNumbers['mentalHealthCenter']!,
      l10n.settings_mindCareCenterNote,
    ),
    (
      l10n.settings_mindCareSuicide,
      crisisPhoneNumbers['suicidePrevention']!,
      l10n.settings_mindCareCenterNote,
    ),
    (l10n.settings_mindCareKakao, '', ''),
    (l10n.settings_mindCarePolice, crisisPhoneNumbers['police']!, ''),
    (l10n.settings_mindCareMedical, crisisPhoneNumbers['medical']!, ''),
  ];
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final palette = sheetContext.palette;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings_mindCareHelp,
                style: TypeScale.title.copyWith(color: palette.ink),
              ),
              const SizedBox(height: Space.md),
              for (final (label, number, note) in entries)
                PressableSurface(
                  onTap: number.isEmpty
                      ? null
                      : () => launchPhone('tel:$number'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TypeScale.body.copyWith(
                                color: palette.ink,
                              ),
                            ),
                            if (note.isNotEmpty)
                              Text(
                                note,
                                style: TypeScale.label.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (number.isNotEmpty)
                        Text(
                          number,
                          style: TypeScale.body.copyWith(color: palette.accent),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.md),
              Text(
                l10n.settings_notMedical,
                style: TypeScale.label.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      );
    },
  );
}
