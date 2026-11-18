import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';
import '../app_theme.dart';
import '../tokens.g.dart';

/// The canvas grab bar at the top of a bottom sheet. It drags the sheet closed and, for assistive
/// technology, it is the top close button.
class SheetGrabBar extends StatelessWidget {
  const SheetGrabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).settings_close,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Container(
            width: 36,
            height: 12,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.line,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
