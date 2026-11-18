#!/usr/bin/env bash
# 다트 코드를 포맷한다. 생성 파일(*.g.dart)은 tool/gen_tokens.py 가 만든 그대로 둔다.
# 예: tool/format.sh            전부 고친다
#     tool/format.sh --check    고칠 게 있으면 실패한다 (CI, 훅)
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t FILES < <(find lib test -name '*.dart' ! -name '*.g.dart' | sort)
if [ "${1:-}" = "--check" ]; then
  exec tool/fl_dart format --output=none --set-exit-if-changed "${FILES[@]}"
fi
exec tool/fl_dart format "${FILES[@]}"
