#!/usr/bin/env bash
# Format Dart code. Generated *.g.dart files stay exactly as tool/gen_tokens.py wrote them.
# tool/format.sh            fix everything
# tool/format.sh --check    fail if anything would change (CI, hooks)
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t FILES < <(find lib test -name '*.dart' ! -name '*.g.dart' | sort)
if [ "${1:-}" = "--check" ]; then
  exec tool/fl_dart format --output=none --set-exit-if-changed "${FILES[@]}"
fi
exec tool/fl_dart format "${FILES[@]}"
