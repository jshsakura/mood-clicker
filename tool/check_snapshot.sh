#!/usr/bin/env bash
# Check tokens against generated files using what will be committed, not the working folder.
#   tool/check_snapshot.sh --index    the staged tree (pre-commit)
#   tool/check_snapshot.sh <commit>   that commit (pre-push)
# git archive honours export-ignore, so read the tree through a temporary index instead.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
SNAP="$WORK"
if [ "${1:-}" = "--index" ]; then
  git checkout-index -a --prefix="$SNAP/"
else
  GIT_INDEX_FILE="$WORK/.index" git read-tree "${1:?commit required}"
  GIT_INDEX_FILE="$WORK/.index" git checkout-index -a --prefix="$WORK/tree/"
  SNAP="$WORK/tree"
fi
python3 "$SNAP/tool/gen_tokens.py" --check
