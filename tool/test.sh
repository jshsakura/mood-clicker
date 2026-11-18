#!/usr/bin/env bash
# Run every test in the repository. pre-push and CI use the same script.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m unittest discover -s tool -p 'test_*.py' -q
tool/fl test
