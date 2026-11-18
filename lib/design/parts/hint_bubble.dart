import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// A small speech bubble with one short line, used for one-time hints. It does not take touches.
class HintBubble extends StatelessWidget {
  const HintBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(text, style: TypeScale.label.copyWith(color: p.ground)),
      ),
    );
  }
}
