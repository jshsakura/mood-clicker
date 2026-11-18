import 'package:flutter/widgets.dart';

import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';

/// The face of each mood. The faces are the only colored thing on screen.
String moodEmoji(Mood mood) => switch (mood) {
  Mood.happy => '\u{1F60A}',
  Mood.excited => '\u{1F929}',
  Mood.angry => '\u{1F621}',
  Mood.sad => '\u{1F622}',
  Mood.anxious => '\u{1F630}',
};

String moodName(BuildContext context, Mood mood) {
  final l10n = AppLocalizations.of(context);
  return switch (mood) {
    Mood.happy => l10n.moodSelect_moodHappy,
    Mood.excited => l10n.moodSelect_moodExcited,
    Mood.angry => l10n.moodSelect_moodAngry,
    Mood.sad => l10n.moodSelect_moodSad,
    Mood.anxious => l10n.moodSelect_moodAnxious,
  };
}
