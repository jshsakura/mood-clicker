"""Pin that the Dart side and the native widget code agree on names, keys and colors.

The native code (Kotlin, Swift) cannot run here, so a typo in a shared name would only show on a
device. These checks read the sources and compare the shared strings.
"""
import plistlib
import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android/app/src/main"
KOTLIN = ANDROID / "kotlin/com/example/mood_clicker/MoodWidgetProvider.kt"
SWIFT = ROOT / "ios/MoodWidget/MoodWidget.swift"
ADAPTERS = ROOT / "lib/surfaces/home_widget_adapters.dart"
LINKS = ROOT / "lib/surfaces/mood_links.dart"
SNAPSHOT = ROOT / "lib/surfaces/widget_snapshot.dart"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


def text(path):
    return path.read_text(encoding="utf-8")


def dart_const(path, name):
    return re.search(rf"const String {name} = '([^']*)';", text(path)).group(1)


class SharedNames(unittest.TestCase):
    def test_the_link_scheme_is_registered_on_ios(self):
        scheme = dart_const(LINKS, "appLinkScheme")
        info = plistlib.loads((ROOT / "ios/Runner/Info.plist").read_bytes())
        schemes = [s for t in info["CFBundleURLTypes"] for s in t["CFBundleURLSchemes"]]
        self.assertIn(scheme, schemes)

    def test_the_app_group_is_the_same_everywhere(self):
        group = dart_const(ADAPTERS, "widgetAppGroupId")
        self.assertIn(f'"{group}"', text(SWIFT))
        for name in ("Runner/Runner.entitlements", "MoodWidget/MoodWidget.entitlements"):
            entitlements = plistlib.loads((ROOT / "ios" / name).read_bytes())
            self.assertEqual(entitlements["com.apple.security.application-groups"], [group], name)

    def test_the_android_widget_class_matches_the_dart_name_and_the_manifest(self):
        name = dart_const(ADAPTERS, "androidWidgetName")
        self.assertIn(f"class {name} : HomeWidgetProvider()", text(KOTLIN))
        manifest = ET.parse(ANDROID / "AndroidManifest.xml").getroot()
        receivers = {r.get(f"{ANDROID_NS}name"): r for r in manifest.iter("receiver")}
        receiver = receivers[f".{name}"]
        self.assertEqual(receiver.get(f"{ANDROID_NS}exported"), "true")
        meta = receiver.find("meta-data")
        self.assertEqual(meta.get(f"{ANDROID_NS}resource"), "@xml/mood_widget_info")

    def test_the_ios_widget_kind_matches_the_dart_name(self):
        kind = dart_const(ADAPTERS, "iosWidgetKind")
        self.assertIn(f'let kind = "{kind}"', text(SWIFT))

    def test_both_native_widgets_read_the_keys_dart_writes(self):
        written = set(re.findall(r"'(\w+)':", text(SNAPSHOT).split("toData()")[1])) | {dart_const(ADAPTERS, "faceImageKey")}
        self.assertEqual(written, {"day", "mood", "count", "link", "face_png"})
        for source in (KOTLIN, SWIFT):
            for key in ("day", "count", "link", "face_png"):
                self.assertIn(f'"{key}"', text(source), f"{source.name} lacks {key}")


class AndroidResources(unittest.TestCase):
    def test_the_layout_and_info_files_point_at_real_resources(self):
        colors = {c.get("name") for c in ET.parse(ANDROID / "res/values/colors.xml").getroot()}
        for rel in ("res/layout/mood_widget.xml", "res/drawable/widget_background.xml"):
            for ref in re.findall(r"@color/(\w+)", text(ANDROID / rel)):
                self.assertIn(ref, colors, f"{rel} uses @color/{ref}")
        info = ET.parse(ANDROID / "res/xml/mood_widget_info.xml").getroot()
        self.assertEqual(info.get(f"{ANDROID_NS}initialLayout"), "@layout/mood_widget")
        self.assertEqual(info.get(f"{ANDROID_NS}description"), "@string/widget_description")

    def test_the_widget_description_is_translated(self):
        for values in ("values", "values-ko", "values-ja"):
            strings = {s.get("name") for s in ET.parse(ANDROID / f"res/{values}/strings.xml").getroot()}
            self.assertIn("widget_description", strings, values)

    def test_android_strings_escape_apostrophes(self):
        """aapt rejects a bare apostrophe in a string resource, and the build fails late."""
        for values in ("values", "values-ko", "values-ja"):
            for string in ET.parse(ANDROID / f"res/{values}/strings.xml").getroot():
                self.assertNotRegex(string.text or "", r"(?<!\\)'", f"{values}/{string.get('name')}")

    def test_the_widget_uses_only_generated_colors_and_no_gradient(self):
        for rel in ("res/layout/mood_widget.xml", "res/drawable/widget_background.xml"):
            body = re.sub(r"<!--.*?-->", "", text(ANDROID / rel), flags=re.S)
            self.assertNotRegex(body, r'"#[0-9A-Fa-f]{3,8}"', f"{rel} has a color literal")
            self.assertNotIn("gradient", body.lower(), rel)

    def test_the_ios_widget_uses_only_generated_colors_and_no_gradient(self):
        body = text(SWIFT)
        self.assertNotRegex(body, r"Color\(\s*(red|white|hex)")
        self.assertNotRegex(body, r"Gradient|\.shadow\(|\.blur\(")
        self.assertIn("WidgetColors.ground", body)
        self.assertIn("WidgetColors.ink", body)


if __name__ == "__main__":
    unittest.main()
