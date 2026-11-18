"""privacy_scan 의 판정을 고정한다.

진짜처럼 보이는 값은 조각을 이어 붙여 만든다. 이 파일 자체가 검사에 걸리지 않게 하려는 것이다.
실행: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from privacy_scan import findings_in_line, scan_diff, scan_files

SCANNER = Path(__file__).resolve().parent / "privacy_scan.py"

LAN_IP = "192.168." + "1.23"
TAIL_IP = "100.101." + "2.3"
EMAIL = "someone" + "@" + "gmail.com"
HOME = "/home/" + "alice" + "/project"
MAC_HOME = "/Users/" + "alice" + "/Library"
REAL_COORD = "37.5665" + "12, 126.9780" + "12"
API_KEY = "AIza" + "Sy" + "A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7"
ULA_V6 = "fd12:3456:" + "789a::1"  # privacy-ok 가짜 ULA
INTERNAL_HOST = "nas" + ".lan"


class Repo:
    """검사기를 실제 git 저장소에 돌려 본다. 리뷰에서 나온 재현 시나리오를 그대로 옮긴다."""

    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "dev@example.com")
        self.git("config", "user.name", "dev")
        self.commit("README.md", "start\n", "chore: start")

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.dir, check=True, capture_output=True, text=True).stdout.strip()

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
        self.assertIn("이메일", findings_in_line(f"contact: {EMAIL}"))

    def test_flags_home_paths_on_linux_and_mac(self):
        self.assertIn("홈 경로", findings_in_line(HOME))
        self.assertIn("홈 경로", findings_in_line(MAC_HOME))

    def test_flags_precise_coordinates(self):
        self.assertIn("좌표", findings_in_line(f"LatLng({REAL_COORD})"))

    def test_flags_known_key_shapes(self):
        self.assertIn("키", findings_in_line(f"apiKey: {API_KEY}"))

    def test_flags_secret_files_but_not_env_example(self):
        hits = scan_files(["android/key.properties", "android/app/google-services.json", ".env", ".env.example"])
        self.assertEqual(3, len(hits))
        self.assertFalse(any(".env.example" in h for h in hits))

    def test_reports_path_and_line_without_value(self):
        diff = f"+++ b/lib/a.dart\n@@ -0,0 +3,2 @@\n+ok line\n+mail {EMAIL}\n"
        hits = scan_diff(diff)
        self.assertEqual(["lib/a.dart:4 이메일"], hits)
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
        repo.write("설정/key.properties", "storePassword=x\n")
        repo.git("add", "-A")
        result = repo.scan("--staged")
        self.assertEqual(1, result.returncode, result.stderr)
        self.assertIn("설정/key.properties", result.stderr)

    def test_range_sees_secret_file_under_non_ascii_folder(self):
        repo = Repo()
        base = repo.git("rev-parse", "HEAD")
        repo.commit("설정/.env", "A=1\n", "chore: env")
        self.assertEqual(1, repo.scan("--range", f"{base}..HEAD").returncode)

    def test_key_inside_svg_is_still_caught(self):
        diff = f"+++ b/assets/logo.svg\n@@ -0,0 +1 @@\n+<svg data-k=\"{API_KEY}\"/>\n"
        self.assertEqual(["assets/logo.svg:1 키"], scan_diff(diff))

    def test_key_inside_very_long_line_is_still_caught(self):
        diff = f"+++ b/a.js\n@@ -0,0 +1 @@\n+{'x' * 3000} {API_KEY}\n"
        self.assertEqual(["a.js:1 키"], scan_diff(diff))

    def test_lock_file_hashes_stay_quiet(self):
        diff = "+++ b/pubspec.lock\n@@ -0,0 +1 @@\n+      sha256: \"" + "ab12" * 16 + "\"\n"
        self.assertEqual([], scan_diff(diff))

    def test_flags_private_ipv6_and_internal_hosts(self):
        self.assertIn("IP", findings_in_line(f"server: [{ULA_V6}]"))
        self.assertIn("내부 호스트", findings_in_line(f"url: http://{INTERNAL_HOST}:8080"))

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

    def test_message_ignores_text_below_scissors(self):
        repo = Repo()
        repo.write("MSG", f"feat: x\n# ------------------------ >8 ------------------------\n+{EMAIL}\n")
        self.assertEqual(0, repo.scan("--message", "MSG").returncode)


if __name__ == "__main__":
    unittest.main()
