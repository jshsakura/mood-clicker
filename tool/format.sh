#!/usr/bin/env bash
# Format the Dart code. Generated files (*.g.dart) stay exactly as tool/gen_tokens.py wrote them.
# Examples: tool/format.sh            fix everything
#           tool/format.sh --check    fail when something needs fixing (CI, hook)
set -euo pipefail
cd "$(dirname "$0")/.."
FILES=()
while IFS= read -r file; do
  FILES+=("$file")
done < <(find lib test -name '*.dart' ! -name '*.g.dart' | sort)
if [ "${1:-}" = "--check" ]; then
  exec tool/fl_dart format --output=none --set-exit-if-changed "${FILES[@]}"
fi
exec tool/fl_dart format "${FILES[@]}"
