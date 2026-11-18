import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';

/// The translated name of a mood, from the `moodSelect_mood*` ARB keys.
String moodLabel(AppLocalizations l, Mood mood) => switch (mood) {
  Mood.happy => l.moodSelect_moodHappy,
  Mood.excited => l.moodSelect_moodExcited,
  Mood.angry => l.moodSelect_moodAngry,
  Mood.sad => l.moodSelect_moodSad,
  Mood.anxious => l.moodSelect_moodAnxious,
};
