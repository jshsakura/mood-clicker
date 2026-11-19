"""Pin that Codex runs the same project guards as Claude Code.

Codex reads .codex/hooks.json. Its shell tool can arrive as exec_command with `cmd`, or as shell
with an argv list, so each guard is reached through .claude/hooks/codex_adapter.py. These tests
feed Codex-shaped events through the adapter and expect the same verdicts as the Claude hooks.
Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import json
import re
import subprocess
import sys
import unittest
from pathlib import Path

from testsupport import git_env

ROOT = Path(__file__).resolve().parent.parent
ADAPTER = ROOT / ".claude" / "hooks" / "codex_adapter.py"


def guard_names(hooks):
    return [re.search(r"([a-z_]+\.py)\"?$", h["command"]).group(1) for h in hooks]


def codex_guards():
    config = json.loads((ROOT / ".codex" / "hooks.json").read_text())
    return guard_names(config["hooks"]["PreToolUse"][0]["hooks"])


def claude_guards():
    config = json.loads((ROOT / ".claude" / "settings.json").read_text())
    return guard_names(config["hooks"]["PreToolUse"][0]["hooks"])


def verdict(guard, event):
    proc = subprocess.run(
        [sys.executable, str(ADAPTER), guard], input=json.dumps(event),
        capture_output=True, text=True, env=git_env(), check=True,
    )
    if not proc.stdout.strip():
        return "allow"
    return json.loads(proc.stdout)["hookSpecificOutput"]["permissionDecision"]


def exec_event(command):
    return {"tool_name": "exec_command", "tool_input": {"cmd": command}, "cwd": str(ROOT)}


def argv_event(command):
    return {"tool_name": "shell", "tool_input": {"command": ["bash", "-lc", command]}, "cwd": str(ROOT)}


DENIED = {
    "push_guard.py": "git push origin main",
    "no_verify_guard.py": "git commit --no-verify -m x",
    "stash_guard.py": "git stash",
    "idle_guard.py": "until false; do sleep 30; done",
}


class CodexHooks(unittest.TestCase):
    def test_codex_runs_every_claude_guard(self):
        self.assertEqual(codex_guards(), claude_guards())

    def test_every_guard_has_a_denied_example(self):
        self.assertEqual(sorted(DENIED), sorted(codex_guards()))

    def test_exec_command_events_are_denied_like_claude(self):
        for guard, command in DENIED.items():
            with self.subTest(guard=guard):
                self.assertEqual(verdict(guard, exec_event(command)), "deny")

    def test_argv_shell_events_are_denied_like_claude(self):
        for guard, command in DENIED.items():
            with self.subTest(guard=guard):
                self.assertEqual(verdict(guard, argv_event(command)), "deny")

    def test_harmless_commands_pass(self):
        for guard in DENIED:
            with self.subTest(guard=guard):
                self.assertEqual(verdict(guard, exec_event("git status")), "allow")

    def test_other_tools_and_bad_input_pass(self):
        patch = {"tool_name": "apply_patch", "tool_input": {"cmd": "git stash"}}
        self.assertEqual(verdict("stash_guard.py", patch), "allow")
        proc = subprocess.run([sys.executable, str(ADAPTER), "stash_guard.py"], input="not json",
                              capture_output=True, text=True, check=True)
        self.assertEqual(proc.stdout, "")


if __name__ == "__main__":
    unittest.main()
