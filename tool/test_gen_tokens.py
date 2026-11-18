"""Pin that gen_tokens stops a designer's mistakes with a clear message."""
import copy
import re
import shutil
import tempfile
import unittest
from pathlib import Path

from gen_tokens import (
    IDENT, OUT, REQUIRED_COLORS, REQUIRED_CORE, ROOT, SPLASH_FILES, SRC, TokenError, load, outputs, parse_json,
    render, splash_outputs, splash_wiring_problems, stale, token_sets,
)

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
        for bad in ["a\\b", "a\nb", "a\rb", "Cost$", "tab\tfont", "", "  ", 3, None]:
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["font"]["family"].update({"$value": bad}))
                self.assertRefuses(t, "font.family")

    def test_apostrophe_in_a_font_name_is_escaped(self):
        t = edited(lambda t: t["core"]["font"]["family"].update({"$value": "O'Neil Sans"}))
        out = render(t)
        self.assertIn("fontFamily: 'O\\x27Neil Sans'", out)
        self.assertNotIn("O'Neil", out)

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


CORE_GROUPS = ("space", "radius", "type", "motion", "font")
BAD_GROUPS = [None, {}, [], 0, "", False, "x", 5, {"$type": "dimension"}, {"$description": "empty"}]


class RequiredGroups(RefusesWith):
    def test_core_groups_cannot_be_null_empty_or_not_objects(self):
        for group in CORE_GROUPS:
            for bad in BAD_GROUPS:
                with self.subTest(group=group, bad=bad):
                    self.assertRefuses(edited(lambda t: t["core"].update({group: bad})), group)

    def test_core_groups_cannot_be_missing(self):
        for group in CORE_GROUPS:
            with self.subTest(group):
                self.assertRefuses(edited(lambda t: t["core"].pop(group)), group)

    def test_color_group_cannot_be_null_empty_or_missing_in_any_theme(self):
        for theme in THEMES:
            for bad in BAD_GROUPS:
                with self.subTest(theme=theme, bad=bad):
                    self.assertRefuses(edited(lambda t: t[theme].update({"color": bad})), theme)
            with self.subTest(theme=theme, bad="missing"):
                self.assertRefuses(edited(lambda t: t[theme].pop("color")), theme)

    def test_a_set_that_is_null_or_not_an_object_is_refused(self):
        for name in ("core", *THEMES):
            for bad in (None, [], 0, "x"):
                with self.subTest(name=name, bad=bad):
                    self.assertRefuses(edited(lambda t: t.update({name: bad})), name)

    def test_names_the_app_uses_cannot_go_missing(self):
        for group, names in REQUIRED_CORE.items():
            for name in names:
                with self.subTest(group=group, name=name):
                    self.assertRefuses(edited(lambda t: t["core"][group].pop(name)), name)

    def test_colors_the_app_uses_cannot_go_missing_from_any_theme(self):
        for theme in THEMES:
            for name in REQUIRED_COLORS:
                with self.subTest(theme=theme, name=name):
                    self.assertRefuses(edited(lambda t: t[theme]["color"].pop(name)), name)

    def test_required_names_match_what_lib_uses(self):
        classes = {"Space": "space", "Radii": "radius", "TypeScale": "type", "Motion": "motion"}
        used = {g: set() for g in classes.values()}
        root = Path(__file__).resolve().parent.parent
        for f in [*(root / "lib").rglob("*.dart"), *(root / "test").rglob("*.dart")]:
            if f.name == "tokens.g.dart":
                continue
            for m in re.finditer(r"\b(Space|Radii|TypeScale|Motion)\.(\w+)", f.read_text(encoding="utf-8")):
                used[classes[m[1]]].add(m[2])
        for group, names in used.items():
            self.assertLessEqual(names, set(REQUIRED_CORE[group]), f"{group}: add it to REQUIRED_CORE")

    def test_extra_names_are_fine(self):
        t = edited(lambda t: t["core"]["space"].update({"huge": {"$type": "dimension", "$value": "96px"}}))
        self.assertIn("static const double huge = 96;", render(t))


