import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/feedback/feedback_settings.dart';
import 'package:mood_clicker/feedback/ports.dart';
import 'package:mood_clicker/feedback/sound_bank.dart';

void main() {
  const cue = SoundCue(SoundPack.basic, 'tap_happy');
  const other = SoundCue(SoundPack.basic, 'tap_sad');
  late List<String> logs;
  late List<String> asked;

  setUp(() {
    logs = [];
    asked = [];
  });

  test('loads the ogg file first and keeps the loaded source', () async {
    final bank = SoundBank<String>(
      load: (path) async {
        asked.add(path);
        return 'src:$path';
      },
      log: logs.add,
    );
    await bank.preload([cue]);
    expect(asked, ['assets/sounds/basic/tap_happy.ogg']);
    expect(bank.sourceFor(cue), 'src:assets/sounds/basic/tap_happy.ogg');
    expect(logs, isEmpty);
  });

  test('falls back to wav when there is no ogg', () async {
    final bank = SoundBank<String>(
      load: (path) async {
        asked.add(path);
        if (path.endsWith('.ogg')) throw FlutterError('no asset');
        return path;
      },
      log: logs.add,
    );
    await bank.preload([cue]);
    expect(bank.sourceFor(cue), 'assets/sounds/basic/tap_happy.wav');
    expect(logs, isEmpty);
  });

  test('a missing file is skipped quietly and gives no source', () async {
    final bank = SoundBank<String>(
      load: (_) async => throw FlutterError('no asset'),
      log: logs.add,
    );
    await bank.preload([cue, other]);
    expect(bank.sourceFor(cue), isNull);
    expect(bank.sourceFor(other), isNull);
    expect(bank.missingCount, 2);
  });

  test('logs once no matter how many files or calls are missing', () async {
    final bank = SoundBank<String>(
      load: (_) async => throw FlutterError('no asset'),
      log: logs.add,
    );
    await bank.preload([cue, other]);
    await bank.preload([cue, other]);
    bank.sourceFor(cue);
    expect(logs, hasLength(1));
  });

  test('loads the files that exist even when others are missing', () async {
    final bank = SoundBank<String>(
      load: (path) async {
        if (path.contains('tap_sad')) throw FlutterError('no asset');
        return path;
      },
      log: logs.add,
    );
    await bank.preload([cue, other]);
    expect(bank.sourceFor(cue), isNotNull);
    expect(bank.sourceFor(other), isNull);
    expect(bank.missingCount, 1);
  });

  test('an unrelated cue that was never preloaded gives no source', () {
    final bank = SoundBank<String>(load: (_) async => 'x', log: logs.add);
    expect(bank.sourceFor(cue), isNull);
    expect(logs, isEmpty);
  });
}
