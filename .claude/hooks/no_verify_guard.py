#!/usr/bin/env python3
"""Denies commands that skip the git hooks: --no-verify, git commit -n, core.hooksPath overrides."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shellparse  # noqa: E402

HOOKS_DIR = ".githooks"
FIX = ("The git hooks run the privacy, slop and l10n scans and the tests. Do not skip them: "
       "fix what the hook reports, then run the command again without the flag.")
# Short options of git commit that take a value, so letters after them are not flags.
COMMIT_VALUE_FLAGS = set("mFCctS")


def commit_short_n(args):
    """True for git commit -n and clusters such as -an."""
    for arg in args:
        if arg == "--":
            return False
        if arg.startswith("-") and not arg.startswith("--") and len(arg) > 1:
            for letter in arg[1:]:
                if letter == "n":
                    return True
                if letter in COMMIT_VALUE_FLAGS:
                    break
    return False


def check(command, _cwd):
    for sub, args, options, _op, _index in shellparse.git_calls(command):
        if "--no-verify" in args and sub in ("commit", "push", "merge", "am", "cherry-pick", "rebase", "revert"):
            return FIX
        if sub == "commit" and commit_short_n(args):
            return FIX
        if any(o.lower().startswith("core.hookspath=") for o in options):
            return FIX
        if sub == "config" and any(a.lower() == "core.hookspath" for a in args):
            values = [a for a in args if not a.startswith("-") and a.lower() != "core.hookspath"]
            if values and values[0] != HOOKS_DIR:
                return FIX
            if "--unset" in args or "--unset-all" in args:
                return FIX
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