class NullAndInheritedTypes(RefusesWith):
    def test_an_explicit_null_type_is_refused(self):
        spots = {
            "light.color.ink": lambda t: t["light"]["color"]["ink"].update({"$type": None}),
            "space.xs": lambda t: t["core"]["space"]["xs"].update({"$type": None}),
            "radius.card": lambda t: t["core"]["radius"]["card"].update({"$type": None}),
            "motion.tap": lambda t: t["core"]["motion"]["tap"].update({"$type": None}),
            "type.body": lambda t: t["core"]["type"]["body"].update({"$type": None}),
            "font.family": lambda t: t["core"]["font"]["family"].update({"$type": None}),
        }
        for where, change in spots.items():
            with self.subTest(where):
                self.assertRefuses(edited(change), where)

    def test_a_group_type_must_match_the_slot(self):
        for group, wrong in (("space", "color"), ("radius", "duration"), ("type", "dimension"),
                             ("motion", "dimension"), ("font", "color"), ("space", None), ("space", 3)):
            with self.subTest(group=group, wrong=wrong):
                t = edited(lambda t: t["core"][group].update({"$type": wrong}))
                self.assertRefuses(t, group)
        t = edited(lambda t: t["dark"]["color"].update({"$type": "dimension"}))
        self.assertRefuses(t, "dark")

    def test_a_matching_group_type_is_fine_and_is_not_a_token_name(self):
        def add(t):
            for group, typ in (("space", "dimension"), ("radius", "dimension"), ("type", "typography"),
                               ("motion", "duration"), ("font", "fontFamily")):
                t["core"][group]["$type"] = typ
            for theme in THEMES:
                t[theme]["color"]["$type"] = "color"
                t[theme]["color"]["$description"] = "note"
        self.assertEqual(render(edited(add)), render(BASE))

    def test_tokens_inherit_the_group_type(self):
        def add(t):
            t["core"]["space"]["$type"] = "dimension"
            for tok in t["core"]["space"].values():
                if isinstance(tok, dict):
                    tok.pop("$type", None)
        self.assertEqual(render(edited(add)), render(BASE))

    def test_a_token_type_that_differs_from_the_group_is_refused(self):
        def add(t):
            t["core"]["space"]["$type"] = "dimension"
            t["core"]["space"]["xs"]["$type"] = "color"
        self.assertRefuses(edited(add), "space.xs")


class Letters(RefusesWith):
    def test_misspelt_typography_field_is_refused(self):
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"fontWeigth": "700"}))
        self.assertRefuses(t, "fontWeigth")

    def test_fields_tokens_studio_adds_are_ignored(self):
        extra = {"paragraphSpacing": "0", "paragraphIndent": "0", "textCase": "none", "textDecoration": "none"}
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update(extra))
        self.assertEqual(render(t), render(BASE))

    def test_letter_spacing_becomes_a_text_style_field(self):
        cases = {"-0.5px": "-0.5", "2px": "2", 1: "1", "0": "0"}
        for given, shown in cases.items():
            with self.subTest(given):
                t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"letterSpacing": given}))
                self.assertIn(f"height: 1.5, letterSpacing: {shown});", render(t))
        t = edited(lambda t: t["core"]["type"]["body"]["$value"].update(
            {"letterSpacing": {"value": 1.5, "unit": "px"}}))
        self.assertIn("height: 1.5, letterSpacing: 1.5);", render(t))

    def test_bad_letter_spacing_is_refused(self):
        for bad in (True, float("nan"), float("inf"), "x", "1em", "", None, {"value": 1, "unit": "rem"}):
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["type"]["body"]["$value"].update({"letterSpacing": bad}))
                self.assertRefuses(t, "type.body.letterSpacing")

    def test_without_letter_spacing_the_output_has_none(self):
        self.assertNotIn("letterSpacing", render(BASE))


