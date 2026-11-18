import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.g.dart';
import 'app_localizations_ja.g.dart';
import 'app_localizations_ko.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.g.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// 앱 이름입니다. 로딩 화면 가운데와 시스템의 앱 목록에 씁니다. 앱 이름이 정해지면 안드로이드 strings.xml, iOS InfoPlist.strings 와 함께 바꿉니다.
  ///
  /// In ko, this message translates to:
  /// **'Unknown'**
  String get appName;

  /// 모든 화면 왼쪽 위 뒤로 가기 버튼의 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get common_back;

  /// 대화 상자의 취소 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get common_cancel;

  /// 설정 항목을 켜는 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'켜기'**
  String get common_on;

  /// 설정 항목을 끄는 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get common_off;

  /// 로딩 화면에서 저장된 기록을 읽지 못했을 때 띄우는 대화 상자의 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'기록이 깨졌습니다'**
  String get loading_brokenTitle;

  /// 깨진 기록 대화 상자의 본문입니다. 말없이 지우지 않는다는 규칙을 알려 줍니다.
  ///
  /// In ko, this message translates to:
  /// **'저장된 기록을 읽지 못했습니다. 새로 시작하면 빈 기록으로 시작합니다.'**
  String get loading_brokenBody;

  /// 깨진 기록 대화 상자에서 빈 기록으로 다시 시작하는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'새로 시작합니다'**
  String get loading_startNew;

  /// 기분 고르기 화면 맨 위 날짜 옆에 붙는 짧은 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get moodSelect_today;

  /// 기분 이름입니다. 기분 고르기 배너와 두드리기 화면 제목에 씁니다. 행복 쪽입니다.
  ///
  /// In ko, this message translates to:
  /// **'행복해요'**
  String get moodSelect_moodHappy;

  /// 기분 이름입니다. 기분 고르기 배너와 두드리기 화면 제목에 씁니다. 행복 쪽입니다.
  ///
  /// In ko, this message translates to:
  /// **'설레요'**
  String get moodSelect_moodExcited;

  /// 기분 이름입니다. 기분 고르기 배너와 두드리기 화면 제목에 씁니다. 슬픔 쪽입니다.
  ///
  /// In ko, this message translates to:
  /// **'화나요'**
  String get moodSelect_moodAngry;

  /// 기분 이름입니다. 기분 고르기 배너와 두드리기 화면 제목에 씁니다. 슬픔 쪽입니다.
  ///
  /// In ko, this message translates to:
  /// **'슬퍼요'**
  String get moodSelect_moodSad;

  /// 기분 이름입니다. 기분 고르기 배너와 두드리기 화면 제목에 씁니다. 슬픔 쪽입니다.
  ///
  /// In ko, this message translates to:
  /// **'불안해요'**
  String get moodSelect_moodAnxious;

  /// 두드리기 화면 아래, 오늘 누적 수 숫자 밑에 붙는 작은 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 두드린 수'**
  String get tap_todayLabel;

  /// 두드리기 화면 아래에 오늘 누적 수를 보여 주는 문구입니다. 숫자는 자리표시자 count 로 들어갑니다.
  ///
  /// In ko, this message translates to:
  /// **'{count, plural, other {오늘 {count}}}'**
  String tap_todayCount(int count);

  /// 달력에서 한 달 뒤로 가는 버튼의 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'지난달'**
  String get calendar_prevMonth;

  /// 달력에서 한 달 앞으로 가는 버튼의 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'다음 달'**
  String get calendar_nextMonth;

  /// 그날 상세와 돌아보기에서 행복 쪽 합계에 붙는 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'행복 쪽'**
  String get dayDetail_happySide;

  /// 그날 상세와 돌아보기에서 슬픔 쪽 합계에 붙는 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'슬픔 쪽'**
  String get dayDetail_sadSide;

  /// 그날 상세에서 기분별 누적 수를 보여 주는 문구입니다. mood 는 기분 이름, count 는 누적 수입니다.
  ///
  /// In ko, this message translates to:
  /// **'{mood} {count, plural, other {{count}번}}'**
  String dayDetail_moodCount(String mood, int count);

  /// 돌아보기에서 기간으로 이번 주를 고르는 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get review_thisWeek;

  /// 돌아보기에서 기간으로 이번 달을 고르는 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get review_thisMonth;

  /// 돌아보기에서 그 기간의 행복 쪽과 슬픔 쪽 비율을 한 줄로 보여 주는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'행복 쪽 {happy}% · 슬픔 쪽 {sad}%'**
  String review_ratioLine(int happy, int sad);

  /// 돌아보기에서 그 기간에 가장 많이 두드린 기분을 알려 주는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'가장 많았던 기분: {mood}'**
  String review_topMood(String mood);

  /// 돌아보기에서 그 기간에 가장 많이 두드린 날을 알려 주는 문구입니다. date 는 달력 형식으로 언어에 맞게 표시됩니다.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 두드린 날: {date}'**
  String review_mostTappedDay(DateTime date);

  /// 돌아보기에서 지난 기간과 비교한 한 줄 알림입니다. 판단이나 조언을 덧붙이지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'지난 기간보다 행복 쪽이 늘었습니다'**
  String get review_trendUp;

  /// 돌아보기에서 지난 기간과 비교한 한 줄 알림입니다. 판단이나 조언을 덧붙이지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'지난 기간보다 행복 쪽이 줄었습니다'**
  String get review_trendDown;

  /// 돌아보기에서 지난 기간과 비교한 한 줄 알림입니다. 비율이 비슷할 때 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'지난 기간과 비슷합니다'**
  String get review_trendSame;

  /// 내 주변 지도 화면의 제목입니다. 3단계에 만드는 화면이지만 문구를 미리 둡니다.
  ///
  /// In ko, this message translates to:
  /// **'내 주변 오늘'**
  String get map_title;

  /// 지도 화면 아래에 보이는 범위 전체의 행복 쪽, 슬픔 쪽 비율입니다.
  ///
  /// In ko, this message translates to:
  /// **'행복 {happy}% · 슬픔 {sad}%'**
  String map_legendLine(int happy, int sad);

  /// 지도 화면에서 위치 권한을 처음 요청할 때 함께 보여 주는 이유입니다. 앱 사용 중에만 물어봅니다.
  ///
  /// In ko, this message translates to:
  /// **'동네 기분 지도를 보려면 위치가 필요합니다'**
  String get map_permissionReason;

  /// 저녁 알림의 제목입니다. 하루 한 번 정한 시각에 뜹니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기분은 어땠나요?'**
  String get reminder_title;

  /// 저녁 알림의 본문입니다. 알림을 누르면 기분 고르기 화면으로 갑니다.
  ///
  /// In ko, this message translates to:
  /// **'잠깐 들러 오늘 마음을 남겨 보세요'**
  String get reminder_body;

  /// 설정 화면의 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings_title;

  /// 설정에서 테마 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settings_theme;

  /// 테마 선택지입니다. 기기 설정을 따라 라이트와 다크 중 하나를 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'시스템 따라가기'**
  String get settings_themeSystem;

  /// 테마 선택지입니다. 밝은 테마입니다.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settings_themeLight;

  /// 테마 선택지입니다. 어두운 테마입니다.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settings_themeDark;

  /// 테마 선택지입니다. 핑크 테마입니다.
  ///
  /// In ko, this message translates to:
  /// **'핑크'**
  String get settings_themePink;

  /// 설정에서 언어 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settings_language;

  /// 언어 선택지입니다. 기기 언어를 따릅니다. 지원하지 않는 기기 언어는 영어로 보입니다.
  ///
  /// In ko, this message translates to:
  /// **'기기 언어'**
  String get settings_languageSystem;

  /// 언어 선택지입니다. 언어 이름은 언어마다 그 언어로 표기하므로 어떤 언어로 번역해도 한국어로 둡니다.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get settings_languageKo;

  /// 언어 선택지입니다. 언어 이름은 언어마다 그 언어로 표기하므로 어떤 언어로 번역해도 English 로 둡니다.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get settings_languageEn;

  /// 언어 선택지입니다. 언어 이름은 언어마다 그 언어로 표기하므로 어떤 언어로 번역해도 日本語 로 둡니다.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get settings_languageJa;

  /// 설정에서 진동 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get settings_vibration;

  /// 진동 세기를 고르는 항목의 이름입니다. 세기 조절이 되는 기기에서만 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'진동 세기'**
  String get settings_vibrationStrength;

  /// 설정에서 소리 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get settings_sound;

  /// 두드릴 때 나는 소리 묶음을 고르는 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'소리 묶음'**
  String get settings_soundPack;

  /// 설정에서 저녁 알림을 켜고 끄는 항목의 이름입니다. 기본은 꺼짐입니다. 켤 때만 권한을 물어봅니다.
  ///
  /// In ko, this message translates to:
  /// **'저녁 알림'**
  String get settings_reminder;

  /// 저녁 알림이 울리는 시각을 고르는 항목의 이름입니다. 기본은 저녁 9시입니다.
  ///
  /// In ko, this message translates to:
  /// **'알림 시각'**
  String get settings_reminderTime;

  /// 설정에서 내 기분을 지도에 보내는지 고르는 항목입니다. 기본은 꺼짐이고 3단계에 켭니다.
  ///
  /// In ko, this message translates to:
  /// **'지도에 내 기분 보태기'**
  String get settings_mapContribute;

  /// 기분 고르기 화면의 달력 버튼 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'달력 보기'**
  String get moodSelect_openCalendar;

  /// 끝까지 채운 날 두드리기 화면을 나갈 때 뜨는 한마디 창의 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 한마디'**
  String get note_title;

  /// 한마디 입력칸의 안내 문구입니다. 40자까지 쓸 수 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'한 줄로 남겨 보세요'**
  String get note_hint;

  /// 한마디를 남기지 않고 닫는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get note_skip;

  /// 한마디를 저장하고 닫는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'남기기'**
  String get note_save;

  /// 준비된 문장 목록 위의 작은 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'이런 말은 어때요'**
  String get note_presetLabel;

  /// 준비된 한마디 문장입니다. 고른 문장의 id 만 나중에 지도로 보낼 수 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'뿌듯한 하루였어요'**
  String get note_presetProud;

  /// 준비된 한마디 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'마음이 차분했어요'**
  String get note_presetCalm;

  /// 준비된 한마디 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'고마운 일이 있었어요'**
  String get note_presetThanks;

  /// 준비된 한마디 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'힘들었지만 버텼어요'**
  String get note_presetHard;

  /// 준비된 한마디 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'많이 피곤했어요'**
  String get note_presetTired;

  /// 준비된 한마디 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'푹 쉬고 싶어요'**
  String get note_presetRest;

  /// 하루 상세 화면에서 그날 남긴 한마디 위의 작은 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'한마디'**
  String get dayDetail_note;

  /// 기록이 없는 날을 눌렀을 때 하루 상세 화면에 보이는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'이날은 기록이 없습니다'**
  String get dayDetail_empty;

  /// 달력의 날짜 칸 숨김 이름(접근성)입니다. {date} 는 이미 현지 형식으로 만든 날짜입니다.
  ///
  /// In ko, this message translates to:
  /// **'{date} 보기'**
  String calendar_openDay(String date);

  /// 저녁 알림 시각 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'오후 8시'**
  String get settings_time20;

  /// 저녁 알림 시각 선택지입니다. 기본값입니다.
  ///
  /// In ko, this message translates to:
  /// **'오후 9시'**
  String get settings_time21;

  /// 저녁 알림 시각 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'오후 10시'**
  String get settings_time22;

  /// 설정의 알림 묶음 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settings_notifications;

  /// 설정의 두드리기 묶음 이름입니다. 진동, 소리, 응원 문구, 화면 흔들기, 기울여 쏟기가 여기에 듭니다.
  ///
  /// In ko, this message translates to:
  /// **'두드리기'**
  String get settings_tapping;

  /// 진동 세기 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'약하게'**
  String get settings_strengthWeak;

  /// 진동 세기 선택지입니다. 기본값입니다.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get settings_strengthNormal;

  /// 진동 세기 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'세게'**
  String get settings_strengthStrong;

  /// 소리 묶음 선택지입니다. 지금은 이 한 벌만 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get settings_soundPackBasic;

  /// 두드릴 때 뜨는 응원 문구를 켜고 끄는 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'응원 문구'**
  String get settings_cheers;

  /// 응원 문구의 글자 크기를 고르는 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get settings_cheersSize;

  /// 응원 문구 글자 크기 선택지입니다. 기본값입니다.
  ///
  /// In ko, this message translates to:
  /// **'보통 글씨'**
  String get settings_cheersNormal;

  /// 응원 문구 글자 크기 선택지입니다.
  ///
  /// In ko, this message translates to:
  /// **'큰 글씨'**
  String get settings_cheersLarge;

  /// 채움이 끝까지 찼을 때 화면을 흔들지 고르는 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'가득 찰 때 화면 흔들기'**
  String get settings_shakeOnFull;

  /// 기기를 기울여 채움을 쏟아 내는 놀이를 켜고 끄는 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'기울여 쏟기'**
  String get settings_tiltToPour;

  /// 설정의 마음 돌봄 묶음 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'마음 돌봄'**
  String get settings_mindCare;

  /// 누르면 위기 연락처 시트가 열리는 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'마음이 많이 힘들 때'**
  String get settings_mindCareHelp;

  /// 위기 시트의 연락처 이름입니다. 번호 1577-0199 는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'정신건강 위기상담'**
  String get settings_mindCareCenter;

  /// 위기 시트에서 109 와 1577-0199 아래에 붙는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'가까운 정신건강복지센터로 연결합니다'**
  String get settings_mindCareCenterNote;

  /// 위기 시트의 연락처 이름입니다. 번호 109 는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'자살예방 상담전화'**
  String get settings_mindCareSuicide;

  /// 위기 시트의 참여 방법 이름입니다. 지금은 번호가 없어 눌러도 연결되지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡 상담 마들랜'**
  String get settings_mindCareKakao;

  /// 위기 시트의 연락처 이름입니다. 번호 112 는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'경찰'**
  String get settings_mindCarePolice;

  /// 위기 시트의 연락처 이름입니다. 번호 119 는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'응급 의료'**
  String get settings_mindCareMedical;

  /// 설정의 지도 묶음 이름입니다. 3단계 기능입니다.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get settings_map;

  /// 지도에 한 줄 문구도 함께 보낼지 고르는 항목입니다. 기본은 꺼짐입니다.
  ///
  /// In ko, this message translates to:
  /// **'한마디도 보태기'**
  String get settings_mapComment;

  /// 설정의 기록 묶음 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get settings_records;

  /// 누르면 기록 파일을 공유 시트로 내보냅니다.
  ///
  /// In ko, this message translates to:
  /// **'기록 내보내기'**
  String get settings_export;

  /// 누르면 확인 시트가 열리는 위험한 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'모든 기록 지우기'**
  String get settings_deleteAll;

  /// 모든 기록 지우기의 확인 시트 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'모든 기록을 지웁니다'**
  String get settings_deleteConfirmTitle;

  /// 모든 기록 지우기의 확인 시트 본문입니다.
  ///
  /// In ko, this message translates to:
  /// **'달력의 기록, 오늘의 한마디, 두드린 수가 모두 사라집니다. 되돌릴 수 없습니다. 먼저 내보내 두면 나중에 다시 볼 수 있습니다.'**
  String get settings_deleteConfirmBody;

  /// 모든 기록 지우기의 확인 시트에서 실제로 지우는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get settings_deleteConfirmAction;

  /// 설정의 정보 묶음 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settings_about;

  /// 앱 버전 항목의 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settings_version;

  /// 누르면 오픈소스 라이선스 화면이 열립니다.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get settings_licenses;

  /// 개인정보 처리방침 항목의 이름입니다. 링크는 아직 준비 중입니다.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settings_privacy;

  /// 테마 카드 아래에 붙는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'고르면 바로 모든 화면에 적용됩니다.'**
  String get settings_themeNote;

  /// 진동 항목의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'두드릴 때마다, 그리고 가득 찰 때 더 크게 울립니다'**
  String get settings_vibrationDesc;

  /// 소리 항목의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'무음 모드에서는 나지 않습니다'**
  String get settings_soundDesc;

  /// 응원 문구 항목의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'두드린 자리에 짧은 말이 나타납니다'**
  String get settings_cheersDesc;

  /// 가득 찰 때 화면 흔들기의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'끄면 흔들림 없이 문구만 보여 줍니다'**
  String get settings_shakeDesc;

  /// 기울여 쏟기의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'폰을 기울이면 물이 넘친 만큼 쏟아지고 두드린 수도 줄어듭니다'**
  String get settings_pourDesc;

  /// 저녁 알림의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록하지 않은 날 한 번만 알려 줍니다'**
  String get settings_reminderDesc;

  /// 지도에 내 기분 보태기의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'약 5km² 넓이의 동네 칸으로 묶어 보내고, 5명이 안 되는 칸은 보이지 않습니다'**
  String get settings_mapContributeDesc;

  /// 한마디도 보태기의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'준비된 문장 중에서 고른 한마디만 보냅니다. 직접 쓴 말은 기기에만 남습니다'**
  String get settings_mapCommentDesc;

  /// 기록 내보내기의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'달력의 기록을 파일 하나로 저장합니다'**
  String get settings_exportDesc;

  /// 내보내기를 마치고 잠깐 뜨는 알림입니다.
  ///
  /// In ko, this message translates to:
  /// **'기록을 파일로 저장했습니다'**
  String get settings_exportDone;

  /// 마음이 많이 힘들 때 항목의 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'24시간 이야기를 들어 주는 곳에 바로 연결합니다'**
  String get settings_mindCareRowDesc;

  /// 위기 시트의 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'혼자 견디지 않아도 됩니다'**
  String get settings_mindCareTitle;

  /// 위기 시트의 첫 안내 문장입니다.
  ///
  /// In ko, this message translates to:
  /// **'지금 많이 힘들다면 이야기를 들어 줄 사람이 있습니다. 무료이고, 이름을 말하지 않아도 됩니다.'**
  String get settings_mindCareIntro;

  /// 자살예방 상담전화 아래에 붙는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'24시간 상담'**
  String get settings_mindCareSuicideNote;

  /// 카카오톡 상담 마들랜 아래에 붙는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'전화가 어려우면 글로 이야기합니다. 24시간'**
  String get settings_mindCareKakaoNote;

  /// 위기 시트 맨 아래에 늘 보이는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'당장 위험하다면 119 또는 112에 전화합니다. 이 앱은 의료기기가 아니며 진료를 대신하지 않습니다.'**
  String get settings_mindCareFootnote;

  /// 위기 시트를 닫는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get settings_close;

  /// 기기 지역이 일본일 때 보이는 일본 상담 이름입니다. 번호는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'#이노치SOS'**
  String get settings_mindCareSosJapan;

  /// 기기 지역이 일본일 때 보이는 일본 상담 이름입니다. 번호는 코드의 상수에서 옵니다.
  ///
  /// In ko, this message translates to:
  /// **'요리소이 상담전화(일본)'**
  String get settings_mindCareYorisoiJapan;

  /// 기분 고르기 화면의 지도 버튼 숨김 이름(접근성)입니다. 설정에서 지도 보기를 켠 때만 보입니다.
  ///
  /// In ko, this message translates to:
  /// **'지도 보기'**
  String get map_openLabel;

  /// 지도 아래 시트의 기본 제목입니다. 아무 동네도 고르지 않았을 때 보입니다.
  ///
  /// In ko, this message translates to:
  /// **'내 주변 3km'**
  String get map_nearby;

  /// 지도 아래 시트에서 동네 하나를 골랐을 때 제목 위에 붙는 작은 글씨입니다.
  ///
  /// In ko, this message translates to:
  /// **'고른 동네'**
  String get map_pickedPlace;

  /// 지도 아래 시트의 설명입니다. 묶는 단위 약 5km²(H3 해상도 7) 와 숨기는 기준 5명이 규칙과 같아야 합니다.
  ///
  /// In ko, this message translates to:
  /// **'글씨는 사람들이 고른 한마디이고, 크기는 그 동네에서 두드린 수입니다. 약 5km² 넓이의 동네 칸으로 묶고, 5명이 안 되는 칸은 보이지 않습니다.'**
  String get map_explain;

  /// 지도 위 범위 전환의 오늘 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get map_rangeToday;

  /// 지도 위 범위 전환의 이번 주 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get map_rangeWeek;

  /// 지도에서 내 자리를 가리키는 점의 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'내 위치'**
  String get map_you;

  /// 고른 동네의 두드린 횟수입니다.
  ///
  /// In ko, this message translates to:
  /// **'{count}번 두드렸습니다'**
  String map_tapsLine(int count);

  /// 지도에 보이는 동네 전체에서 기분을 남긴 사람 수입니다. 행복 슬픔 비율을 켠 때만 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'{count}명이 남겼습니다'**
  String map_peopleLine(int count);

  /// 지도 아래 시트의 제목입니다. 행복 슬픔 비율을 켠 때만 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'행복한 쪽이 {percent}%'**
  String map_happySide(int percent);

  /// 지도 아래 시트의 제목입니다. 슬픈 쪽이 더 많을 때입니다. 행복 슬픔 비율을 켠 때만 씁니다.
  ///
  /// In ko, this message translates to:
  /// **'슬픈 쪽이 {percent}%'**
  String map_sadSide(int percent);

  /// 지도의 한마디 글씨 하나의 숨김 이름(접근성)입니다.
  ///
  /// In ko, this message translates to:
  /// **'{word}, {count}번 두드림'**
  String map_spotLabel(String word, int count);

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 웃었다'**
  String get map_wordSmiled;

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'조금 쉬고 싶다'**
  String get map_wordRest;

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'맛있는 걸 먹었다'**
  String get map_wordAteWell;

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'생각보다 괜찮았다'**
  String get map_wordBetterThanExpected;

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'내일도 이렇게'**
  String get map_wordTomorrowToo;

  /// 지도에 쓰는 준비된 한마디입니다.
  ///
  /// In ko, this message translates to:
  /// **'고마운 사람이 있었다'**
  String get map_wordThankful;

  /// 설정의 지도 구역에서 지도 화면 진입점을 켜고 끄는 스위치입니다.
  ///
  /// In ko, this message translates to:
  /// **'지도 보기'**
  String get settings_mapView;

  /// 지도 보기 스위치 설명입니다.
  ///
  /// In ko, this message translates to:
  /// **'켜 두면 기분 고르기 화면에 지도 버튼이 보입니다. 끄면 보이지 않습니다'**
  String get settings_mapViewDesc;

  /// 지도 아래 시트 제목입니다. 비율 표시를 공통성 문구로 고르고, 그 범위에서 슬픈 쪽이 더 많을 때 씁니다. 숫자와 순위를 쓰지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 마음이 가라앉은 사람이 나만은 아닙니다'**
  String get map_togetherSad;

  /// 지도 아래 시트 제목입니다. 비율 표시를 공통성 문구로 고르고, 그 범위에서 행복한 쪽이 더 많을 때 씁니다. 숫자와 순위를 쓰지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기분이 좋은 사람이 가까이에 많습니다'**
  String get map_togetherHappy;

  /// 기분 고르기 화면의 큰 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'오늘 기분은'**
  String get moodSelect_title;

  /// 첫 화면에서 기록을 읽는 동안 로고 아래에 보이는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오는 중입니다'**
  String get loading_message;

  /// 달력 위 요약의 기록 일수 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get calendar_recordedDays;

  /// 달력 위 요약의 도장 횟수 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'도장'**
  String get calendar_stamps;

  /// 달력 기록 일수 단위입니다.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calendar_daysUnit;

  /// 달력 도장 횟수 단위입니다.
  ///
  /// In ko, this message translates to:
  /// **'번'**
  String get calendar_stampsUnit;

  /// 달력 아래 월간 막대그래프 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'이달의 흐름'**
  String get calendar_monthFlow;

  /// 달력 월간 막대그래프 오른쪽 보조 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'두드린 수'**
  String get calendar_tapsAxis;

  /// 달력 아래 고른 날 카드의 두드린 수 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'{count}번 두드렸습니다'**
  String calendar_tappedTimes(int count);

  /// 달력 도장 첫째 줄입니다.
  ///
  /// In ko, this message translates to:
  /// **'참 잘'**
  String get calendar_stampLine1;

  /// 달력 도장 둘째 줄입니다.
  ///
  /// In ko, this message translates to:
  /// **'했어요'**
  String get calendar_stampLine2;

  /// 그날 상세 위 카드의 작은 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'이날의 기분'**
  String get dayDetail_moodHeading;

  /// 그날 상세 위 카드의 부제입니다.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 두드린 기분입니다'**
  String get dayDetail_dominantCaption;

  /// 그날 상세 아래 주간 막대그래프 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 돌아보기'**
  String get dayDetail_weekReview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
