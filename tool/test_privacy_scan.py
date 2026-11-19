"""Pin privacy_scan verdicts.

Realistic values are built from pieces so this file does not trip the scan itself.
Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from privacy_scan import findings_in_line, scan_diff, scan_files
from testsupport import run_git

SCANNER = Path(__file__).resolve().parent / "privacy_scan.py"

LAN_IP = "192.168." + "1.23"
TAIL_IP = "100.101." + "2.3"
EMAIL = "someone" + "@" + "gmail.com"
HOME = "/home/" + "alice" + "/project"
MAC_HOME = "/Users/" + "alice" + "/Library"
REAL_COORD = "37.5665" + "12, 126.9780" + "12"
API_KEY = "AIza" + "Sy" + "A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7"
ULA_V6 = "fd12:3456:" + "789a::1"  # privacy-ok fake ULA
INTERNAL_HOST = "nas" + ".lan"


class Repo:
    """Run the scanner against a real git repository, replaying the review scenarios."""

    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "dev@example.com")
        self.git("config", "user.name", "dev")
        self.commit("README.md", "start\n", "chore: start")

    def git(self, *args):
        return run_git(self.dir, *args)

    def write(self, name, text):
        path = self.dir / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def commit(self, name, text, message):
        self.write(name, text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)
        return self.git("rev-parse", "HEAD")

    def scan(self, *args):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        return subprocess.run([sys.executable, str(SCANNER), *args], cwd=self.dir, capture_output=True, text=True, env=env)


class FindsLeaks(unittest.TestCase):
    def test_flags_lan_and_tailscale_ip(self):
        self.assertIn("IP", findings_in_line(f"host = '{LAN_IP}'"))
        self.assertIn("IP", findings_in_line(f"ssh {TAIL_IP}"))

    def test_flags_real_email(self):
        self.assertIn("email", findings_in_line(f"contact: {EMAIL}"))

    def test_flags_home_paths_on_linux_and_mac(self):
        self.assertIn("home path", findings_in_line(HOME))
        self.assertIn("home path", findings_in_line(MAC_HOME))

    def test_flags_precise_coordinates(self):
        self.assertIn("coordinates", findings_in_line(f"LatLng({REAL_COORD})"))

    def test_flags_known_key_shapes(self):
        self.assertIn("key", findings_in_line(f"apiKey: {API_KEY}"))

    def test_flags_secret_files_but_not_env_example(self):
        hits = scan_files(["android/key.properties", "android/app/google-services.json", ".env", ".env.example"])
        self.assertEqual(3, len(hits))
        self.assertFalse(any(".env.example" in h for h in hits))

    def test_reports_path_and_line_without_value(self):
        diff = f"+++ b/lib/a.dart\n@@ -0,0 +3,2 @@\n+ok line\n+mail {EMAIL}\n"
        hits = scan_diff(diff)
        self.assertEqual(["lib/a.dart:4 email"], hits)
        self.assertNotIn("gmail", hits[0])


class AllowsDocumentationValues(unittest.TestCase):
    def test_allows_documentation_ip_and_example_email(self):
        self.assertEqual([], findings_in_line("server: 192.0.2.10 user@example.com"))

    def test_allows_generic_home_and_coarse_coordinates(self):
        self.assertEqual([], findings_in_line("/home/runner/work LatLng(37.56, 126.97)"))

    def test_allows_flutter_generated_files(self):
        self.assertEqual([], findings_in_line('"filename" : "Icon-App-20x20@2x.png",'))
        self.assertEqual([], findings_in_line("  revision: " + "8f3a" * 10))

    def test_privacy_ok_marker_skips_line(self):
        self.assertEqual([], findings_in_line(f"{EMAIL} // privacy-ok"))

    def test_ignores_removed_lines(self):
        self.assertEqual([], scan_diff(f"+++ b/a.txt\n@@ -1 +0,0 @@\n-{EMAIL}\n"))


class ClosesReviewGaps(unittest.TestCase):
    def test_range_sees_secret_file_added_then_deleted(self):
        repo = Repo()
        base = repo.git("rev-parse", "HEAD")
        repo.commit("android/key.properties", "storePassword=x\n", "chore: add")
        repo.git("rm", "-q", "android/key.properties")
        repo.git("commit", "-q", "-m", "chore: remove")
        result = repo.scan("--range", f"{base}..HEAD")
        self.assertEqual(1, result.returncode, result.stderr)
        self.assertIn("key.properties", result.stderr)

    def test_range_sees_leak_added_then_reverted(self):
        repo = Repo()
        base = repo.git("rev-parse", "HEAD")
        repo.commit("notes.txt", f"mail {EMAIL}\n", "docs: add")
        repo.commit("notes.txt", "clean\n", "docs: clean")
        self.assertEqual(1, repo.scan("--range", f"{base}..HEAD").returncode)

    def test_staged_sees_secret_file_under_non_ascii_folder(self):
        repo = Repo()
        repo.write("\uc124\uc815/key.properties", "storePassword=x\n")
        repo.git("add", "-A")
        result = repo.scan("--staged")
        self.assertEqual(1, result.returncode, result.stderr)
        self.assertIn("\uc124\uc815/key.properties", result.stderr)

    def test_range_sees_secret_file_under_non_ascii_folder(self):
        repo = Repo()
        base = repo.git("rev-parse", "HEAD")
        repo.commit("\uc124\uc815/.env", "A=1\n", "chore: env")
        self.assertEqual(1, repo.scan("--range", f"{base}..HEAD").returncode)

    def test_key_inside_svg_is_still_caught(self):
        diff = f"+++ b/assets/logo.svg\n@@ -0,0 +1 @@\n+<svg data-k=\"{API_KEY}\"/>\n"
        self.assertEqual(["assets/logo.svg:1 key"], scan_diff(diff))

    def test_key_inside_very_long_line_is_still_caught(self):
        diff = f"+++ b/a.js\n@@ -0,0 +1 @@\n+{'x' * 3000} {API_KEY}\n"
        self.assertEqual(["a.js:1 key"], scan_diff(diff))

    def test_lock_file_hashes_stay_quiet(self):
        diff = "+++ b/pubspec.lock\n@@ -0,0 +1 @@\n+      sha256: \"" + "ab12" * 16 + "\"\n"
        self.assertEqual([], scan_diff(diff))

    def test_flags_private_ipv6_and_internal_hosts(self):
        self.assertIn("IP", findings_in_line(f"server: [{ULA_V6}]"))
        self.assertIn("internal host", findings_in_line(f"url: http://{INTERNAL_HOST}:8080"))

    def test_allows_documentation_ipv6_and_local_settings_file(self):
        self.assertEqual([], findings_in_line("server: [2001:db8::1] and ::1"))
        self.assertEqual([], findings_in_line(".claude/settings.local.json"))
        self.assertEqual([], findings_in_line("final x = a::b;"))

    def test_four_part_version_is_not_an_ip(self):
        self.assertEqual([], findings_in_line("version: 10.2.3.4"))

    def test_message_comment_lines_are_scanned(self):
        repo = Repo()
        repo.write("MSG", f"feat: x\n#{EMAIL}\n")
        self.assertEqual(1, repo.scan("--message", "MSG").returncode)

    def test_message_ignores_verbose_diff_below_git_scissors(self):
        repo = Repo()
        repo.write("MSG", "feat: x\n# ------------------------ >8 ------------------------\n"
                   "# Do not modify or remove the line above.\n" + f"+{EMAIL}\n")
        self.assertEqual(0, repo.scan("--message", "MSG").returncode)


class ClosesSecondReview(unittest.TestCase):
    def test_range_sees_leak_added_only_in_merge_commit(self):
        repo = Repo()
        base = repo.git("rev-parse", "HEAD")
        repo.git("switch", "-q", "-c", "side")
        repo.commit("side.txt", "x\n", "chore: side")
        repo.git("switch", "-q", "main")
        repo.commit("main.txt", "y\n", "chore: main")
        repo.git("merge", "-q", "--no-commit", "side")
        repo.write("android/key.properties", "storePassword=x\n")
        repo.write("notes.txt", f"mail {EMAIL}\n")
        repo.git("add", "-A")
        repo.git("commit", "-q", "-m", "chore: merge")
        result = repo.scan("--range", f"{base}..HEAD")
        self.assertEqual(1, result.returncode)
        self.assertIn("key.properties", result.stderr)
        self.assertIn("notes.txt", result.stderr)

    def test_flags_password_in_json(self):
        secret = "Ab3" + "xY9qLm2" + "Pz7WkR4tQ2v"
        self.assertIn("secret", findings_in_line(f'  "password": "{secret}",'))

    def test_quoted_korean_path_with_double_quote_does_not_crash(self):
        repo = Repo()
        repo.write('\uba54\ubaa8 "1".txt', "plain line\n")
        repo.git("add", "-A")
        result = repo.scan("--staged")
        self.assertEqual(0, result.returncode, result.stderr)

    def test_verbatim_cleanup_scans_below_scissors_written_by_hand(self):
        repo = Repo()
        repo.git("config", "commit.cleanup", "verbatim")
        repo.write("MSG", f"feat: x\n# ------------------------ >8 ------------------------\n{EMAIL}\n")
        self.assertEqual(1, repo.scan("--message", "MSG").returncode)

    def test_internal_host_with_trailing_dot(self):
        self.assertIn("internal host", findings_in_line(f"server: {INTERNAL_HOST}."))

    def test_cpp_scope_and_server_version_are_not_addresses(self):
        self.assertEqual([], findings_in_line("server = a::b;"))
        self.assertEqual([], findings_in_line("Server version 10.2.3.4"))
        self.assertIn("IP", findings_in_line("server version at http://" + LAN_IP))

    def test_content_line_shaped_like_file_header_is_still_scanned(self):
        diff = f"+++ b/a.txt\n@@ -0,0 +1,2 @@\n+++ b/x {API_KEY}\n+ok\n"
        self.assertEqual(["a.txt:1 key"], scan_diff(diff))


class ClosesThirdReview(unittest.TestCase):
    def test_unicode_line_separator_does_not_shift_hunks(self):
        diff = ("+++ b/a.svg\n@@ -0,0 +1,2 @@\n+<svg>\u2028</svg>\n+<g/>\n"
                f"+++ b/b.md\n@@ -0,0 +1 @@\n+mail {EMAIL}\n")
        self.assertEqual(["b.md:1 email"], scan_diff(diff))

    def test_version_field_does_not_hide_host_address(self):
        line = '{"host": "' + LAN_IP + '", "version": "1.2.3"}'
        self.assertIn("IP", findings_in_line(line))

    def test_a_short_version_before_the_host_does_not_hide_it_either(self):
        line = '{"version": 1, "host": "' + LAN_IP + '"}'
        self.assertIn("IP", findings_in_line(line))
        self.assertIn("IP", findings_in_line("version 1, server " + LAN_IP))

    def test_a_version_value_that_looks_like_an_address_stays_allowed_in_both_shapes(self):
        self.assertEqual([], findings_in_line('{"version": "10.2.3.4"}'))
        self.assertEqual([], findings_in_line("build 10.2.3.4"))
        self.assertEqual([], findings_in_line("tool v10.2.3.4"))

    def test_path_with_space_keeps_its_extension(self):
        diff = f"+++ b/docs/a b.md\t\n@@ -0,0 +1 @@\n+mail {EMAIL}\n"
        self.assertEqual(["docs/a b.md:1 email"], scan_diff(diff))

    def test_merge_reports_only_lines_new_to_every_parent(self):
        repo = Repo()
        repo.git("switch", "-q", "-c", "feature")
        base = repo.git("rev-parse", "main")
        repo.commit("feature.md", "ok\n", "docs: feature")
        repo.git("switch", "-q", "main")
        repo.commit("base.txt", f"mail {EMAIL}  privacy-ok\n", "docs: base")
        repo.commit("base.txt", f"mail {EMAIL}\n", "docs: base again")
        repo.git("switch", "-q", "feature")
        repo.git("merge", "-q", "--no-edit", "main")
        main_tip = repo.git("rev-parse", "main")
        self.assertEqual(0, repo.scan("--range", f"{main_tip}..feature").returncode)

    def test_message_keeps_scissors_text_unless_git_wrote_it(self):
        repo = Repo()
        repo.write("MSG", f"feat: x\n# ------------------------ >8 ------------------------\n{EMAIL}\n")
        self.assertEqual(1, repo.scan("--message", "MSG").returncode)
        repo.write("MSG2", "feat: x\n# ------------------------ >8 ------------------------\n"
                   "# Do not modify or remove the line above.\n" + f"+{EMAIL}\n")
        self.assertEqual(0, repo.scan("--message", "MSG2").returncode)


if __name__ == "__main__":
    unittest.main()
