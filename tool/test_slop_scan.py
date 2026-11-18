"""slop_scan 의 판정을 고정한다. 걸리는 말은 조각을 이어 붙여 이 파일 자체가 걸리지 않게 한다."""
import unittest

from slop_scan import findings_in_line, scan_diff

EM = "—"
EN = "–"
CURLY = "“"


class FindsSlop(unittest.TestCase):
    def test_flags_dashes_used_as_connectors(self):
        self.assertIn("대시", findings_in_line(f"새 셸 {EM} 실행 중인 작업은 끝납니다", "md"))
        self.assertIn("대시", findings_in_line(f"a {EN} b", "md"))

    def test_flags_curly_quotes(self):
        self.assertIn("둥근 따옴표", findings_in_line(f"{CURLY}hello”", "md"))

    def test_flags_ai_vocabulary_and_chatbot_phrases(self):
        self.assertIn("AI 말투", findings_in_line("Let us " + "delve" + " into it", "md"))
        self.assertIn("AI 말투", findings_in_line("I hope this " + "helps!", "msg"))
        self.assertIn("AI 말투", findings_in_line("물론" + "입니다! 바로 하겠습니다", "md"))

    def test_flags_emoji_in_headings_and_bullets(self):
        self.assertIn("꾸밈 이모지", findings_in_line("## \U0001F680 시작하기", "md"))
        self.assertIn("꾸밈 이모지", findings_in_line("- ✅ 끝남", "md"))

    def test_flags_debug_prints_and_dynamic_casts_in_dart(self):
        self.assertIn("디버그 출력", findings_in_line("    pr" + "int('x');", "dart"))
        self.assertIn("디버그 출력", findings_in_line("debugPr" + "int(x);", "dart"))
        self.assertIn("dynamic 캐스트", findings_in_line("final y = x as " + "dynamic;", "dart"))

    def test_reports_path_and_line(self):
        diff = f"+++ b/docs/A.md\n@@ -0,0 +4,2 @@\n+괜찮은 줄\n+a {EM} b\n"
        self.assertEqual(["docs/A.md:5 대시"], scan_diff(diff))


class AllowsNormalText(unittest.TestCase):
    def test_allows_plain_korean_and_hyphens(self):
        self.assertEqual([], findings_in_line("실행 중인 작업을 끝내고 셸을 새로 엽니다. well-known", "md"))

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
