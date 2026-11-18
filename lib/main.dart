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
  ThemeChoice _choice = ThemeChoice.system;

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final palette = paletteFor(_choice, platform);
    return MaterialApp(
      title: 'Mood Clicker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      home: TokenPreview(
        choice: _choice,
        onChoice: (c) => setState(() => _choice = c),
      ),
    );
  }
}
