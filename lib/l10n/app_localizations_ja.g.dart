// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '気分クリッカー';

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
  String get settings_mapContribute => '地図に自分の気分を足す';
}
