import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// How a pressable surface looks and how far it shrinks while pressed.
enum PressableKind {
  /// A round 44 px icon button. Shrinks to 0.92.
  icon(0.92),

  /// A banner or card. Shrinks to 0.98.
  card(0.98);

  const PressableKind(this.pressedScale);

  final double pressedScale;
}

/// The one pressable surface of the app. A press shrinks it a little and darkens it a little in
/// [Motion.tap]. There is no ink splash and no rectangular highlight. The full screen tap area of
/// the tap screen is not a pressable surface and does not use this.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.kind,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.color,
  });

  /// A 44 px circular icon button.
  PressableSurface.icon({
    Key? key,
    required IconData icon,
    required VoidCallback? onTap,
    required String semanticLabel,
  }) : this(
         key: key,
         kind: PressableKind.icon,
         onTap: onTap,
         semanticLabel: semanticLabel,
         child: _IconFace(icon),
       );

  /// The size of an icon button.
  static const double iconSize = 44;

  /// How much the surface is darkened while pressed (the share of the ink color laid on top).
  static const double pressedDarken = 0.08;

  final PressableKind kind;

  /// Null turns the surface off: it does not react to presses.
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  /// The surface color. Defaults to the palette surface.
  final Color? color;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isIcon = widget.kind == PressableKind.icon;
    final shape = isIcon
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          );
    final enabled = widget.onTap != null;
    final pressed = _pressed && enabled;
    Widget face = DecoratedBox(
      decoration: ShapeDecoration(
        color: widget.color ?? p.surface,
        shape: shape,
      ),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: Motion.tap,
                opacity: pressed ? 1 : 0,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: p.ink.withValues(
                      alpha: PressableSurface.pressedDarken,
                    ),
                    shape: shape,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (isIcon) {
      face = SizedBox.square(dimension: PressableSurface.iconSize, child: face);
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: Motion.tap,
          curve: Curves.easeOut,
          scale: pressed ? widget.kind.pressedScale : 1,
          child: face,
        ),
      ),
    );
  }
}

class _IconFace extends StatelessWidget {
  const _IconFace(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Center(child: Icon(icon, size: 22, color: context.palette.ink));
}
