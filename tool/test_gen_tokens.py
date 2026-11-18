"""gen_tokens 가 디자이너의 실수를 분명한 말로 막는지 고정한다."""
import copy
import json
import unittest
from pathlib import Path

from gen_tokens import SRC, TokenError, render

BASE = json.loads(Path(SRC).read_text(encoding="utf-8"))


class Renders(unittest.TestCase):
    def test_real_tokens_render_every_theme(self):
        out = render(BASE)
        for theme in BASE["color"]:
            self.assertIn(f"const AppPalette {theme}Palette", out)

    def test_new_color_becomes_a_field_on_every_theme(self):
        t = copy.deepcopy(BASE)
        for theme in t["color"].values():
            theme["glow"] = {"$type": "color", "$value": "#112233"}
        out = render(t)
        self.assertIn("final Color glow;", out)
        self.assertIn("glow: Color(0xFF112233)", out)

    def test_alpha_hex_moves_alpha_to_front(self):
        t = copy.deepcopy(BASE)
        t["color"]["dark"]["line"]["$value"] = "#11223380"
        self.assertIn("line: Color(0x80112233)", render(t))


class Refuses(unittest.TestCase):
    def assertRefuses(self, tokens, fragment):
        with self.assertRaises(TokenError) as cm:
            render(tokens)
        self.assertIn(fragment, str(cm.exception))

    def test_color_missing_from_one_theme(self):
        t = copy.deepcopy(BASE)
        del t["color"]["pink"]["sad"]
        self.assertRefuses(t, "color.pink")

    def test_bad_hex(self):
        t = copy.deepcopy(BASE)
        t["color"]["light"]["ink"]["$value"] = "black"
        self.assertRefuses(t, "color.light.ink")

    def test_bad_duration(self):
        t = copy.deepcopy(BASE)
        t["motion"]["tap"]["$value"] = "fast"
        self.assertRefuses(t, "motion.tap")

    def test_bad_weight(self):
        t = copy.deepcopy(BASE)
        t["type"]["body"]["$value"]["fontWeight"] = 450
        self.assertRefuses(t, "type.body.fontWeight")


if __name__ == "__main__":
    unittest.main()
