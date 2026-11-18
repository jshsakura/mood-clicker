#!/usr/bin/env bash
# 작업 폴더가 아니라 커밋될 내용으로 토큰과 생성 파일이 맞는지 본다.
#   tool/check_snapshot.sh --index    스테이징된 내용 (pre-commit)
#   tool/check_snapshot.sh <커밋>      그 커밋의 내용 (pre-push)
# git archive 는 export-ignore 속성을 따르므로 쓰지 않는다. 임시 인덱스로 트리를 그대로 꺼낸다.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
SNAP=$(mktemp -d)
trap 'rm -rf "$SNAP"' EXIT
if [ "${1:-}" = "--index" ]; then
  git checkout-index -a --prefix="$SNAP/"
else
  GIT_INDEX_FILE="$SNAP/.index" git read-tree "${1:?커밋을 줍니다}"
  GIT_INDEX_FILE="$SNAP/.index" git checkout-index -a --prefix="$SNAP/tree/"
  SNAP="$SNAP/tree"
fi
python3 "$SNAP/tool/gen_tokens.py" --check
