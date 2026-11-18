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
  String get settings_languageSystem => '端末の言語';

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

  @override
  String get settings_time20 => '午後8時';

  @override
  String get settings_time21 => '午後9時';

  @override
  String get settings_time22 => '午後10時';

  @override
  String get settings_notifications => '通知';

  @override
  String get settings_tapping => 'たたく';

  @override
  String get settings_strengthWeak => 'やわらかく';

  @override
  String get settings_strengthNormal => 'ふつう';

  @override
  String get settings_strengthStrong => '強く';

  @override
  String get settings_soundPackBasic => '基本';

  @override
  String get settings_cheers => '応援メッセージ';

  @override
  String get settings_cheersSize => '文字の大きさ';

  @override
  String get settings_cheersNormal => 'ふつうの文字';

  @override
  String get settings_cheersLarge => '大きく';

  @override
  String get settings_shakeOnFull => 'いっぱいになったら画面を揺らす';

  @override
  String get settings_tiltToPour => '傾けてこぼす';

  @override
  String get settings_mindCare => '心のケア';

  @override
  String get settings_mindCareHelp => 'つらくなったとき';

  @override
  String get settings_mindCareCenter => '精神健康危機相談(韓国)';

  @override
  String get settings_mindCareCenterNote => '近くのこころの健康福祉センターにつながります';

  @override
  String get settings_mindCareSuicide => '自殺予防相談電話(韓国)';

  @override
  String get settings_mindCareKakao => 'マドゥルレン(カカオトーク)';

  @override
  String get settings_mindCarePolice => '警察';

  @override
  String get settings_mindCareMedical => '救急医療';

  @override
  String get settings_map => '地図';

  @override
  String get settings_mapComment => 'ひと言も足す';

  @override
  String get settings_records => '記録';

  @override
  String get settings_export => '記録を書き出す';

  @override
  String get settings_deleteAll => 'すべての記録を消す';

  @override
  String get settings_deleteConfirmTitle => 'すべての記録を消します';

  @override
  String get settings_deleteConfirmBody =>
      'カレンダーの記録、今日のひとこと、たたいた数がすべて消えます。元に戻せません。先に書き出しておけばあとで見られます。';

  @override
  String get settings_deleteConfirmAction => '消す';

  @override
  String get settings_about => '情報';

  @override
  String get settings_version => 'バージョン';

  @override
  String get settings_licenses => 'オープンソースライセンス';

  @override
  String get settings_privacy => 'プライバシーポリシー';

  @override
  String get settings_themeNote => '選ぶとすぐすべての画面に適用されます。';

  @override
  String get settings_vibrationDesc => 'たたくたびに、そしていっぱいになるときは強く鳴ります';

  @override
  String get settings_soundDesc => 'マナーモードでは鳴りません';

  @override
  String get settings_cheersDesc => 'たたいた場所に短い言葉が現れます';

  @override
  String get settings_shakeDesc => 'オフにすると揺れずに言葉だけ表示します';

  @override
  String get settings_pourDesc => '端末を傾けると水がこぼれ、たたいた数も減ります';

  @override
  String get settings_reminderDesc => '記録していない日に一度だけ知らせます';

  @override
  String get settings_mapContributeDesc => '約1km単位にまとめて送り、5人に満たない場所は表示しません';

  @override
  String get settings_mapCommentDesc => '用意された文から選んだ一言だけを送ります。書いた言葉は端末にだけ残ります';

  @override
  String get settings_exportDesc => 'カレンダーの記録を一つのファイルに保存します';

  @override
  String get settings_exportDone => '記録をファイルに保存しました';

  @override
  String get settings_mindCareRowDesc => '24時間話を聞いてくれる窓口につなぎます';

  @override
  String get settings_mindCareTitle => '一人で抱える必要はありません';

  @override
  String get settings_mindCareIntro =>
      '今つらいなら、話を聞いてくれる人がいます。無料で、名前を言う必要もありません。';

  @override
  String get settings_mindCareSuicideNote => '24時間相談';

  @override
  String get settings_mindCareKakaoNote => '電話が難しければ文字で話せます。24時間';

  @override
  String get settings_mindCareFootnote =>
      '危険なときは119か112に電話してください。このアプリは医療機器ではなく、診療の代わりにはなりません。';

  @override
  String get settings_close => '閉じる';

  @override
  String get settings_mindCareSosJapan => '#いのちSOS';

  @override
  String get settings_mindCareYorisoiJapan => 'よりそいホットライン';
}
