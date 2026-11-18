import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_table.dart';

void main() {
  test(
    'scaledByFill increases intensity, sharpness, and amplitudes with fill',
    () {
      final base = FeedbackTable.of(FeedbackKind.tap, 'happy').haptic!;
      final low = base.scaledByFill(0.0);
      final mid = base.scaledByFill(0.5);
      final high = base.scaledByFill(1.0);

      expect(low.ios.first.intensity, lessThan(mid.ios.first.intensity));
      expect(mid.ios.first.intensity, lessThan(high.ios.first.intensity));
      expect(low.ios.first.sharpness, lessThan(mid.ios.first.sharpness));
      expect(mid.ios.first.sharpness, lessThan(high.ios.first.sharpness));

      expect(
        low.android.amplitudes.last,
        lessThan(high.android.amplitudes.last),
      );
      expect(
        low.android.primitives.first.scale,
        lessThan(high.android.primitives.first.scale),
      );
    },
  );

  test('scaledByFill clamps out-of-range fill values', () {
    final base = FeedbackTable.of(FeedbackKind.tap, 'angry').haptic!;
    expect(
      base.scaledByFill(-0.5).ios.first.intensity,
      base.scaledByFill(0.0).ios.first.intensity,
    );
    expect(
      base.scaledByFill(2.0).ios.first.intensity,
      base.scaledByFill(1.0).ios.first.intensity,
    );
  });

  test('toChannelMap serializes ios and android sections', () {
    final cue = FeedbackTable.of(FeedbackKind.rare, 'happy').haptic!;
    final map = cue.toChannelMap();
    expect(map['ios'], isA<List<Object>>());
    expect(map['android'], isA<Map<String, Object>>());
  });
}
