#!/usr/bin/env bash
# 클론한 뒤 한 번 돌린다. git 훅을 켜고 Flutter 이미지와 패키지를 받는다.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* tool/fl tool/fl_dart tool/privacy_scan.py
docker pull "${FLUTTER_IMAGE:-ghcr.io/cirruslabs/flutter:3.44.0}" >/dev/null
tool/fl pub get
echo "준비 끝. 훅: $(git config core.hooksPath)"
