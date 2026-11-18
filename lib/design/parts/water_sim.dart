import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'dart:ui' show Size;

import '../../domain/tuning.dart';

/// A droplet thrown off the surface. Positions are in screen pixels, y grows downward.
class Droplet {
  Droplet(this.x, this.y, this.vx, this.vy, this.radius);

  double x;
  double y;
  double vx;
  double vy;
  final double radius;
}

/// The water surface of the tap screen: a row of springs that pull to rest and pull on their
/// neighbors. It is state that changes every frame, so it is a plain mutable object that tells
/// its listeners (the painter) after each step. All numbers live in [FillTuning].
///
/// Height is in pixels, positive up from the resting surface; velocity is pixels per second.
class WaterSim extends ChangeNotifier {
  WaterSim({Random? random}) : _random = random ?? Random();

  static const int columns = FillTuning.columns;

  /// Inner steps are at most this long so the springs stay stable at any frame time.
  static const double _subStep = 1 / 240;

  final Random _random;
  final List<double> heights = List<double>.filled(columns, 0);
  final List<double> _velocity = List<double>.filled(columns, 0);
  final List<Droplet> droplets = [];
  final Queue<({double time, List<double> heights})> _history = Queue();

  /// The width and height of the drawing area in pixels.
  Size size = Size.zero;

  /// The level being shown, 0 to 1. It follows the real level smoothly.
  double level = 0;

  /// The tilt of the surface in radians. Positive leans the right edge down.
  double tiltRadians = 0;

  double _clock = 0;
  double _idleMs = 0;

  /// The resting height of the surface at [x], tilt included, without waves. y grows downward.
  double restingYAt(double x) =>
      size.height * (1 - level) + (x - size.width / 2) * tan(tiltRadians);

  double _heightAt(double x) {
    if (size.width <= 0) return 0;
    final position = (x / size.width * (columns - 1)).clamp(0.0, columns - 1.0);
    final low = position.floor();
    final high = min(low + 1, columns - 1);
    final share = position - low;
    return heights[low] * (1 - share) + heights[high] * share;
  }

  /// Where the surface is at [x] in screen pixels, waves and tilt included.
  double surfaceYAt(double x) => restingYAt(x) - _heightAt(x);

  /// Pushes the columns around [x] with a gaussian bump of random width.
  /// A positive [strength] raises the water, a negative one presses it down.
  void kick(double x, double strength) {
    if (size.width <= 0) return;
    final center = x / size.width * (columns - 1);
    final width =
        FillTuning.kickWidthMin +
        _random.nextDouble() *
            (FillTuning.kickWidthMax - FillTuning.kickWidthMin);
    for (var i = 0; i < columns; i++) {
      final d = i - center;
      _velocity[i] += strength * exp(-(d * d) / (2 * width * width));
    }
  }

  /// A tap that lands on the water at [x]: it pushes the water up where it hits, and sloshes the
  /// whole surface toward the other side. [scale] makes a harder hit (the moment of a full gauge).
  void hit(double x, {required bool insideWater, double scale = 1}) {
    kick(x, (insideWater ? 1 : -1) * FillTuning.kick * scale);
    final side = size.width <= 0 ? 0.0 : (x / size.width - 0.5) * 2;
    _lean(-side * FillTuning.slosh * scale);
  }

  /// A linear push across the row: negative columns on the left get -amount, the right get +amount.
  void _lean(double amount) {
    for (var i = 0; i < columns; i++) {
      _velocity[i] += amount * (i / (columns - 1) * 2 - 1);
    }
  }

  /// Water that is running out ripples. [lostPixels] is how far the level dropped this frame.
  void ripple(double lostPixels) {
    if (lostPixels <= 0) return;
    final lost = min(lostPixels, FillTuning.drainMaxPx);
    for (var n = 0; n < FillTuning.drainColumns; n++) {
      final column = _random.nextInt(columns);
      _velocity[column] +=
          (_random.nextDouble() - 0.5) * lost * FillTuning.drainJiggle;
    }
    if (tiltRadians != 0) {
      // The surface leans to the low side: the low edge goes up.
      _lean(tiltRadians.sign * lost * FillTuning.drainTiltPull);
    }
  }

