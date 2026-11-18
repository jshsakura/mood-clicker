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
    expect(crisisRegionOf(null), CrisisRegion.korea);
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
}
