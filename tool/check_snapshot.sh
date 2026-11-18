#!/usr/bin/env bash
# 작업 폴더가 아니라 커밋될 내용으로 토큰과 생성 파일이 맞는지 본다.
#   tool/check_snapshot.sh --index    스테이징된 내용 (pre-commit)
#   tool/check_snapshot.sh <커밋>      그 커밋의 내용 (pre-push)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
SNAP=$(mktemp -d)
trap 'rm -rf "$SNAP"' EXIT
if [ "${1:-}" = "--index" ]; then
  git checkout-index -a --prefix="$SNAP/"
else
  git archive "${1:?커밋을 줍니다}" | tar -x -C "$SNAP"
fi
python3 "$SNAP/tool/gen_tokens.py" --check
