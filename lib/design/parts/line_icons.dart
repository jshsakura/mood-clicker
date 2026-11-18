import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The back chevron of the approved canvas: a 22 px line icon, 2 px stroke, round ends, drawn on
/// the 24 unit grid of the design. Colored with the palette ink.
class ChevronLeftIcon extends StatelessWidget {
  const ChevronLeftIcon({super.key});

  static const double size = 22;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(size),
    painter: _ChevronPainter(context.palette.ink),
  );
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  static const double _grid = 24;
  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _grid;
    final path = Path()
      ..moveTo(15 * k, 5 * k)
      ..lineTo(8 * k, 12 * k)
      ..lineTo(15 * k, 19 * k);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
