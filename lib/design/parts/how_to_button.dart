import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import 'line_icon.dart';
import 'pressable_surface.dart';

/// The how-to-play button of the headers: a question mark that opens the sheet that explains the
/// game. PressableSurface brings the button semantics and keyboard focus with it.
class HowToButton extends StatelessWidget {
  const HowToButton({super.key, this.onTap, this.compact = false});

  /// Null turns the button off, like the other header buttons.
  final VoidCallback? onTap;

  /// The small size that sits in the chip row beside the date.
  final bool compact;

  /// Width and icon size of the compact button, about the height of a header chip.
  static const double compactBox = 32;
  static const double compactIcon = 18;

  @override
  Widget build(BuildContext context) {
    return PressableSurface.icon(
      icon: LineIcons.help,
      semanticLabel: AppLocalizations.of(context).howTo_label,
      onTap: onTap,
      box: compact ? compactBox : PressableSurface.iconSize,
      iconSize: compact ? compactIcon : 22,
    );
  }
}
