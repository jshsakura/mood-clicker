import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/app_theme.dart';
import '../design/parts/pressable_surface.dart';
import '../design/theme_choice.dart';
import '../design/tokens.g.dart';
import '../domain/feel_settings.dart';
import '../feedback/feedback_settings.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/locale_choice.dart';
import '../reminder/reminder_controller.dart';
import '../reminder/reminder_port.dart';
import 'crisis_contacts.dart';
import 'records_port.dart';
import 'privacy_screen.dart';
import 'settings.dart';
import 'settings_store.dart';

/// The settings screen, following the canvas: section headings over rounded
/// surface cards, pill switches with the detail choices folded underneath.
///
/// Writes go through [store]; the feel, theme and language notifiers carry
/// the change into the app at once. The reminder slice goes through
/// [reminder], the only place that may ask for notification permission.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.feel,
    required this.theme,
    required this.language,
    required this.mapView,
    required this.reminder,
    required this.records,
    required this.appVersion,
    this.launchPhone = launchPhoneCall,
  });

  final SettingsStore store;
  final ValueNotifier<FeelSettings> feel;
  final ValueNotifier<ThemeChoice> theme;
  final ValueNotifier<LocaleChoice> language;
  final ValueNotifier<bool> mapView;
  final ReminderController reminder;
  final RecordsPort records;
  final String appVersion;
  final Future<bool> Function(String url) launchPhone;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

