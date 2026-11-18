@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'shots_comparator.dart';

/// Renders each screen per theme x device and compares with the committed goldens (images/).
///
/// The goldens come from linux docker, so pixels differ on a Mac. Compare only with tool/shots.sh or in CI.
/// tool/shots.sh sets SHOTS_OUT, so it only writes pictures to build/shots/ instead of comparing.
void main() {
  setUpAll(() async {
    final missing = await loadGoldenFonts();
    if (missing.isNotEmpty) {
      fail(
        'Fonts missing from the Flutter SDK: $missing. Goldens only match with tool/shots.sh or the CI docker image.',
      );
    }
    final out = const String.fromEnvironment('SHOTS_OUT');
    if (out.isNotEmpty) useShotsOutput(Directory(out));
  });

  for (final screen in goldenScreens) {
    for (final choice in goldenThemes) {
      for (final device in goldenDevices) {
        final name = '${screen.name}_${choice.name}_${device.name}';
        testWidgets(name, (tester) async {
          await pumpOnDevice(
            tester,
            device,
            choice,
            screen.build(choice),
            settle: screen.act == null,
          );
          await screen.act?.call(tester);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('images/$name.png'),
          );
        });
      }
    }
  }
}
