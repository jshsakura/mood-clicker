import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/tuning.dart';

/// The hand-feel numbers agreed with the designer. A change here is a deliberate decision.
void main() {
  test(
    'gauge numbers: 60 taps fill it, it holds 1 s, and a full gauge drains in about 15 s',
    () {
      expect(GaugeTuning.stepPerTap, 1 / 60);
      expect(GaugeTuning.grace, const Duration(seconds: 1));
      expect(GaugeTuning.decayPerSecond, 0.07);
      expect(GaugeTuning.displayFollow, const Duration(milliseconds: 420));
      expect(1 / GaugeTuning.decayPerSecond, closeTo(14.3, 0.1));
    },
  );

  test('water spring numbers', () {
    expect(FillTuning.columns, 60);
    expect(FillTuning.spring, 8);
    expect(FillTuning.spread, 1800);
    expect(FillTuning.damping, 1.1);
    expect(FillTuning.kick, 260);
    expect(FillTuning.kickWidthMin, 2.4);
    expect(FillTuning.kickWidthMax, 4.4);
    expect(FillTuning.slosh, 70);
    expect(FillTuning.idleWobble, const Duration(milliseconds: 500));
  });

  test('back wave, droplets and splashes', () {
    expect(FillTuning.backShiftColumns, 3);
    expect(FillTuning.backScale, 0.75);
    expect(FillTuning.backDelay, const Duration(milliseconds: 200));
    expect(FillTuning.backRise, 5);
    expect(FillTuning.dropletReach, 220);
    expect(FillTuning.dropletsMin, 2);
    expect(FillTuning.dropletsMax, 5);
    expect(FillTuning.dropletsWhenComplete, 2);
    expect(FillTuning.dropletsLimit, 40);
    expect(FillTuning.dropletUpMin, 220);
    expect(FillTuning.dropletUpMax, 500);
    expect(FillTuning.dropletSide, 90);
    expect(FillTuning.dropletRadiusMin, 2);
    expect(FillTuning.dropletRadiusMax, 5);
    expect(FillTuning.dropletGravity, 1400);
    expect(FillTuning.splashBase, 30);
    expect(FillTuning.splashPerRadius, 8);
  });

  test('ripples while the level falls', () {
    expect(FillTuning.drainMaxPx, 6);
    expect(FillTuning.drainColumns, 3);
    expect(FillTuning.drainJiggle, 160);
    expect(FillTuning.drainTiltPull, 14);
  });

  test('tilt and spill numbers', () {
    expect(FillTuning.tiltLimitDegrees, 85);
    expect(FillTuning.spillRate, 2);
    expect(FillTuning.largeTextScale, 1.18);
  });

  test('the moment the gauge becomes full', () {
    expect(CompleteTuning.shakeDuration, const Duration(milliseconds: 420));
    expect(CompleteTuning.shakeAmplitude, 9);
    expect(CompleteTuning.waterKickScale, 2.2);
  });

  test('phrase look numbers', () {
    expect(CheerTuning.fontSizeBase, 18);
    expect(CheerTuning.fontSizeSpan, 42);
    expect(CheerTuning.fontSizeExponent, 1.3);
    expect(CheerTuning.fontSizeRareBonus, 6);
    expect(CheerTuning.fontSizeComplete, 76);
    expect(CheerTuning.fontSizeComplete, 76);
    expect(CheerTuning.maxWidthShare, 0.6);
    expect(CheerTuning.sideDeadZone, 60);
    expect(CheerTuning.rareStars, 5);
    expect(CheerTuning.rareRays, 8);
  });
}
