// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Unknown';

  @override
  String get common_back => '뒤로';

  @override
  String get common_cancel => '취소';

  @override
  String get loading_brokenTitle => '기록이 깨졌습니다';

  @override
  String get loading_brokenBody => '저장된 기록을 읽지 못했습니다. 새로 시작하면 빈 기록으로 시작합니다.';

  @override
  String get loading_startNew => '새로 시작합니다';

  @override
  String get moodSelect_moodHappy => '행복해요';

  @override
  String get moodSelect_moodExcited => '설레요';

  @override
  String get moodSelect_moodAngry => '화나요';

  @override
  String get moodSelect_moodSad => '슬퍼요';

  @override
  String get moodSelect_moodAnxious => '불안해요';

  @override
  String get tap_todayLabel => '오늘 두드린 수';

  @override
  String tap_todayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 $count',
    );
    return '$_temp0';
  }

  @override
  String get calendar_prevMonth => '지난달';

  @override
  String get calendar_nextMonth => '다음 달';

  @override
  String get dayDetail_happySide => '행복 쪽';

  @override
  String get dayDetail_sadSide => '슬픔 쪽';

  @override
  String dayDetail_moodCount(String mood, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count번',
    );
    return '$mood $_temp0';
  }

  @override
  String get review_thisWeek => '이번 주';

  @override
  String get review_thisMonth => '이번 달';

  @override
  String review_ratioLine(int happy, int sad) {
    return '행복 쪽 $happy% · 슬픔 쪽 $sad%';
  }

  @override
  String review_topMood(String mood) {
    return '가장 많았던 기분: $mood';
  }

  @override
  String review_mostTappedDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '가장 많이 두드린 날: $dateString';
  }

  @override
  String get review_trendUp => '지난 기간보다 행복 쪽이 늘었습니다';

  @override
  String get review_trendDown => '지난 기간보다 행복 쪽이 줄었습니다';

  @override
  String get review_trendSame => '지난 기간과 비슷합니다';

  @override
  String get map_title => '내 주변 오늘';

  @override
  String map_legendLine(int happy, int sad) {
    return '행복 $happy% · 슬픔 $sad%';
  }

  @override
  String get map_permissionReason => '동네 기분 지도를 보려면 위치가 필요합니다';

  @override
  String get reminder_title => '오늘 기분은 어땠나요?';

  @override
  String get reminder_body => '잠깐 들러 오늘 마음을 남겨 보세요';

  @override
  String get settings_title => '설정';

  @override
  String get settings_theme => '테마';

  @override
  String get settings_themeSystem => '시스템 따라가기';

  @override
  String get settings_themeLight => '라이트';

  @override
  String get settings_themeDark => '다크';

  @override
  String get settings_themePink => '핑크';

  @override
  String get settings_language => '언어';

  @override
  String get settings_languageSystem => '기기 언어';

  @override
  String get settings_languageKo => '한국어';

  @override
  String get settings_languageEn => 'English';

  @override
  String get settings_languageJa => '日本語';

  @override
  String get settings_vibration => '진동';

  @override
  String get settings_sound => '소리';

  @override
  String get settings_reminder => '저녁 알림';

  @override
  String get settings_mapContribute => '지도에 내 기분 보태기';

  @override
  String get moodSelect_openCalendar => '달력 보기';

  @override
  String get note_title => '오늘 한마디';

  @override
  String get note_hint => '한 줄로 남겨 보세요';

  @override
  String get note_skip => '건너뛰기';

  @override
  String get note_save => '남기기';

  @override
  String get note_presetLabel => '이런 말은 어때요';

  @override
  String get note_presetProud => '뿌듯한 하루였어요';

  @override
  String get note_presetCalm => '마음이 차분했어요';

  @override
  String get note_presetThanks => '고마운 일이 있었어요';

  @override
  String get note_presetHard => '힘들었지만 버텼어요';

  @override
  String get note_presetTired => '많이 피곤했어요';

  @override
  String get note_presetRest => '푹 쉬고 싶어요';

  @override
  String get dayDetail_note => '한마디';

  @override
  String get dayDetail_empty => '이날은 기록이 없습니다';

  @override
  String calendar_openDay(String date) {
    return '$date 보기';
  }

  @override
  String get settings_time20 => '오후 8시';

  @override
  String get settings_time21 => '오후 9시';

  @override
  String get settings_time22 => '오후 10시';

  @override
  String get settings_notifications => '알림';

  @override
  String get settings_tapping => '두드리기';

  @override
  String get settings_strengthWeak => '약하게';

  @override
  String get settings_strengthNormal => '보통';

  @override
  String get settings_strengthStrong => '세게';

  @override
  String get settings_soundPackBasic => '기본';

  @override
  String get settings_soundPackPentatonic => '펜타토닉';

  @override
  String get settings_cheers => '응원 문구';

  @override
  String get settings_cheersNormal => '보통 글씨';

  @override
  String get settings_cheersLarge => '큰 글씨';

  @override
  String get settings_shakeOnFull => '가득 찰 때 화면 흔들기';

  @override
  String get settings_tiltToPour => '기울여 쏟기';

  @override
  String get settings_mindCare => '마음 돌봄';

  @override
  String get settings_mindCareHelp => '마음이 많이 힘들 때';

  @override
  String get settings_mindCareCenter => '정신건강 위기상담';

  @override
  String get settings_mindCareCenterNote => '가까운 정신건강복지센터로 연결합니다';

  @override
  String get settings_mindCareSuicide => '자살예방 상담전화';

  @override
  String get settings_mindCareKakao => '카카오톡 상담 마들랜';

  @override
  String get settings_mindCarePolice => '경찰';

  @override
  String get settings_mindCareMedical => '응급 의료';

  @override
  String get settings_map => '지도';

  @override
  String get settings_mapComment => '한마디도 보태기';

  @override
  String get settings_records => '기록';

  @override
  String get settings_export => '기록 내보내기';

  @override
  String get settings_deleteAll => '모든 기록 지우기';

  @override
  String get settings_deleteConfirmTitle => '모든 기록을 지웁니다';

  @override
  String get settings_deleteConfirmBody =>
      '달력의 기록, 오늘의 한마디, 두드린 수가 모두 사라집니다. 되돌릴 수 없습니다. 먼저 내보내 두면 나중에 다시 볼 수 있습니다.';

  @override
  String get settings_deleteConfirmAction => '지우기';

  @override
  String get settings_about => '정보';

  @override
  String get settings_version => '버전';

  @override
  String get settings_licenses => '오픈소스 라이선스';

  @override
  String get settings_privacy => '개인정보 처리방침';

  @override
  String get settings_themeNote => '고르면 바로 모든 화면에 적용됩니다.';

  @override
  String get settings_vibrationDesc => '두드릴 때마다, 그리고 가득 찰 때 더 크게 울립니다';

  @override
  String get settings_soundDesc => '무음 모드에서는 나지 않습니다';

  @override
  String get settings_cheersDesc => '두드린 자리에 짧은 말이 나타납니다';

  @override
  String get settings_shakeDesc => '끄면 흔들림 없이 문구만 보여 줍니다';

  @override
  String get settings_pourDesc => '폰을 기울이면 물이 넘친 만큼 쏟아지고 두드린 수도 줄어듭니다';

  @override
  String get settings_reminderDesc => '아직 기록하지 않은 날 한 번만 알려 줍니다';

  @override
  String get settings_mapContributeDesc =>
      '약 5km² 넓이의 동네 칸으로 묶어 보내고, 5명이 안 되는 칸은 보이지 않습니다';

  @override
  String get settings_mapCommentDesc =>
      '준비된 문장 중에서 고른 한마디만 보냅니다. 직접 쓴 말은 기기에만 남습니다';

  @override
  String get settings_exportDesc => '달력의 기록을 파일 하나로 저장합니다';

  @override
  String get settings_exportDone => '기록을 파일로 저장했습니다';

  @override
  String get settings_mindCareRowDesc => '24시간 이야기를 들어 주는 곳에 바로 연결합니다';

  @override
  String get settings_mindCareTitle => '혼자 견디지 않아도 됩니다';

  @override
  String get settings_mindCareIntro =>
      '지금 많이 힘들다면 이야기를 들어 줄 사람이 있습니다. 무료이고, 이름을 말하지 않아도 됩니다.';

  @override
  String get settings_mindCareSuicideNote => '24시간 상담';

  @override
  String get settings_mindCareKakaoNote => '전화가 어려우면 글로 이야기합니다. 24시간';

  @override
  String get settings_mindCareFootnote =>
      '당장 위험하다면 119 또는 112에 전화합니다. 이 앱은 의료기기가 아니며 진료를 대신하지 않습니다.';

  @override
  String get settings_close => '닫기';

  @override
  String get settings_mindCareSosJapan => '#이노치SOS';

  @override
  String get settings_mindCareYorisoiJapan => '요리소이 상담전화(일본)';

  @override
  String get map_openLabel => '지도 보기';

  @override
  String get map_nearby => '이 지도 안';

  @override
  String get map_pickedPlace => '고른 동네';

  @override
  String get map_explain =>
      '얼굴은 그 동네 칸의 대표 기분이고, 숫자는 남긴 사람 수입니다. 약 5km² 넓이의 칸으로 묶고, 5명이 안 되는 칸은 보이지 않습니다.';

  @override
  String get map_rangeToday => '오늘';

  @override
  String get map_rangeWeek => '이번 주';

  @override
  String get map_you => '내 위치';

  @override
  String map_tapsLine(int count) {
    return '$count번 두드렸습니다';
  }

  @override
  String map_peopleLine(int count) {
    return '$count명이 남겼습니다';
  }

  @override
  String map_happySide(int percent) {
    return '행복한 쪽이 $percent%';
  }

  @override
  String map_sadSide(int percent) {
    return '슬픈 쪽이 $percent%';
  }

  @override
  String map_spotLabel(String word, int count) {
    return '$word, $count번 두드림';
  }

  @override
  String get map_wordSmiled => '오늘은 웃었다';

  @override
  String get map_wordRest => '조금 쉬고 싶다';

  @override
  String get map_wordAteWell => '맛있는 걸 먹었다';

  @override
  String get map_wordBetterThanExpected => '생각보다 괜찮았다';

  @override
  String get map_wordTomorrowToo => '내일도 이렇게';

  @override
  String get map_wordThankful => '고마운 사람이 있었다';

  @override
  String get settings_mapView => '지도 보기';

  @override
  String get settings_mapViewDesc => '켜 두면 기분 고르기 화면에 지도 버튼이 보입니다. 끄면 보이지 않습니다';

  @override
  String get map_togetherSad => '오늘 마음이 가라앉은 사람이 나만은 아닙니다';

  @override
  String get map_togetherHappy => '오늘 기분이 좋은 사람이 가까이에 많습니다';

  @override
  String get moodSelect_title => '오늘 기분은';

  @override
  String get loading_message => '기록을 불러오는 중입니다';

  @override
  String get calendar_recordedDays => '기록';

  @override
  String get calendar_stamps => '도장';

  @override
  String get calendar_daysUnit => '일';

  @override
  String get calendar_stampsUnit => '번';

  @override
  String get calendar_monthFlow => '이달의 흐름';

  @override
  String get calendar_tapsAxis => '두드린 수';

  @override
  String calendar_tappedTimes(int count) {
    return '$count번 두드렸습니다';
  }

  @override
  String calendar_noteQuote(String note) {
    return '“$note”';
  }

  @override
  String get calendar_stampLine1 => '참 잘';

  @override
  String get calendar_stampLine2 => '했어요';

  @override
  String get dayDetail_moodHeading => '이날의 기분';

  @override
  String get dayDetail_dominantCaption => '가장 많이 두드린 기분입니다';

  @override
  String get dayDetail_weekReview => '이번 주 돌아보기';

  @override
  String get settings_exportEmpty => '내보낼 기록이 아직 없습니다';

  @override
  String get calendar_today => '오늘';

  @override
  String get calendar_emptyMonth => '이달에는 기록이 없습니다';

  @override
  String get dayDetail_addNote => '한마디 남기기';

  @override
  String get dayDetail_editNote => '한마디 고치기';

  @override
  String get map_empty => '아직 주변에 남긴 기록이 없습니다';

  @override
  String get map_sampleNotice => '지금은 둘러보기용 표본 지도입니다';

  @override
  String get tap_hint => '화면 어디든 두드립니다';

  @override
  String get note_reason => '끝까지 채웠습니다. 오늘을 한 줄로 남깁니다.';

  @override
  String get note_privacy =>
      '직접 쓴 말은 이 기기에만 남습니다. 위 문장 중에서 고른 것만 지도에 이름 없이 보입니다.';

  @override
  String get note_saveFailed => '저장하지 못했습니다. 잠시 뒤 다시 눌러 주세요. 쓴 글은 그대로 있습니다.';

  @override
  String get tap_action => '두드리기';

  @override
  String get settings_mindCareUs988 => '988 자살 및 위기 상담 전화(미국)';

  @override
  String get settings_mindCareUs988Text => '988 문자 상담(미국)';

  @override
  String get settings_mindCareFindHelpline => '지금 계신 나라의 상담 전화 찾기';

  @override
  String get settings_mindCareFindHelplineNote =>
      '나라별 무료 상담 전화를 모아 둔 사이트가 열립니다';

  @override
  String get settings_mindCareFootnoteJapan =>
      '당장 위험하다면 110 또는 119에 전화합니다. 이 앱은 의료기기가 아니며 진료를 대신하지 않습니다.';

  @override
  String get settings_mindCareFootnoteUs =>
      '당장 위험하다면 911에 전화합니다. 이 앱은 의료기기가 아니며 진료를 대신하지 않습니다.';

  @override
  String get settings_mindCareFootnoteOther =>
      '당장 위험하다면 지금 계신 나라의 긴급 번호에 전화합니다. 이 앱은 의료기기가 아니며 진료를 대신하지 않습니다.';

  @override
  String get settings_mindCareCopyFallback =>
      '앱을 열지 못해 번호를 복사해 두었습니다. 전화나 문자 앱에 붙여 넣어 주세요.';

  @override
  String note_titleOn(String date) {
    return '$date 한마디';
  }

  @override
  String get settings_deleteFailed =>
      '기록을 지우지 못했습니다. 잠시 뒤 다시 시도해 주세요. 기록은 그대로 남아 있습니다.';

  @override
  String get release_settleAngry => '충분히 두드렸어요. 잠시 숨을 골라 볼까요?';

  @override
  String get release_settleSad => '여기까지 왔어요. 지금 이대로도 괜찮아요.';

  @override
  String get release_settleAnxious => '잠시 쉬어 가도 괜찮아요. 숨을 따라 해도, 안 해도 됩니다.';

  @override
  String get release_breathingRing =>
      '숨 고르기를 돕는 원입니다. 커질 때 들이쉬고 작아질 때 내쉬어도 좋고, 따라 하지 않아도 됩니다.';

  @override
  String get howTo_label => '놀이 방법';

  @override
  String get howTo_title => '놀이 방법';

  @override
  String get howTo_fill => '두드리면 물이 차오릅니다.';

  @override
  String get howTo_rest => '잠시 쉬면 물이 조금씩 내려갑니다.';

  @override
  String get howTo_tilt => '폰을 기울이면 물이 넘쳐 화면의 숫자가 줄어듭니다.';

  @override
  String get howTo_spark => '가끔 반짝이는 특별한 말이 나옵니다.';

  @override
  String get howTo_hold => '95퍼센트에서 100퍼센트 사이를 몇 초 버티면 특별한 보상이 있습니다.';

  @override
  String get howTo_finish => '가득 채우면 기분에 맞는 마무리가 펼쳐집니다.';

  @override
  String get howTo_bubble => '놀이 방법';

  @override
  String get settings_weatherView => '날씨 보기';

  @override
  String get settings_weatherViewDesc =>
      '소수 첫째 자리로 뭉갠 위치로 현재 날씨만 가져옵니다. 끄면 위치도 묻지 않습니다.';

  @override
  String get settings_weatherSource => '날씨 출처';

  @override
  String get weather_clear => '맑음';

  @override
  String get weather_partlyCloudy => '구름 조금';

  @override
  String get weather_cloudy => '흐림';

  @override
  String get weather_rain => '비';

  @override
  String get weather_snow => '눈';

  @override
  String get permission_locationWhenInUse =>
      '앱을 쓰는 동안 소수 첫째 자리로 뭉갠 위치만 날씨를 가져오는 데 씁니다.';

  @override
  String get map_zoomIn => '지도를 조금 더 확대하면 동네 칸이 보입니다';
}
