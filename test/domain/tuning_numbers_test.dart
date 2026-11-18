import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/domain/tuning.dart';

/// The hand-feel numbers agreed with the designer. A change here is a deliberate decision.
void main() {
  test('water spring numbers', () {
    expect(FillTuning.columns, 40);
    expect(FillTuning.spring, 8);
    expect(FillTuning.spread, 900);
    expect(FillTuning.damping, 1.6);
    expect(FillTuning.kick, 260);
    expect(FillTuning.kickWidthMin, 1.6);
    expect(FillTuning.kickWidthMax, 3);
    expect(FillTuning.slosh, 70);
    expect(FillTuning.idleWobble, const Duration(milliseconds: 500));
  });

  test('tilt and spill numbers', () {
    expect(FillTuning.tiltLimitRadians, 0.5);
    expect(FillTuning.spillPerRadianPerSecond, 1.5);
  });

  test('the moment the gauge becomes full', () {
    expect(CompleteTuning.shakeDuration, const Duration(milliseconds: 420));
    expect(CompleteTuning.shakeAmplitude, 9);
    expect(CompleteTuning.stampStartScale, 2.6);
    expect(CompleteTuning.stampLand, const Duration(milliseconds: 160));
    expect(CompleteTuning.stampHold, const Duration(milliseconds: 1900));
    expect(CompleteTuning.stampFade, const Duration(milliseconds: 500));
    expect(CompleteTuning.waterKickScale, 2.2);
  });

  test('phrase look numbers', () {
    expect(CheerTuning.fontSizeBase, 30);
    expect(CheerTuning.fontSizePerFill, 30);
    expect(CheerTuning.fontSizeComplete, 76);
    expect(CheerTuning.maxWidthShare, 0.6);
    expect(CheerTuning.sideDeadZone, 60);
    expect(CheerTuning.rareStars, 5);
    expect(CheerTuning.rareRays, 8);
  });
}
