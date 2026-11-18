"""Shared helpers for the project Claude Code hooks. Standard library only.

A hook reads one PreToolUse event as JSON on stdin. It prints nothing to allow the command, or one
deny decision whose reason tells the agent how to fix the command.
"""
import json
import os
import re
import sys

# Options of git itself that take a separate value: git -C <dir> push.
GIT_OPTIONS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
WRAPPERS = {"command", "env", "sudo", "exec", "time", "nohup"}
SHELLS = {"bash", "sh", "zsh"}


def read_payload():
    """The whole event when it is a Bash call with a string command, else None."""
    try:
        event = json.load(sys.stdin)
        if event.get("tool_name") != "Bash" or not isinstance(event["tool_input"]["command"], str):
            return None
    except (ValueError, KeyError, TypeError, AttributeError):
        return None
    return event


def read_event():
    """The Bash command and working directory of the event, or None for anything else."""
    event = read_payload()
    if event is None:
        return None
    return event["tool_input"]["command"], event.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def strip_heredocs(command):
    """Removes heredoc bodies: they are data for a program, not commands of this line."""
    kept, delimiter = [], None
    for line in command.split("\n"):
        if delimiter is not None:
            if line.strip() == delimiter:
                delimiter = None
            continue
        kept.append(line)
        match = re.search(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)", line)
        if match:
            delimiter = match.group(1)
    return "\n".join(kept)


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))


def split_commands(command):
    """Splits a shell line into [(words, operator_after)], respecting quotes.

    Operators are && || ; | & and newline. Quotes are removed from the words. A command inside
    bash -c "..." is split too, so a wrapped git call is seen.
    """
    command = strip_heredocs(command)
    out, words, word, quote, started = [], [], [], None, False
    i = 0

    def end_word():
        nonlocal word, started
        if started:
            words.append("".join(word))
        word, started = [], False

    def end_command(op):
        nonlocal words
        end_word()
        if words:
            out.append((words, op))
        elif out and op:
            out[-1] = (out[-1][0], op)
        words = []

    while i < len(command):
        c = command[i]
        if quote == "'":
            if c == "'":
                quote = None
            else:
                word.append(c)
        elif quote == '"':
            if c == '"':
                quote = None
            elif c == "\\" and i + 1 < len(command):
                i += 1
                word.append(command[i])
            else:
                word.append(c)
        elif c in "'\"":
            quote, started = c, True
        elif c == "\\" and i + 1 < len(command):
            i += 1
            word.append(command[i])
            started = True
        elif command.startswith(("&&", "||"), i):
            end_command(command[i:i + 2])
            i += 1
        elif c in ";|&\n":
            end_command(";" if c == "\n" else c)
        elif c in " \t\r":
            end_word()
        else:
            word.append(c)
            started = True
        i += 1
    end_command("")
    return _unwrap(out)


def _unwrap(commands):
    result = []
    for words, op in commands:
        core = _strip_prefix(words)
        if core and os.path.basename(core[0]) in SHELLS and "-c" in core[1:]:
            idx = core.index("-c")
            if idx + 1 < len(core):
                inner = split_commands(core[idx + 1])
                if inner:
                    inner[-1] = (inner[-1][0], op)
                    result += inner
                    continue
        result.append((words, op))
    return result


def _strip_prefix(words):
    i = 0
    while i < len(words) and (re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[i]) or words[i] in WRAPPERS):
        i += 1
    return words[i:]


def git_call(words):
    """(subcommand, args, git_options) when the words are a git call, else None.

    git_options holds the options before the subcommand, for example ["-c", "core.hooksPath=x"].
    """
    core = _strip_prefix(words)
    if not core or os.path.basename(core[0]) != "git":
        return None
    options, i = [], 1
    while i < len(core) and core[i].startswith("-"):
        options.append(core[i])
        if core[i] in GIT_OPTIONS_WITH_VALUE and i + 1 < len(core):
            i += 1
            options.append(core[i])
        i += 1
    if i >= len(core):
        return None
    return core[i], core[i + 1:], options


def git_calls(command):
    """Every git call of the line as (subcommand, args, git_options, operator_after, index)."""
    calls = []
    for index, (words, op) in enumerate(split_commands(command)):
        call = git_call(words)
        if call:
            calls.append((*call, op, index))
    return calls
