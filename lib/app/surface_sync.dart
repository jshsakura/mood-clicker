import 'package:flutter/material.dart';

import '../domain/day_key.dart';
import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';
import '../screens/tap/tap_screen.dart';
import 'app_services.dart';

/// Keeps the home widget and the icon shortcuts in step with the app:
/// the widget follows the record of today, the shortcuts follow the language and the last 14 days,
/// and a widget tap or shortcut opens the tap screen of that mood.
///
/// It sits inside the app's [MaterialApp.builder], so it can read the translations.
class SurfaceSync extends StatefulWidget {
  const SurfaceSync({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<SurfaceSync> createState() => _SurfaceSyncState();
}

class _SurfaceSyncState extends State<SurfaceSync> {
  late AppServices _services;
  Locale? _registeredFor;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _services = AppScope.of(context);
      _services.journal.addListener(_publish);
      _services.surfaces?.onLaunchMood = _open;
      _services.surfaces?.start();
    }
    _registerShortcuts();
  }

  @override
  void dispose() {
    _services.journal.removeListener(_publish);
    super.dispose();
  }

  void _publish() {
    final surfaces = _services.surfaces;
    if (surfaces == null || !_services.journal.isLoaded) return;
    final today = _services.journal.journal.dayOf(DayKey.of(_services.now()));
    surfaces.publishToday(today).catchError((Object error) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, library: 'surface sync'),
      );
    });
    // The picks of the last 14 days changed with the taps, so the menu follows.
    _registerShortcuts(force: true);
  }

  /// Registers when the language changed, when the journal was loaded or the taps changed.
  void _registerShortcuts({bool force = false}) {
    final surfaces = _services.surfaces;
    if (surfaces == null || !_services.journal.isLoaded) return;
    final locale = Localizations.localeOf(context);
    if (!force && _registeredFor == locale) return;
    _registeredFor = locale;
    surfaces
        .registerShortcuts(
          AppLocalizations.of(context),
          _services.journal.journal,
          _services.now(),
        )
        .catchError((Object error) {
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, library: 'surface sync'),
          );
        });
  }

  void _open(Mood mood) {
    if (!_services.journal.isLoaded) {
      _services.launchMood.value = mood;
      return;
    }
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    // Start from the mood picker so back goes there, not to another tap screen. The routes are
    // removed, not popped: a tap screen asks to be left by its own back button.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => TapScreen(mood: mood)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
