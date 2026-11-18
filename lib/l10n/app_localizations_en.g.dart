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
  String get reminder_title => 'How was your mood today?';

  @override
  String get reminder_body => 'A moment to check in with yourself';

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
  String get settings_languageSystem => 'Device language';

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
  String get settings_reminder => 'Evening reminder';

  @override
  String get settings_reminderTime => 'Reminder time';

  @override
  String get settings_mapContribute => 'Share my mood on the map';

  @override
  String get moodSelect_openCalendar => 'View calendar';

  @override
  String get note_title => 'Note for today';

  @override
  String get note_hint => 'Leave one line';

  @override
  String get note_skip => 'Skip';

  @override
  String get note_save => 'Save';

  @override
  String get note_presetLabel => 'Or pick one';

  @override
  String get note_presetProud => 'I felt proud today';

  @override
  String get note_presetCalm => 'I felt calm';

  @override
  String get note_presetThanks => 'Something made me grateful';

  @override
  String get note_presetHard => 'It was hard, but I got through';

  @override
  String get note_presetTired => 'I was very tired';

  @override
  String get note_presetRest => 'I just want to rest';

  @override
  String get dayDetail_note => 'Note';

  @override
  String get dayDetail_empty => 'Nothing recorded this day';

  @override
  String calendar_openDay(String date) {
    return 'View $date';
  }

  @override
  String get settings_time20 => '8 PM';

  @override
  String get settings_time21 => '9 PM';

  @override
  String get settings_time22 => '10 PM';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_tapping => 'Tapping';

  @override
  String get settings_strengthWeak => 'Gently';

  @override
  String get settings_strengthNormal => 'Normal';

  @override
  String get settings_strengthStrong => 'Strong';

  @override
  String get settings_soundPackBasic => 'Basic';

  @override
  String get settings_cheers => 'Cheer phrases';

  @override
  String get settings_cheersSize => 'Text size';

  @override
  String get settings_cheersNormal => 'Normal text';

  @override
  String get settings_cheersLarge => 'Large';

  @override
  String get settings_shakeOnFull => 'Shake the screen when full';

  @override
  String get settings_tiltToPour => 'Tilt to pour';

  @override
  String get settings_mindCare => 'Mind care';

  @override
  String get settings_mindCareHelp => 'When it feels heavy';

  @override
  String get settings_mindCareCenter => 'Mental health crisis line (Korea)';

  @override
  String get settings_mindCareCenterNote => 'Connects you to a nearby center';

  @override
  String get settings_mindCareSuicide => 'Suicide prevention line (Korea)';

  @override
  String get settings_mindCareKakao => 'Madeullaen (KakaoTalk)';

  @override
  String get settings_mindCarePolice => 'Police';

  @override
  String get settings_mindCareMedical => 'Emergency medical';

  @override
  String get settings_map => 'Map';

  @override
  String get settings_mapComment => 'Add a word too';

  @override
  String get settings_records => 'Records';

  @override
  String get settings_export => 'Export records';

  @override
  String get settings_deleteAll => 'Delete all records';

  @override
  String get settings_deleteConfirmTitle => 'Delete every record';

  @override
  String get settings_deleteConfirmBody =>
      'The calendar, the day notes and every tap count disappear. This cannot be undone. Export first to keep a copy.';

  @override
  String get settings_deleteConfirmAction => 'Delete';

  @override
  String get settings_about => 'About';

  @override
  String get settings_version => 'Version';

  @override
  String get settings_licenses => 'Open source licenses';

  @override
  String get settings_privacy => 'Privacy policy';

  @override
  String get settings_privacyPending => 'Coming soon';

  @override
  String get settings_themeNote => 'Tap one and every screen changes at once.';

  @override
  String get settings_vibrationDesc =>
      'Buzzes on every tap, and stronger when the gauge fills';

  @override
  String get settings_soundDesc => 'Stays silent while the device is muted';

  @override
  String get settings_cheersDesc => 'A short line appears where you tapped';

  @override
  String get settings_shakeDesc => 'Off means no shake, only the message';

  @override
  String get settings_pourDesc =>
      'Tilting spills the water and lowers the count';

  @override
  String get settings_reminderDesc => 'Only on days without a record, once';

  @override
  String get settings_mapContributeDesc =>
      'Sent as ~1km blocks; places under five people stay hidden';

  @override
  String get settings_mapCommentDesc =>
      'Only a picked sentence is sent; anything written stays on the device';

  @override
  String get settings_exportDesc => 'Saves the calendar to one file';

  @override
  String get settings_exportDone => 'Saved the records to a file';

  @override
  String get settings_mindCareRowDesc =>
      'Connects you to someone who listens, any hour';

  @override
  String get settings_mindCareTitle => 'You do not have to hold this alone';

  @override
  String get settings_mindCareIntro =>
      'If today is heavy, someone is there to listen. It is free and you never have to give a name.';

  @override
  String get settings_mindCareSuicideNote => 'Open 24 hours';

  @override
  String get settings_mindCareKakaoNote =>
      'When calls are hard, talk by text. Any hour';

  @override
  String get settings_mindCareFootnote =>
      'In immediate danger call 119 or 112. This app is not a medical device and does not replace care from a doctor.';

  @override
  String get settings_close => 'Close';

  @override
  String get settings_mindCareSosJapan => '#Inochi SOS';

  @override
  String get settings_mindCareYorisoiJapan => 'Yorisoi Hotline (Japan)';
}
