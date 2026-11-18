import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import 'line_icon.dart';
import 'pressable_surface.dart';

/// The one help button of the headers: one tap opens the crisis sheet from
/// any screen (docs/EVIDENCE.md, the crisis sheet section).
///
/// PressableSurface brings the button semantics and keyboard focus with it.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, this.onTap});

  /// Null turns the button off, like the other header buttons.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableSurface.icon(
      icon: LineIcons.help,
      semanticLabel: AppLocalizations.of(context).settings_mindCareHelp,
      onTap: onTap,
    );
  }
}
