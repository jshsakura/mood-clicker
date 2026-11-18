import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';
import '../../domain/mood.dart';
import 'mood_face.dart';
import 'pressable_surface.dart';

/// One large banner row on the mood picker screen.
class MoodBanner extends StatelessWidget {
  const MoodBanner({
    super.key,
    required this.label,
    required this.mood,
    required this.countLabel,
    required this.onTap,
  });

  final String label;
  final Mood mood;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableSurface(
      kind: PressableKind.card,
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Row(
          children: [
            // The face is the only colored thing on the banner.
            MoodFace(mood: mood, size: 36),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Text(label, style: TypeScale.title.copyWith(color: p.ink)),
            ),
            Text(
              countLabel,
              style: TypeScale.label.copyWith(color: p.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
