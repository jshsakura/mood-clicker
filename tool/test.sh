#!/usr/bin/env bash
# 저장소의 테스트를 전부 돌린다. push 전과 CI 에서 같은 것을 쓴다.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m unittest discover -s tool -p 'test_*.py' -q
tool/fl test
