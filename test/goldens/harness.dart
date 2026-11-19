import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/token_preview.dart';
import 'package:mood_clicker/design/tokens.g.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';

import '../screens/fake_app.dart';
import 'release_part_shots.dart';
import 'screen_shots.dart';

/// The fonts the tests really load. They must match fonts in pubspec.yaml; a test reports a mismatch.
const goldenFonts = <String, List<String>>{
  'Pretendard': [
    'assets/fonts/Pretendard-Regular.otf',
    'assets/fonts/Pretendard-Bold.otf',
  ],
  'Baloo2': ['assets/fonts/Baloo2-ExtraBold.ttf'],
};

/// The emoji font name, set as a font fallback.
const emojiFamily = 'NotoColorEmoji';

/// Icons and emoji use fonts that ship with the Flutter SDK. They are not kept in the repository.
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

/// Loads the app's real fonts and the SDK icon and emoji fonts instead of the default Ahem (squares only).
/// Returns the names of SDK fonts that were not found. The golden test fails if any is missing.
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

/// A device frame to render in. Sizes are logical pixels.
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

  /// The status bar and home bar space, which SafeArea keeps clear.
  final double topInset;
  final double bottomInset;
}

const goldenDevices = [
  GoldenDevice('iphone', Size(390, 844), 3, topInset: 47, bottomInset: 34),
  GoldenDevice('android', Size(412, 915), 2.625, topInset: 24, bottomInset: 16),
];

/// A theme to render in.
final goldenThemes = [for (final p in allPalettes) ThemeChoice.named(p.name)];

/// One screen. Its name becomes the file name.
class GoldenScreen {
  const GoldenScreen(this.name, this.build, {this.act, this.deviceNames});

  final String name;
  final Widget Function(ThemeChoice choice) build;

  /// The devices to shoot on. Null means all of them.
  final Set<String>? deviceNames;

  /// For a screen that never settles (the tap screen has a running ticker): it drives the screen
  /// to the state to shoot. The screen is then not pumped until it settles.
  final Future<void> Function(WidgetTester tester)? act;
}

/// The screens to render. Add one line when a screen is added.
final goldenScreens = <GoldenScreen>[
  ...releasePartShots,
  GoldenScreen(
    'token_preview',
    (choice) => TokenPreview(choice: choice, onChoice: (_) {}),
  ),
  for (final shot in shotScreens)
    GoldenScreen(
      shot.name,
      (choice) {
        final app = shotApp(holdLoading: shot.name == 'loading');
        _shotApps[shot.name] = app;
        return scoped(app, shot.build(app));
      },
      act: shot.act == null
          ? null
          : (tester) => shot.act!(tester, _shotApps[shot.name]!),
    ),
];

/// The fake app behind each screen shot, so the act step can move its clock.
final _shotApps = <String, TestApp>{};

/// Sets the device size and safe area, then pumps the screen.
Future<void> pumpOnDevice(
  WidgetTester tester,
  GoldenDevice device,
  ThemeChoice choice,
  Widget screen, {
  bool settle = true,
}) async {
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

  // Emoji only draw when set as a font fallback. Material overrides the text style with the theme, so set it on the theme.
  final base = buildTheme(paletteFor(choice, Brightness.light));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(fontFamilyFallback: [emojiFamily]),
      ),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
