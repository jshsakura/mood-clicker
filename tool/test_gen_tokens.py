"""gen_tokens 가 디자이너의 실수를 분명한 말로 막는지 고정한다."""
import copy
import re
import tempfile
import unittest
from pathlib import Path

from gen_tokens import IDENT, OUT, SRC, TokenError, load, parse_json, render, token_sets

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
        self.assertRefuses(t, "pink")

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

    def test_bad_weight(self):
        t = copy.deepcopy(BASE)
        t["core"]["type"]["body"]["$value"]["fontWeight"] = "450"
        self.assertRefuses(t, "type.body.fontWeight")


DART_RESERVED = """assert break case catch class const continue default do else enum extends
false final finally for if in is new null rethrow return super switch this throw true try var
void while with""".split()


def edited(fn):
    t = copy.deepcopy(BASE)
    fn(t)
    return t


class RefusesWith(unittest.TestCase):
    def assertRefuses(self, tokens, fragment):
        with self.assertRaises(TokenError) as cm:
            render(tokens)
        self.assertIn(fragment, str(cm.exception))


class GroupTypes(RefusesWith):
    def test_each_group_demands_its_own_type(self):
        cases = {
            "light.color.ink": lambda t: t["light"]["color"]["ink"].update({"$type": "dimension"}),
            "space.xs": lambda t: t["core"]["space"]["xs"].update({"$type": "color"}),
            "radius.card": lambda t: t["core"]["radius"]["card"].update({"$type": "duration"}),
            "motion.tap": lambda t: t["core"]["motion"]["tap"].update({"$type": "dimension"}),
            "type.body": lambda t: t["core"]["type"]["body"].update({"$type": "color"}),
            "font.family": lambda t: t["core"]["font"]["family"].update({"$type": "color"}),
        }
        for where, change in cases.items():
            with self.subTest(where):
                self.assertRefuses(edited(change), where)

    def test_unreferenced_font_is_checked_too(self):
        t = edited(lambda t: t["core"]["font"].update({"spare": {"$type": "color", "$value": "Mono"}}))
        self.assertRefuses(t, "font.spare")

    def test_reference_must_point_at_a_font_family(self):
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"fontFamily": "{space.xs}"}))
        self.assertRefuses(t, "type.body.fontFamily")


class Json(unittest.TestCase):
    def test_duplicate_key_is_refused_at_any_depth(self):
        for text in ('{"a": 1, "a": 2}', '{"x": {"a": 1, "b": 2, "a": 3}}'):
            with self.subTest(text):
                with self.assertRaises(TokenError) as cm:
                    parse_json(text, "light.json")
                self.assertIn("light.json", str(cm.exception))

    def test_load_reports_the_file_with_a_duplicate(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d, "tokens.json")
            f.write_text('{"core": {"space": {}, "space": {}}}', encoding="utf-8")
            with self.assertRaises(TokenError) as cm:
                load(f)
            self.assertIn("tokens.json", str(cm.exception))

    def test_load_refuses_a_missing_file(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(TokenError):
                load(Path(d, "nope.json"))

    def test_nan_and_infinity_literals_are_refused(self):
        for text in ('{"a": NaN}', '{"a": Infinity}', '{"a": -Infinity}'):
            with self.subTest(text):
                with self.assertRaises(TokenError):
                    parse_json(text)


class Sizes(RefusesWith):
    BAD = [True, False, float("nan"), float("inf"), float("-inf"), -4, -0.5, "-4px", "NaNpx",
           "inf", "1e999", {"value": -1, "unit": "px"}, {"value": True, "unit": "px"},
           {"value": float("nan"), "unit": "px"}, None, [], "px"]

    def test_space_and_radius_take_only_finite_non_negative_numbers(self):
        for group, name in (("space", "xs"), ("radius", "card")):
            for bad in self.BAD:
                with self.subTest(group=group, bad=bad):
                    t = edited(lambda t: t["core"][group][name].update({"$value": bad}))
                    self.assertRefuses(t, f"{group}.{name}")

    def test_zero_is_a_fine_size(self):
        t = edited(lambda t: t["core"]["space"]["xs"].update({"$value": "0px"}))
        self.assertIn("static const double xs = 0;", render(t))

    def test_font_size_and_line_height_must_be_positive(self):
        for field, bads in (
            ("fontSize", ["0px", 0, -1, "-3px", True, float("nan"), float("inf"), None]),
            ("lineHeight", ["0", 0, -1.2, "0%", "-10%", True, float("nan"), float("inf"), "x%"]),
        ):
            for bad in bads:
                with self.subTest(field=field, bad=bad):
                    t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({field: bad}))
                    self.assertRefuses(t, f"type.body.{field}")

    def test_typography_value_must_be_an_object(self):
        t = edited(lambda t: t["core"]["type"]["body"].update({"$value": "16px"}))
        self.assertRefuses(t, "type.body")


