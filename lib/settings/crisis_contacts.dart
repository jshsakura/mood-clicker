/// Crisis support contacts for the mind care sheet.
///
/// Every number lives in one constant per region so the sheet and the tests
/// agree. The Korean numbers serve the default region; a device set to the
/// Japan region shows the Japanese 24 hour lines instead. The KakaoTalk
/// community row has no number; its name is a translated string and it
/// never dials.
library;

/// The region of a crisis contact set.
enum CrisisRegion { korea, japan }

/// Phone numbers of the Korean crisis contacts, keyed for the sheet.
const Map<String, String> crisisPhoneNumbers = {
  'suicidePrevention': '109',
  'mentalHealthCenter': '1577-0199',
  'police': '112',
  'medical': '119',
};

/// Phone numbers shown when the device region is Japan, keyed for the sheet.
const Map<String, String> japanCrisisPhoneNumbers = {
  'suicidePrevention': '0120-061-338',
  'mentalHealthCenter': '0120-279-338',
};

/// The sheet entries of one region: a label key that names the entry in the
/// ARB, an optional phone number and an optional note key.
class CrisisEntry {
  const CrisisEntry({required this.labelKey, this.number, this.noteKey});

  /// The ARB key suffix of the entry name.
  final String labelKey;
  final String? number;
  final String? noteKey;
}

const List<CrisisEntry> koreaCrisisEntries = [
  CrisisEntry(labelKey: 'suicide', number: '109', noteKey: 'SuicideNote'),
  CrisisEntry(labelKey: 'center', number: '1577-0199', noteKey: 'CenterNote'),
  CrisisEntry(labelKey: 'kakao', noteKey: 'KakaoNote'),
];

const List<CrisisEntry> japanCrisisEntries = [
  CrisisEntry(
    labelKey: 'sosJapan',
    number: '0120-061-338',
    noteKey: 'SuicideNote',
  ),
  CrisisEntry(
    labelKey: 'yorisoiJapan',
    number: '0120-279-338',
    noteKey: 'SuicideNote',
  ),
];

/// Picks the crisis set from a device country code: `JP` gets the Japanese
/// lines, everything else the Korean ones.
CrisisRegion crisisRegionOf(String? countryCode) {
  return countryCode != null && countryCode.toUpperCase() == 'JP'
      ? CrisisRegion.japan
      : CrisisRegion.korea;
}

List<CrisisEntry> crisisEntriesFor(CrisisRegion region) {
  return region == CrisisRegion.japan ? japanCrisisEntries : koreaCrisisEntries;
}
