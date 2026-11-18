#!/usr/bin/env bash
# Run once after cloning: enables the git hooks and fetches the Flutter image and packages.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* tool/fl tool/fl_dart tool/privacy_scan.py
docker pull "${FLUTTER_IMAGE:-ghcr.io/cirruslabs/flutter:3.44.0}" >/dev/null
tool/fl pub get
echo "Ready. Hooks: $(git config core.hooksPath)"
