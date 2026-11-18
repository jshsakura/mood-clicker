import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../design/app_theme.dart';
import '../../design/parts/pressable_surface.dart';
import '../../design/tokens.g.dart';
import '../../domain/day_key.dart';
import '../../domain/tuning.dart';
import '../../l10n/app_localizations.g.dart';

/// The ready-made sentences. The id is the only part that may ever leave the device.
const notePresetIds = ['proud', 'calm', 'thanks', 'hard', 'tired', 'rest'];

String notePresetText(AppLocalizations l10n, String id) => switch (id) {
  'proud' => l10n.note_presetProud,
  'calm' => l10n.note_presetCalm,
  'thanks' => l10n.note_presetThanks,
  'hard' => l10n.note_presetHard,
  'tired' => l10n.note_presetTired,
  _ => l10n.note_presetRest,
};

/// Asks for the note of the day. The user can skip. Saving writes the note at once.
Future<void> showNoteSheet(BuildContext context, DayKey day) {
  final services = AppScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AppScope(
      services: services,
      child: _NoteSheet(day: day),
    ),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.day});

  final DayKey day;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _controller = TextEditingController();
  String? _presetId;
  String? _presetText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(AppLocalizations l10n, String id) {
    final text = notePresetText(l10n, id);
    setState(() {
      _presetId = id;
      _presetText = text;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _edited(String text) {
    // A preset the user changed is the user's own words now: no id goes with it.
    if (_presetId != null && text != _presetText) {
      setState(() {
        _presetId = null;
        _presetText = null;
      });
    }
  }

  Future<void> _save() async {
    final services = AppScope.of(context);
    final navigator = Navigator.of(context);
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await services.journal.setNote(
        widget.day,
        note: text,
        presetId: _presetId,
      );
    }
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.note_title, style: TypeScale.title.copyWith(color: p.ink)),
          const SizedBox(height: Space.md),
          TextField(
            controller: _controller,
            maxLength: NoteTuning.maxLength,
            maxLines: 1,
            onChanged: _edited,
            decoration: InputDecoration(hintText: l10n.note_hint),
          ),
          const SizedBox(height: Space.sm),
          Text(
            l10n.note_presetLabel,
            style: TypeScale.label.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final id in notePresetIds)
                PressableSurface(
                  kind: PressableKind.card,
                  onTap: () => _pick(l10n, id),
                  color: _presetId == id ? p.line : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                      vertical: Space.sm,
                    ),
                    child: Text(
                      notePresetText(l10n, id),
                      style: TypeScale.label.copyWith(color: p.ink),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.note_skip),
              ),
              const SizedBox(width: Space.sm),
              FilledButton(onPressed: _save, child: Text(l10n.note_save)),
            ],
          ),
        ],
      ),
    );
  }
}
