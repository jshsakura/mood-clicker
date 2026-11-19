import 'package:flutter/material.dart';

import '../../domain/tuning.dart';
import 'water_sim.dart';
import '../tokens.g.dart';

/// Draws the water of the tap screen: a wave behind (surface color), the front wave (fill color)
/// with a 2 px edge line, and the droplets. Everything is flat: no gradient, no shadow, no glow.
class WaterPainter extends CustomPainter {
  WaterPainter({required this.sim, required this.palette, this.bleed = 0})
    : super(repaint: sim);

  final WaterSim sim;
  final AppPalette palette;

  /// How far the water runs past the left and right edges, flat. A shaking frame never shows
  /// the background there.
  final double bleed;

  @override
  void paint(Canvas canvas, Size size) {
    sim.size = size;
    if (sim.level <= 0 && sim.droplets.isEmpty) return;
    final back = sim.backHeights();
    final front = sim.heights;
    if (sim.level > 0) {
      canvas.drawPath(
        _fillPath(size, back, lift: FillTuning.backRise),
        Paint()..color = palette.surface,
      );
      final top = _topPath(size, front, lift: 0);
      final body = Path.from(top)
        ..lineTo(size.width + bleed, size.height)
        ..lineTo(-bleed, size.height)
        ..close();
      canvas.drawPath(body, Paint()..color = palette.fill);
      canvas.drawPath(
        top,
        Paint()
          ..color = palette.fillEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final dropPaint = Paint()..color = palette.fill;
    final edgePaint = Paint()
      ..color = palette.fillEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = FillTuning.dropletBorder;
    for (final d in sim.droplets) {
      canvas.drawCircle(Offset(d.x, d.y), d.radius, dropPaint);
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.radius - FillTuning.dropletBorder / 2,
        edgePaint,
      );
    }
  }

  Path _fillPath(Size size, List<double> heights, {required double lift}) {
    return _topPath(size, heights, lift: lift)
      ..lineTo(size.width + bleed, size.height)
      ..lineTo(-bleed, size.height)
      ..close();
  }

  /// The surface line through one point per column, smoothed with Catmull-Rom splines.
  Path _topPath(Size size, List<double> heights, {required double lift}) {
    final n = heights.length;
    final points = [
      for (var i = 0; i < n; i++)
        Offset(
          i * size.width / (n - 1),
          sim.restingYAt(i * size.width / (n - 1)) - heights[i] - lift,
        ),
    ];
    final path = Path()
      ..moveTo(points[0].dx - bleed, points[0].dy)
      ..lineTo(points[0].dx, points[0].dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = points[i == 0 ? 0 : i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2 < n ? i + 2 : n - 1];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path..lineTo(points.last.dx + bleed, points.last.dy);
  }

  @override
  bool shouldRepaint(WaterPainter old) =>
      old.sim != sim || old.palette != palette || old.bleed != bleed;
}
