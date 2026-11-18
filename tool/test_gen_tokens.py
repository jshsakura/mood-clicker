"""gen_tokens 가 디자이너의 실수를 분명한 말로 막는지 고정한다."""
import copy
import unittest

from gen_tokens import TokenError, load, render

BASE = load()
THEMES = [k for k in BASE if k != "core"]


class Renders(unittest.TestCase):
    def test_real_tokens_render_every_theme(self):
        out = render(BASE)
        for theme in THEMES:
            self.assertIn(f"const AppPalette {theme}Palette", out)

    def test_new_color_becomes_a_field_on_every_theme(self):
        t = copy.deepcopy(BASE)
        for theme in THEMES:
            t[theme]["color"]["glow"] = {"$type": "color", "$value": "#112233"}
        out = render(t)
        self.assertIn("final Color glow;", out)
        self.assertIn("glow: Color(0xFF112233)", out)

    def test_alpha_hex_moves_alpha_to_front(self):
        t = copy.deepcopy(BASE)
        t["dark"]["color"]["line"]["$value"] = "#11223380"
        self.assertIn("line: Color(0x80112233)", render(t))


class Resolves(unittest.TestCase):
    def test_typography_reads_font_family_reference(self):
        self.assertIn("fontFamily: 'Pretendard'", render(BASE))

    def test_percent_line_height(self):
        t = copy.deepcopy(BASE)
        t["core"]["type"]["body"]["$value"]["lineHeight"] = "150%"
        self.assertIn("fontSize: 16, fontWeight: FontWeight.w400, height: 1.5", render(t))


class Refuses(unittest.TestCase):
    def assertRefuses(self, tokens, fragment):
        with self.assertRaises(TokenError) as cm:
            render(tokens)
        self.assertIn(fragment, str(cm.exception))

    def test_color_missing_from_one_theme(self):
        t = copy.deepcopy(BASE)
        del t["pink"]["color"]["sad"]
        self.assertRefuses(t, "pink.json")

    def test_bad_hex(self):
        t = copy.deepcopy(BASE)
        t["light"]["color"]["ink"]["$value"] = "black"
        self.assertRefuses(t, "light.color.ink")

    def test_bad_duration(self):
        t = copy.deepcopy(BASE)
        t["core"]["motion"]["tap"]["$value"] = "fast"
        self.assertRefuses(t, "motion.tap")

    def test_unknown_reference(self):
        t = copy.deepcopy(BASE)
        t["core"]["type"]["body"]["$value"]["fontFamily"] = "{font.nope}"
        self.assertRefuses(t, "{font.nope}")

    def test_theme_without_brightness(self):
        t = copy.deepcopy(BASE)
        del t["pink"]["$extensions"]
        self.assertRefuses(t, "brightness")

    def test_bad_weight(self):
        t = copy.deepcopy(BASE)
        t["core"]["type"]["body"]["$value"]["fontWeight"] = "450"
        self.assertRefuses(t, "type.body.fontWeight")


if __name__ == "__main__":
    unittest.main()
