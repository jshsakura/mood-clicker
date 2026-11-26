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
  String get loading_brokenTitle => 'Your records are damaged';

  @override
  String get loading_brokenBody =>
      'We could not read your saved records. Starting anew begins with empty records.';

  @override
  String get loading_startNew => 'Start anew';

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
  String get tap_todayLabel => 'Taps today';

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
  String get settings_sound => 'Sound';

  @override
  String get settings_reminder => 'Evening reminder';

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
  String get settings_soundPackPentatonic => 'Pentatonic';

  @override
  String get settings_cheers => 'Cheer phrases';

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
      'Sent as neighbourhood cells of about 5km²; cells under five people stay hidden';

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

  @override
  String get map_openLabel => 'Open map';

  @override
  String get map_nearby => 'On this map';

  @override
  String get map_pickedPlace => 'Picked place';

  @override
  String get map_explain =>
      'The face is the mood that stands for the cell, and the number is how many people left one. Places are grouped into cells of about 5km², and cells with fewer than five people stay hidden.';

  @override
  String get map_rangeToday => 'Today';

  @override
  String get map_rangeWeek => 'This week';

  @override
  String get map_you => 'My spot';

  @override
  String map_tapsLine(int count) {
    return 'Tapped $count times';
  }

  @override
  String map_peopleLine(int count) {
    return '$count people left a mood';
  }

  @override
  String map_happySide(int percent) {
    return '$percent% on the happy side';
  }

  @override
  String map_sadSide(int percent) {
    return '$percent% on the sad side';
  }

  @override
  String map_spotLabel(String word, int count) {
    return '$word, tapped $count times';
  }

  @override
  String get map_wordSmiled => 'I smiled today';

  @override
  String get map_wordRest => 'I want a little rest';

  @override
  String get map_wordAteWell => 'I ate something good';

  @override
  String get map_wordBetterThanExpected => 'Better than I thought';

  @override
  String get map_wordTomorrowToo => 'Same again tomorrow';

  @override
  String get map_wordThankful => 'Someone I\'m thankful for';

  @override
  String get settings_mapView => 'Show map';

  @override
  String get settings_mapViewDesc =>
      'Shows a map button on the mood screen. Off hides it';

  @override
  String get map_togetherSad => 'You are not the only one feeling low today';

  @override
  String get map_togetherHappy => 'Many people nearby feel good today';

  @override
  String get moodSelect_title => 'How are you feeling today?';

  @override
  String get loading_message => 'Loading your records';

  @override
  String get calendar_recordedDays => 'Recorded';

  @override
  String get calendar_stamps => 'Stamps';

  @override
  String get calendar_daysUnit => 'd';

  @override
  String get calendar_stampsUnit => '';

  @override
  String get calendar_monthFlow => 'Monthly flow';

  @override
  String get calendar_tapsAxis => 'Taps';

  @override
  String calendar_tappedTimes(int count) {
    return '$count taps';
  }

  @override
  String calendar_noteQuote(String note) {
    return '“$note”';
  }

  @override
  String get calendar_stampLine1 => 'Well';

  @override
  String get calendar_stampLine2 => 'done';

  @override
  String get dayDetail_moodHeading => 'Mood of the day';

  @override
  String get dayDetail_dominantCaption => 'Most tapped mood';

  @override
  String get dayDetail_weekReview => 'This week';

  @override
  String get settings_exportEmpty => 'There are no records to export yet';

  @override
  String get calendar_today => 'Today';

  @override
  String get calendar_emptyMonth => 'No entries this month';

  @override
  String get dayDetail_addNote => 'Add note';

  @override
  String get dayDetail_editNote => 'Edit note';

  @override
  String get map_empty => 'No nearby entries yet';

  @override
  String get map_sampleNotice => 'Showing a sample neighborhood map';

  @override
  String get tap_hint => 'Tap anywhere';

  @override
  String get note_reason => 'You filled it up. Leave a line for today.';

  @override
  String get note_privacy =>
      'Words you write stay on this device. Only a sentence picked from the list is shown on the map, with no name.';

  @override
  String get note_saveFailed =>
      'Could not save. Try again in a moment. Your text is still here.';

  @override
  String get tap_action => 'Tap';

  @override
  String get settings_mindCareUs988 => '988 Suicide and Crisis Lifeline (US)';

  @override
  String get settings_mindCareUs988Text => 'Text 988 (US)';

  @override
  String get settings_mindCareFindHelpline =>
      'Find a helpline in the country you are in';

  @override
  String get settings_mindCareFindHelplineNote =>
      'Opens a site that lists free helplines by country';

  @override
  String get settings_mindCareFootnoteJapan =>
      'In immediate danger call 110 or 119. This app is not a medical device and does not replace care from a doctor.';

  @override
  String get settings_mindCareFootnoteUs =>
      'In immediate danger call 911. This app is not a medical device and does not replace care from a doctor.';

  @override
  String get settings_mindCareFootnoteOther =>
      'In immediate danger call the emergency number of the country you are in. This app is not a medical device and does not replace care from a doctor.';

  @override
  String get settings_mindCareCopyFallback =>
      'The app did not open, so the number is copied. Paste it into your phone or messages app.';

  @override
  String note_titleOn(String date) {
    return 'Note for $date';
  }

  @override
  String get settings_deleteFailed =>
      'Could not delete the records. Try again in a moment. Your records are unchanged.';

  @override
  String get release_settleAngry =>
      'That was plenty of tapping. Shall we take a moment to breathe?';

  @override
  String get release_settleSad =>
      'You made it this far. It\'s okay as you are right now.';

  @override
  String get release_settleAnxious =>
      'It\'s okay to rest a little. You can follow the breath, or not.';

  @override
  String get howTo_label => 'How to play';

  @override
  String get howTo_title => 'How to play';

  @override
  String get howTo_fill => 'Tap and the water rises.';

  @override
  String get howTo_rest => 'Rest a moment and it sinks little by little.';

  @override
  String get howTo_tilt =>
      'Tilt the phone and the water spills, so the number on screen goes down.';

  @override
  String get howTo_spark => 'Now and then a sparkling special phrase appears.';

  @override
  String get howTo_hold =>
      'Stay between 95 and 100 percent for a few seconds for a special reward.';

  @override
  String get howTo_finish =>
      'Fill it up and a finish that fits your mood plays.';

  @override
  String get howTo_bubble => 'How to play';

  @override
  String get settings_weatherView => 'Show weather';

  @override
  String get settings_weatherViewDesc =>
      'Uses a location rounded to one decimal place to fetch local weather only. When off, location is never requested.';

  @override
  String get settings_weatherSource => 'Weather data';

  @override
  String get weather_clear => 'Clear';

  @override
  String get weather_partlyCloudy => 'Partly cloudy';

  @override
  String get weather_cloudy => 'Cloudy';

  @override
  String get weather_rain => 'Rain';

  @override
  String get weather_snow => 'Snow';

  @override
  String get permission_locationWhenInUse =>
      'Used only while the app is open, with coordinates rounded to one decimal place, to fetch local weather.';

  @override
  String get map_zoomIn => 'Zoom in a little to see the neighborhood cells';
}
