"""Pin that the checks are really connected to the places that run them."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


class Wiring(unittest.TestCase):
    def test_cheers_check_runs_in_test_script_pre_commit_and_ci(self):
        for rel in ("tool/test.sh", ".githooks/pre-commit", ".github/workflows/ci.yml"):
            self.assertIn("tool/cheers_check.py", read(rel), rel)

    def test_a_pull_request_text_is_scanned_without_printing_values(self):
        ci = read(".github/workflows/ci.yml")
        self.assertRegex(ci, r"pull_request:\s*\n\s+types:\s*\[[^\]]*\bedited\b")
        self.assertIn("PR_BODY: ${{ github.event.pull_request.body }}", ci)
        self.assertIn("PR_TITLE: ${{ github.event.pull_request.title }}", ci)
        self.assertIn('tool/privacy_scan.py --message "$RUNNER_TEMP/pr-text.txt"', ci)

    def test_the_text_is_never_interpolated_into_a_shell_line(self):
        for line in read(".github/workflows/ci.yml").splitlines():
            if line.strip().startswith("run:") or line.strip().startswith("python3 "):
                self.assertNotIn("pull_request.body", line)
                self.assertNotIn("pull_request.title", line)

    def test_an_edited_description_does_not_rerun_the_builds(self):
        ci = read(".github/workflows/ci.yml")
        check = ci[ci.index("  check:"):ci.index("  apple:")]
        self.assertIn("github.event.action != 'edited'", check)

    def test_a_newer_push_cancels_the_older_run(self):
        # Queued macOS jobs from stale commits were cancelled one by one and each sent a failure mail.
        ci = read(".github/workflows/ci.yml")
        top = ci[:ci.index("jobs:")]
        self.assertRegex(top, r"concurrency:\s*\n\s+group: ci-\$\{\{ github\.event\.pull_request\.number \|\| github\.ref \}\}")
        self.assertIn("cancel-in-progress: true", top)
        # A text edit must not cancel the build of the same commit.
        self.assertIn("github.event.action == 'edited'", top)

    def test_the_apple_build_cannot_wait_forever(self):
        ci = read(".github/workflows/ci.yml")
        self.assertRegex(ci[ci.index("  apple:"):], r"timeout-minutes: \d+")


if __name__ == "__main__":
    unittest.main()
