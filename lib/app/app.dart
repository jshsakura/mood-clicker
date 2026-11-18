import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/theme_choice.dart';
import '../l10n/app_localizations.g.dart';
import '../l10n/locale_resolution.dart';
import '../screens/loading_screen.dart';
import 'app_services.dart';
import 'surface_sync.dart';

/// The app: theme, language, text size and the first screen.
class MoodClickerApp extends StatefulWidget {
  const MoodClickerApp({super.key, required this.services});

  final AppServices services;

  @override
  State<MoodClickerApp> createState() => _MoodClickerAppState();
}

class _MoodClickerAppState extends State<MoodClickerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    return AppScope(
      services: widget.services,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.services.feel,
          widget.services.theme,
          if (widget.services.language != null) widget.services.language!,
        ]),
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Unknown',
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          // Read the choice here, inside the builder, so picking a theme in settings repaints the app.
          theme: buildTheme(paletteFor(widget.services.theme.value, platform)),
          // Like a system dark switch, a theme change is immediate. An animation would blend colors mid-frame and break contrast.
          themeAnimationDuration: Duration.zero,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: widget.services.language?.value.locale,
          localeListResolutionCallback: (deviceLocales, supported) =>
              resolveAppLocale(deviceLocales ?? const [], supported),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: widget.services.feel.value.textScale,
            maxScaleFactor: 3,
            child: SurfaceSync(navigatorKey: _navigatorKey, child: child!),
          ),
          home: const LoadingScreen(),
        ),
      ),
    );
  }
}
