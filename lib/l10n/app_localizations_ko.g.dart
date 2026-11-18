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
  String get common_on => '켜기';

  @override
  String get common_off => '끄기';

  @override
  String get loading_brokenTitle => '기록이 깨졌습니다';

  @override
  String get loading_brokenBody => '저장된 기록을 읽지 못했습니다. 새로 시작하면 빈 기록으로 시작합니다.';

  @override
  String get loading_startNew => '새로 시작합니다';

  @override
  String get moodSelect_today => '오늘';

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
  String get reminder_body => '잠깐 들어와 두드려 보세요';

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
  String get settings_vibrationStrength => '진동 세기';

  @override
  String get settings_sound => '소리';

  @override
  String get settings_soundPack => '소리 묶음';

  @override
  String get settings_reminder => '저녁 알림';

  @override
  String get settings_reminderTime => '알림 시각';

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
  String get settings_strengthWeak => '약';

  @override
  String get settings_strengthNormal => '보통';

  @override
  String get settings_strengthStrong => '세게';

  @override
  String get settings_soundPackBasic => '기본';

  @override
  String get settings_cheers => '응원 문구';

  @override
  String get settings_cheersSize => '글자 크기';

  @override
  String get settings_cheersNormal => '보통';

  @override
  String get settings_cheersLarge => '큰 글씨';

  @override
  String get settings_shakeOnFull => '가득 찰 때 화면 흔들기';

  @override
  String get settings_tiltToPour => '기울여 쏟기';

  @override
  String get settings_mindCare => '마음 돌봄';

  @override
  String get settings_mindCareHelp => '위기 때 도움 요청하기';

  @override
  String get settings_mindCareCenter => '정신건강 상담전화';

  @override
  String get settings_mindCareCenterNote => '가까운 정신건강복지센터로 연결합니다';

  @override
  String get settings_mindCareSuicide => '자살예방 상담전화';

  @override
  String get settings_mindCareKakao => '카카오톡 마들랜';

  @override
  String get settings_mindCarePolice => '경찰';

  @override
  String get settings_mindCareMedical => '응급 의료';

  @override
  String get settings_notMedical => '이 앱은 의료기기가 아니며 진료를 대신하지 않습니다';

  @override
  String get settings_map => '지도';

  @override
  String get settings_mapComment => '한마디도 보태기';

  @override
  String get settings_mapCommentNote => '고른 준비 문장만 보냅니다';

  @override
  String get settings_records => '기록';

  @override
  String get settings_export => '기록 내보내기';

  @override
  String get settings_deleteAll => '모든 기록 지우기';

  @override
  String get settings_deleteConfirmTitle => '기록을 지웁니다';

  @override
  String get settings_deleteConfirmBody => '지난 날들의 기록이 모두 사라집니다. 되돌릴 수 없습니다.';

  @override
  String get settings_deleteConfirmAction => '지웁니다';

  @override
  String get settings_about => '정보';

  @override
  String get settings_version => '버전';

  @override
  String get settings_licenses => '오픈소스 라이선스';

  @override
  String get settings_privacy => '개인정보 처리방침';

  @override
  String get settings_privacyPending => '준비 중입니다';

  @override
  String get settings_mapContribute => '지도에 내 기분 보태기';
}
