"""privacy_scan 의 판정을 고정한다.

진짜처럼 보이는 값은 조각을 이어 붙여 만든다. 이 파일 자체가 검사에 걸리지 않게 하려는 것이다.
실행: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import unittest

from privacy_scan import findings_in_line, scan_diff, scan_files

LAN_IP = "192.168." + "1.23"
TAIL_IP = "100.101." + "2.3"
EMAIL = "someone" + "@" + "gmail.com"
HOME = "/home/" + "alice" + "/project"
MAC_HOME = "/Users/" + "alice" + "/Library"
REAL_COORD = "37.5665" + "12, 126.9780" + "12"
API_KEY = "AIza" + "Sy" + "A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7"


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


if __name__ == "__main__":
    unittest.main()
