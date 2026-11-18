import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// One large banner row on the mood picker screen.
class MoodBanner extends StatelessWidget {
  const MoodBanner({
    super.key,
    required this.label,
    required this.emoji,
    required this.isHappySide,
    required this.todayCount,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isHappySide;
  final int todayCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final side = isHappySide ? p.happy : p.sad;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Row(
            children: [
              Container(
                width: Space.sm,
                height: Space.xxxl,
                decoration: BoxDecoration(
                  color: side,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
              const SizedBox(width: Space.lg),
              Text(emoji, style: TypeScale.display),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Text(
                  label,
                  style: TypeScale.title.copyWith(color: p.ink),
                ),
              ),
              Text(
                '$todayCount',
                style: TypeScale.label.copyWith(color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
