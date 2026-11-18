"""Pin l10n_check verdicts.

Korean strings appear as escapes so this file stays English only, matching
the repository rule.
Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import json
import tempfile
import unittest
from pathlib import Path

import l10n_check

KO_HELLO = "\ud589\ubcf5\ud574\uc694"  # three Hangul syllables, "happy" in Korean
LONG_KO = "\uc624\ub298\ub3c4 \uc218\ub9cc\uc73c\uc168\uc5b4\uc694"  # nine syllables, over the old limit when doubled


def write(root, name, text):
    path = root / name
    path.write_text(text, encoding="utf-8")
    return path


class ArbParity(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.template = {
            "@@locale": "ko",
            "moodSelect_today": "\uc624\ub298",
            "@moodSelect_today": {"description": "label"},
            "tap_todayCount": "{count, plural, other {\uc624\ub298 {count}}}",
        }

    def arb(self, name, data):
        return write(self.root, name, json.dumps(data, ensure_ascii=False))

    def test_matching_keys_and_placeholders_pass(self):
        other = dict(self.template)
        other["@@locale"] = "en"
        other["moodSelect_today"] = "Today"
        other["tap_todayCount"] = "{count, plural, other{Today {count}}}"
        self.arb("app_en.arb", other)
        self.assertEqual([], l10n_check.check_arb_pair(self.template, self.root / "app_en.arb"))

    def test_missing_key_is_an_error(self):
        other = dict(self.template)
        del other["moodSelect_today"]
        self.arb("app_en.arb", other)
        errors = l10n_check.check_arb_pair(self.template, self.root / "app_en.arb")
        self.assertTrue(any("missing key moodSelect_today" in e for e in errors), errors)

    def test_extra_key_is_an_error(self):
        other = dict(self.template)
        other["moodSelect_moodMeh"] = "meh"
        self.arb("app_en.arb", other)
        errors = l10n_check.check_arb_pair(self.template, self.root / "app_en.arb")
        self.assertTrue(any("extra key moodSelect_moodMeh" in e for e in errors), errors)

    def test_placeholder_mismatch_is_an_error(self):
        other = dict(self.template)
        other["tap_todayCount"] = "{count, plural, other{Today {number}}}"
        self.arb("app_en.arb", other)
        errors = l10n_check.check_arb_pair(self.template, self.root / "app_en.arb")
        self.assertTrue(any("placeholders of tap_todayCount" in e for e in errors), errors)

    def test_icu_clause_words_are_not_placeholders(self):
        self.assertEqual(frozenset({"count"}), l10n_check.placeholders("{count, plural, other {{count}}}"))

    def test_broken_json_is_an_error(self):
        write(self.root, "app_en.arb", "{not json")
        errors = l10n_check.check_arb_pair(self.template, self.root / "app_en.arb")
        self.assertEqual(1, len(errors))


def cheers(phrases=("nice", "well done")):
    return {
        "version": 1,
        "moods": {mood: {stage: list(phrases) for stage in l10n_check.STAGES} for mood in l10n_check.MOOD_IDS},
    }


class CheersFiles(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def write_cheers(self, data, name="ko.json"):
        return write(self.root, name, json.dumps(data, ensure_ascii=False))

    def test_agreed_shape_passes(self):
        path = self.write_cheers(cheers())
        errors, warnings = l10n_check.check_cheers_file(path)
        self.assertEqual([], errors)
        self.assertEqual([], warnings)

    def test_phrase_counts_may_differ_between_languages(self):
        data = cheers()
        data["moods"]["happy"]["low"] = ["nice", "good", KO_HELLO]
        path = self.write_cheers(data)
        errors, _ = l10n_check.check_cheers_file(path)
        self.assertEqual([], errors)

    def test_missing_mood_is_an_error(self):
        data = cheers()
        del data["moods"]["angry"]
        path = self.write_cheers(data)
        errors, _ = l10n_check.check_cheers_file(path)
        self.assertTrue(any("missing mood angry" in e for e in errors), errors)

    def test_unknown_mood_is_an_error(self):
        data = cheers()
        data["moods"]["sleepy"] = data["moods"]["happy"]
        path = self.write_cheers(data)
        errors, _ = l10n_check.check_cheers_file(path)
        self.assertTrue(any("unknown mood sleepy" in e for e in errors), errors)

    def test_empty_stage_is_an_error(self):
        data = cheers()
        data["moods"]["sad"]["full"] = []
        path = self.write_cheers(data)
        errors, _ = l10n_check.check_cheers_file(path)
        self.assertTrue(any("stage full needs a non-empty list" in e for e in errors), errors)

    def test_wrong_version_is_an_error(self):
        data = cheers()
        data["version"] = 2
        path = self.write_cheers(data)
        errors, _ = l10n_check.check_cheers_file(path)
        self.assertTrue(any("version" in e for e in errors), errors)

    def test_long_phrase_only_warns(self):
        data = cheers()
        data["moods"]["happy"]["low"] = [LONG_KO * 2]
        path = self.write_cheers(data)
        errors, warnings = l10n_check.check_cheers_file(path)
        self.assertEqual([], errors)
        self.assertTrue(any("longer than" in w for w in warnings), warnings)


class ValueLanguage(unittest.TestCase):
    """An en or ja file must not carry Korean text. A per-key allow list covers real exceptions."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.template = {"@@locale": "ko", "a_title": KO_HELLO, "a_name": KO_HELLO}

    def arb(self, name, data):
        return write(self.root, name, json.dumps(data, ensure_ascii=False))

    def cheers(self, name, phrases):
        stages = {"low": phrases, "high": phrases, "full": phrases}
        moods = {m: stages for m in l10n_check.MOOD_IDS}
        return write(self.root, name, json.dumps({"version": 1, "moods": moods}, ensure_ascii=False))

    def test_a_korean_value_in_an_en_arb_is_an_error(self):
        path = self.arb("app_en.arb", {"@@locale": "en", "a_title": "Today", "a_name": KO_HELLO})
        errors = l10n_check.check_arb_pair(self.template, path)
        self.assertEqual(1, len(errors), errors)
        self.assertIn("app_en.arb", errors[0])
        self.assertIn("a_name", errors[0])

    def test_a_korean_value_in_a_ja_arb_is_an_error(self):
        path = self.arb("app_ja.arb", {"@@locale": "ja", "a_title": "\u4eca\u65e5", "a_name": KO_HELLO})
        errors = l10n_check.check_arb_pair(self.template, path)
        self.assertEqual(1, len(errors), errors)
        self.assertIn("a_name", errors[0])

    def test_korean_in_the_ko_arb_and_in_metadata_is_fine(self):
        data = {"@@locale": "en", "a_title": "Today", "a_name": "Name", "@a_name": {"description": KO_HELLO}}
        self.assertEqual([], l10n_check.check_arb_pair(self.template, self.arb("app_en.arb", data)))

    def test_the_allow_list_excuses_one_key_only(self):
        data = {"@@locale": "en", "a_title": KO_HELLO, "a_name": KO_HELLO}
        errors = l10n_check.check_arb_pair(self.template, self.arb("app_en.arb", data),
                                           {"a_name": "native language name"})
        self.assertEqual(1, len(errors), errors)
        self.assertIn("a_title", errors[0])

    def test_an_allow_entry_that_is_not_needed_is_an_error(self):
        data = {"@@locale": "en", "a_title": "Today", "a_name": "Name"}
        errors = l10n_check.check_arb_pair(self.template, self.arb("app_en.arb", data), {"a_name": "old reason"})
        self.assertEqual(1, len(errors), errors)
        self.assertIn("a_name", errors[0])
        self.assertIn("not needed", errors[0])

    def test_an_allow_entry_needs_a_reason(self):
        data = {"@@locale": "en", "a_title": "Today", "a_name": KO_HELLO}
        errors = l10n_check.check_arb_pair(self.template, self.arb("app_en.arb", data), {"a_name": " "})
        self.assertTrue(any("reason" in e for e in errors), errors)

    def test_korean_in_en_cheers_is_an_error(self):
        errors, _ = l10n_check.check_cheers_file(self.cheers("en.json", ["Yay!", KO_HELLO]))
        self.assertTrue(errors)
        self.assertIn("en.json", errors[0])

    def test_korean_in_ja_cheers_is_an_error_including_phrase_objects(self):
        phrases = [{"t": KO_HELLO, "b": "happy_l001"}]
        errors, _ = l10n_check.check_cheers_file(self.cheers("ja.json", phrases))
        self.assertTrue(errors)

    def test_korean_cheers_are_fine(self):
        errors, _ = l10n_check.check_cheers_file(self.cheers("ko.json", [KO_HELLO]))
        self.assertEqual([], errors)

    def test_the_allow_list_works_for_cheers_by_phrase_text(self):
        path = self.cheers("en.json", ["Yay!", KO_HELLO])
        errors, _ = l10n_check.check_cheers_file(path, {KO_HELLO: "a loanword on purpose"})
        self.assertEqual([], errors)

    def test_the_real_allow_file_names_the_language_names(self):
        allow = l10n_check.load_allow()
        self.assertIn("settings_languageKo", allow["app_en.arb"])
        self.assertIn("settings_languageKo", allow["app_ja.arb"])

    def test_the_allow_file_may_only_name_files_that_exist(self):
        errors = l10n_check.check_allow_files({"app_fr.arb": {"k": "x"}})
        self.assertEqual(1, len(errors), errors)
        self.assertIn("app_fr.arb", errors[0])


class RepositoryTree(unittest.TestCase):
    def test_repository_sources_pass(self):
        errors, warnings = l10n_check.check_tree()
        self.assertEqual([], errors)

    def test_ci_command_exits_zero(self):
        self.assertEqual(0, l10n_check.main())
