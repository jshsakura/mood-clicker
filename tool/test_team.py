"""Pin tool/team/itl and tool/team/start.sh.

The tmux tests run against a private tmux server (TMUX_TMPDIR points into a temp folder) and are
skipped when tmux is missing.
Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import importlib.machinery
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

from testsupport import git_env, run_git

TEAM = Path(__file__).resolve().parent / "team"
HAS_TMUX = shutil.which("tmux") is not None


def load_itl():
    loader = importlib.machinery.SourceFileLoader("itl_module", str(TEAM / "itl"))
    spec = importlib.util.spec_from_loader("itl_module", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


itl = load_itl()


def pane(name="", session="s", pane_id="%0", socket="/x"):
    return {"socket": socket, "id": pane_id, "session": session, "where": "0.0", "command": "cat",
            "cwd": "/w", "name": name, "addr": f"{session}:{pane_id}"}


class Pure(unittest.TestCase):
    def test_a_tmux_listing_is_parsed_with_the_name_last(self):
        raw = "%3\tmain\t0.1\tclaude\t/w/app\tleader\n%4\tmain\t0.2\tbash\t/w/app\t\nbroken line\n"
        panes = itl.parse_panes(raw, "/sock")
        self.assertEqual(["%3", "%4"], [p["id"] for p in panes])
        self.assertEqual(["leader", ""], [p["name"] for p in panes])
        self.assertEqual("main:%3", panes[0]["addr"])

    def test_a_name_or_an_exact_address_finds_one_pane(self):
        panes = [pane("leader", pane_id="%0"), pane("w1", pane_id="%1")]
        self.assertEqual("%1", itl.resolve(panes, "w1")[0]["id"])
        self.assertEqual("%0", itl.resolve(panes, "s:%0")[0]["id"])

    def test_an_ambiguous_or_unknown_target_is_an_error(self):
        panes = [pane("w", pane_id="%0"), pane("w", pane_id="%1")]
        found, error = itl.resolve(panes, "w")
        self.assertIsNone(found)
        self.assertIn("s:%0", error)
        self.assertIn("s:%1", error)
        self.assertIsNone(itl.resolve(panes, "nobody")[0])
        self.assertIsNone(itl.resolve(panes, "  ")[0])

    def test_the_sender_tag_tells_the_receiver_how_to_reply(self):
        self.assertEqual("[from leader · reply: itl send leader '...'] ", itl.sender_tag("leader"))

    def test_text_that_could_press_keys_or_is_too_long_is_refused(self):
        with self.assertRaises(itl.ItlError):
            itl.send_text(pane(), "a\x1b[A")
        with self.assertRaises(itl.ItlError):
            itl.send_text(pane(), "x" * (itl.MAX_TEXT_BYTES + 1))

    def test_names_are_plain(self):
        for good in ["leader", "w1", "a.b-c_d"]:
            self.assertTrue(itl.NAME_RE.match(good), good)
        for bad in ["", "-x", "a b", "a;b", "x" * 33, "%1"]:
            self.assertFalse(itl.NAME_RE.match(bad), bad)

    def test_the_file_is_one_python_script_with_only_the_standard_library(self):
        text = (TEAM / "itl").read_text(encoding="utf-8")
        self.assertTrue(text.startswith("#!/usr/bin/env python3"))
        for line in text.splitlines():
            if line.startswith(("import ", "from ")):
                self.assertIn(line.split()[1], sys.stdlib_module_names, line)


class TmuxCase(unittest.TestCase):
    def setUp(self):
        if not HAS_TMUX:
            self.skipTest("tmux is not installed")
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.env = {k: v for k, v in git_env().items() if k not in ("TMUX", "TMUX_PANE")}
        self.env["TMUX_TMPDIR"] = str(self.root / "tmux")
        os.makedirs(self.env["TMUX_TMPDIR"])
        self.addCleanup(lambda: subprocess.run(["tmux", "kill-server"], env=self.env, capture_output=True))

    def tmux(self, *args):
        return subprocess.run(["tmux", *args], env=self.env, capture_output=True, text=True, check=True).stdout

    def itl(self, *args, env=None, check=True):
        done = subprocess.run([sys.executable, str(TEAM / "itl"), *args], env={**self.env, **(env or {})},
                              capture_output=True, text=True)
        if check:
            self.assertEqual(0, done.returncode, done.stderr)
        return done

    def start_pane(self, name, session="t"):
        """A pane that runs cat, so what is typed into it comes back on its screen."""
        if session not in self.tmux("list-sessions", "-F", "#{session_name}") if self.has_server() else True:
            self.tmux("new-session", "-d", "-s", session, "-x", "120", "-y", "30", "cat")
            pane_id = self.tmux("list-panes", "-t", session, "-F", "#{pane_id}").split()[-1]
        else:
            pane_id = self.tmux("split-window", "-d", "-P", "-F", "#{pane_id}", "-t", session, "cat").strip()
        self.tmux("set-option", "-p", "-t", pane_id, "@itl_name", name)
        return pane_id

    def has_server(self):
        return subprocess.run(["tmux", "list-sessions"], env=self.env, capture_output=True).returncode == 0

    def wait_for(self, name, text):
        for _ in range(30):
            if text in self.itl("read", name).stdout:
                return True
            time.sleep(0.1)
        return False


class ItlOnTmux(TmuxCase):
    def test_list_shows_named_panes(self):
        self.start_pane("leader")
        self.start_pane("w1")
        out = self.itl("list").stdout
        self.assertIn("leader", out)
        self.assertIn("w1", out)

    def test_send_types_the_text_and_read_shows_it(self):
        self.start_pane("w1")
        self.itl("send", "w1", "hello", "there")
        self.assertTrue(self.wait_for("w1", "hello there"))

    def test_a_named_sender_adds_its_reply_hint(self):
        self.start_pane("w1")
        leader = self.start_pane("leader")
        socket = next(Path(self.env["TMUX_TMPDIR"]).glob("tmux-*/default"))
        self.itl("send", "w1", "go", env={"TMUX": f"{socket},1,0", "TMUX_PANE": leader})
        self.assertTrue(self.wait_for("w1", "reply: itl send leader"))

    def test_text_is_pasted_literally(self):
        self.start_pane("w1")
        self.itl("send", "w1", "Enter C-c $(echo no) ; x")
        self.assertTrue(self.wait_for("w1", "Enter C-c $(echo no) ; x"))

    def test_two_panes_with_one_name_are_not_guessed(self):
        self.start_pane("w")
        self.start_pane("w")
        done = self.itl("send", "w", "x", check=False)
        self.assertNotEqual(0, done.returncode)
        self.assertIn("several panes", done.stderr)

    def test_whoami_and_name_work_inside_a_pane(self):
        pane_id = self.start_pane("")
        socket = next(Path(self.env["TMUX_TMPDIR"]).glob("tmux-*/default"))
        inside = {"TMUX": f"{socket},1,0", "TMUX_PANE": pane_id}
        self.itl("name", "boss", env=inside)
        self.assertIn("boss", self.itl("whoami", env=inside).stdout)

    def test_no_tmux_server_is_a_calm_answer(self):
        self.assertIn("no panes", self.itl("list").stdout)


class StartScript(TmuxCase):
    def setUp(self):
        super().setUp()
        if shutil.which("git") is None:
            self.skipTest("git is not installed")
        self.repo = self.root / "proj"
        self.repo.mkdir()
        run_git(self.repo, "init", "-q", "-b", "main")
        run_git(self.repo, "config", "user.email", "dev@example.com")
        run_git(self.repo, "config", "user.name", "dev")
        (self.repo / "f.txt").write_text("x\n")
        run_git(self.repo, "add", "-A")
        run_git(self.repo, "commit", "-q", "-m", "chore: start")

    def start(self, *args):
        return subprocess.run(["bash", str(TEAM / "start.sh"), *args], cwd=self.repo, env=self.env,
                              capture_output=True, text=True)

    def panes(self):
        out = self.tmux("list-panes", "-s", "-t", "team", "-F", "#{@itl_name}\t#{pane_current_path}\t#{pane_current_command}")
        return [line.split("\t") for line in out.splitlines()]

    def test_one_leader_and_the_named_workers_start_in_their_own_worktrees(self):
        done = self.start("-s", "team", "cat", "ui", "api")
        self.assertEqual(0, done.returncode, done.stderr)
        by_name = {p[0]: p for p in self.panes()}
        self.assertEqual({"leader", "ui", "api"}, set(by_name))
        self.assertEqual(str(self.repo), by_name["leader"][1])
        for name in ("ui", "api"):
            worktree = self.root / f"proj-{name}"
            self.assertTrue((worktree / "f.txt").is_file())
            self.assertEqual(str(worktree), by_name[name][1])
            self.assertEqual(f"work/{name}", run_git(worktree, "branch", "--show-current"))

    def test_the_agent_command_is_started_in_every_pane(self):
        self.start("-s", "team", "cat", "ui")
        # The keys wait in the pane until its shell is ready, so give a slow shell profile time.
        for _ in range(100):
            commands = [p[2] for p in self.panes()]
            if commands == ["cat", "cat"]:
                break
            time.sleep(0.1)
        self.assertEqual(["cat", "cat"], commands)

    def test_a_count_makes_numbered_workers(self):
        self.assertEqual(0, self.start("-s", "team", "-n", "2", "cat").returncode)
        self.assertEqual({"leader", "w1", "w2"}, {p[0] for p in self.panes()})

    def test_running_it_again_creates_nothing_twice(self):
        self.start("-s", "team", "cat", "ui")
        before = self.panes()
        done = self.start("-s", "team", "cat", "ui")
        self.assertEqual(0, done.returncode, done.stderr)
        self.assertEqual(sorted(before), sorted(self.panes()))
        self.assertIn("already", done.stdout)

    def test_a_new_worker_is_added_to_a_running_team(self):
        self.start("-s", "team", "cat", "ui")
        self.assertEqual(0, self.start("-s", "team", "cat", "ui", "docs").returncode)
        self.assertEqual({"leader", "ui", "docs"}, {p[0] for p in self.panes()})

    def test_a_missing_agent_command_prints_usage(self):
        done = self.start("-s", "team")
        self.assertNotEqual(0, done.returncode)
        self.assertIn("usage", done.stderr.lower())

    def test_a_bad_worker_name_is_refused_before_anything_is_made(self):
        done = self.start("-s", "team", "cat", "bad name")
        self.assertNotEqual(0, done.returncode)
        self.assertFalse(self.has_server())

    def test_a_folder_that_is_not_a_worktree_is_not_overwritten(self):
        (self.root / "proj-ui").mkdir()
        done = self.start("-s", "team", "cat", "ui")
        self.assertNotEqual(0, done.returncode)
        self.assertIn("proj-ui", done.stderr)


if __name__ == "__main__":
    unittest.main()
