import 'package:flutter/foundation.dart';

import '../design/theme_choice.dart';
import '../domain/feel_settings.dart';
import '../feedback/feedback_controller.dart';
import '../l10n/locale_choice.dart';
import '../settings/settings.dart';
import '../settings/settings_store.dart';

/// The stored settings put to work: the notifiers the app listens to and the feedback controller,
/// all filled from the store when the app starts and updated when the settings screen saves.
class SettingsHub {
  SettingsHub._(this.feedback, Settings settings)
    : feel = ValueNotifier(settings.feelSettings),
      theme = ValueNotifier(settings.themeChoice),
      language = ValueNotifier(settings.language),
      mapView = ValueNotifier(settings.mapView),
      mapContribute = ValueNotifier(settings.mapContribute),
      weatherView = ValueNotifier(settings.weatherView);

  final FeedbackController feedback;
  final ValueNotifier<FeelSettings> feel;
  final ValueNotifier<ThemeChoice> theme;
  final ValueNotifier<LocaleChoice> language;
  final ValueNotifier<bool> mapView;

  /// Whether today's counts go to the shared map. The map sharer listens to it.
  final ValueNotifier<bool> mapContribute;
  final ValueNotifier<bool> weatherView;

  /// Reads the store and starts every consumer from what it holds.
  static Future<SettingsHub> open({
    required SettingsStore store,
    required FeedbackController feedback,
  }) async {
    final settings = await store.read();
    final hub = SettingsHub._(feedback, settings);
    hub.apply(settings);
    return hub;
  }

  /// Puts a settings value to every consumer. The settings screen calls it after each save.
  void apply(Settings settings) {
    feel.value = settings.feelSettings;
    theme.value = settings.themeChoice;
    language.value = settings.language;
    mapView.value = settings.mapView;
    mapContribute.value = settings.mapContribute;
    weatherView.value = settings.weatherView;
    feedback.settings = settings.feedbackSettings;
  }
}
