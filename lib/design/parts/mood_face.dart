import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/mood.dart';
import '../app_theme.dart';

/// The face of a mood: a circle, two eyes, a brow for some moods and a mouth. It is drawn in one
/// color, the color of its mood.
class MoodFace extends StatelessWidget {
  const MoodFace({super.key, required this.mood, this.size = 36, this.color});

  final Mood mood;
  final double size;

  /// Overrides the mood color, for a preview drawn with another theme's palette.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = color ?? p.moodColor(mood);
    return SvgPicture.asset(
      'assets/icons/mood_${mood.id}.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
