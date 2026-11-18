import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/app_theme.dart';
import '../../design/tokens.g.dart';
import '../../domain/cheer.dart';
import '../../domain/cheer_layout.dart';
import '../../domain/tuning.dart';

/// A phrase that is on screen: its text and size next to the layout slot that places it.
class LivePhrase {
  const LivePhrase({
    required this.slot,
    required this.text,
    required this.fontSize,
  });

  final CheerSlot slot;
  final String text;
  final double fontSize;
}

/// Draws the live phrases. Phrases are looked up each frame, so the owner repaints this with its frame notifier.
class CheerOverlay extends StatelessWidget {
  const CheerOverlay({
    super.key,
    required this.phrases,
    required this.now,
    required this.surfaceYAt,
  });

  final List<LivePhrase> phrases;
  final DateTime Function() now;

  /// The water surface at an x, so a phrase over the water gets the color that reads on it.
  final double Function(double x) surfaceYAt;

  @override
  Widget build(BuildContext context) {
    final time = now();
    final alive = CheerLayout.alive([for (final p in phrases) p.slot], time);
    final children = <Widget>[];
    for (var i = 0; i < phrases.length; i++) {
      final phrase = phrases[i];
      if (!alive.contains(phrase.slot)) continue;
      final newer = phrases
          .skip(i + 1)
          .where((q) => alive.contains(q.slot))
          .length;
      children.add(
        _PhraseView(
          phrase: phrase,
          box: CheerLayout.currentBox(phrase.slot, time),
          opacity: _opacity(phrase.slot, newer, time),
          overWater: false,
          surfaceYAt: surfaceYAt,
        ),
      );
    }
    return IgnorePointer(child: Stack(children: children));
  }

  /// Fully visible for most of the life, fading out over the last quarter.
  static double _opacity(CheerSlot slot, int newerCount, DateTime now) {
    final life = CheerLayout.lifetimeFor(newerCount, kind: slot.kind);
    final age = now.difference(slot.shownAt);
    final left = 1 - age.inMicroseconds / life.inMicroseconds;
    return (left / 0.25).clamp(0.0, 1.0);
  }
}

class _PhraseView extends StatelessWidget {
  const _PhraseView({
    required this.phrase,
    required this.box,
    required this.opacity,
    required this.overWater,
    required this.surfaceYAt,
  });

  final LivePhrase phrase;
  final CheerRect box;
  final double opacity;
  final bool overWater;
  final double Function(double x) surfaceYAt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = box.right - box.left;
    final height = box.bottom - box.top;
    final middleY = (box.top + box.bottom) / 2;
    final onWater = middleY > surfaceYAt((box.left + box.right) / 2);
    final isRare = phrase.slot.kind == CheerKind.rare;
    final textColor = isRare ? p.ground : (onWater ? p.onFill : p.ink);
    final text = Text(
      phrase.text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: TypeScale.title.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: phrase.fontSize,
        height: 1,
        color: textColor,
      ),
    );
    return Positioned(
      left: box.left,
      top: box.top,
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: isRare
            ? CustomPaint(
                painter: _RarePillPainter(color: p.ink, rayColor: p.ink),
                child: Center(child: text),
              )
            : Center(child: text),
      ),
    );
  }
}

/// The rare phrase: a solid pill with stars and rays around it. Flat shapes only.
class _RarePillPainter extends CustomPainter {
  const _RarePillPainter({required this.color, required this.rayColor});

  final Color color;
  final Color rayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pill = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final center = size.center(Offset.zero);
    final rays = Paint()
      ..color = rayColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < CheerTuning.rareRays; i++) {
      final angle = i * 2 * pi / CheerTuning.rareRays;
      final direction = Offset(cos(angle), sin(angle));
      // Start outside the pill edge along this direction, and run a short way further out.
      final reach = _edgeDistance(size, direction);
      canvas.drawLine(
        center + direction * (reach + 6),
        center + direction * (reach + 16),
        rays,
      );
    }
    canvas.drawRRect(pill, Paint()..color = color);
    final starPaint = Paint()..color = rayColor;
    for (var i = 0; i < CheerTuning.rareStars; i++) {
      final angle = -pi / 2 + (i - (CheerTuning.rareStars - 1) / 2) * 0.5;
      final spot =
          center + Offset(cos(angle), sin(angle)) * (size.width / 2 + 14);
      canvas.drawPath(_star(spot, 6), starPaint);
    }
  }

  /// How far from the center the pill edge is along [direction] (an ellipse stand-in).
  static double _edgeDistance(Size size, Offset direction) {
    final a = size.width / 2;
    final b = size.height / 2;
    return (a * b) / sqrt(pow(b * direction.dx, 2) + pow(a * direction.dy, 2));
  }

  static Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -pi / 2 + i * pi / 5;
      final point = c + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_RarePillPainter old) =>
      old.color != color || old.rayColor != rayColor;
}
