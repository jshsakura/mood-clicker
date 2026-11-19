/// Crisis support contacts for the mind care sheet.
///
/// Every number lives in one constant per region so the sheet and the tests
/// agree. Korea, Japan and the United States have lines of their own. Any
/// other country, and a device that reports none, gets no number at all: a
/// Korean line is no help to someone elsewhere, so the sheet points to a
/// directory of local helplines and to the local emergency number. The
/// KakaoTalk community row has no number; its name is a translated string and
/// it never dials.
library;

/// The region of a crisis contact set.
enum CrisisRegion { korea, japan, unitedStates, other }

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

/// The 988 line of the United States. It takes calls and texts.
const String usCrisisLine = '988';

/// The directory of helplines by country, for every region without a line of its own.
const String helplineDirectoryUrl = 'https://findahelpline.com';

/// The shown name of [helplineDirectoryUrl].
const String helplineDirectoryHost = 'findahelpline.com';

/// The sheet entries of one region: a label key that names the entry in the
/// ARB, what a tap opens, and an optional note key.
class CrisisEntry {
  const CrisisEntry({
    required this.labelKey,
    this.number,
    this.textNumber,
    this.url,
    this.noteKey,
  });

  /// The ARB key suffix of the entry name.
  final String labelKey;

  /// A number a tap dials.
  final String? number;

  /// A number a tap sends a text to.
  final String? textNumber;

  /// A web page a tap opens.
  final String? url;
  final String? noteKey;

  /// The link a tap opens, or null for an entry that does nothing.
  String? get launchUrl {
    if (number != null) return 'tel:$number';
    if (textNumber != null) return 'sms:$textNumber';
    return url;
  }

  /// What the row shows on its right side.
  String? get trailing {
    if (number != null) return number;
    if (textNumber != null) return textNumber;
    return url == null ? null : helplineDirectoryHost;
  }
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

const List<CrisisEntry> unitedStatesCrisisEntries = [
  CrisisEntry(labelKey: 'us988', number: usCrisisLine, noteKey: 'SuicideNote'),
  CrisisEntry(
    labelKey: 'us988Text',
    textNumber: usCrisisLine,
    noteKey: 'SuicideNote',
  ),
];

const List<CrisisEntry> otherCrisisEntries = [
  CrisisEntry(
    labelKey: 'findHelpline',
    url: helplineDirectoryUrl,
    noteKey: 'FindHelplineNote',
  ),
];

/// Picks the crisis set from a device country code. Only `KR`, `JP` and `US`
/// have lines of their own; anything else, and no code at all, is
/// [CrisisRegion.other].
CrisisRegion crisisRegionOf(String? countryCode) {
  return switch (countryCode?.toUpperCase()) {
    'KR' => CrisisRegion.korea,
    'JP' => CrisisRegion.japan,
    'US' => CrisisRegion.unitedStates,
    _ => CrisisRegion.other,
  };
}

List<CrisisEntry> crisisEntriesFor(CrisisRegion region) {
  return switch (region) {
    CrisisRegion.korea => koreaCrisisEntries,
    CrisisRegion.japan => japanCrisisEntries,
    CrisisRegion.unitedStates => unitedStatesCrisisEntries,
    CrisisRegion.other => otherCrisisEntries,
  };
}
