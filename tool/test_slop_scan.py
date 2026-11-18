"""Pin slop_scan verdicts. Flagged words are built from pieces so this file does not trip the scan."""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from slop_scan import findings_in_line, scan_diff
from testsupport import run_git

SCANNER = Path(__file__).resolve().parent / "slop_scan.py"

EM = "—"
EN = "–"
CURLY = "“"


class FindsSlop(unittest.TestCase):
    def test_flags_dashes_used_as_connectors(self):
        self.assertIn("dash", findings_in_line(f"\uc0c8 \uc178 {EM} \uc2e4\ud589 \uc911\uc778 \uc791\uc5c5\uc740 \ub05d\ub0a9\ub2c8\ub2e4", "md"))
        self.assertIn("dash", findings_in_line(f"a {EN} b", "md"))

    def test_flags_curly_quotes(self):
        self.assertIn("curly quote", findings_in_line(f"{CURLY}hello”", "md"))

    def test_flags_ai_vocabulary_and_chatbot_phrases(self):
        self.assertIn("AI phrase", findings_in_line("Let us " + "delve" + " into it", "md"))
        self.assertIn("AI phrase", findings_in_line("I hope this " + "helps!", "msg"))
        self.assertIn("AI phrase", findings_in_line("\ubb3c\ub860" + "\uc785\ub2c8\ub2e4! \ubc14\ub85c \ud558\uaca0\uc2b5\ub2c8\ub2e4", "md"))

    def test_flags_emoji_in_headings_and_bullets(self):
        self.assertIn("decorative emoji", findings_in_line("## \U0001F680 \uc2dc\uc791\ud558\uae30", "md"))
        self.assertIn("decorative emoji", findings_in_line("- \U0001F389 \ub05d\ub0a8", "md"))

    def test_flags_debug_prints_and_dynamic_casts_in_dart(self):
        self.assertIn("debug print", findings_in_line("    pr" + "int('x');", "dart"))
        self.assertIn("debug print", findings_in_line("debugPr" + "int(x);", "dart"))
        self.assertIn("dynamic cast", findings_in_line("final y = x as " + "dynamic;", "dart"))

    def test_reports_path_and_line(self):
        diff = f"+++ b/docs/A.md\n@@ -0,0 +4,2 @@\n+\uad1c\ucc2e\uc740 \uc904\n+a {EM} b\n"
        self.assertEqual(["docs/A.md:5 dash"], scan_diff(diff))


class KeepsCodeEnglish(unittest.TestCase):
    KO = "\uc548\ub155"  # two Hangul syllables

    def test_flags_hangul_in_code_and_comments(self):
        self.assertIn("Hangul in code", findings_in_line(f"// {self.KO}", "dart"))
        self.assertIn("Hangul in code", findings_in_line(f"label = '{self.KO}'", "dart-test"))
        self.assertIn("Hangul in code", findings_in_line(f"# {self.KO}", "code"))

    def test_allows_hangul_in_docs_and_token_data(self):
        self.assertEqual([], findings_in_line(f"{self.KO} \ud569\ub2c8\ub2e4.", "md"))
        self.assertEqual([], findings_in_line(f'"$description": "{self.KO}"', "data"))

    def test_json_files_are_data(self):
        diff = f"+++ b/design/tokens.json\n@@ -0,0 +1 @@\n+\"{self.KO}\"\n"
        self.assertEqual([], scan_diff(diff))


class ClosesThirdReview(unittest.TestCase):
    def test_numeric_ranges_and_status_marks_are_fine(self):
        self.assertEqual([], findings_in_line("3\u20135", "md"))
        self.assertEqual([], findings_in_line("- \u2705 done", "md"))
        self.assertEqual([], findings_in_line("- \u26a0\ufe0f check", "md"))

    def test_ai_words_apply_to_prose_not_identifiers(self):
        self.assertEqual([], findings_in_line("final util" + "ization = 0.5;", "dart"))
        self.assertIn("AI phrase", findings_in_line("Certain" + "ly! Here it is", "md"))

    def test_print_rules_follow_dart_syntax(self):
        self.assertEqual([], findings_in_line("/// Call pr" + "int(x) to log.", "dart"))
        self.assertEqual([], findings_in_line("  String pr" + "int() => text;", "dart"))
        self.assertIn("debug print", findings_in_line("core.pr" + "int(x);", "dart"))

    def test_renamed_file_is_scanned_as_added(self):
        repo_dir = tempfile.TemporaryDirectory()
        d = Path(repo_dir.name)
        run = lambda *a: run_git(d, *a)
        run("init", "-q")
        run("config", "user.email", "dev@example.com")
        run("config", "user.name", "dev")
        (d / "test").mkdir()
        (d / "test" / "r.dart").write_text("void f() { pr" + "int(1); }\n")
        run("add", "-A")
        run("commit", "-q", "-m", "test: r")
        (d / "lib").mkdir()
        run("mv", "test/r.dart", "lib/r.dart")
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        r = subprocess.run([sys.executable, str(SCANNER), "--staged"], cwd=d, capture_output=True, text=True, env=env)
        self.assertEqual(1, r.returncode, r.stderr)


