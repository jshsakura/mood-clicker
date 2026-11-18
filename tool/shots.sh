#!/usr/bin/env bash
# Renders screens to PNG pictures without a device so you can check them by eye. Runs in docker.
#   tool/shots.sh            render fresh pictures into build/shots/ (not committed)
#   tool/shots.sh --check    compare with the committed goldens (test/goldens/images/); fails on a difference
#   tool/shots.sh --update   replace the committed goldens with the current screens; look at the changed pictures, then commit
#
# The goldens come from the linux docker image, so pixels differ on a Mac or any other environment.
# That is why the comparison runs only in this script and in CI (same image). So this script always
# uses docker, even when a local Flutter of the pinned version is installed (as on a Mac).
export FL_DOCKER=1
set -euo pipefail
cd "$(dirname "$0")/.."
TEST=test/goldens/golden_test.dart

case "${1:-}" in
  "")
    rm -rf build/shots
    tool/fl test "$TEST" --dart-define=SHOTS_OUT=build/shots
    echo "$(find build/shots -name '*.png' | wc -l) pictures: build/shots/"
    ;;
  --check)
    rm -rf test/goldens/failures
    if tool/fl test "$TEST"; then
      echo "✓ matches the committed goldens"
    else
      echo "✗ differs from the goldens. Diff pictures: test/goldens/failures/ (*_masterImage is the old one, *_testImage the new one, *_isolatedDiff the difference)" >&2
      echo "  If the change is intended, replace the goldens with tool/shots.sh --update." >&2
      exit 1
    fi
    ;;
  --update)
    tool/fl test "$TEST" --update-goldens
    echo "Goldens replaced. See which pictures changed with git diff --stat test/goldens/images, open them to check, then commit"
    ;;
  *)
    echo "usage: tool/shots.sh [--check|--update]" >&2
    exit 2
    ;;
esac
