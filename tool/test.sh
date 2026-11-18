#!/usr/bin/env bash
# Run every test in the repository. pre-push and CI use the same script.
set -euo pipefail
cd "$(dirname "$0")/.."
# Hooks run with GIT_DIR and GIT_INDEX_FILE set to the real repository. Tests that build
# throwaway repositories must not inherit them, or they commit into the branch being pushed.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX
python3 -m unittest discover -s tool -p 'test_*.py' -q
python3 tool/cheers_check.py
tool/fl test
