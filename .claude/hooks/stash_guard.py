#!/usr/bin/env python3
"""Denies a bare git stash and a stash pop, apply or drop without a stash reference."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shellparse  # noqa: E402

REASON = ("The stash list is shared by every worktree of this repository, so a bare stash or pop can take or "
          'drop another session\'s work. Name your stash: git stash push -m "<what and why>", and address it '
          "explicitly: git stash list, then git stash pop stash@{n}. Or commit a work-in-progress change instead.")
NEEDS_REF = {"pop", "apply", "drop"}
PASS_THROUGH = {"list", "show", "branch", "create", "store", "clear"}


def check(command, _cwd):
    for sub, args, _options, _op, _index in shellparse.git_calls(command):
        if sub != "stash":
            continue
        positional = [a for a in args if not a.startswith("-")]
        action = positional[0] if positional else "push"
        if action in PASS_THROUGH:
            continue
        if action in NEEDS_REF:
            if not any(a.startswith("stash@{") or a.isdigit() for a in positional[1:]):
                return REASON
            continue
        # push, or options only (implicit push): a message is required.
        message = any(a in ("-m", "--message") or a.startswith("--message=") or (a.startswith("-") and not a.startswith("--") and "m" in a[1:]) for a in args)
        if not message:
            return REASON
    return None


def main():
    event = shellparse.read_event()
    if event is None:
        return
    reason = check(*event)
    if reason:
        shellparse.deny(reason)


if __name__ == "__main__":
    main()
