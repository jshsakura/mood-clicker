#!/usr/bin/env python3
"""Runs a Claude Code PreToolUse guard for Codex.

Codex sends the same hook wire format as Claude Code and reads the same
hookSpecificOutput.permissionDecision answer, but its shell tool may be named
exec_command or shell and may carry the command as `cmd` or as an argv list.
This adapter rewrites the event into Claude's shape (tool_name "Bash",
tool_input.command as one string), runs the guard given as arguments, and
passes its answer and exit code through. Events for other tools pass.

A bare guard name such as push_guard.py runs the guard next to this file, so
.codex/hooks.json can name the same guards as .claude/settings.json.
"""
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path

HOOKS = Path(__file__).resolve().parent

SHELL_TOOLS = {"bash", "shell", "exec_command", "local_shell", "unified_exec", "container.exec"}
SHELLS = {"bash", "sh", "zsh", "/bin/bash", "/bin/sh", "/bin/zsh", "/usr/bin/bash", "/usr/bin/zsh"}


def command_text(tool_input):
    raw = tool_input.get("command", tool_input.get("cmd"))
    if isinstance(raw, str):
        return raw
    if isinstance(raw, list) and all(isinstance(part, str) for part in raw):
        if len(raw) >= 3 and raw[0] in SHELLS and raw[1] in {"-c", "-lc", "-ic"}:
            return raw[2]
        return shlex.join(raw)
    return None


def normalize(event):
    if str(event.get("tool_name", "")).lower() not in SHELL_TOOLS:
        return None
    tool_input = event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return None
    command = command_text(tool_input)
    if command is None:
        return None
    return {**event, "tool_name": "Bash", "tool_input": {**tool_input, "command": command}}


def main(argv):
    if len(argv) < 2:
        return 0
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return 0
    claude_event = normalize(event) if isinstance(event, dict) else None
    if claude_event is None:
        return 0
    env = {**os.environ, "CLAUDE_PROJECT_DIR": os.environ.get("CLAUDE_PROJECT_DIR") or claude_event.get("cwd") or os.getcwd()}
    guard = argv[1:]
    if len(guard) == 1 and (HOOKS / guard[0]).is_file():
        guard = [sys.executable, str(HOOKS / guard[0])]
    result = subprocess.run(guard, input=json.dumps(claude_event), text=True, capture_output=True, env=env)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv))