class Odd(RefusesWith):
    def test_huge_integers_are_refused_not_crashed_on(self):
        t = edited(lambda t: t["core"]["space"]["xs"].update({"$value": 10**400}))
        self.assertRefuses(t, "space.xs")
        t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": {"value": 10**400, "unit": "ms"}}))
        self.assertRefuses(t, "motion.tap")

    def test_non_ascii_digits_are_refused(self):
        t = edited(lambda t: t["core"]["space"]["xs"].update({"$value": "\u0664px"}))
        self.assertRefuses(t, "space.xs")
        t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": "\u0669\u0660ms"}))
        self.assertRefuses(t, "motion.tap")
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"fontWeight": "\u0664\u0660\u0660"}))
        self.assertRefuses(t, "type.body.fontWeight")

    def test_a_group_that_is_not_an_object_is_refused_even_when_falsy(self):
        for group in ("space", "radius", "type", "motion", "font"):
            for bad in ([], 0, "", False):
                with self.subTest(group=group, bad=bad):
                    self.assertRefuses(edited(lambda t: t["core"].update({group: bad})), group)


class Durations(RefusesWith):
    def test_durations_must_be_whole_non_negative_milliseconds(self):
        bads = ["-5ms", "1.5ms", "ms", 120, True, None,
                {"value": -1, "unit": "ms"}, {"value": 1.5, "unit": "ms"},
                {"value": True, "unit": "ms"}, {"value": float("nan"), "unit": "ms"},
                {"value": float("inf"), "unit": "s"}, {"value": 0.0005, "unit": "s"},
                {"value": 1, "unit": "min"}, {"value": 1}]
        for bad in bads:
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": bad}))
                self.assertRefuses(t, "motion.tap")

    def test_zero_duration_is_fine(self):
        t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": "0ms"}))
        self.assertIn("tap = Duration(milliseconds: 0)", render(t))


class Names(RefusesWith):
    def test_color_names_must_not_clash_with_the_palette_class(self):
        for name in ["name", "brightness", "type", "other", "t", "copyWith", "lerp", "hashCode",
                     "runtimeType", "toString", "required", *DART_RESERVED]:
            with self.subTest(name):
                def add(t):
                    for theme in THEMES:
                        t[theme]["color"][name] = {"$type": "color", "$value": "#112233"}
                self.assertRefuses(edited(add), name)

    def test_newline_at_the_end_of_a_name_is_not_allowed(self):
        def add(t):
            for theme in THEMES:
                t[theme]["color"]["glow\n"] = {"$type": "color", "$value": "#112233"}
        self.assertRefuses(edited(add), "glow")

    def test_reserved_words_are_refused_in_every_group(self):
        cases = {
            "space": {"$type": "dimension", "$value": "4px"},
            "radius": {"$type": "dimension", "$value": "4px"},
            "motion": {"$type": "duration", "$value": "10ms"},
            "type": copy.deepcopy(BASE["core"]["type"]["body"]),
        }
        for group, token in cases.items():
            for word in ("default", "class", "switch"):
                with self.subTest(group=group, word=word):
                    t = edited(lambda t: t["core"][group].update({word: token}))
                    self.assertRefuses(t, word)

    def test_font_family_cannot_break_out_of_the_dart_string(self):
        for bad in ["O'Neil", "a\\b", "a\nb", "a\rb", "Cost$", "tab\tfont", "", "  ", 3, None]:
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["font"]["family"].update({"$value": bad}))
                self.assertRefuses(t, "font.family")

    def test_font_family_with_spaces_is_fine(self):
        t = edited(lambda t: t["core"]["font"]["family"].update({"$value": "Noto Sans KR"}))
        self.assertIn("fontFamily: 'Noto Sans KR'", render(t))

    def test_every_emitted_identifier_passes_the_ident_rule(self):
        out = render(BASE)
        names = re.findall(r"static const \w+ (\w+) =", out) + re.findall(r"final Color (\w+);", out)
        self.assertTrue(names)
        for n in names:
            self.assertRegex(n, IDENT)