class JudgesARangeByItsResult(unittest.TestCase):
    """Style is about what lands, so a range is judged by its net diff, not by each commit."""

    def setUp(self):
        self.repo_dir = tempfile.TemporaryDirectory()
        self.d = Path(self.repo_dir.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "dev@example.com")
        self.git("config", "user.name", "dev")
        (self.d / "lib").mkdir()
        self.commit("lib/a.dart", "void a() {}\n", "chore: base")
        self.git("branch", "base")

    def tearDown(self):
        self.repo_dir.cleanup()

    def git(self, *a):
        return run_git(self.d, *a)

    def commit(self, path, text, message):
        (self.d / path).write_text(text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def scan_range(self):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        return subprocess.run([sys.executable, str(SCANNER), "--range", "base..HEAD"], cwd=self.d, capture_output=True, text=True, env=env)

    def test_a_tell_fixed_later_in_the_range_passes(self):
        self.commit("lib/a.dart", "void a() {} // \ud55c\uae00\n", "chore: add a comment")
        self.commit("lib/a.dart", "void a() {} // english\n", "fix: move the comment to English")
        r = self.scan_range()
        self.assertEqual(0, r.returncode, r.stderr)

    def test_a_tell_left_at_the_end_fails(self):
        self.commit("lib/a.dart", "void a() {} // \ud55c\uae00\n", "chore: add a comment")
        r = self.scan_range()
        self.assertEqual(1, r.returncode, r.stderr)
        self.assertIn("lib/a.dart:1", r.stderr)

    def test_commit_messages_are_still_checked_one_by_one(self):
        self.commit("lib/a.dart", "void b() {}\n", "chore: tidy \u2014 then more")
        self.commit("lib/a.dart", "void c() {}\n", "chore: tidy again")
        r = self.scan_range()
        self.assertEqual(1, r.returncode, r.stderr)
        self.assertIn("commit message", r.stderr)


class KeepsTheStyleFlat(unittest.TestCase):
    """Design rule: no gradients, blurred shadows or glows. Banned names are built from pieces so this file stays clean."""

    def flat(self, line, kind="dart"):
        return "flat style" in findings_in_line(line, kind)

    def test_flags_gradients(self):
        for name in ("Linear", "Radial", "Sweep"):
            self.assertTrue(self.flat(f"  gradient: const {name}Gradient(colors: c),"), name)
        self.assertTrue(self.flat("final g = Gra" + "dient(colors: c);"))

    def test_flags_shadows_and_blurs(self):
        self.assertTrue(self.flat("boxShadow: [Box" + "Shadow(blurRadius: 4)],"))
        self.assertTrue(self.flat("shadows: [const Sha" + "dow(blurRadius: 8)],"))
        self.assertTrue(self.flat("ImageFilter" + ".blur(sigmaX: 2, sigmaY: 2)"))
        self.assertTrue(self.flat("child: Backdrop" + "Filter(filter: f),"))
        self.assertTrue(self.flat("MaskFilter" + ".blur(BlurStyle.normal, 3)"))

    def test_flags_nonzero_elevation_only(self):
        self.assertTrue(self.flat("elevation: 4,"))
        self.assertTrue(self.flat("Card(elevation: e)"))
        self.assertFalse(self.flat("elevation: 0,"))
        self.assertFalse(self.flat("Card(elevation: 0.0)"))
        self.assertFalse(self.flat("scrolledUnderElevation: 0,"))

    def test_checks_tests_too(self):
        self.assertTrue(self.flat("final g = Linear" + "Gradient(colors: c);", "dart-test"))

    def test_skips_comments_and_test_names(self):
        self.assertFalse(self.flat("// no Linear" + "Gradient here"))
        self.assertFalse(self.flat("/// Never use Box" + "Shadow."))
        self.assertFalse(self.flat("final x = 1; // was Box" + "Shadow"))
        self.assertFalse(self.flat("  test('has no Linear" + "Gradient', () {", "dart-test"))
        self.assertFalse(self.flat("testWidgets(\"no Backdrop" + "Filter\", (t) async {", "dart-test"))
        self.assertFalse(self.flat("group('no Box" + "Shadow', () {", "dart-test"))

    def test_test_name_exemption_does_not_hide_code_after_it(self):
        self.assertTrue(self.flat("test('x', () => Box" + "Shadow());", "dart-test"))

    def test_marker_skips_line(self):
        self.assertFalse(self.flat("elevation: 4,  slop-ok"))

    def test_other_languages_are_not_checked(self):
        self.assertFalse(self.flat("elevation: 4", "code"))
        self.assertFalse(self.flat("Linear" + "Gradient", "md"))

    def test_reports_path_and_line(self):
        diff = "+++ b/lib/a.dart\n@@ -0,0 +3 @@\n+  elevation: 2,\n"
        self.assertEqual(["lib/a.dart:3 flat style"], scan_diff(diff))


class AllowsNormalText(unittest.TestCase):
    def test_allows_plain_korean_and_hyphens(self):
        self.assertEqual([], findings_in_line("\uc2e4\ud589 \uc911\uc778 \uc791\uc5c5\uc744 \ub05d\ub0b4\uace0 \uc178\uc744 \uc0c8\ub85c \uc5fd\ub2c8\ub2e4. well-known", "md"))

    def test_allows_markdown_rules_and_table_borders(self):
        self.assertEqual([], findings_in_line("---", "md"))
        self.assertEqual([], findings_in_line("|---|---|", "md"))

    def test_prints_are_fine_outside_lib_dart(self):
        self.assertEqual([], findings_in_line("print(x)", "py"))

    def test_marker_skips_line(self):
        self.assertEqual([], findings_in_line(f"a {EM} b  slop-ok", "md"))

    def test_skips_files_it_does_not_judge(self):
        self.assertEqual([], scan_diff(f"+++ b/assets/fonts/x.svg\n@@ -0,0 +1 @@\n+{EM}\n"))
        self.assertEqual([], scan_diff(f"+++ b/THIRD_PARTY_NOTICES.md\n@@ -0,0 +1 @@\n+{EM}\n"))


if __name__ == "__main__":
    unittest.main()
