import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../design/theme_choice.dart';
import '../domain/cheer.dart';
import '../domain/cheer_picker.dart';
import '../domain/feel_settings.dart';
import '../domain/mood.dart';
import '../feedback/feedback_controller.dart';
import '../surfaces/native_surfaces.dart';
import 'journal_store.dart';

/// Reads the phone tilt as an angle in radians. 0 is upright, positive leans the right edge down.
typedef TiltStream = Stream<double> Function();

/// Everything a screen needs from outside, in one place. Tests build one with fakes.
class AppServices {
  AppServices({
    required this.journal,
    required this.feedback,
    required this.loadCheers,
    required this.cheerPicker,
    required this.deckStore,
    required this.feel,
    required this.tilt,
    required this.theme,
    this.settingsBuilder,
    this.surfaces,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final JournalStore journal;
  final FeedbackController feedback;

  /// Loads the cheer phrases for a language code. Called once per language.
  final Future<CheerBook> Function(String languageCode) loadCheers;
  final CheerPicker cheerPicker;
  final CheerDeckStore deckStore;

  /// The hand-feel settings. The settings screen changes them.
  final ValueListenable<FeelSettings> feel;
  final TiltStream tilt;

  /// The theme the user picked. The settings screen changes it.
  final ValueNotifier<ThemeChoice> theme;

  /// The settings screen, built by whoever owns settings. Null hides the settings button.
  final WidgetBuilder? settingsBuilder;
  final DateTime Function() now;

  /// The home widget and icon shortcuts. Null in tests that do not need them.
  final NativeSurfaces? surfaces;

  /// A mood a widget or shortcut asked for before the journal was loaded. The loading screen opens
  /// its tap screen once it is done.
  final ValueNotifier<Mood?> launchMood = ValueNotifier<Mood?>(null);
}

/// Gives [AppServices] to the screens below.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'no AppScope above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
