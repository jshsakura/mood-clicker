// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Unknown';

  @override
  String get common_back => 'Back';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_on => 'On';

  @override
  String get common_off => 'Off';

  @override
  String get loading_brokenTitle => 'Your records are damaged';

  @override
  String get loading_brokenBody =>
      'We could not read your saved records. Starting anew begins with empty records.';

  @override
  String get loading_startNew => 'Start anew';

  @override
  String get moodSelect_today => 'Today';

  @override
  String get moodSelect_moodHappy => 'Happy';

  @override
  String get moodSelect_moodExcited => 'Excited';

  @override
  String get moodSelect_moodAngry => 'Angry';

  @override
  String get moodSelect_moodSad => 'Sad';

  @override
  String get moodSelect_moodAnxious => 'Anxious';

  @override
  String tap_todayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Today $count',
      one: 'Today 1',
    );
    return '$_temp0';
  }

  @override
  String get calendar_prevMonth => 'Previous month';

  @override
  String get calendar_nextMonth => 'Next month';

  @override
  String get dayDetail_happySide => 'Happy side';

  @override
  String get dayDetail_sadSide => 'Sad side';

  @override
  String dayDetail_moodCount(String mood, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$mood $_temp0';
  }

  @override
  String get review_thisWeek => 'This week';

  @override
  String get review_thisMonth => 'This month';

  @override
  String review_ratioLine(int happy, int sad) {
    return 'Happy side $happy% · Sad side $sad%';
  }

  @override
  String review_topMood(String mood) {
    return 'Most frequent mood: $mood';
  }

  @override
  String review_mostTappedDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Most tapped day: $dateString';
  }

  @override
  String get review_trendUp => 'More happy taps than the last period';

  @override
  String get review_trendDown => 'Fewer happy taps than the last period';

  @override
  String get review_trendSame => 'About the same as the last period';

  @override
  String get map_title => 'Around me today';

  @override
  String map_legendLine(int happy, int sad) {
    return 'Happy $happy% · Sad $sad%';
  }

  @override
  String get map_permissionReason =>
      'Location is needed to show moods around you';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_themeSystem => 'Follow system';

  @override
  String get settings_themeLight => 'Light';

  @override
  String get settings_themeDark => 'Dark';

  @override
  String get settings_themePink => 'Pink';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_languageSystem => 'System default';

  @override
  String get settings_languageKo => '한국어';

  @override
  String get settings_languageEn => 'English';

  @override
  String get settings_languageJa => '日本語';

  @override
  String get settings_vibration => 'Vibration';

  @override
  String get settings_vibrationStrength => 'Vibration strength';

  @override
  String get settings_sound => 'Sound';

  @override
  String get settings_soundPack => 'Sound pack';

  @override
  String get settings_mapContribute => 'Share my mood on the map';
}
