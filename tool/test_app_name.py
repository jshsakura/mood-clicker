"""Pin the working app name on every platform so a rename cannot miss one."""
import plistlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NAME = "Unknown"


class AppName(unittest.TestCase):
    def test_android_label(self):
        manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
        label = re.search(r'android:label="([^"]*)"', manifest).group(1)
        if label != "@string/app_name":
            self.assertEqual(label, NAME)
            return
        files = sorted((ROOT / "android/app/src/main/res").glob("values*/strings.xml"))
        self.assertTrue(files)
        for f in files:
            value = re.search(r'<string name="app_name">([^<]*)</string>', f.read_text(encoding="utf-8")).group(1)
            self.assertEqual(value, NAME, f.parent.name)

    def test_localized_names(self):
        for f in sorted((ROOT / "ios/Runner").glob("*.lproj/InfoPlist.strings")):
            self.assertIn(f'"CFBundleDisplayName" = "{NAME}";', f.read_text(encoding="utf-8"), f.parent.name)
        for f in sorted((ROOT / "lib/l10n").glob("app_*.arb")):
            self.assertIn(f'"appName": "{NAME}"', f.read_text(encoding="utf-8"), f.name)

    def test_ios_display_and_bundle_names(self):
        info = plistlib.loads((ROOT / "ios/Runner/Info.plist").read_bytes())
        self.assertEqual(info["CFBundleDisplayName"], NAME)
        self.assertEqual(info["CFBundleName"], NAME)

    def test_macos_product_name(self):
        config = (ROOT / "macos/Runner/Configs/AppInfo.xcconfig").read_text(encoding="utf-8")
        self.assertEqual(re.search(r"^PRODUCT_NAME\s*=\s*(.+)$", config, re.M).group(1).strip(), NAME)

    def test_flutter_app_title(self):
        main = (ROOT / "lib/app/app.dart").read_text(encoding="utf-8")
        self.assertEqual(re.search(r"title: '([^']*)'", main).group(1), NAME)

    def test_package_id_is_not_renamed(self):
        self.assertIn("name: mood_clicker", (ROOT / "pubspec.yaml").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