class Dtcg(RefusesWith):
    def test_color_object_matches_the_hex_form(self):
        obj = {"colorSpace": "srgb", "components": [1, 0.5, 0], "alpha": 0.5}
        t = edited(lambda t: t["dark"]["color"]["line"].update({"$value": obj}))
        self.assertIn("line: Color(0x80FF8000)", render(t))

    def test_color_object_without_alpha_is_opaque(self):
        obj = {"colorSpace": "srgb", "components": [0, 0, 1]}
        t = edited(lambda t: t["dark"]["color"]["line"].update({"$value": obj}))
        self.assertIn("line: Color(0xFF0000FF)", render(t))

    def test_color_object_may_carry_a_matching_hex(self):
        obj = {"colorSpace": "srgb", "components": [1, 0, 0], "hex": "#ff0000"}
        t = edited(lambda t: t["dark"]["color"]["line"].update({"$value": obj}))
        self.assertIn("line: Color(0xFFFF0000)", render(t))

    def test_bad_color_objects(self):
        good = {"colorSpace": "srgb", "components": [0.1, 0.2, 0.3]}
        bads = [
            {**good, "colorSpace": "display-p3"},
            {"components": [0.1, 0.2, 0.3]},
            {**good, "components": [0.1, 0.2]},
            {**good, "components": [0.1, 0.2, 0.3, 0.4]},
            {**good, "components": [0.1, 0.2, 1.1]},
            {**good, "components": [-0.1, 0.2, 0.3]},
            {**good, "components": [True, 0.2, 0.3]},
            {**good, "components": ["none", 0.2, 0.3]},
            {**good, "components": [float("nan"), 0.2, 0.3]},
            {**good, "alpha": 2},
            {**good, "alpha": -0.1},
            {**good, "alpha": True},
            {**good, "extra": 1},
            {**good, "hex": "#FFFFFF"},
            {**good, "hex": "red"},
            "#12345",
            12,
            [1, 2, 3],
        ]
        for bad in bads:
            with self.subTest(bad=bad):
                t = edited(lambda t: t["dark"]["color"]["line"].update({"$value": bad}))
                self.assertRefuses(t, "dark.color.line")

    def test_dimension_object_matches_the_string_form(self):
        a = edited(lambda t: t["core"]["space"]["xs"].update({"$value": "4px"}))
        b = edited(lambda t: t["core"]["space"]["xs"].update({"$value": {"value": 4, "unit": "px"}}))
        self.assertEqual(render(a), render(b))

    def test_dimension_object_needs_px(self):
        for bad in ({"value": 4, "unit": "rem"}, {"value": 4}, {"unit": "px"},
                    {"value": 4, "unit": "px", "extra": 1}):
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["space"]["xs"].update({"$value": bad}))
                self.assertRefuses(t, "space.xs")

    def test_font_size_may_be_a_dimension_object(self):
        spec = {"fontSize": {"value": 16, "unit": "px"}}
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update(spec))
        self.assertEqual(render(t), render(BASE))

    def test_duration_object_forms_match_the_string_form(self):
        for form in ({"value": 120, "unit": "ms"}, {"value": 0.12, "unit": "s"}, "120ms"):
            with self.subTest(form=form):
                t = edited(lambda t: t["core"]["motion"]["fillRise"].update({"$value": form}))
                self.assertEqual(render(t), render(BASE))


def without_brightness(theme, ground=None):
    def change(t):
        t[theme].pop("$extensions", None)
        if ground:
            t[theme]["color"]["ground"]["$value"] = ground
    return edited(change)


