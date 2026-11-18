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


class RepositoryTree(unittest.TestCase):
    def test_repository_sources_pass(self):
        errors, warnings = l10n_check.check_tree()
        self.assertEqual([], errors)

    def test_ci_command_exits_zero(self):
        self.assertEqual(0, l10n_check.main())
