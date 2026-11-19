import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// Character states. They match the state names of the designer's Rive or Lottie animation.
enum CharacterPose { idle, react, palmsTogether, finish }

/// The slot the character goes in. For now it is a box that shows the state name.
/// When the animation arrives, only the inside of this widget changes. Callers stay as they are.
class CharacterSlot extends StatelessWidget {
  const CharacterSlot({super.key, required this.pose, this.size = 160});

  final CharacterPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: p.line, width: 2),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Text(
        pose.name,
        style: TypeScale.label.copyWith(color: p.inkMuted),
      ),
    );
  }
}
