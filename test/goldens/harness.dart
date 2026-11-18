import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/token_preview.dart';

/// 테스트에서 실제로 불러올 글꼴. pubspec.yaml 의 fonts 와 같아야 하고, 어긋나면 테스트가 알려 준다.
const goldenFonts = <String, List<String>>{
  'Pretendard': [
    'assets/fonts/Pretendard-Regular.otf',
    'assets/fonts/Pretendard-Bold.otf',
  ],
  'Baloo2': ['assets/fonts/Baloo2-ExtraBold.ttf'],
};

/// 이모지 글꼴 이름. 글꼴 대체 목록으로 걸어 준다.
const emojiFamily = 'NotoColorEmoji';

/// 아이콘과 이모지는 Flutter SDK 가 들고 있는 글꼴을 쓴다. 저장소에는 넣지 않는다.
const _sdkFonts = <String, String>{
  'MaterialIcons':
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  emojiFamily: 'engine/src/flutter/txt/third_party/fonts/NotoColorEmoji.ttf',
};

String? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory(env).existsSync()) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (Directory('${dir.path}/bin/cache').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return null;
}

Future<void> _load(String family, List<File> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// 기본 글꼴(네모만 나오는 Ahem) 대신 앱의 진짜 글꼴과 SDK 의 아이콘, 이모지 글꼴을 불러온다.
/// 찾지 못한 SDK 글꼴의 이름을 돌려준다. 골든 테스트는 하나라도 빠지면 실패시킨다.
Future<List<String>> loadGoldenFonts() async {
  for (final entry in goldenFonts.entries) {
    await _load(entry.key, [for (final path in entry.value) File(path)]);
  }
  final root = _flutterRoot();
  final missing = <String>[];
  for (final entry in _sdkFonts.entries) {
    final file = root == null ? null : File('$root/${entry.value}');
    if (file != null && file.existsSync()) {
      await _load(entry.key, [file]);
    } else {
      missing.add(entry.key);
    }
  }
  return missing;
}

/// 그림을 뽑을 기기 틀. 크기는 논리 픽셀이다.
class GoldenDevice {
  const GoldenDevice(
    this.name,
    this.size,
    this.pixelRatio, {
    required this.topInset,
    required this.bottomInset,
  });

  final String name;
  final Size size;
  final double pixelRatio;

  /// 상태 표시줄과 홈 막대 자리. SafeArea 가 비켜 가는 만큼이다.
  final double topInset;
  final double bottomInset;
}

const goldenDevices = [
  GoldenDevice('iphone', Size(390, 844), 3, topInset: 47, bottomInset: 34),
  GoldenDevice('android', Size(412, 915), 2.625, topInset: 24, bottomInset: 16),
];

/// 그림을 뽑을 테마.
const goldenThemes = [ThemeChoice.light, ThemeChoice.dark, ThemeChoice.pink];

/// 화면 하나. 이름은 파일 이름이 된다.
class GoldenScreen {
  const GoldenScreen(this.name, this.build);

  final String name;
  final Widget Function(ThemeChoice choice) build;
}

/// 그림을 뽑을 화면 목록. 화면이 생기면 한 줄을 더한다.
final goldenScreens = <GoldenScreen>[
  GoldenScreen(
    'token_preview',
    (choice) => TokenPreview(choice: choice, onChoice: (_) {}),
  ),
];

/// 기기 크기와 안전 영역을 맞추고 화면을 올린다.
Future<void> pumpOnDevice(
  WidgetTester tester,
  GoldenDevice device,
  ThemeChoice choice,
  Widget screen,
) async {
  final view = tester.view;
  view.devicePixelRatio = device.pixelRatio;
  view.physicalSize = device.size * device.pixelRatio;
  final padding = FakeViewPadding(
    top: device.topInset * device.pixelRatio,
    bottom: device.bottomInset * device.pixelRatio,
  );
  view.padding = padding;
  view.viewPadding = padding;
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
    view.resetViewPadding();
  });

  // 이모지는 글꼴 대체 목록에 걸어야 그려진다. Material 이 글자 스타일을 테마로 덮으므로 테마에 건다.
  final base = buildTheme(paletteFor(choice, Brightness.light));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(fontFamilyFallback: [emojiFamily]),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}
