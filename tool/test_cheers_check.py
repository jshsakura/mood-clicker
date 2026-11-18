import contextlib
import io
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cheers_check import MOODS, TIERS, check_bundle, count_graphemes, load_rules, main


def _valid_bundle(lang: str) -> dict:
    moods = {}
    n = 0
    for mood in MOODS:
        sample = ("\ud1a1" if lang == "ko" else "Okay ")
        moods[mood] = {}
        for tier, count in (
            ("low", 2),
            ("high", 2),
            ("full", 1),
            ("complete", 1),
            ("rare", 1),
        ):
            items = []
            for _ in range(count):
                n += 1
                items.append(f"{sample}{n}")
            moods[mood][tier] = items
    return {"version": 1, "moods": moods}


class CheersCheckTest(unittest.TestCase):
    small_counts = {"low": 2, "high": 2, "full": 1, "complete": 1, "rare": 1}

    def test_valid_bundles_pass_with_emojis(self) -> None:
        ko = _valid_bundle("ko")
        ko["moods"]["happy"]["low"][0] = "\uc88b\uc544! \U0001F389"
        en = _valid_bundle("en")
        en["moods"]["happy"]["low"][0] = "Yay! \u2600\uFE0F"
        self.assertEqual(check_bundle(ko, "ko", self.small_counts), [])
        self.assertEqual(check_bundle(en, "en", self.small_counts), [])

    def test_grapheme_counting(self) -> None:
        self.assertEqual(count_graphemes("\U0001F389"), 1)
        self.assertEqual(count_graphemes("\u2600\uFE0F"), 1)
        self.assertEqual(count_graphemes("\U0001F468\u200D\U0001F469\u200D\U0001F467"), 1)
        self.assertEqual(count_graphemes("\uc88b\uc544! \U0001F389"), 5)

    def test_detects_exact_and_normalized_duplicates_across_moods(self) -> None:
        data = _valid_bundle("en")
        data["moods"]["happy"]["low"][0] = "Let's go!"
        data["moods"]["excited"]["high"][0] = "Lets go"
        errs = check_bundle(data, "en", self.small_counts)
        self.assertTrue(any("normalized duplicate" in e for e in errs), errs)

    def test_base_grouping_allows_text_play_up_to_4_and_rejects_5(self) -> None:
        data = _valid_bundle("en")
        data["moods"]["happy"]["low"] = [
            {"t": "Nice!", "b": "b1"},
            {"t": "Nice!!", "b": "b1"},
            {"t": "Nice! \U0001F389", "b": "b1"},
            {"t": "Nice~", "b": "b1"},
        ]
        self.assertEqual(check_bundle(data, "en", self.small_counts), [])

        data["moods"]["happy"]["high"][0] = {"t": "Nice! \u266a", "b": "b1"}
        errs = check_bundle(data, "en", self.small_counts)
        self.assertTrue(any("exceeds max 4" in e for e in errs), errs)

    def test_enforces_min_bases_per_mood(self) -> None:
        data = _valid_bundle("en")
        errs = check_bundle(data, "en", self.small_counts, min_bases_per_mood=10)
        self.assertEqual(len(errs), len(MOODS), errs)

    def test_detects_length_violations(self) -> None:
        ko = _valid_bundle("ko")
        ko["moods"]["sad"]["low"][0] = "\uac00"
        ko["moods"]["sad"]["low"][1] = "\uac00" * 15
        errs_ko = check_bundle(ko, "ko", self.small_counts)
        self.assertEqual(len(errs_ko), 2, errs_ko)

        en = _valid_bundle("en")
        en["moods"]["sad"]["low"][0] = "A"
        en["moods"]["sad"]["low"][1] = "A" * 21
        errs_en = check_bundle(en, "en", self.small_counts)
        self.assertEqual(len(errs_en), 2, errs_en)

    def test_detects_forbidden_words_dashes_and_quotes(self) -> None:
        empty_rules = {"version": 1, "global": {}, "moods": {}}
        en = _valid_bundle("en")
        en["moods"]["sad"]["low"][0] = "Best therapy"
        en["moods"]["angry"]["low"][0] = "Wait\u2014now"
        en["moods"]["happy"]["low"][0] = "\u201cNice\u201d"
        errs = check_bundle(en, "en", self.small_counts, rules=empty_rules)
        self.assertEqual(len(errs), 3, errs)

        ko = _valid_bundle("ko")
        ko["moods"]["sad"]["low"][0] = "\uc6b0\uc6b8\uc99d \uadf9\ubcf5"
        errs_ko = check_bundle(ko, "ko", self.small_counts, rules=empty_rules)
        self.assertTrue(any("forbidden word" in e for e in errs_ko), errs_ko)

    def test_per_mood_rules_exclamation_emojis_and_banned_words(self) -> None:
        data = _valid_bundle("en")
        data["moods"]["sad"] = {
            "low": ["Softly now!", "Warm tea \U0001F389"],
            "high": ["Cheer up now", "Quiet breath"],
            "full": ["Rest easy (つ´∀`)つ"],
            "complete": ["Dawn is here hehe"],
            "rare": ["White cloud"],
        }
        data["moods"]["anxious"]["low"][0] = "Breathe \U0001F33F"
        data["moods"]["happy"]["low"][0] = "Nice!!"
        data["moods"]["happy"]["low"][1] = "Great!!!"

        rules = {
            "version": 1,
            "global": {"banned_words": {"ko": [], "en": []}},
            "moods": {
                "happy": {
                    "max_exclamation": 2,
                    "allowed_emojis": None,
                    "allow_kaomoji": True,
                    "allow_laughter": True,
                    "banned_words": {"ko": [], "en": []},
                },
                "sad": {
                    "max_exclamation": 0,
                    "allowed_emojis": [],
                    "allow_kaomoji": False,
                    "allow_laughter": False,
                    "banned_words": {"ko": [], "en": ["cheer up", "hit"]},
                },
                "anxious": {
                    "max_exclamation": 1,
                    "allowed_emojis": ["\U0001F33F"],
                    "allow_kaomoji": True,
                    "allow_laughter": True,
                    "banned_words": {"ko": [], "en": []},
                },
            },
        }
        errs = check_bundle(data, "en", self.small_counts, rules=rules)
        self.assertEqual(len(errs), 6, errs)
        self.assertTrue(any("exclamation count 1 exceeds max 0" in e for e in errs), errs)
        self.assertTrue(any("exclamation count 3 exceeds max 2" in e for e in errs), errs)
        self.assertTrue(any("disallowed emoji" in e for e in errs), errs)
        self.assertTrue(any("kaomoji not allowed" in e for e in errs), errs)
        self.assertTrue(any("laughter not allowed" in e for e in errs), errs)
        self.assertTrue(any("mood-banned word" in e for e in errs), errs)
        self.assertFalse(any("White cloud" in e for e in errs), errs)

    def test_default_rules_file_loads(self) -> None:
        rules = load_rules()
        self.assertEqual(rules.get("version"), 1)
        for mood in MOODS:
            self.assertIn(mood, rules.get("moods", {}))

    def test_detects_missing_counts(self) -> None:
        data = _valid_bundle("en")
        errs = check_bundle(data, "en")
        # 5 moods * 5 tiers + 5 moods missing min bases + 1 total item count + 3 calm moods * 5 tiers min bases
        self.assertEqual(
            len(errs),
            len(MOODS) * len(TIERS) + len(MOODS) + 1 + 3 * len(TIERS),
        )

    def test_safety_rules_reject_assertions_and_allow_optional_suggestions(self) -> None:
        rules = load_rules()
        bad_cases = {
            "ko": [
                "\uc9c0\uae08 \uc774 \ubc29 \uc548\uc804\ud574",
                "\uc2ec\uc7a5\uc774 \ube68\ub9ac \ub6f0\uc5b4",
                "\uacc1\uc5d0 \uc788\uc5b4 \uc904\uac8c",
                "\uc228\uc744 \uba48\ucdb0 \ubd10",
                "\ub3c4\ub9dd\uce58\uc9c0 \uc54a\uace0 \uc798 \ubc84\ud17c\uc5b4",
            ],
            "en": [
                "You are safe here",
                "Heart beats so fast",
                "Right here with you",
                "Hold your breath now",
                "Did not flee today",
            ],
            "ja": [
                "ここは安全な場所",
                "心臓が速く打つね",
                "ずっとそばにいるよ",
                "息を止めてみて",
                "逃げずに耐え抜いた",
            ],
        }
        good_cases = {
            "ko": ["\uc5b4\uae68 \ub0b4\ub824 \ubd10\ub3c4 \ub3fc", "\ubb3c \ub9c8\uc154\ub3c4 \uc548 \ub9c8\uc154\ub3c4"],
            "en": ["Can rest hands now", "Okay to pause here"],
            "ja": ["肩を下ろしてもいい", "水は飲まなくてもいい"],
        }
        for lang in ("ko", "en", "ja"):
            for mood in ("angry", "anxious"):
                for phrase in bad_cases[lang]:
                    data = _valid_bundle(lang)
                    data["moods"][mood]["low"][0] = phrase
                    errs = check_bundle(data, lang, self.small_counts, rules=rules)
                    self.assertTrue(
                        any("mood-banned" in e for e in errs),
                        f"{lang}.{mood} should reject {phrase!r}, got {errs}",
                    )
                for phrase in good_cases[lang]:
                    data = _valid_bundle(lang)
                    data["moods"][mood]["low"][0] = phrase
                    errs = check_bundle(data, lang, self.small_counts, rules=rules)
                    self.assertEqual(
                        [],
                        errs,
                        f"{lang}.{mood} should allow {phrase!r}, got {errs}",
                    )

    def test_unnegated_self_harm_is_rejected_across_all_moods(self) -> None:
        bad = {
            "ko": "\ub098\ub97c \ud574\uccd0",
            "en": "Hurt yourself now",
            "ja": "\u305f\u3060\u81ea\u5206\u50b7\u3064\u3051",
        }
        good = {
            "ko": "\ub098\ub97c \ud574\uce58\uc9c0 \uc54a\uc544",
            "en": "Do not hurt yourself",
            "ja": "\u81ea\u5206\u3092\u50b7\u3064\u3051\u306a\u304f\u3066\u3044\u3044",
        }
        for lang in ("ko", "en", "ja"):
            for mood in MOODS:
                data = _valid_bundle(lang)
                data["moods"][mood]["low"][0] = bad[lang]
                errs = check_bundle(data, lang, self.small_counts)
                self.assertTrue(
                    any("self-harm" in e for e in errs),
                    f"{lang}.{mood} should reject {bad[lang]!r}, got {errs}",
                )
                data = _valid_bundle(lang)
                data["moods"][mood]["low"][0] = good[lang]
                errs = check_bundle(data, lang, self.small_counts)
                self.assertEqual(
                    [],
                    errs,
                    f"{lang}.{mood} should allow {good[lang]!r}, got {errs}",
                )

    def test_per_tier_unique_base_minimums_pass_exact_and_fail_short(self) -> None:
        tier_mins = {"low": 2, "high": 2, "full": 1, "complete": 1, "rare": 1}
        data = _valid_bundle("en")
        self.assertEqual(
            [],
            check_bundle(
                data,
                "en",
                min_counts=self.small_counts,
                min_bases_per_tier=tier_mins,
            ),
        )
        # Adding a variation under the same base 'b' does not add a new unique base.
        short_data = _valid_bundle("en")
        short_data["moods"]["angry"]["low"] = [
            {"t": "Okay one", "b": "b1"},
            {"t": "Okay one again", "b": "b1"},
        ]
        errs = check_bundle(
            short_data,
            "en",
            min_counts=self.small_counts,
            min_bases_per_tier=tier_mins,
        )
        self.assertTrue(
            any("en.angry.low:" in e and "short by 1" in e for e in errs),
            errs,
        )


BANNED_KO = "\uc6b0\uc6b8\uc99d"  # a clinical word the rules forbid in cheers

ROOT = Path(__file__).resolve().parent.parent


class RealAssets(unittest.TestCase):
    """The checker must run on the shipped assets, not only on fixtures."""

    def run_on(self, root):
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            code = main(["--root", str(root)])
        return code, err.getvalue()

    def test_the_shipped_assets_pass(self):
        self.assertEqual((0, ""), self.run_on(ROOT))

    def test_a_forbidden_word_in_a_shipped_asset_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            shutil.copytree(ROOT / "assets" / "cheers", Path(tmp) / "assets" / "cheers")
            path = Path(tmp) / "assets" / "cheers" / "ko.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            first = data["moods"]["happy"]["low"][0]
            first["t"] = BANNED_KO + " " + first["t"]
            path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            code, err = self.run_on(tmp)
        self.assertEqual(1, code)
        self.assertIn("ko", err)

if __name__ == "__main__":
    unittest.main()
