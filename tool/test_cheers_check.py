import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cheers_check import MOODS, TIERS, check_bundle, count_graphemes


def _valid_bundle(lang: str) -> dict:
    sample = "\ud1a1!" if lang == "ko" else "Yay!"
    moods = {}
    n = 0
    for mood in MOODS:
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
        en = _valid_bundle("en")
        en["moods"]["sad"]["low"][0] = "Best therapy"
        en["moods"]["angry"]["low"][0] = "Wait\u2014now"
        en["moods"]["happy"]["low"][0] = "\u201cNice\u201d"
        errs = check_bundle(en, "en", self.small_counts)
        self.assertEqual(len(errs), 3, errs)

        ko = _valid_bundle("ko")
        ko["moods"]["sad"]["low"][0] = "\uc6b0\uc6b8\uc99d \uadf9\ubcf5"
        errs_ko = check_bundle(ko, "ko", self.small_counts)
        self.assertTrue(any("forbidden word" in e for e in errs_ko), errs_ko)

    def test_detects_missing_counts(self) -> None:
        data = _valid_bundle("en")
        errs = check_bundle(data, "en")
        # 5 moods * 5 tiers + 5 moods missing min bases
        self.assertEqual(len(errs), len(MOODS) * len(TIERS) + len(MOODS))


if __name__ == "__main__":
    unittest.main()