class StaticNames(RefusesWith):
    OK = ["name", "type", "t", "other", "copyWith", "lerp", "required", "static", "get", "brightness"]
    BAD = ["hashCode", "toString", "runtimeType", "noSuchMethod", *DART_RESERVED]

    def token(self, group):
        return {
            "space": {"$type": "dimension", "$value": "4px"},
            "radius": {"$type": "dimension", "$value": "4px"},
            "motion": {"$type": "duration", "$value": "10ms"},
            "type": copy.deepcopy(BASE["core"]["type"]["body"]),
        }[group]

    def test_only_real_collisions_are_refused_outside_the_palette(self):
        for group in ("space", "radius", "motion", "type"):
            for name in self.OK:
                with self.subTest(group=group, ok=name):
                    t = edited(lambda t: t["core"][group].update({name: self.token(group)}))
                    self.assertIn(f" {name} = ", render(t))
            for name in self.BAD:
                with self.subTest(group=group, bad=name):
                    t = edited(lambda t: t["core"][group].update({name: self.token(group)}))
                    self.assertRefuses(t, name)

    def test_palette_names_stay_strict(self):
        for name in ("type", "t", "other", "required", "name"):
            def add(t):
                for theme in THEMES:
                    t[theme]["color"][name] = {"$type": "color", "$value": "#112233"}
            with self.subTest(name):
                self.assertRefuses(edited(add), name)


class DurationLimits(RefusesWith):
    def test_one_hour_is_the_ceiling(self):
        ok = ["3600000ms", {"value": 3600000, "unit": "ms"}, {"value": 3600, "unit": "s"}]
        for good in ok:
            with self.subTest(good=good):
                t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": good}))
                self.assertIn("tap = Duration(milliseconds: 3600000)", render(t))
        too_long = ["3600001ms", "99999999999999999999ms", {"value": 3600001, "unit": "ms"},
                    {"value": 3601, "unit": "s"}, {"value": 1e308, "unit": "ms"},
                    {"value": 1e308, "unit": "s"}, {"value": 10**400, "unit": "s"}]
        for bad in too_long:
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": bad}))
                self.assertRefuses(t, "motion.tap")

    def test_a_tiny_positive_value_that_rounds_to_zero_is_refused(self):
        for bad in ({"value": 1e-9, "unit": "ms"}, {"value": 1e-9, "unit": "s"},
                    {"value": 5e-7, "unit": "ms"}, {"value": 0.4, "unit": "ms"}):
            with self.subTest(bad=bad):
                t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": bad}))
                self.assertRefuses(t, "motion.tap")

    def test_zero_in_every_form_is_fine(self):
        for good in ("0ms", {"value": 0, "unit": "ms"}, {"value": 0.0, "unit": "s"}, {"value": -0.0, "unit": "ms"}):
            with self.subTest(good=good):
                t = edited(lambda t: t["core"]["motion"]["tap"].update({"$value": good}))
                self.assertIn("tap = Duration(milliseconds: 0)", render(t))


def contrast(a, b):
    from gen_tokens import luminance
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


class Contrast(unittest.TestCase):
    """Keep a color change from making text unreadable. Same criterion (WCAG) as the Dart palette_test."""

    def argb(self, theme, name):
        from gen_tokens import color_argb
        return color_argb(BASE[theme]["color"][name], f"{theme}.color.{name}")

    def test_text_on_fill_accent_and_error_is_readable(self):
        for theme in THEMES:
            for text, ground in (("onFill", "fill"), ("onAccent", "accent"), ("onError", "error")):
                with self.subTest(theme=theme, pair=f"{text}/{ground}"):
                    self.assertGreaterEqual(contrast(self.argb(theme, text), self.argb(theme, ground)), 4.5)

    def test_mood_colors_stand_out_on_the_card_surface(self):
        for theme in THEMES:
            for name in ("happy", "sad"):
                with self.subTest(theme=theme, name=name):
                    self.assertGreaterEqual(contrast(self.argb(theme, name), self.argb(theme, "surface")), 3.0)

    def test_information_colors_are_black_and_gray_in_light_and_dark(self):
        """Design rule: accent, fill and their text colors are single-tone black or gray; color is for the mood faces only."""
        for theme in ("light", "dark"):
            for name in ("accent", "onAccent", "fill", "onFill", "fillEdge", "mapLine"):
                with self.subTest(theme=theme, name=name):
                    argb = self.argb(theme, name)
                    r, g, b = (int(argb[i:i + 2], 16) for i in (2, 4, 6))
                    self.assertLessEqual(max(r, g, b) - min(r, g, b), 8, f"{theme}.{name} is not a gray")

    def test_the_new_colors_are_required(self):
        self.assertIn("onFill", REQUIRED_COLORS)
        self.assertIn("onError", REQUIRED_COLORS)

    def test_fill_edge_is_required(self):
        self.assertIn("fillEdge", REQUIRED_COLORS)

    def test_fill_edge_stands_out_from_the_ground(self):
        """The line on top of the water has to be visible on the ground even when the fill itself is pale."""
        for theme in THEMES:
            with self.subTest(theme=theme):
                self.assertGreaterEqual(contrast(self.argb(theme, "fillEdge"), self.argb(theme, "ground")), 1.5)


