import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'design/theme_choice.dart';
import 'design/token_preview.dart';

void main() => runApp(const MoodClickerApp());

class MoodClickerApp extends StatefulWidget {
  const MoodClickerApp({super.key});

  @override
  State<MoodClickerApp> createState() => _MoodClickerAppState();
}

class _MoodClickerAppState extends State<MoodClickerApp> {
  ThemeChoice _choice = const ThemeChoice.named('light');

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final palette = paletteFor(_choice, platform);
    return MaterialApp(
      title: 'Mood Clicker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      // 시스템 다크 전환처럼 테마는 즉시 바뀐다. 애니메이션이 있으면 중간 프레임의 색이 섞여 대비가 깨진다.
      themeAnimationDuration: Duration.zero,
      home: TokenPreview(
        choice: _choice,
        onChoice: (c) => setState(() => _choice = c),
      ),
    );
  }
}