class Brightness(RefusesWith):
    def test_missing_brightness_is_guessed_from_ground(self):
        for theme in THEMES:
            with self.subTest(theme):
                self.assertEqual(render(without_brightness(theme)), render(BASE))

    def test_empty_extensions_count_as_missing(self):
        t = edited(lambda t: t["dark"].update({"$extensions": {"app": {}}}))
        self.assertEqual(render(t), render(BASE))

    def test_relative_luminance_half_is_the_dividing_line(self):
        cases = {"#FFFFFF": "light", "#BCBCBC": "light", "#BBBBBB": "dark",
                 "#808080": "dark", "#000000": "dark", "#FFF1F5": "light", "#121216": "dark"}
        for ground, expected in cases.items():
            with self.subTest(ground):
                out = render(without_brightness("pink", ground))
                self.assertIn(f"name: 'pink',\n  brightness: Brightness.{expected},", out)

    def test_ground_alpha_is_ignored(self):
        out = render(without_brightness("pink", "#00000080"))
        self.assertIn("name: 'pink',\n  brightness: Brightness.dark,", out)

    def test_ground_may_be_a_color_object(self):
        obj = {"colorSpace": "srgb", "components": [1, 1, 1]}
        out = render(without_brightness("pink", obj))
        self.assertIn("name: 'pink',\n  brightness: Brightness.light,", out)

    def test_written_brightness_wins_over_the_guess(self):
        t = edited(lambda t: t["light"]["color"]["ground"].update({"$value": "#000000"}))
        self.assertIn("name: 'light',\n  brightness: Brightness.light,", render(t))

    def test_a_wrong_brightness_is_still_refused(self):
        t = edited(lambda t: t["pink"]["$extensions"]["app"].update({"brightness": "bright"}))
        self.assertRefuses(t, "brightness")

    def test_nothing_to_guess_from_is_refused(self):
        t = without_brightness("pink")
        del t["pink"]["color"]["ground"]
        for theme in THEMES:
            t[theme]["color"].pop("ground", None)
        self.assertRefuses(t, "ground")


class SingleFile(RefusesWith):
    def doc(self, **extra):
        return {**BASE, **extra}

    def test_the_checked_in_file_lists_every_set_in_a_fixed_order(self):
        self.assertEqual(list(BASE), ["core", "dark", "light", "pink"])

    def test_dollar_keys_are_skipped(self):
        doc = self.doc(**{"$themes": [{"id": "x", "name": "x"}], "$metadata": {"tokenSetOrder": list(BASE)},
                          "$other": 3})
        self.assertEqual(render(doc), render(BASE))
        self.assertEqual(list(token_sets(doc)), list(BASE))

    def test_token_set_order_decides_the_theme_order(self):
        doc = self.doc(**{"$metadata": {"tokenSetOrder": ["core", "pink", "dark", "light"]}})
        self.assertIn("allPalettes = [pinkPalette, darkPalette, lightPalette];", render(doc))

    def test_sets_missing_from_the_order_follow_it(self):
        doc = self.doc(**{"$metadata": {"tokenSetOrder": ["core", "light"]}})
        self.assertEqual(list(token_sets(doc)), ["core", "light", "dark", "pink"])

    def test_bad_token_set_order_is_refused(self):
        for order in (["core", "ghost"], ["core", "core"], "core", [1, 2], {"core": 1}):
            with self.subTest(order):
                self.assertRefuses(self.doc(**{"$metadata": {"tokenSetOrder": order}}), "tokenSetOrder")

    def test_the_checked_in_file_is_the_single_source(self):
        self.assertEqual(SRC.name, "tokens.json")
        self.assertTrue(SRC.is_file())
        self.assertFalse(SRC.with_suffix("").exists())

    def test_load_reads_one_file_and_skips_dollar_keys(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d, "tokens.json")
            f.write_text(
                __import__("json").dumps({**BASE, "$themes": [], "$metadata": {"tokenSetOrder": list(BASE)}}),
                encoding="utf-8",
            )
            self.assertEqual(render(load(f)), render(BASE))

    def test_a_bare_number_is_pixels(self):
        a = edited(lambda t: t["core"]["space"]["xs"].update({"$value": 4}))
        b = edited(lambda t: t["core"]["space"]["xs"].update({"$value": "4"}))
        self.assertEqual(render(a), render(BASE))
        self.assertEqual(render(b), render(BASE))
        c = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"fontSize": 16}))
        self.assertEqual(render(c), render(BASE))


class Output(unittest.TestCase):
    def test_checked_in_output_is_exactly_what_the_tokens_render(self):
        self.assertEqual(OUT.read_text(encoding="utf-8"), render(BASE))


if __name__ == "__main__":
    unittest.main()
