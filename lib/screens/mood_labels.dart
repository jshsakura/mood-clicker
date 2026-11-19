import 'package:flutter/widgets.dart';

import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';

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