Future<bool> launchPhoneCall(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class _SettingsScreenState extends State<SettingsScreen> {
  Settings _settings = const Settings();

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final stored = await widget.store.read();
    if (!mounted) return;
    setState(() => _settings = stored);
  }

  Future<void> _save(Settings next) async {
    await widget.store.write(next);
    setState(() => _settings = next);
    widget.feel.value = next.feelSettings;
    widget.theme.value = next.themeChoice;
    widget.language.value = next.language;
    widget.mapView.value = next.mapView;
  }

  void _saveReminderSlice() {
    setState(
      () => _settings = _settings.copyWith(reminder: widget.reminder.settings),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.md,
            Space.md,
            Space.xl,
          ),
          children: [
            _Header(title: l10n.settings_title),
            const SizedBox(height: Space.lg),
            _Section(
              label: l10n.settings_theme,
              card: [
                _ThemeGrid(
                  selected: _settings.theme,
                  onPick: (name) => _save(_settings.copyWith(theme: name)),
                ),
                _CardNote(l10n.settings_themeNote),
              ],
            ),
            _Section(
              label: l10n.settings_language,
              card: [
                _SegmentBar(
                  options: [
                    (LocaleChoice.system, l10n.settings_languageSystem),
                    (LocaleChoice.ko, l10n.settings_languageKo),
                    (LocaleChoice.en, l10n.settings_languageEn),
                    (LocaleChoice.ja, l10n.settings_languageJa),
                  ],
                  selected: _settings.language,
                  onPick: (choice) =>
                      _save(_settings.copyWith(language: choice)),
                ),
              ],
            ),
            _Section(
              label: l10n.settings_tapping,
              card: [
                _ToggleBlock(
                  label: l10n.settings_vibration,
                  description: l10n.settings_vibrationDesc,
                  value: _settings.hapticsOn,
                  onChanged: (on) => _save(_settings.copyWith(hapticsOn: on)),
                  details: [
                    (HapticStrength.weak, l10n.settings_strengthWeak),
                    (HapticStrength.normal, l10n.settings_strengthNormal),
                    (HapticStrength.strong, l10n.settings_strengthStrong),
                  ],
                  selectedDetail: _settings.hapticStrength,
                  onPickDetail: (strength) =>
                      _save(_settings.copyWith(hapticStrength: strength)),
                ),
                _ToggleBlock(
                  label: l10n.settings_sound,
                  description: l10n.settings_soundDesc,
                  value: _settings.soundOn,
                  onChanged: (on) => _save(_settings.copyWith(soundOn: on)),
                  details: [
                    for (final pack in SoundPack.available)
                      (
                        pack,
                        pack == SoundPack.basic
                            ? l10n.settings_soundPackBasic
                            : pack.name,
                      ),
                  ],
                  selectedDetail: _settings.soundPack,
                  onPickDetail: (pack) =>
                      _save(_settings.copyWith(soundPack: pack)),
                ),
                _ToggleBlock(
                  label: l10n.settings_cheers,
                  description: l10n.settings_cheersDesc,
                  value: _settings.cheersOn,
                  onChanged: (on) => _save(_settings.copyWith(cheersOn: on)),
                  details: [
                    (CheerSize.normal, l10n.settings_cheersNormal),
                    (CheerSize.large, l10n.settings_cheersLarge),
                  ],
                  selectedDetail: _settings.cheerSize,
                  onPickDetail: (size) =>
                      _save(_settings.copyWith(cheerSize: size)),
                ),
                _ToggleBlock(
                  label: l10n.settings_shakeOnFull,
                  description: l10n.settings_shakeDesc,
                  value: _settings.shakeOnFull,
                  onChanged: (on) => _save(_settings.copyWith(shakeOnFull: on)),
                ),
                _ToggleBlock(
                  label: l10n.settings_tiltToPour,
                  description: l10n.settings_pourDesc,
                  value: _settings.tiltToPour,
                  onChanged: (on) => _save(_settings.copyWith(tiltToPour: on)),
                ),
              ],
            ),
            _Section(
              label: l10n.settings_notifications,
              card: [
                _ToggleBlock(
                  label: l10n.settings_reminder,
                  description: l10n.settings_reminderDesc,
                  value: _settings.reminder.enabled,
                  onChanged: _toggleReminder,
                  details: [
                    (20, l10n.settings_time20),
                    (21, l10n.settings_time21),
                    (22, l10n.settings_time22),
                  ],
                  selectedDetail: _settings.reminder.hour,
                  onPickDetail: _pickReminderTime,
                ),
              ],
            ),
            _Section(
              label: l10n.settings_map,
              card: [
                _ToggleBlock(
                  label: l10n.settings_mapView,
                  description: l10n.settings_mapViewDesc,
                  value: _settings.mapView,
                  onChanged: (on) => _save(_settings.copyWith(mapView: on)),
                ),
                _ToggleBlock(
                  label: l10n.settings_mapContribute,
                  description: l10n.settings_mapContributeDesc,
                  value: _settings.mapContribute,
                  onChanged: (on) =>
                      _save(_settings.copyWith(mapContribute: on)),
                ),
                _ToggleBlock(
                  label: l10n.settings_mapComment,
                  description: l10n.settings_mapCommentDesc,
                  value: _settings.mapComment,
                  onChanged: (on) => _save(_settings.copyWith(mapComment: on)),
                ),
              ],
            ),
            _Section(
              label: l10n.settings_records,
              card: [
                _LinkRow(
                  label: l10n.settings_export,
                  description: l10n.settings_exportDesc,
                  onTap: _exportRecords,
                ),
                _LinkRow(
                  label: l10n.settings_deleteAll,
                  onTap: _confirmDeleteAll,
                  destructive: true,
                ),
              ],
            ),
            _Section(
              label: l10n.settings_mindCare,
              card: [
                _LinkRow(
                  label: l10n.settings_mindCareHelp,
                  description: l10n.settings_mindCareRowDesc,
                  onTap: () => _openCrisisSheet(),
                ),
              ],
            ),
            _Section(
              label: l10n.settings_about,
              card: [
                _LinkRow(
                  label: l10n.settings_version,
                  value: widget.appVersion,
                ),
                _LinkRow(
                  label: l10n.settings_licenses,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appName,
                    applicationVersion: widget.appVersion,
                  ),
                ),
                _LinkRow(
                  label: l10n.settings_privacy,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context);
    await widget.records.exportJournal();
    _toast(l10n.settings_exportDone);
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

  Future<void> _openCrisisSheet() async {
    final region = crisisRegionOf(
      WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) =>
          CrisisSheet(region: region, launchPhone: widget.launchPhone),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableSurface.icon(
          icon: Icons.arrow_back,
          semanticLabel: AppLocalizations.of(context).common_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: Space.md),
        Text(
          title,
          style: TypeScale.title.copyWith(
            color: context.palette.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.card});

  final String label;
  final List<Widget> card;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Text(
              label,
              style: TypeScale.label.copyWith(color: palette.inkMuted),
            ),
          ),
          const SizedBox(height: Space.sm),
          Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            child: Column(
              children: [
                for (var i = 0; i < card.length; i++) ...[
                  if (i > 0) const _RowSeparator(),
                  card[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNote extends StatelessWidget {
  const _CardNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
      child: Text(
        text,
        style: TypeScale.label.copyWith(color: context.palette.inkMuted),
      ),
    );
  }
}

class _ToggleBlock<T> extends StatelessWidget {
  const _ToggleBlock({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.details = const [],
    this.selectedDetail,
    this.onPickDetail,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<(T, String)> details;
  final T? selectedDetail;
  final ValueChanged<T>? onPickDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          // The whole row toggles, like the pill itself.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Space.md),
                      Text(
                        label,
                        style: TypeScale.body.copyWith(
                          color: context.palette.ink,
                        ),
                      ),
                      Text(
                        description,
                        style: TypeScale.label.copyWith(
                          color: context.palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                    ],
                  ),
                ),
                _PillSwitch(value: value, onChanged: onChanged, label: label),
              ],
            ),
          ),
        ),
        if (value && details.isNotEmpty && onPickDetail != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
            child: _SegmentBar(
              options: details,
              selected: selectedDetail as T,
              onPick: onPickDetail!,
            ),
          ),
      ],
    );
  }
}

