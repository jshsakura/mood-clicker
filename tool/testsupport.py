"""Shared helpers for tool tests that build throwaway git repositories."""
import os
import subprocess


def git_env():
    """The environment without GIT_ variables. Hooks set them to the real repository, and a test must find its own repository from cwd."""
    return {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}


def run_git(cwd, *args):
    """Run git in cwd with a clean environment and return stripped stdout."""
    r = subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True, env=git_env())
    return r.stdout.strip()

