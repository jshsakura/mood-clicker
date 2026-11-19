import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/app_theme.dart';
import '../../design/tokens.g.dart';
import '../../domain/cheer.dart';
import '../../domain/cheer_layout.dart';
import '../../domain/tuning.dart';

/// Draws the phrases of the tap screen, one line each, where the layout put them. A phrase pops
/// in with a small overshoot, floats up, and fades out. A rare one is a black pill with stars and
/// turning rays. The owner repaints this on every frame.
class CheerOverlay extends StatelessWidget {
  const CheerOverlay({super.key, required this.phrases, required this.now});

  final List<CheerSlot> phrases;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final time = now();
    final alive = CheerLayout.alive(phrases, time);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < alive.length; i++)
            _PhraseView(
              slot: alive[i],
              progress: CheerLayout.progress(alive[i], i, alive.length, time),
              age: time.difference(alive[i].shownAt),
            ),
        ],
      ),
    );
  }
}

class _PhraseView extends StatelessWidget {
  const _PhraseView({
    required this.slot,
    required this.progress,
    required this.age,
  });

  final CheerSlot slot;
  final double progress;
  final Duration age;

  /// The width of the rare rays frame and its height, from the design.
  static const Size _raysFrame = Size(260, 160);
  static const double _raysTurnPerMs = 1 / 20;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isRare = slot.kind == CheerKind.rare;
    final text = Text(
      slot.text,
      maxLines: 1,
      softWrap: false,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: TypeScale.title.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: slot.fontSize,
        letterSpacing: -1,
        height: 1.05,
        color: isRare ? p.ground : p.ink,
      ),
    );
    final Widget body = isRare ? _rare(p, text) : text;
    return Positioned(
      left: slot.center.x,
      top: slot.center.y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.translate(
          offset: Offset(0, -CheerLayout.riseAt(progress)),
          child: Transform.rotate(
            angle: slot.rotationDegrees * pi / 180,
            child: Transform.scale(
              scale: CheerLayout.scaleAt(progress),
              child: Opacity(
                opacity: CheerLayout.alphaAt(progress).clamp(0.0, 1.0),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rare(AppPalette p, Widget text) {
    final starSize = slot.fontSize * 0.34;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.rotate(
          angle: age.inMicroseconds / 1000 * _raysTurnPerMs * pi / 180,
          child: CustomPaint(
            size: _raysFrame,
            painter: _RaysPainter(color: p.ink),
          ),
        ),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: p.ink,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: Size(
                    CheerTuning.rareStars * starSize +
                        (CheerTuning.rareStars - 1) * _starGap,
                    starSize,
                  ),
                  painter: _StarsPainter(color: p.ground, gap: _starGap),
                ),
                const SizedBox(height: 2),
                text,
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const double _starGap = 3;
}

/// The eight short lines around a rare phrase, in the 260 by 160 frame of the design.
class _RaysPainter extends CustomPainter {
  const _RaysPainter({required this.color});

  final Color color;

  static const List<(double, double, double, double)> _lines = [
    (218.7, 99.9, 240.9, 106.8),
    (166.7, 128.0, 175.9, 144.7),
    (93.3, 128.0, 84.1, 144.7),
    (41.3, 99.9, 19.1, 106.8),
    (41.3, 60.1, 19.1, 53.2),
    (93.3, 32.0, 84.1, 15.3),
    (166.7, 32.0, 175.9, 15.3),
    (218.7, 60.1, 240.9, 53.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (x1, y1, x2, y2) in _lines) {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

/// Five flat stars in a row, as wide as the star text of the design.
class _StarsPainter extends CustomPainter {
  const _StarsPainter({required this.color, required this.gap});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final d = size.height;
    for (var i = 0; i < CheerTuning.rareStars; i++) {
      final center = Offset(i * (d + gap) + d / 2, d / 2);
      final path = Path();
      for (var k = 0; k < 10; k++) {
        final r = (k.isEven ? d : d * 0.45) / 2;
        final a = -pi / 2 + k * pi / 5;
        final pt = center + Offset(cos(a), sin(a)) * r;
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.color != color;
}
