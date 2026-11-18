import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/l10n/asset_paths.dart';

void main() {
  Set<String> shipped(Set<String> languages) {
    return {
      for (final language in languages) ...[
        'assets/stamps/$language/well_done.svg',
        'assets/cheers/$language.json',
      ],
    };
  }

  AssetExists existsIn(Set<String> paths) =>
      (String path) => paths.contains(path);

  group('stampAssetPath', () {
    test('uses the language folder when the stamp ships', () {
      final paths = shipped({'ko', 'ja'});
      expect(
        stampAssetPath('ja', existsIn(paths)),
        'assets/stamps/ja/well_done.svg',
      );
    });

    test('falls back to Korean when the language has no stamp', () {
      final paths = shipped({'ko'});
      expect(
        stampAssetPath('fr', existsIn(paths)),
        'assets/stamps/ko/well_done.svg',
      );
    });

    test('honors a custom stamp name', () {
      final paths = {'assets/stamps/en/nice_try.svg'};
      expect(
        stampAssetPath('en', existsIn(paths), name: 'nice_try'),
        'assets/stamps/en/nice_try.svg',
      );
      expect(
        stampAssetPath('ko', existsIn(paths), name: 'nice_try'),
        'assets/stamps/ko/nice_try.svg',
      );
    });
  });

  group('cheersAssetPath', () {
    test('uses the language file when the pack ships', () {
      final paths = shipped({'ko', 'en', 'ja'});
      expect(cheersAssetPath('en', existsIn(paths)), 'assets/cheers/en.json');
    });

    test('falls back to Korean when the language has no pack', () {
      final paths = shipped({'ko', 'en'});
      expect(cheersAssetPath('de', existsIn(paths)), 'assets/cheers/ko.json');
    });
  });
}
