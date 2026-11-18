"""Tests that make throwaway repositories must never touch the real one.

Git runs hooks with GIT_DIR and GIT_INDEX_FILE pointing at the real repository. A test
that called git in a temporary folder with that environment once committed into the
branch being pushed. These tests pin both guards: the shared helper and tool/test.sh.
"""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from testsupport import git_env, run_git

TOOL = Path(__file__).resolve().parent


def make_repo(path):
    subprocess.run(["git", "init", "-q", str(path)], check=True, env=git_env(), capture_output=True)
    run_git(path, "config", "user.email", "dev@example.com")
    run_git(path, "config", "user.name", "dev")
    (path / "f.txt").write_text("x\n")
    run_git(path, "add", "-A")
    run_git(path, "commit", "-q", "-m", "chore: start")
    return run_git(path, "rev-parse", "HEAD")


class GitIsolation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.real = root / "real"
        self.scratch = root / "scratch"
        self.real.mkdir()
        self.scratch.mkdir()
        self.real_head = make_repo(self.real)
        self.saved = dict(os.environ)
        os.environ["GIT_DIR"] = str(self.real / ".git")
        os.environ["GIT_INDEX_FILE"] = str(self.real / ".git" / "index")

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.saved)
        self.tmp.cleanup()

    def real_state(self):
        env = git_env()
        head = subprocess.run(["git", "-C", str(self.real), "rev-parse", "HEAD"], env=env, capture_output=True, text=True).stdout.strip()
        branches = subprocess.run(["git", "-C", str(self.real), "branch", "--format=%(refname:short)"], env=env, capture_output=True, text=True).stdout.split()
        return head, branches

    def test_helper_ignores_the_hook_environment(self):
        before = self.real_state()
        make_repo(self.scratch)
        run_git(self.scratch, "branch", "base")
        self.assertEqual(before, self.real_state())
        self.assertTrue((self.scratch / ".git").is_dir())

    def test_test_runner_drops_the_hook_environment(self):
        script = (TOOL / "test.sh").read_text(encoding="utf-8")
        head = script.split("python3 -m unittest", 1)[0]
        for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR", "GIT_OBJECT_DIRECTORY"):
            self.assertIn(name, head, f"tool/test.sh must unset {name} before running tests")

    def test_no_test_calls_git_without_the_helper(self):
        for f in sorted(TOOL.glob("test_*.py")):
            text = f.read_text(encoding="utf-8")
            for i, line in enumerate(text.splitlines(), 1):
                if 'subprocess.run(["git"' in line and "env=" not in line:
                    self.fail(f"{f.name}:{i} runs git without a clean env; use testsupport.run_git")


if __name__ == "__main__":
    unittest.main()
