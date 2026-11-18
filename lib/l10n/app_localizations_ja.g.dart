// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Unknown';

  @override
  String get common_back => '戻る';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_on => 'オン';

  @override
  String get common_off => 'オフ';

  @override
  String get loading_brokenTitle => '記録が壊れています';

  @override
  String get loading_brokenBody => '保存した記録を読み込めませんでした。やり直すと空の記録から始まります。';

  @override
  String get loading_startNew => 'やり直す';

  @override
  String get moodSelect_today => '今日';

  @override
  String get moodSelect_moodHappy => '幸せ';

  @override
  String get moodSelect_moodExcited => 'わくわく';

  @override
  String get moodSelect_moodAngry => 'イライラ';

  @override
  String get moodSelect_moodSad => '悲しい';

  @override
  String get moodSelect_moodAnxious => '不安';

  @override
  String tap_todayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日 $count回',
    );
    return '$_temp0';
  }

  @override
  String get calendar_prevMonth => '前の月';

  @override
  String get calendar_nextMonth => '次の月';

  @override
  String get dayDetail_happySide => '幸せ側';

  @override
  String get dayDetail_sadSide => '悲しい側';

  @override
  String dayDetail_moodCount(String mood, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回',
    );
    return '$mood $_temp0';
  }

  @override
  String get review_thisWeek => '今週';

  @override
  String get review_thisMonth => '今月';

  @override
  String review_ratioLine(int happy, int sad) {
    return '幸せ側 $happy% · 悲しい側 $sad%';
  }

  @override
  String review_topMood(String mood) {
    return 'いちばん多かった気分: $mood';
  }

  @override
  String review_mostTappedDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'いちばんたたいた日: $dateString';
  }

  @override
  String get review_trendUp => '前の期間より幸せ側が増えました';

  @override
  String get review_trendDown => '前の期間より幸せ側が減りました';

  @override
  String get review_trendSame => '前の期間と同じくらいです';

  @override
  String get map_title => '近所の今日';

  @override
  String map_legendLine(int happy, int sad) {
    return '幸せ $happy% · 悲しい $sad%';
  }

  @override
  String get map_permissionReason => '近所の気分を見るには位置情報が必要です';

  @override
  String get reminder_title => '今日の気分はどうでしたか？';

  @override
  String get reminder_body => '少しだけ、今日の気持ちを残してみませんか';

  @override
  String get settings_title => '設定';

  @override
  String get settings_theme => 'テーマ';

  @override
  String get settings_themeSystem => 'システムに従う';

  @override
  String get settings_themeLight => 'ライト';

  @override
  String get settings_themeDark => 'ダーク';

  @override
  String get settings_themePink => 'ピンク';

  @override
  String get settings_language => '言語';

  @override
  String get settings_languageSystem => 'システムに従う';

  @override
  String get settings_languageKo => '한국어';

  @override
  String get settings_languageEn => 'English';

  @override
  String get settings_languageJa => '日本語';

  @override
  String get settings_vibration => '振動';

  @override
  String get settings_vibrationStrength => '振動の強さ';

  @override
  String get settings_sound => 'サウンド';

  @override
  String get settings_soundPack => 'サウンドセット';

  @override
  String get settings_reminder => '夜のリマインダー';

  @override
  String get settings_reminderTime => '通知の時刻';

  @override
  String get settings_mapContribute => '地図に自分の気分を足す';

  @override
  String get moodSelect_openCalendar => 'カレンダーを見る';

  @override
  String get note_title => '今日のひとこと';

  @override
  String get note_hint => 'ひとことで残してみましょう';

  @override
  String get note_skip => 'スキップ';

  @override
  String get note_save => '残す';

  @override
  String get note_presetLabel => 'こんな言葉はどう？';

  @override
  String get note_presetProud => '誇らしい一日でした';

  @override
  String get note_presetCalm => '心が穏やかでした';

  @override
  String get note_presetThanks => 'ありがたいことがありました';

  @override
  String get note_presetHard => 'つらかったけど乗り越えました';

  @override
  String get note_presetTired => 'とても疲れました';

  @override
  String get note_presetRest => 'ゆっくり休みたいです';

  @override
  String get dayDetail_note => 'ひとこと';

  @override
  String get dayDetail_empty => 'この日は記録がありません';

  @override
  String calendar_openDay(String date) {
    return '$dateを見る';
  }
}
