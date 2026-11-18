@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'shots_comparator.dart';

/// 화면마다 테마 x 기기로 그림을 뽑아 커밋된 골든(images/)과 비교한다.
///
/// 골든은 리눅스 도커에서 뽑은 것이라 맥과 픽셀이 다르다. 비교는 tool/shots.sh 나 CI 에서만 한다.
/// tool/shots.sh 는 SHOTS_OUT 을 줘서 비교 대신 build/shots/ 에 그림만 낸다.
void main() {
  setUpAll(() async {
    final missing = await loadGoldenFonts();
    if (missing.isNotEmpty) {
      fail(
        'Flutter SDK 에서 글꼴을 찾지 못했습니다: $missing. 골든은 tool/shots.sh 나 CI 의 도커 이미지에서만 맞습니다.',
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
          await pumpOnDevice(tester, device, choice, screen.build(choice));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('images/$name.png'),
          );
        });
      }
    }
  }
}
