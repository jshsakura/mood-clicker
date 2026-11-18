import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/settings/crisis_contacts.dart';

void main() {
  test('the Korean crisis numbers are pinned', () {
    expect(crisisPhoneNumbers, const {
      'suicidePrevention': '109',
      'mentalHealthCenter': '1577-0199',
      'police': '112',
      'medical': '119',
    });
  });

  test('the Japanese crisis numbers are pinned', () {
    expect(japanCrisisPhoneNumbers, const {
      'suicidePrevention': '0120-061-338',
      'mentalHealthCenter': '0120-279-338',
    });
  });

  test('the region follows the device country code', () {
    expect(crisisRegionOf('JP'), CrisisRegion.japan);
    expect(crisisRegionOf('jp'), CrisisRegion.japan);
    expect(crisisRegionOf('KR'), CrisisRegion.korea);
    expect(crisisRegionOf('us'), CrisisRegion.unitedStates);
  });

  test('the Korean set carries the pinned numbers', () {
    for (final entry in crisisEntriesFor(CrisisRegion.korea)) {
      if (entry.number != null) {
        expect(crisisPhoneNumbers.containsValue(entry.number), isTrue);
      }
    }
  });

  test('the Japan set carries the pinned numbers', () {
    for (final entry in crisisEntriesFor(CrisisRegion.japan)) {
      expect(japanCrisisPhoneNumbers.containsValue(entry.number), isTrue);
    }
  });

  test('GB, no region and unknown codes never get a Korean number', () {
    for (final code in ['GB', null, '', 'ZZ', 'DE']) {
      expect(crisisRegionOf(code), CrisisRegion.other, reason: '$code');
    }
    for (final entry in crisisEntriesFor(CrisisRegion.other)) {
      expect(entry.number, isNull);
      expect(entry.textNumber, isNull);
      expect(entry.launchUrl, helplineDirectoryUrl);
    }
  });

  test('the United States gets 988 by call and by text', () {
    final entries = crisisEntriesFor(CrisisRegion.unitedStates);
    expect(entries.map((e) => e.launchUrl), ['tel:988', 'sms:988']);
  });

  test('no region leaks the numbers of another', () {
    final korean = crisisPhoneNumbers.values.toSet();
    final japanese = japanCrisisPhoneNumbers.values.toSet();
    for (final region in [CrisisRegion.unitedStates, CrisisRegion.other]) {
      for (final entry in crisisEntriesFor(region)) {
        expect(korean, isNot(contains(entry.number)));
        expect(japanese, isNot(contains(entry.number)));
      }
    }
  });
}
