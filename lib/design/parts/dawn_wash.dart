import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Paints the cleanse: the full water drains down and warm dawn light spreads in from the screen
/// edges (yellow on top, mint at the sides, peach at the bottom). [progress] goes from 0 to 1.
class DawnWashPainter extends CustomPainter {
  const DawnWashPainter({
    required this.progress,
    required this.water,
    required this.yellow,
    required this.mint,
    required this.peach,
  });

  /// The strongest the light gets. The theme tokens already hold soft colors, so this only keeps the
  /// light from covering the screen.
  static const double maxAlpha = 0.85;

  /// How far the light reaches in from an edge, as a share of the short side of the screen.
  static const double reachStart = 0.15;
  static const double reachEnd = 0.6;

  final double progress;
  final Color water;
  final Color yellow;
  final Color mint;
  final Color peach;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final drain = Curves.easeInOut.transform(t);
    final waterTop = size.height * drain;
    if (waterTop < size.height) {
      canvas.drawRect(
        Rect.fromLTRB(0, waterTop, size.width, size.height),
        Paint()..color = water,
      );
    }
    final glow = Curves.easeOut.transform(t);
    if (glow <= 0) return;
    final alpha = maxAlpha * glow;
    final reach =
        size.shortestSide * (reachStart + (reachEnd - reachStart) * glow);
    _band(
      canvas,
      Rect.fromLTWH(0, 0, size.width, reach),
      yellow,
      alpha,
      Alignment.topCenter,
      Alignment.bottomCenter,
    );
    _band(
      canvas,
      Rect.fromLTWH(0, size.height - reach, size.width, reach),
      peach,
      alpha,
      Alignment.bottomCenter,
      Alignment.topCenter,
    );
    _band(
      canvas,
      Rect.fromLTWH(0, 0, reach, size.height),
      mint,
      alpha,
      Alignment.centerLeft,
      Alignment.centerRight,
    );
    _band(
      canvas,
      Rect.fromLTWH(size.width - reach, 0, reach, size.height),
      mint,
      alpha,
      Alignment.centerRight,
      Alignment.centerLeft,
    );
  }

  void _band(
    Canvas canvas,
    Rect rect,
    Color color,
    double alpha,
    Alignment from,
    Alignment to,
  ) {
    final colors = [color.withValues(alpha: alpha), color.withValues(alpha: 0)];
    final g = LinearGradient(begin: from, end: to, colors: colors); // slop-ok
    canvas.drawRect(rect, Paint()..shader = g.createShader(rect));
  }

  @override
  bool shouldRepaint(DawnWashPainter old) =>
      old.progress != progress ||
      old.water != water ||
      old.yellow != yellow ||
      old.mint != mint ||
      old.peach != peach;
}

/// The cleanse picture that fills its parent. The colors come from the theme tokens.
class DawnWash extends StatelessWidget {
  const DawnWash({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: CustomPaint(
          painter: DawnWashPainter(
            progress: progress,
            water: p.fill,
            yellow: p.dawnYellow,
            mint: p.dawnMint,
            peach: p.dawnPeach,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