STORYBOARD = (ROOT / SPLASH_FILES["ios_storyboard"]).read_text(encoding="utf-8")


def with_ground(light=None, dark=None):
    def change(t):
        if light:
            t["light"]["color"]["ground"]["$value"] = light
        if dark:
            t["dark"]["color"]["ground"]["$value"] = dark
    return edited(change)


class Splash(RefusesWith):
    A_LIGHT, SET, STORY, WIDGET = (
        SPLASH_FILES[k] for k in ("android_light", "ios_colorset", "ios_storyboard", "ios_widget_colors")
    )

    def test_widget_colors_come_from_the_light_theme(self):
        out = splash_outputs(with_ground("#F6F6F8"), STORYBOARD)
        ink = BASE["light"]["color"]["ink"]["$value"].lstrip("#")[:6].upper()
        self.assertIn('<color name="widget_ground">#F6F6F8</color>', out[self.A_LIGHT])
        self.assertIn(f'<color name="widget_ink">#{ink}</color>', out[self.A_LIGHT])
        line = BASE["light"]["color"]["line"]["$value"].lstrip("#")[:6].upper()
        self.assertIn(f'<color name="widget_line">#{line}</color>', out[self.A_LIGHT])
        swift = out[self.WIDGET]
        self.assertIn("Generated file. Do not edit.", swift)
        self.assertIn("static let ground = Color(red: 246.0 / 255, green: 246.0 / 255, blue: 248.0 / 255)", swift)
        r, g, b = (int(ink[i:i + 2], 16) for i in (0, 2, 4))
        self.assertIn(f"static let ink = Color(red: {r}.0 / 255, green: {g}.0 / 255, blue: {b}.0 / 255)", swift)

    def test_an_ink_with_alpha_is_refused_for_the_widget(self):
        def change(t):
            t["light"]["color"]["ink"]["$value"] = "#16161A80"
        self.assertRefuses_splash(edited(change), "ink")

    def test_android_color_comes_from_the_light_ground(self):
        out = splash_outputs(with_ground("#F6F6F8", "#101820"), STORYBOARD)
        self.assertIn('<color name="splash_background">#F6F6F8</color>', out[self.A_LIGHT])

    def test_there_are_no_dark_splash_files(self):
        """The app starts in light, so the native splash stays light even when the OS is dark."""
        self.assertNotIn("android_dark", SPLASH_FILES)
        for rel in splash_outputs(BASE, STORYBOARD):
            self.assertNotIn("values-night", str(rel))

    def test_ios_color_set_holds_one_color_without_a_dark_variant(self):
        import json
        out = splash_outputs(with_ground("#F6F6F8", "#101820"), STORYBOARD)
        colors = json.loads(out[self.SET])["colors"]
        self.assertEqual(len(colors), 1)
        self.assertNotIn("appearances", colors[0])
        comps = tuple(colors[0]["color"]["components"][k] for k in ("red", "green", "blue", "alpha"))
        self.assertEqual(comps, ("0xF6", "0xF6", "0xF8", "1.000"))

    def test_storyboard_fallback_follows_light_ground_and_nothing_else_changes(self):
        out = splash_outputs(with_ground("#F6F6F8"), STORYBOARD)[self.STORY]
        self.assertIn('red="0.96470588235294119" green="0.96470588235294119" blue="0.97254901960784312"', out)
        changed = [(a, b) for a, b in zip(STORYBOARD.splitlines(), out.splitlines()) if a != b]
        self.assertEqual(len(changed), 1)
        self.assertEqual(len(STORYBOARD.splitlines()), len(out.splitlines()))

    def test_storyboard_fallback_uses_exact_one_and_zero(self):
        out = splash_outputs(with_ground("#FF0000"), STORYBOARD)[self.STORY]
        self.assertIn('red="1" green="0" blue="0" alpha="1"', out)

    def test_the_dark_ground_does_not_touch_any_splash_file(self):
        self.assertEqual(splash_outputs(with_ground(dark="#101820"), STORYBOARD), splash_outputs(BASE, STORYBOARD))

    def test_storyboard_attribute_order_does_not_matter(self):
        """Xcode may write the color attributes in any order. The generator reads the XML, not a text pattern."""
        reordered = STORYBOARD.replace(
            '<color red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>',
            '<color alpha="0.5" colorSpace="custom" customColorSpace="sRGB" blue="0" green="0" red="0"/>',
        )
        self.assertNotEqual(reordered, STORYBOARD)
        out = splash_outputs(with_ground("#FF0000"), reordered)[self.STORY]
        self.assertIn(
            '<color alpha="1" colorSpace="custom" customColorSpace="sRGB" blue="0" green="0" red="1"/>', out)
        self.assertEqual(len(out.splitlines()), len(STORYBOARD.splitlines()))

    def test_storyboard_with_two_named_colors_of_that_name_is_refused(self):
        doubled = STORYBOARD.replace("</resources>", '<namedColor name="SplashBackground"><color red="0" green="0" '
                                     'blue="0" alpha="1"/></namedColor></resources>')
        with self.assertRaises(TokenError):
            splash_outputs(BASE, doubled)

    def test_color_objects_work_and_alpha_is_refused(self):
        obj = {"colorSpace": "srgb", "components": [0, 0, 0]}
        out = splash_outputs(with_ground(light=obj), STORYBOARD)
        self.assertIn("#000000", out[self.A_LIGHT])
        self.assertRefuses_splash(with_ground(light="#FFFFFF80"), "light")

    def assertRefuses_splash(self, tokens, fragment):
        with self.assertRaises(TokenError) as cm:
            splash_outputs(tokens, STORYBOARD)
        self.assertIn(fragment, str(cm.exception))

    def test_it_needs_a_light_set(self):
        self.assertRefuses_splash(edited(lambda t: t.pop("light")), "light")

    def test_a_storyboard_without_the_named_color_is_refused(self):
        with self.assertRaises(TokenError) as cm:
            splash_outputs(BASE, STORYBOARD.replace("SplashBackground", "Other"))
        self.assertIn("SplashBackground", str(cm.exception))

    def test_checked_in_platform_files_are_what_the_tokens_produce(self):
        for rel, text in splash_outputs(BASE, STORYBOARD).items():
            with self.subTest(rel.name):
                self.assertEqual((ROOT / rel).read_text(encoding="utf-8"), text)

    def test_stale_lists_every_file_that_differs_and_only_those(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for rel in SPLASH_FILES.values():
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text((ROOT / rel).read_text(encoding="utf-8"), encoding="utf-8")
            (root / OUT.relative_to(ROOT)).parent.mkdir(parents=True, exist_ok=True)
            (root / OUT.relative_to(ROOT)).write_text(OUT.read_text(encoding="utf-8"), encoding="utf-8")
            self.assertEqual(stale(outputs(BASE, root), root), [])
            changed = stale(outputs(with_ground(light="#F6F6F8"), root), root)
            self.assertEqual(
                sorted(p.name for p in changed),
                sorted([self.A_LIGHT.name, self.SET.name, self.STORY.name, self.WIDGET.name, OUT.name]),
            )
            (root / self.A_LIGHT).unlink()
            self.assertIn(self.A_LIGHT, stale(outputs(BASE, root), root))


class SplashWiring(unittest.TestCase):
    """--check verifies that the native splash actually uses the generated colors, not only that they exist."""
    RES = Path("android/app/src/main/res")
    STYLES = RES / "values/styles.xml"
    STYLES_V31 = RES / "values-v31/styles.xml"
    LAUNCH_BG = RES / "drawable/launch_background.xml"
    SET = SPLASH_FILES["ios_colorset"]
    STORY = SPLASH_FILES["ios_storyboard"]

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        for rel in (self.RES, self.SET.parent, self.STORY.parent):
            shutil.copytree(ROOT / rel, self.root / rel, ignore=shutil.ignore_patterns("mipmap-*", "LaunchImage*"))

    def edit(self, rel, old, new):
        path = self.root / rel
        text = path.read_text(encoding="utf-8")
        self.assertIn(old, text)
        path.write_text(text.replace(old, new), encoding="utf-8")

    def problems(self):
        return splash_wiring_problems(self.root)

    def test_the_checked_in_project_is_wired(self):
        self.assertEqual(splash_wiring_problems(ROOT), [])

    def test_a_styles_file_that_points_at_another_color_is_reported(self):
        self.edit(self.STYLES, '@color/splash_background', '@color/other')
        found = self.problems()
        self.assertTrue(any("values/styles.xml" in p and "splash_background" in p for p in found), found)

    def test_the_android_12_splash_color_must_use_the_generated_name(self):
        self.edit(self.STYLES_V31, '@color/splash_background', '@color/other')
        found = self.problems()
        self.assertTrue(any("values-v31/styles.xml" in p for p in found), found)

    def test_a_launch_background_without_the_color_is_reported(self):
        self.edit(self.LAUNCH_BG, '@color/splash_background', '#FF0000')
        found = self.problems()
        self.assertTrue(any("launch_background" in p for p in found), found)

    def test_a_leftover_dark_splash_resource_is_reported(self):
        night = self.root / self.RES / "values-night"
        night.mkdir()
        (night / "colors.xml").write_text(
            '<resources><color name="splash_background">#000000</color></resources>', encoding="utf-8")
        found = self.problems()
        self.assertTrue(any("values-night" in p for p in found), found)

    def test_a_storyboard_that_uses_another_named_color_is_reported(self):
        self.edit(self.STORY, '<color key="backgroundColor" name="SplashBackground"/>',
                  '<color key="backgroundColor" name="Other"/>')
        found = self.problems()
        self.assertTrue(any("LaunchScreen.storyboard" in p and "SplashBackground" in p for p in found), found)

    def test_a_missing_color_set_is_reported(self):
        shutil.rmtree(self.root / self.SET.parent)
        found = self.problems()
        self.assertTrue(any("colorset" in p.lower() for p in found), found)

    def test_a_fallback_color_that_is_not_opaque_is_reported(self):
        self.edit(self.STORY, 'blue="1" alpha="1"', 'blue="1" alpha="0.5"')
        found = self.problems()
        self.assertTrue(any("alpha" in p for p in found), found)

    def test_a_color_set_with_a_dark_variant_is_reported(self):
        (self.root / self.SET).write_text(
            (self.root / self.SET).read_text(encoding="utf-8").replace(
                '"idiom" : "universal",\n      "color"',
                '"appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],\n      "idiom" : "universal",\n      "color"', 1),
            encoding="utf-8")
        found = self.problems()
        self.assertTrue(any("dark" in p for p in found), found)


class Output(unittest.TestCase):
    def test_header_points_at_the_single_token_file(self):
        out = render(BASE)
        self.assertIn("// Edit design/tokens.json, then run python3 tool/gen_tokens.py.", out)
        self.assertNotIn("design/tokens/", out)

    def test_checked_in_output_is_exactly_what_the_tokens_render(self):
        self.assertEqual(OUT.read_text(encoding="utf-8"), render(BASE))


if __name__ == "__main__":
    unittest.main()
