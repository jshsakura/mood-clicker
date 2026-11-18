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
        child: CustomPaint(painter: _SmallStampPainter(p.ground, p.error)),
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticLabel,
      child: Transform.rotate(
        angle: -12 * math.pi / 180,
        child: Opacity(
          opacity: 0.92,
          child: SizedBox.square(
            dimension: 76,
            child: CustomPaint(
              painter: _WellDoneStampPainter(p.error),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line1,
                      style: TypeScale.label.copyWith(
                        color: p.error,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      line2,
                      style: TypeScale.label.copyWith(
                        color: p.error,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WellDoneStampPainter extends CustomPainter {
  const _WellDoneStampPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 34),
      0.15,
      math.pi * 1.82,
      false,
      outer,
    );
    canvas.drawCircle(center, 28.5, inner);
  }

  @override
  bool shouldRepaint(_WellDoneStampPainter old) => old.color != color;
}
