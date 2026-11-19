import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/sheet_grab_bar.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.g.dart';

/// Opens the sheet that tells how the game plays. It drags like the other sheets: down to close,
/// up to scroll on a small screen.
Future<void> showHowToPlaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      snap: true,
      builder: (context, scrollController) =>
          HowToPlaySheet(scrollController: scrollController),
    ),
  );
}

/// One line of the sheet per thing the game does, each with its own icon. Every line says what the
/// game really does.
class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    final rows = <(LineIcons, String)>[
      (LineIcons.howDrop, l10n.howTo_fill),
      (LineIcons.howRest, l10n.howTo_rest),
      (LineIcons.howTilt, l10n.howTo_tilt),
      (LineIcons.howSpark, l10n.howTo_spark),
      (LineIcons.howHold, l10n.howTo_hold),
      (LineIcons.howFinish, l10n.howTo_finish),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.md,
          Space.xl,
          Space.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetGrabBar(),
            const SizedBox(height: Space.md),
            Text(
              l10n.howTo_title,
              style: TypeScale.title.copyWith(color: palette.ink),
            ),
            const SizedBox(height: Space.lg),
            for (final (icon, text) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LineIcon(icon, color: palette.ink2),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        text,
                        style: TypeScale.body.copyWith(color: palette.ink),
                      ),
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
