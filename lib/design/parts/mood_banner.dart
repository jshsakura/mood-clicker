import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';
import 'pressable_surface.dart';

/// One large banner row on the mood picker screen.
class MoodBanner extends StatelessWidget {
  const MoodBanner({
    super.key,
    required this.label,
    required this.emoji,
    required this.todayCount,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final int todayCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableSurface(
      kind: PressableKind.card,
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xl,
          vertical: Space.lg,
        ),
        child: Row(
          children: [
            // The face is the only colored thing on the banner.
            Text(emoji, style: TypeScale.display),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Text(label, style: TypeScale.title.copyWith(color: p.ink)),
            ),
            Text(
              '$todayCount',
              style: TypeScale.label.copyWith(color: p.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
