import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/settings/crisis_contacts.dart';

void main() {
  test('the crisis numbers are pinned', () {
    expect(crisisPhoneNumbers, const {
      'suicidePrevention': '109',
      'mentalHealthCenter': '1577-0199',
      'police': '112',
      'medical': '119',
    });
  });
}