class _RowSeparator extends StatelessWidget {
  const _RowSeparator();
  @override
  Widget build(BuildContext context) {
    // The first row of a card has no line above it.
    return SizedBox(
      height: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.palette.line),
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      checked: value,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: Motion.tap,
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? palette.ink : palette.fillEdge,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: palette.ground,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentBar<T> extends StatelessWidget {
  const _SegmentBar({
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.ground,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: _SegmentOption(
                label: label,
                selected: value == selected,
                onTap: () => onPick(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.tap,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ink : null,
          borderRadius: BorderRadius.circular(Radii.button - 4),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TypeScale.label.copyWith(
            color: selected ? palette.ground : palette.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.selected, required this.onPick});

  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The canvas order: light, dark, pink, then follow system.
    final choices = [
      (const ThemeChoice.named('light'), l10n.settings_themeLight),
      (const ThemeChoice.named('dark'), l10n.settings_themeDark),
      (const ThemeChoice.named('pink'), l10n.settings_themePink),
      (ThemeChoice.system, l10n.settings_themeSystem),
    ];
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The canvas lays the four cards out in two columns.
          final width = (constraints.maxWidth - Space.sm) / 2;
          return Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final (choice, label) in choices)
                SizedBox(
                  width: width,
                  child: _ThemeCard(
                    choice: choice,
                    label: label,
                    selected: selected == choice.name,
                    onTap: () => onPick(choice.name),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.choice,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final preview = paletteFor(choice, Brightness.light);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 104,
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: preview.ground,
              borderRadius: BorderRadius.circular(Radii.button),
              border: Border.all(
                color: selected ? palette.ink : preview.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).moodSelect_today,
                  style: TypeScale.label.copyWith(
                    color: preview.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Space.xs),
                _MiniRow(
                  color: preview.happy,
                  line: preview.line,
                  face: preview.ink,
                ),
                const SizedBox(height: Space.xs),
                _MiniRow(
                  color: preview.sad,
                  line: preview.line,
                  face: preview.ink,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 16, color: palette.ink),
                  const SizedBox(width: Space.xs),
                ],
                Text(
                  label,
                  style: TypeScale.label.copyWith(
                    color: palette.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.color, required this.line, required this.face});

  final Color color;
  final Color line;
  final Color face;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(Radii.button - 4),
      ),
      child: Row(
        children: [
          Icon(Icons.mood, size: 16, color: color),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    this.description,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final String? description;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = destructive ? palette.error : palette.ink;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Space.md),
                      Text(label, style: TypeScale.body.copyWith(color: color)),
                      if (description != null)
                        Text(
                          description!,
                          style: TypeScale.label.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      const SizedBox(height: Space.md),
                    ],
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    style: TypeScale.label.copyWith(color: palette.inkMuted),
                  ),
                if (onTap != null) ...[
                  const SizedBox(width: Space.sm),
                  Icon(Icons.chevron_right, size: 16, color: palette.inkMuted),
                ],
              ],
            ),
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
            Text(
              title,
              style: TypeScale.title.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(body, style: TypeScale.body.copyWith(color: palette.ink)),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: PressableSurface(
                    kind: PressableKind.card,
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        cancelLabel,
                        style: TypeScale.body.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: PressableSurface(
                    kind: PressableKind.card,
                    color: palette.error,
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        actionLabel,
                        style: TypeScale.body.copyWith(
                          color: palette.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

/// The crisis sheet of the mind care section.
class CrisisSheet extends StatelessWidget {
  const CrisisSheet({
    super.key,
    required this.region,
    required this.launchPhone,
  });

  final CrisisRegion region;
  final Future<bool> Function(String url) launchPhone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    String labelOf(CrisisEntry entry) => switch (entry.labelKey) {
      'suicide' => l10n.settings_mindCareSuicide,
      'center' => l10n.settings_mindCareCenter,
      'kakao' => l10n.settings_mindCareKakao,
      'sosJapan' => l10n.settings_mindCareSosJapan,
      _ => l10n.settings_mindCareYorisoiJapan,
    };
    String? noteOf(CrisisEntry entry) => switch (entry.noteKey) {
      'SuicideNote' => l10n.settings_mindCareSuicideNote,
      'CenterNote' => l10n.settings_mindCareCenterNote,
      'KakaoNote' => l10n.settings_mindCareKakaoNote,
      _ => null,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings_mindCareTitle,
              style: TypeScale.title.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              l10n.settings_mindCareIntro,
              style: TypeScale.body.copyWith(color: palette.inkMuted),
            ),
            const SizedBox(height: Space.md),
            for (final entry in crisisEntriesFor(region)) ...[
              PressableSurface(
                kind: PressableKind.card,
                onTap: entry.number == null
                    ? null
                    : () => launchPhone('tel:${entry.number}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Space.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labelOf(entry),
                                style: TypeScale.body.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (noteOf(entry) != null)
                                Text(
                                  noteOf(entry)!,
                                  style: TypeScale.label.copyWith(
                                    color: palette.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (entry.number != null)
                        Text(
                          entry.number!,
                          style: TypeScale.body.copyWith(
                            color: palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
            Text(
              l10n.settings_mindCareFootnote,
              style: TypeScale.label.copyWith(color: palette.inkMuted),
            ),
            const SizedBox(height: Space.md),
            PressableSurface(
              kind: PressableKind.card,
              color: palette.ink,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  l10n.settings_close,
                  style: TypeScale.body.copyWith(
                    color: palette.ground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
