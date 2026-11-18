import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/feedback/feedback_kind.dart';
import 'package:mood_clicker/feedback/feedback_table.dart';
import 'package:mood_clicker/feedback/platform_haptics.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('mood_clicker/haptics_test');
  final cue = FeedbackTable.of(FeedbackKind.tap, 'happy').haptic!;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('uses native channel when it returns true', () async {
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          called = call.method == 'play';
          return true;
        });
    final fallback = FakeHaptics();
    final haptics = PlatformHaptics(channel: channel, fallback: fallback);

    await haptics.play(cue);
    expect(called, isTrue);
    expect(fallback.played, isEmpty);
  });

  test('falls back when channel returns false or is missing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    final fallback = FakeHaptics();
    final haptics = PlatformHaptics(channel: channel, fallback: fallback);

    await haptics.play(cue);
    expect(fallback.played, [cue]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await haptics.play(cue);
    expect(fallback.played, [cue, cue]);
  });

  test('forwards cancel to fallback', () {
    final fallback = FakeHaptics();
    final haptics = PlatformHaptics(channel: channel, fallback: fallback);
    haptics.cancel();
    expect(fallback.cancelCount, 1);
  });
}
