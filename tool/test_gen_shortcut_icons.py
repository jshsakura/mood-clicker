"""Pin that the shortcut icons match the mood faces and tokens, and that they follow them."""
import copy
import re
import unittest

from gen_shortcut_icons import MOODS, ROOT, android_xml, icon_name, ios_svg, outputs, stale
from gen_tokens import load

TOKENS = load()


class Current(unittest.TestCase):
    def test_generated_files_are_up_to_date(self):
        self.assertEqual(stale(outputs(TOKENS)), [], "run python3 tool/gen_shortcut_icons.py")

    def test_every_mood_has_android_and_ios_files(self):
        for mood in MOODS:
            name = icon_name(mood)
            self.assertTrue((ROOT / f"android/app/src/main/res/drawable/{name}.xml").is_file(), name)
            self.assertTrue((ROOT / f"ios/Runner/Assets.xcassets/{name}.imageset/{name}.svg").is_file(), name)
            self.assertTrue((ROOT / f"ios/Runner/Assets.xcassets/{name}.imageset/Contents.json").is_file(), name)

    def test_the_mood_list_is_the_dart_enum(self):
        enum = (ROOT / "lib/domain/mood.dart").read_text(encoding="utf-8")
        for mood in MOODS:
            self.assertRegex(enum, rf"\b{mood}\b")


class Follows(unittest.TestCase):
    def test_android_color_is_the_light_mood_color(self):
        for mood in MOODS:
            token = TOKENS["light"]["color"][f"mood{mood.capitalize()}"]["$value"].lstrip("#").upper()
            self.assertIn(f'strokeColor="#{token}"', android_xml(mood, TOKENS))

    def test_a_changed_token_changes_the_icon(self):
        t = copy.deepcopy(TOKENS)
        t["light"]["color"]["moodSad"]["$value"] = "#010203"
        self.assertIn("#010203", android_xml("sad", t))
        self.assertNotIn("#010203", android_xml("happy", t))

    def test_every_face_line_reaches_both_platforms(self):
        for mood in MOODS:
            face = (ROOT / f"assets/icons/mood_{mood}.svg").read_text(encoding="utf-8")
            lines = len(re.findall(r"<(?:circle|path)\b", face))
            self.assertEqual(android_xml(mood, TOKENS).count("strokeColor"), lines, mood)
            self.assertEqual(ios_svg(mood).count("<path"), lines, mood)

    def test_ios_icon_has_one_color_only(self):
        for mood in MOODS:
            self.assertNotRegex(ios_svg(mood), r"#(?!000000)[0-9A-Fa-f]{6}")


class Kept(unittest.TestCase):
    def test_resource_shrinking_keeps_the_icons_looked_up_by_name(self):
        keep = (ROOT / "android/app/src/main/res/raw/keep.xml").read_text(encoding="utf-8")
        self.assertIn("@drawable/shortcut_*", keep)

    def test_ci_checks_the_icons(self):
        ci = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn("tool/gen_shortcut_icons.py --check", ci)


if __name__ == "__main__":
    unittest.main()