  /// Throws droplets up from the point [x], [y] on the surface.
  void throwDroplets(double x, double y, int count) {
    for (
      var i = 0;
      i < count && droplets.length < FillTuning.dropletsLimit;
      i++
    ) {
      droplets.add(
        Droplet(
          x,
          y,
          (_random.nextDouble() * 2 - 1) * FillTuning.dropletSide,
          -(FillTuning.dropletUpMin +
              _random.nextDouble() *
                  (FillTuning.dropletUpMax - FillTuning.dropletUpMin)),
          FillTuning.dropletRadiusMin +
              _random.nextDouble() *
                  (FillTuning.dropletRadiusMax - FillTuning.dropletRadiusMin),
        ),
      );
    }
  }

  /// How many droplets a tap throws: 2 to 5, twice that at the moment the gauge fills.
  int dropletCount({required bool complete}) {
    final base =
        FillTuning.dropletsMin +
        _random.nextInt(FillTuning.dropletsMax - FillTuning.dropletsMin + 1);
    return complete ? base * FillTuning.dropletsWhenComplete : base;
  }

  /// Moves everything on by [seconds].
  void step(double seconds) {
    if (seconds <= 0) return;
    final steps = max(1, (seconds / _subStep).ceil());
    final dt = seconds / steps;
    for (var s = 0; s < steps; s++) {
      _springs(dt);
      _moveDroplets(dt);
    }
    _wobbleWhenIdle(seconds);
    _clock += seconds;
    _history.addLast((time: _clock, heights: List<double>.of(heights)));
    final keepFrom = _clock - FillTuning.backDelay.inMilliseconds / 1000 - 0.25;
    while (_history.length > 2 && _history.first.time < keepFrom) {
      _history.removeFirst();
    }
    notifyListeners();
  }

  void _springs(double dt) {
    final accel = List<double>.filled(columns, 0);
    for (var i = 0; i < columns; i++) {
      final left = heights[i == 0 ? 0 : i - 1];
      final right = heights[i == columns - 1 ? i : i + 1];
      final pull = (left - heights[i]) + (right - heights[i]);
      accel[i] =
          -FillTuning.spring * heights[i] -
          FillTuning.damping * _velocity[i] +
          FillTuning.spread * pull;
    }
    for (var i = 0; i < columns; i++) {
      _velocity[i] += accel[i] * dt;
      heights[i] += _velocity[i] * dt;
    }
  }

  void _moveDroplets(double dt) {
    droplets.removeWhere((d) {
      d.vy += FillTuning.dropletGravity * dt;
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      if (d.x < 0 || d.x > size.width || d.y > size.height) return true;
      if (d.vy > 0 && d.y >= surfaceYAt(d.x)) {
        final column = (d.x / size.width * (columns - 1)).round().clamp(
          0,
          columns - 1,
        );
        _velocity[column] -=
            FillTuning.splashBase + d.radius * FillTuning.splashPerRadius;
        return true;
      }
      return false;
    });
  }

  void _wobbleWhenIdle(double seconds) {
    _idleMs += seconds * 1000;
    if (_idleMs < FillTuning.idleWobble.inMilliseconds) return;
    _idleMs = 0;
    if (size.width <= 0) return;
    kick(
      _random.nextDouble() * size.width,
      (_random.nextDouble() - 0.5) * FillTuning.kick * 0.1,
    );
  }

  /// The wave behind the front one: the front wave of [FillTuning.backDelay] ago, shifted by
  /// [FillTuning.backShiftColumns] columns and scaled by [FillTuning.backScale].
  List<double> backHeights() {
    final wanted = _clock - FillTuning.backDelay.inMilliseconds / 1000;
    List<double>? source;
    for (final entry in _history) {
      if (entry.time <= wanted) {
        source = entry.heights;
      } else {
        break;
      }
    }
    final from = source ?? List<double>.filled(columns, 0);
    return [
      for (var i = 0; i < columns; i++)
        from[(i - FillTuning.backShiftColumns).clamp(0, columns - 1)] *
            FillTuning.backScale,
    ];
  }
}
