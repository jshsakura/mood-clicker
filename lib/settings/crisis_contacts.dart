/// Crisis support contacts for the mind care sheet.
///
/// Every number lives in this one constant so the sheet and the tests agree.
/// The KakaoTalk community row has no number; its name is a translated
/// string (settings_mindCareKakao) and gets no dial action yet.
library;

/// Phone numbers of the crisis contacts, keyed for the sheet.
const Map<String, String> crisisPhoneNumbers = {
  'suicidePrevention': '109',
  'mentalHealthCenter': '1577-0199',
  'police': '112',
  'medical': '119',
};
