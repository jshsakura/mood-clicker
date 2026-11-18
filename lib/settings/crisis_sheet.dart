import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/app_theme.dart';
import '../design/parts/pressable_surface.dart';
import '../design/parts/sheet_grab_bar.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.g.dart';
import 'crisis_contacts.dart';

Future<bool> launchPhoneCall(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Opens the crisis sheet for the region of the device. It is reached only from the mind care
/// entry of the settings.
///
/// The sheet drags: down to close, up to scroll when the region has more
/// lines than fit.
Future<void> showCrisisSheet(
  BuildContext context, {
  Future<bool> Function(String url) launchPhone = launchPhoneCall,
}) {
  final region = crisisRegionOf(
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      snap: true,
      builder: (context, scrollController) => CrisisSheet(
        region: region,
        launchPhone: launchPhone,
        scrollController: scrollController,
      ),
    ),
  );
}

/// The crisis sheet of the mind care section.
class CrisisSheet extends StatelessWidget {
  const CrisisSheet({
    super.key,
    required this.region,
    required this.launchPhone,
    this.scrollController,
  });

  final CrisisRegion region;
  final Future<bool> Function(String url) launchPhone;

  /// The sheet's own controller, so dragging scrolls while pinned and
  /// dismisses at the top of the content.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    String labelOf(CrisisEntry entry) => switch (entry.labelKey) {
      'suicide' => l10n.settings_mindCareSuicide,
      'center' => l10n.settings_mindCareCenter,
      'kakao' => l10n.settings_mindCareKakao,
      'sosJapan' => l10n.settings_mindCareSosJapan,
      'yorisoiJapan' => l10n.settings_mindCareYorisoiJapan,
      'us988' => l10n.settings_mindCareUs988,
      'us988Text' => l10n.settings_mindCareUs988Text,
      _ => l10n.settings_mindCareFindHelpline,
    };
    String? noteOf(CrisisEntry entry) => switch (entry.noteKey) {
      'SuicideNote' => l10n.settings_mindCareSuicideNote,
      'CenterNote' => l10n.settings_mindCareCenterNote,
      'KakaoNote' => l10n.settings_mindCareKakaoNote,
      'FindHelplineNote' => l10n.settings_mindCareFindHelplineNote,
      _ => null,
    };

    /// Dials or texts, and when the system refuses, copies the number and
    /// says so: the number on the row is the fallback.
    Future<void> openEntry(CrisisEntry entry) async {
      final url = entry.launchUrl!;
      final opened = await launchPhone(url);
      if (opened || !context.mounted) return;
      await Clipboard.setData(
        ClipboardData(
          text: entry.trailing ?? entry.number ?? entry.textNumber ?? '',
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.settings_mindCareCopyFallback)),
        );
    }

    return SafeArea(
      // The sheet grows with the region; small screens scroll instead of
      // overflowing. The bar at the top says it can be dragged down to close.
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
                onTap: entry.launchUrl == null ? null : () => openEntry(entry),
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
                      if (entry.trailing != null)
                        Text(
                          entry.trailing!,
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
            Text(switch (region) {
              CrisisRegion.korea => l10n.settings_mindCareFootnote,
              CrisisRegion.japan => l10n.settings_mindCareFootnoteJapan,
              CrisisRegion.unitedStates => l10n.settings_mindCareFootnoteUs,
              CrisisRegion.other => l10n.settings_mindCareFootnoteOther,
            }, style: TypeScale.label.copyWith(color: palette.inkMuted)),
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
