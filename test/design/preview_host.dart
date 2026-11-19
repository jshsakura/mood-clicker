import 'package:flutter/material.dart';
import 'package:mood_clicker/design/app_theme.dart';
import 'package:mood_clicker/design/theme_choice.dart';
import 'package:mood_clicker/design/token_preview.dart';
import 'package:mood_clicker/l10n/app_localizations.g.dart';
import 'package:mood_clicker/l10n/locale_resolution.dart';

/// The token preview in its own small app, with the theme switching the real app used to do
/// before the screens replaced the preview. The preview is a dev page now (a goldens target).
class PreviewHost extends StatefulWidget {
  const PreviewHost({super.key});

  @override
  State<PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends State<PreviewHost> {
  ThemeChoice _choice = const ThemeChoice.named('light');

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(
      _choice,
      MediaQuery.platformBrightnessOf(context),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      themeAnimationDuration: Duration.zero,
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
