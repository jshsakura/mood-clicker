import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';
import 'line_icon.dart';

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
    this.radius,
    this.selected,
    this.dimWhenOff = true,
  });

  /// A 44 px circular icon button.
  PressableSurface.icon({
    Key? key,
    required LineIcons icon,
    required VoidCallback? onTap,
    required String semanticLabel,
    double iconSize = 22,
    Color? iconColor,
    Color? color,
    bool dimWhenOff = true,
  }) : this(
         key: key,
         kind: PressableKind.icon,
         onTap: onTap,
         semanticLabel: semanticLabel,
         color: color,
         dimWhenOff: dimWhenOff,
         child: Center(
           child: Builder(
             builder: (context) =>
                 LineIcon(icon, size: iconSize, color: iconColor),
           ),
         ),
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

  /// The corner radius of a card. Defaults to [Radii.card].
  final double? radius;

  /// Whether the surface is the chosen one of a group, told to screen readers. Null for none.
  final bool? selected;

  /// Whether a switched off surface fades. A button that only rests (the next month arrow of the
  /// current month) keeps its look and sets this to false.
  final bool dimWhenOff;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _pressed = false;
  bool _focusVisible = false;

  /// The ring that shows keyboard focus, like the design's focus-visible outline.
  static const double focusRingWidth = 2;

  /// How much a switched off surface fades.
  static const double disabledOpacity = 0.4;

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
            borderRadius: BorderRadius.circular(widget.radius ?? Radii.card),
          );
    final enabled = widget.onTap != null;
    final pressed = _pressed && enabled;
    Widget face = DecoratedBox(
      decoration: ShapeDecoration(
        color: widget.color ?? p.surface,
        shape: shape,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_focusVisible && enabled)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: isIcon
                        ? CircleBorder(
                            side: BorderSide(
                              color: p.ink,
                              width: focusRingWidth,
                            ),
                          )
                        : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              widget.radius ?? Radii.card,
                            ),
                            side: BorderSide(
                              color: p.ink,
                              width: focusRingWidth,
                            ),
                          ),
                  ),
                ),
              ),
            ),
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
      selected: widget.selected,
      // The tap action sits on the same node as the name, so a screen reader can run it.
      onTap: widget.onTap,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focusVisible = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: Motion.tap,
            opacity: enabled || !widget.dimWhenOff ? 1 : disabledOpacity,
            child: AnimatedScale(
              duration: Motion.tap,
              curve: Curves.easeOut,
              scale: pressed ? widget.kind.pressedScale : 1,
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}
