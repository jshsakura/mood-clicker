#!/usr/bin/env bash
# Run once after cloning. Turns on the git hooks and fetches the packages.
# Pulls the Flutter docker image only when the flutter on PATH is not the pinned version.
set -euo pipefail
cd "$(dirname "$0")/.."
. tool/flutter_env.sh
git config core.hooksPath .githooks
chmod +x .githooks/* tool/fl tool/fl_dart tool/privacy_scan.py
if ! use_local_flutter; then
  docker pull "$FLUTTER_IMAGE" > /dev/null
fi
tool/fl pub get
echo "Ready. Hooks: $(git config core.hooksPath)"
