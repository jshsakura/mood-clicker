#!/usr/bin/env python3
"""Denies Bash calls that only wait: no-ops, bare sleeps, polling loops, long sleeps, and rereading a
background task's output file that has not grown.

Why: every Bash call is billed with the whole context of the conversation, whatever the command
does. A call that waits or checks again and again costs as much as real work and adds nothing, and
the harness already calls the agent back when a background task ends. The alternatives are
run_in_background for long commands, and one Monitor with an until condition for a condition that
must be awaited.

False positives are the real risk, so words inside quotes and heredoc bodies are never read as
commands (shellparse removes them before the check).
"""
import os
import re
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shellparse  # noqa: E402

# A foreground sleep longer than this many seconds counts as waiting.
MAX_FOREGROUND_SLEEP = float(os.environ.get("IDLE_GUARD_MAX_SLEEP", "30"))
# A task output file read again within this many seconds, unchanged, counts as polling.
PEEK_WINDOW = float(os.environ.get("IDLE_GUARD_WINDOW", "900"))
STATE_FILE = os.environ.get("IDLE_GUARD_STATE") or os.path.join(
    tempfile.gettempdir(), f"claude-idle-guard-{os.getuid()}.tsv")

NOOP = {":", "true", "echo", "exit 0"}
LOOP_WORDS = {"while", "until"}
CLAUSE_WORDS = {"do", "then", "else"}
READERS = {"cat", "tail", "head", "less", "grep", "wc"}
TASK_OUTPUT = re.compile(r"/tasks/[A-Za-z0-9_-]+\.output$")
UNITS = {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}

WHY_BILLING = "Every Bash call is billed with the whole conversation context, even a trivial one."
ADVICE = ("For a long command use run_in_background (the harness calls you back when it ends). "
          "To wait for a condition, give one Monitor an until loop instead of polling.")


def command_words(words):
    """The words of one command with clause keywords and grouping characters removed from the front."""
    words = shellparse._strip_prefix(words)
    while words and words[0] in CLAUSE_WORDS:
        words = shellparse._strip_prefix(words[1:])
    if words:
        words = [words[0].lstrip("({")] + words[1:]
    while words and not words[0]:
        words = words[1:]
    if len(words) > 1:
        words = words[:-1] + [words[-1].rstrip(")}")]
    return words


def sleep_seconds(words):
    """Seconds of a sleep command, or None when the words are not a sleep with a plain duration."""
    if len(words) != 2 or words[0] != "sleep":
        return None
    match = re.fullmatch(r"([0-9]+(?:\.[0-9]+)?)([smhd]?)", words[1])
    return float(match.group(1)) * UNITS[match.group(2)] if match else None


def peek_path(words):
    if not words or os.path.basename(words[0]) not in READERS:
        return None
    for word in words[1:]:
        if TASK_OUTPUT.search(word):
            return word
    return None


def unchanged_since_last_read(path):
    """True when the file has the same size and mtime as at the previous read inside the window."""
    try:
        stat = os.stat(path)
    except OSError:
        return False
    signature, now, previous = f"{stat.st_size}:{int(stat.st_mtime)}", time.time(), None
    try:
        with open(STATE_FILE, encoding="utf-8") as handle:
            for line in handle:
                stamp, file, sig = (line.rstrip("\n").split("\t") + ["", "", ""])[:3]
                if file == path:
                    previous = (float(stamp), sig)
    except (OSError, ValueError):
        pass
    try:
        with open(STATE_FILE, "a", encoding="utf-8") as handle:
            handle.write(f"{now}\t{path}\t{signature}\n")
    except OSError:
        pass
    return previous is not None and previous[1] == signature and now - previous[0] < PEEK_WINDOW


def check(command):
    commands = [command_words(words) for words, _op in shellparse.split_commands(command)]
    commands = [c for c in commands if c]
    flat = " ".join(" ".join(c) for c in commands).strip()
    if not commands or flat in NOOP:
        return (f"{WHY_BILLING} This command does nothing. If there is nothing to check, "
                "go on to the next step without calling a tool.")
    if len(commands) == 1 and sleep_seconds(commands[0]) is not None:
        return f"{WHY_BILLING} This call only waits. {ADVICE}"
    sleeps = [sleep_seconds(c) for c in commands if sleep_seconds(c) is not None]
    if any(c[0] in LOOP_WORDS or (c[0] == "for" and any(w.startswith("$(seq") for w in c)) for c in commands) and sleeps:
        return f"{WHY_BILLING} This loop polls with sleep. {ADVICE}"
    if sleeps and max(sleeps) > MAX_FOREGROUND_SLEEP:
        return f"{WHY_BILLING} This call sleeps {max(sleeps):g} seconds in the foreground. {ADVICE}"
    for words in commands:
        path = peek_path(words)
        if path and unchanged_since_last_read(path):
            return (f"{WHY_BILLING} This task output file has not grown since you last read it. "
                    "The harness calls you back when a background task ends, so do not check in between. "
                    "If you must wait for a condition, give one Monitor an until loop.")
    return None


def main():
    event = shellparse.read_payload()
    if event is None or event["tool_input"].get("run_in_background") is True:
        return
    reason = check(event["tool_input"]["command"])
    if reason:
        shellparse.deny(reason)


if __name__ == "__main__":
    main()
