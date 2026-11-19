import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import 'line_icon.dart';
import 'pressable_surface.dart';

/// The how-to-play button of the headers: a question mark that opens the sheet that explains the
/// game. PressableSurface brings the button semantics and keyboard focus with it.
class HowToButton extends StatelessWidget {
  const HowToButton({super.key, this.onTap});

  /// Null turns the button off, like the other header buttons.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableSurface.icon(
      icon: LineIcons.help,
      semanticLabel: AppLocalizations.of(context).howTo_label,
      onTap: onTap,
    );
  }
}
