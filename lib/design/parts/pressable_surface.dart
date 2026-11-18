import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// The shared pressable surface for rows and cards.
///
/// This is a placeholder implementation so screens can adopt the name now;
/// 12.5 replaces the body without touching callers. Flat style: a surface
/// color, a hairline border and a pressed ink response, no shadow or
/// elevation.
class PressableSurface extends StatelessWidget {
  const PressableSurface({
    super.key,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.all(Space.md),
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(
              color: selected ? p.accent : p.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
