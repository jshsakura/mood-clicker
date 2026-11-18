#!/usr/bin/env python3
"""Denies a git push to main or master, and a git push the tests did not gate."""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shellparse  # noqa: E402

PROTECTED = ("main", "master")
TEST_SCRIPT = "tool/test.sh"


def current_branch(cwd):
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    try:
        out = subprocess.run(["git", "-C", cwd, "symbolic-ref", "--short", "-q", "HEAD"],
                             capture_output=True, text=True, env=env, timeout=5)
    except (OSError, subprocess.SubprocessError):
        return ""
    return out.stdout.strip()


def destination(refspec):
    """The branch a refspec pushes to: +HEAD:refs/heads/main -> main."""
    dest = refspec.lstrip("+").split(":")[-1]
    return re.sub(r"^refs/heads/", "", dest)


def check(command, cwd):
    commands = shellparse.split_commands(command)
    tested = False
    for words, op in commands:
        call = shellparse.git_call(words)
        if call and call[0] == "push":
            args = call[1]
            if "--dry-run" in args or "-n" in args:
                tested = tested and op == "&&"
                continue
            positional = [a for a in args if not a.startswith("-")]
            refspecs = positional[1:]
            if "--all" in args or "--mirror" in args or any(destination(r) in PROTECTED for r in refspecs):
                return ("Pushing to main or master is blocked. Push your branch and merge it through a pull request: "
                        "git push -u origin <branch>, then open the PR.")
            if not refspecs and current_branch(cwd) in PROTECTED:
                return ("This push would send main or master. Switch to a feature branch first "
                        "(git switch -c <branch>), push it, and merge through a pull request.")
            if not tested:
                return (f"Run the tests in the same command before pushing, joined with &&: "
                        f"{TEST_SCRIPT} && git push -u origin <branch>. A push after ; or || is not gated by the tests.")
        elif any(TEST_SCRIPT in w for w in words):
            tested = op == "&&"
            continue
        tested = tested and op == "&&"
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
