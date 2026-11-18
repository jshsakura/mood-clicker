import 'package:flutter/material.dart';

import 'design/app_theme.dart';
import 'design/theme_choice.dart';
import 'design/token_preview.dart';
import 'l10n/app_localizations.g.dart';
import 'l10n/locale_resolution.dart';

void main() => runApp(const MoodClickerApp());

class MoodClickerApp extends StatefulWidget {
  const MoodClickerApp({super.key});

  @override
  State<MoodClickerApp> createState() => _MoodClickerAppState();
}

class _MoodClickerAppState extends State<MoodClickerApp> {
  ThemeChoice _choice = ThemeChoice.light;

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    final palette = paletteFor(_choice, platform);
    return MaterialApp(
      title: 'Mood Clicker',
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (deviceLocales, supported) =>
          resolveAppLocale(deviceLocales ?? const [], supported),
      home: TokenPreview(
        choice: _choice,
        onChoice: (c) => setState(() => _choice = c),
      ),
    );
  }
}
