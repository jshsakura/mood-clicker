"""Pin the verdicts of the project Claude Code hooks in .claude/hooks.

Each hook reads one PreToolUse event on stdin and either prints nothing (allow) or prints a deny
decision whose reason says how to fix the command.
Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from testsupport import git_env, run_git

ROOT = Path(__file__).resolve().parent.parent
HOOKS = ROOT / ".claude" / "hooks"


def run_hook(name, command, cwd=None, tool="Bash", background=False, env=None):
    """Returns the deny reason, or None when the hook allows the command."""
    tool_input = {"command": command}
    if background:
        tool_input["run_in_background"] = True
    event = {"tool_name": tool, "tool_input": tool_input, "cwd": str(cwd or ROOT)}
    proc = subprocess.run(
        [sys.executable, str(HOOKS / name)],
        input=json.dumps(event), capture_output=True, text=True, env={**git_env(), **(env or {})}, check=True,
    )
    if not proc.stdout.strip():
        return None
    out = json.loads(proc.stdout)["hookSpecificOutput"]
    assert out["hookEventName"] == "PreToolUse"
    assert out["permissionDecision"] == "deny"
    return out["permissionDecisionReason"]


class Base(unittest.TestCase):
    hook = ""

    def deny(self, command, mention=None, cwd=None):
        reason = run_hook(self.hook, command, cwd)
        self.assertIsNotNone(reason, f"should deny: {command}")
        if mention:
            self.assertIn(mention, reason)

    def allow(self, command, cwd=None):
        self.assertIsNone(run_hook(self.hook, command, cwd), f"should allow: {command}")


class PushGuard(Base):
    hook = "push_guard.py"

    def test_push_to_main_or_master_is_denied(self):
        for cmd in [
            "tool/test.sh && git push origin main",
            "tool/test.sh && git push origin HEAD:main",
            "tool/test.sh && git push origin +feat:master",
            "tool/test.sh && git push origin refs/heads/main",
            "tool/test.sh && git push -u origin main",
            "tool/test.sh && git push --all",
            "tool/test.sh && git push --mirror",
            "tool/test.sh && git -C . push origin main",
        ]:
            self.deny(cmd, "pull request")

    def test_the_reason_names_the_fix_for_main(self):
        self.deny("tool/test.sh && git push origin main", "git push -u origin <branch>")

    def test_a_push_without_arguments_from_main_is_denied(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_git(tmp, "init", "-q", "-b", "main")
            self.deny("tool/test.sh && git push", "main", cwd=tmp)
            run_git(tmp, "checkout", "-q", "-b", "feat/x")
            self.allow("tool/test.sh && git push", cwd=tmp)

    def test_a_push_needs_the_tests_in_the_same_command(self):
        self.deny("git push origin feat/x", "tool/test.sh")
        self.deny("git -C . push -u origin feat/x", "tool/test.sh")
        self.deny("git push", "tool/test.sh")

    def test_the_tests_must_gate_the_push(self):
        self.allow("tool/test.sh && git push -u origin feat/x")
        self.allow("tool/test.sh && git fetch && git push origin feat/x")
        self.deny("tool/test.sh; git push origin feat/x", "&&")
        self.deny("tool/test.sh || git push origin feat/x", "&&")
        self.deny("git push origin feat/x && tool/test.sh", "tool/test.sh")

    def test_harmless_commands_pass(self):
        self.allow("git status")
        self.allow("git push --dry-run origin feat/x")
        self.allow("git push -n origin feat/x")
        self.allow('echo "git push origin main"')
        self.allow("git log --oneline -3")
        self.allow("grep -rn 'git push origin main' docs")

    def test_a_push_inside_a_shell_string_is_seen(self):
        self.deny('bash -c "git push origin main"', "pull request")
        self.deny("sh -c 'git push origin feat/x'", "tool/test.sh")

    def test_other_tools_and_bad_input_pass(self):
        self.assertIsNone(run_hook(self.hook, "git push origin main", tool="Read"))
        proc = subprocess.run([sys.executable, str(HOOKS / self.hook)], input="not json",
                              capture_output=True, text=True, env=git_env())
        self.assertEqual((0, ""), (proc.returncode, proc.stdout.strip()))


class NoVerifyGuard(Base):
    hook = "no_verify_guard.py"

    def test_skipping_hooks_is_denied(self):
        for cmd in [
            "git commit --no-verify -m x",
            "git commit -n -m x",
            "git commit -an -m x",
            "git push --no-verify origin feat/x",
            "tool/test.sh && git push --no-verify",
            "git merge --no-verify feat/x",
            "git -c core.hooksPath=/dev/null commit -m x",
            "git config core.hooksPath /dev/null",
            "git config --local core.hooksPath ''",
            'bash -c "git commit --no-verify -m x"',
        ]:
            self.deny(cmd)

    def test_the_reason_names_the_fix(self):
        self.deny("git commit --no-verify -m x", "fix what the hook reports")

    def test_normal_use_passes(self):
        for cmd in [
            "git commit -m 'fix: x'",
            "git commit -am 'fix: x'",
            "git push -n origin feat/x",
            "git log -n 3",
            "git config core.hooksPath .githooks",
            "git config core.hooksPath",
            'echo "use --no-verify"',
            "grep -rn -- --no-verify docs",
            "git status",
        ]:
            self.allow(cmd)


class StashGuard(Base):
    hook = "stash_guard.py"

    def test_bare_stash_commands_are_denied(self):
        for cmd in [
            "git stash",
            "git stash -u",
            "git stash push",
            "git stash push -u",
            "git stash pop",
            "git stash apply",
            "git stash drop",
            "git -C . stash",
            "cd x && git stash pop",
            'bash -c "git stash"',
        ]:
            self.deny(cmd)

    def test_the_reason_explains_the_shared_stash_and_the_fix(self):
        self.deny("git stash", "shared by every worktree")
        self.deny("git stash pop", "stash@{")
        self.deny("git stash", "git stash push -m")

    def test_named_and_explicit_use_passes(self):
        for cmd in [
            'git stash push -m "wip: card layout"',
            'git stash push -u -m "wip"',
            "git stash push --message wip",
            "git stash list",
            "git stash show stash@{0}",
            "git stash pop stash@{1}",
            "git stash apply stash@{0}",
            "git stash drop stash@{2}",
            "git stash branch fix/x stash@{0}",
            'echo "git stash"',
            "git status",
        ]:
            self.allow(cmd)


class IdleGuard(Base):
    hook = "idle_guard.py"

    def test_waiting_calls_are_denied(self):
        for cmd in [
            ":",
            "true",
            "sleep 5",
            "sleep 5;",
            "sleep 1200; echo done; git log --oneline -3",
            "cd x && sleep 2000; echo done",
            "sleep 2m && ls",
            "for i in $(seq 1 20); do check; sleep 3; done",
            "while true; do curl -s localhost/health; sleep 5; done",
            "until grep -q done f; do sleep 10; done",
            "while true\ndo\n  sleep 5\ndone",
            "while :; do (sleep 2); done",
        ]:
            self.deny(cmd)

    def test_the_reason_names_the_alternative(self):
        self.deny("sleep 5", "run_in_background")
        self.deny("while true; do sleep 5; done", "Monitor")
        self.deny(":", "next step")

    def test_ordinary_commands_pass(self):
        for cmd in [
            "git status --short",
            "sudo systemctl stop app && sleep 3 && systemctl is-active app",
            "systemctl start app && sleep 20 && systemctl is-active app",
            "for i in $(seq 1 5); do echo $i; done",
            "cat sleep_report.md",
            "python3 - <<EOF\nprint(1)\nEOF",
            "claude -p 'try this: sleep 300; echo done'",
            'echo "sleep 600"',
            'grep -n "sleep 5" deploy.sh',
            "python3 -c 'import time; time.sleep(600)'",
            "for c in 'true' 'for i in $(seq 60); do curl -s x; sleep 5; done'; do ./run.sh \"$c\"; done",
            "python3 - <<EOF\nwhile True:\n    run(); sleep 5\nEOF",
        ]:
            self.allow(cmd)

    def test_a_call_that_already_runs_in_the_background_may_wait(self):
        self.assertIsNone(run_hook(self.hook, "sleep 3000; ./build.sh", background=True))

    def test_rereading_an_unchanged_task_output_is_denied(self):
        with tempfile.TemporaryDirectory() as tmp:
            tasks = Path(tmp) / "tasks"
            tasks.mkdir()
            out = tasks / "abc123.output"
            out.write_text("")
            env = {"IDLE_GUARD_STATE": str(Path(tmp) / "state")}
            ask = lambda cmd: run_hook(self.hook, cmd, env=env)
            self.assertIsNone(ask(f"cat {out}"), "the first read is fine")
            self.assertIn("Monitor", ask(f"cat {out}") or "")
            self.assertIsNotNone(ask(f"tail -5 {out}"))
            out.write_text("more output\n")
            self.assertIsNone(ask(f"cat {out}"), "a file that grew may be read")
            self.assertIsNotNone(ask(f"cat {out}"))

    def test_other_files_are_never_treated_as_task_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "notes.output"
            f.write_text("x")
            env = {"IDLE_GUARD_STATE": str(Path(tmp) / "state")}
            for _ in range(3):
                self.assertIsNone(run_hook(self.hook, f"cat {f}", env=env))


class Wiring(unittest.TestCase):
    def setUp(self):
        self.settings = json.loads((ROOT / ".claude" / "settings.json").read_text(encoding="utf-8"))

    def commands(self):
        out = []
        for entry in self.settings["hooks"]["PreToolUse"]:
            self.assertEqual("Bash", entry["matcher"])
            out += [h["command"] for h in entry["hooks"]]
        return out

    def test_every_hook_file_is_wired_with_a_project_relative_path(self):
        wired = " ".join(self.commands())
        for name in ["push_guard.py", "no_verify_guard.py", "stash_guard.py", "idle_guard.py"]:
            self.assertIn(f'"$CLAUDE_PROJECT_DIR/.claude/hooks/{name}"', wired)
            self.assertTrue((HOOKS / name).is_file())

    def test_hooks_use_python3_only(self):
        for command in self.commands():
            self.assertTrue(command.startswith("python3 "), command)

    def test_no_personal_paths_in_the_hooks(self):
        for path in HOOKS.glob("*.py"):
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("/home/", text, path.name)


if __name__ == "__main__":
    unittest.main()
