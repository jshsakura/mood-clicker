import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../design/app_theme.dart';
import '../../design/parts/pressable_surface.dart';
import '../../design/tokens.g.dart';
import '../../domain/day_key.dart';
import '../../domain/day_record.dart';
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

/// Asks for the note of [day]. The user can skip. Saving writes the note at once. The sheet starts
/// with the line already on that day, so it also edits. [afterComplete] adds the line that says why
/// the sheet opened: the gauge was filled.
Future<void> showNoteSheet(
  BuildContext context,
  DayKey day, {
  bool afterComplete = false,
}) {
  final services = AppScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AppScope(
      services: services,
      child: _NoteSheet(
        day: day,
        afterComplete: afterComplete,
        existing: services.journal.journal.dayOf(day),
      ),
    ),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.day,
    required this.afterComplete,
    required this.existing,
  });

  final DayKey day;

  /// What the day holds when the sheet opens: the note to edit, if any.
  final DayRecord existing;
  final bool afterComplete;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller;
  String? _presetId;
  String? _presetText;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final record = widget.existing;
    _controller = TextEditingController(text: record.note ?? '');
    _presetId = record.notePresetId;
    _presetText = record.note;
  }

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
      _failed = false;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _edited(String text) {
    // A preset the user changed is the user's own words now: no id goes with it.
    if (_presetId != null && text != _presetText) {
      _presetId = null;
      _presetText = null;
    }
    if (_failed) setState(() => _failed = false);
  }

  /// Writes the note. On a failure the sheet stays open with the draft and says so. When the
  /// sheet was already dismissed while the write ran, nothing is popped: the pop would close the
  /// screen below it.
  Future<void> _save() async {
    final text = _controller.text.trim();
    if (_saving || text.isEmpty) return;
    final journal = AppScope.of(context).journal;
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _failed = false;
    });
    bool written;
    try {
      written = await journal.setNote(
        widget.day,
        note: text,
        presetId: _presetId,
      );
    } on Object {
      written = false;
    }
    if (!mounted) return;
    if (!written) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    if (route != null && route.isCurrent) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.note_title,
                      style: TypeScale.title.copyWith(color: p.ink),
                    ),
                    if (widget.afterComplete) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        l10n.note_reason,
                        style: TypeScale.label.copyWith(color: p.inkMuted),
                      ),
                    ],
                    const SizedBox(height: Space.md),
                    TextField(
                      controller: _controller,
                      maxLength: NoteTuning.maxLength,
                      maxLines: 1,
                      onChanged: _edited,
                      decoration: InputDecoration(hintText: l10n.note_hint),
                    ),
                    Text(
                      l10n.note_privacy,
                      style: TypeScale.label.copyWith(color: p.inkMuted),
                    ),
                    const SizedBox(height: Space.md),
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
                    const SizedBox(height: Space.md),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_failed)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Text(
                          l10n.note_saveFailed,
                          style: TypeScale.label.copyWith(color: p.error),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.note_skip),
                      ),
                      const SizedBox(width: Space.sm),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) => FilledButton(
                          onPressed: _saving || value.text.trim().isEmpty
                              ? null
                              : _save,
                          child: Text(l10n.note_save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
