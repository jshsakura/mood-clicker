import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/app_theme.dart';
import '../design/tokens.g.dart';
import '../domain/mood.dart';

/// A stand-in for the mood faces until the designer's artwork arrives. The home screen widget
/// renders this widget to a picture, so replacing its inside updates the widget as well.
/// A flat disc in the side color with eyes and a mouth. No gradient, shadow or glow.
class MoodFaceMark extends StatelessWidget {
  const MoodFaceMark({super.key, required this.mood, this.size = 96});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = lightPalette.moodColor(mood);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _FacePainter(mood, color, lightPalette.ground),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter(this.mood, this.disc, this.feature);

  final Mood mood;
  final Color disc;
  final Color feature;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawCircle(size.center(Offset.zero), s / 2, Paint()..color = disc);
    final ink = Paint()
      ..color = feature
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = feature;
    for (final dx in [-0.18, 0.18]) {
      canvas.drawCircle(Offset(s * (0.5 + dx), s * 0.4), s * 0.045, fill);
    }
    final mouth = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.66),
      width: s * 0.36,
      height: s * 0.22,
    );
    switch (mood) {
      case Mood.happy:
        canvas.drawArc(mouth, 0.2, math.pi - 0.4, false, ink);
      case Mood.excited:
        canvas.drawArc(mouth, 0, math.pi, true, fill);
      case Mood.angry:
        canvas.drawLine(
          Offset(s * 0.3, s * 0.3),
          Offset(s * 0.43, s * 0.34),
          ink,
        );
        canvas.drawLine(
          Offset(s * 0.7, s * 0.3),
          Offset(s * 0.57, s * 0.34),
          ink,
        );
        canvas.drawLine(
          Offset(s * 0.36, s * 0.7),
          Offset(s * 0.64, s * 0.7),
          ink,
        );
      case Mood.sad:
        canvas.drawArc(
          mouth.translate(0, s * 0.1),
          math.pi + 0.2,
          math.pi - 0.4,
          false,
          ink,
        );
      case Mood.anxious:
        final path = Path()..moveTo(s * 0.34, s * 0.7);
        for (var i = 1; i <= 4; i++) {
          path.lineTo(s * (0.34 + 0.075 * i), s * (i.isOdd ? 0.66 : 0.7));
        }
        canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.mood != mood || old.disc != disc || old.feature != feature;
}
