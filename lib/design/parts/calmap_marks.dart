import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../app_theme.dart';
import '../tokens.g.dart';

/// Tiny 16 px circular stamp badge shown in the top-right of stamped calendar cells.
class SmallStampBadge extends StatelessWidget {
  const SmallStampBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Transform.rotate(
      angle: -14 * math.pi / 180,
      child: SizedBox.square(
        dimension: 16,
        child: CustomPaint(painter: _SmallStampPainter(p.ground, p.stamp)),
      ),
    );
  }
}

class _SmallStampPainter extends CustomPainter {
  const _SmallStampPainter(this.bg, this.ink);

  final Color bg;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 6.6, Paint()..color = bg);
    final outer = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final inner = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, 6.6, outer);
    canvas.drawCircle(center, 4.4, inner);
    final check = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(5.6, 8.2)
      ..lineTo(7.2, 9.7)
      ..lineTo(10.4, 6.4);
    canvas.drawPath(path, check);
  }

  @override
  bool shouldRepaint(_SmallStampPainter old) => old.bg != bg || old.ink != ink;
}

/// 76 px rotated "Well done" stamp shown on the selected day card when full.
class WellDoneStamp extends StatelessWidget {
  const WellDoneStamp({
    super.key,
    required this.line1,
    required this.line2,
    required this.semanticLabel,
  });

  final String line1;
  final String line2;
  final String semanticLabel;

  static const double size = 76;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: -12 * math.pi / 180,
          child: Opacity(
            opacity: 0.92,
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _WellDoneStampPainter(p.stamp, line1, line2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WellDoneStampPainter extends CustomPainter {
  const _WellDoneStampPainter(this.color, this.line1, this.line2);

  final Color color;
  final String line1;
  final String line2;

  // The ring is a circle of radius 34 drawn as a long dash, a short gap and a short dash that
  // ends where the circle closes (dash array 180 4 40 3 of the sketch).
  static const double _ringRadius = 34;
  static const double _longDash = 180;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final ring = Rect.fromCircle(center: center, radius: _ringRadius);
    final circumference = 2 * math.pi * _ringRadius;
    canvas.drawArc(ring, 0, _longDash / _ringRadius, false, outer);
    final secondStart = (_longDash + _gap) / _ringRadius;
    canvas.drawArc(
      ring,
      secondStart,
      circumference / _ringRadius - secondStart,
      false,
      outer,
    );
    canvas.drawCircle(center, 28.5, inner);
    _line(canvas, line1, center.dx, 35, 2);
    _line(canvas, line2, center.dx, 52, 0.5);
  }

  /// Draws [text] centered on [x] with its baseline at [baseline].
  void _line(
    Canvas canvas,
    String text,
    double x,
    double baseline,
    double spacing,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TypeScale.label.copyWith(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: spacing,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top =
        baseline -
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(canvas, Offset(x - painter.width / 2, top));
  }

  @override
  bool shouldRepaint(_WellDoneStampPainter old) =>
      old.color != color || old.line1 != line1 || old.line2 != line2;
}
