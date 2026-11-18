/// Every value the settings screen edits, in one place.
///
/// The screen writes through [SettingsStore]; the reminder slice is owned by
/// the reminder controller so the permission flow stays in one place, but
/// the storage behind both is the same store.
library;

import 'package:flutter/foundation.dart';

import '../design/theme_choice.dart';
import '../domain/feel_settings.dart';
import '../feedback/feedback_settings.dart';
import '../l10n/locale_choice.dart';
import '../reminder/reminder_settings.dart';

/// Vibration strength. Devices without amplitude control ignore it.
enum HapticStrength { weak, normal, strong }

/// Cheer phrase text size on the tap screen.
enum CheerSize { normal, large }

@immutable
class Settings {
  const Settings({
    // A palette name from design/tokens, or ThemeChoice.system.name.
    this.theme = 'light',
    this.language = LocaleChoice.system,
    this.hapticsOn = true,
    this.hapticStrength = HapticStrength.normal,
    this.soundOn = true,
    this.soundPack = SoundPack.basic,
    this.cheersOn = true,
    this.cheerSize = CheerSize.normal,
    this.shakeOnFull = true,
    this.tiltToPour = true,
    this.reminder = const ReminderSettings(),
    this.mapView = mapViewDefault,
    this.mapContribute = false,
    this.mapComment = false,
  });

  /// Whether the map entry shows up. On: the map is a core feature.
  static const bool mapViewDefault = true;

  /// The name of the chosen palette, or `system` to follow the device.
  final String theme;
  final LocaleChoice language;
  final bool hapticsOn;
  final HapticStrength hapticStrength;
  final bool soundOn;
  final SoundPack soundPack;
  final bool cheersOn;
  final CheerSize cheerSize;
  final bool shakeOnFull;
  final bool tiltToPour;
  final ReminderSettings reminder;
  final bool mapView;
  final bool mapContribute;
  final bool mapComment;

  ThemeChoice get themeChoice => theme == ThemeChoice.system.name
      ? ThemeChoice.system
      : ThemeChoice.named(theme);

  /// The tap screen reads its effects through this mapping.
  FeelSettings get feelSettings => FeelSettings(
    screenShake: shakeOnFull,
    cheerPhrases: cheersOn,
    largeText: cheerSize == CheerSize.large,
    tiltSpill: tiltToPour,
  );

  Settings fromFeel(FeelSettings feel) {
    return copyWith(
      shakeOnFull: feel.screenShake,
      cheersOn: feel.cheerPhrases,
      cheerSize: feel.largeText ? CheerSize.large : CheerSize.normal,
      tiltToPour: feel.tiltSpill,
    );
  }

  Settings copyWith({
    String? theme,
    LocaleChoice? language,
    bool? hapticsOn,
    HapticStrength? hapticStrength,
    bool? soundOn,
    SoundPack? soundPack,
    bool? cheersOn,
    CheerSize? cheerSize,
    bool? shakeOnFull,
    bool? tiltToPour,
    ReminderSettings? reminder,
    bool? mapView,
    bool? mapContribute,
    bool? mapComment,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      hapticStrength: hapticStrength ?? this.hapticStrength,
      soundOn: soundOn ?? this.soundOn,
      soundPack: soundPack ?? this.soundPack,
      cheersOn: cheersOn ?? this.cheersOn,
      cheerSize: cheerSize ?? this.cheerSize,
      shakeOnFull: shakeOnFull ?? this.shakeOnFull,
      tiltToPour: tiltToPour ?? this.tiltToPour,
      reminder: reminder ?? this.reminder,
      mapView: mapView ?? this.mapView,
      mapContribute: mapContribute ?? this.mapContribute,
      mapComment: mapComment ?? this.mapComment,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Settings && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() =>
      'Settings($theme, $language, $hapticsOn, $hapticStrength, $soundOn, '
      '$soundPack, $cheersOn, $cheerSize, $shakeOnFull, $tiltToPour, '
      '$reminder, $mapView, $mapContribute, $mapComment)';
}
