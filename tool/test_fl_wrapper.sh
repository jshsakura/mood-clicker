#!/usr/bin/env bash
# Checks how tool/fl, tool/fl_dart and tool/format.sh choose between a local Flutter and docker.
# Fake flutter, dart and docker programs go first on PATH and record what they were asked to do.
# This must also run on bash 3.2 (the macOS default): no mapfile, associative arrays or ${var,,}.
set -u
unset FL_DOCKER FLUTTER_VERSION FLUTTER_IMAGE
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BASH_DIR="$(dirname "$(command -v bash)")"
PINNED="$(bash -c '. "$1"; printf %s "$FLUTTER_VERSION"' _ "$ROOT/tool/flutter_env.sh" 2>/dev/null)"
if [ -z "$PINNED" ]; then
  echo "FAIL: tool/flutter_env.sh does not define FLUTTER_VERSION" >&2
  exit 1
fi

CHECKS=0
FAILED=0
CASES=0

fail() {
  CHECKS=$((CHECKS + 1))
  FAILED=$((FAILED + 1))
  echo "FAIL [$CASE_NAME]: $1" >&2
  sed 's/^/    log: /' "$LOG" >&2
  sed 's/^/    stderr: /' "$CASE/stderr" >&2
}
pass() { CHECKS=$((CHECKS + 1)); }
expect_log() { if grep -q -e "$1" "$LOG"; then pass; else fail "log lacks: $1"; fi; }
expect_no_log() { if grep -q -e "$1" "$LOG"; then fail "log has: $1"; else pass; fi; }
expect_stderr() { if grep -q -e "$1" "$CASE/stderr"; then pass; else fail "stderr lacks: $1"; fi; }
expect_quiet() { if [ -s "$CASE/stderr" ]; then fail "stderr is not empty"; else pass; fi; }
expect_rc() { if [ "$RC" -eq "$1" ]; then pass; else fail "exit code $RC, wanted $1"; fi; }

new_case() {
  CASES=$((CASES + 1))
  CASE_NAME="$1"
  CASE="$WORK/case-$CASES"
  mkdir -p "$CASE/bin"
  LOG="$CASE/log"
  : > "$LOG"
  cat > "$CASE/bin/docker" <<'SH'
#!/bin/sh
echo "docker $*" >> "$FAKE_LOG"
SH
  chmod +x "$CASE/bin/docker"
}

# fake_flutter <version|fail|garbage>
fake_flutter() {
  cat > "$CASE/bin/flutter" <<SH
#!/bin/sh
if [ "\$1" = "--version" ]; then
  case "$1" in
    fail) exit 1 ;;
    garbage) echo "Flutter, but no machine readable version"; exit 0 ;;
  esac
  printf '{\n  "frameworkVersion": "$1",\n  "channel": "stable"\n}\n'
  exit 0
fi
echo "flutter \$* cwd=\$(pwd)" >> "\$FAKE_LOG"
SH
  chmod +x "$CASE/bin/flutter"
}

fake_dart() {
  cat > "$CASE/bin/dart" <<'SH'
#!/bin/sh
echo "dart $* cwd=$(pwd)" >> "$FAKE_LOG"
SH
  chmod +x "$CASE/bin/dart"
}

# run <script under tool/> [args...]
run() {
  FAKE_LOG="$LOG" PATH="$CASE/bin:/usr/bin:/bin:$BASH_DIR" "$ROOT/tool/$1" "${@:2}" > "$CASE/stdout" 2> "$CASE/stderr"
  RC=$?
}

# --- tool/fl -----------------------------------------------------------------

new_case "fl uses the pinned local flutter"
fake_flutter "$PINNED"
run fl test test/domain
expect_rc 0
expect_log "^flutter test test/domain cwd=$ROOT\$"
expect_no_log "docker"
expect_quiet

new_case "fl falls back to docker when the local version differs"
fake_flutter "0.0.1"
run fl analyze
expect_rc 0
expect_log "^docker run .* -v $ROOT:/app .*flutter:$PINNED .*analyze"
expect_no_log "^flutter"
expect_stderr "0.0.1"

new_case "fl uses docker when there is no flutter"
run fl test
expect_rc 0
expect_log "^docker run"
expect_quiet

new_case "fl uses docker when flutter --version fails"
fake_flutter fail
run fl test
expect_log "^docker run"
expect_no_log "^flutter"

new_case "fl uses docker when flutter prints no version"
fake_flutter garbage
run fl test
expect_log "^docker run"
expect_no_log "^flutter"

new_case "FL_DOCKER=1 forces docker"
fake_flutter "$PINNED"
FL_DOCKER=1 run fl test
expect_log "^docker run"
expect_no_log "^flutter"

new_case "FL_DOCKER=0 does not force docker"
fake_flutter "$PINNED"
FL_DOCKER=0 run fl test
expect_log "^flutter test"
expect_no_log "docker"

new_case "FLUTTER_IMAGE overrides the docker image"
FLUTTER_IMAGE=example.invalid/flutter:9 run fl test
expect_log "example.invalid/flutter:9"

new_case "fl passes arguments with spaces through to docker"
run fl test "a b"
expect_log "a b"

# --- gradle volume: one per working tree, pub cache shared --------------------------

gradle_volume_of_log() { sed -n 's/.* -v \(mood-clicker-gradle[^: ]*\):\/root\/\.gradle.*/\1/p' "$LOG" | head -n 1; }

new_case "each working tree gets its own gradle volume and the pub cache stays shared"
run fl test
VOLUME="$(gradle_volume_of_log)"
if echo "$VOLUME" | grep -q -E '^mood-clicker-gradle-[0-9a-f]{8}$'; then pass; else fail "volume name is '$VOLUME'"; fi
expect_log " -v mood-clicker-pub-cache:/root/.pub-cache"
expect_no_log " -v mood-clicker-gradle:/root/.gradle"

new_case "the gradle volume name is stable for one working tree"
run fl test
FIRST="$(gradle_volume_of_log)"
: > "$LOG"
run fl analyze
if [ -n "$FIRST" ] && [ "$FIRST" = "$(gradle_volume_of_log)" ]; then pass; else fail "'$FIRST' then '$(gradle_volume_of_log)'"; fi

new_case "another working tree uses another gradle volume"
run fl test
FIRST="$(gradle_volume_of_log)"
OTHER="$CASE/other-tree"
mkdir -p "$OTHER/tool"
cp "$ROOT/tool/fl" "$ROOT/tool/flutter_env.sh" "$OTHER/tool/"
: > "$LOG"
FAKE_LOG="$LOG" PATH="$CASE/bin:/usr/bin:/bin:$BASH_DIR" "$OTHER/tool/fl" test > "$CASE/stdout" 2> "$CASE/stderr"
SECOND="$(gradle_volume_of_log)"
if [ -n "$FIRST" ] && [ -n "$SECOND" ] && [ "$FIRST" != "$SECOND" ]; then pass; else fail "'$FIRST' and '$SECOND'"; fi
expect_log " -v $OTHER:/app"

new_case "FL_GRADLE_VOLUME overrides the gradle volume"
FL_GRADLE_VOLUME=shared-gradle run fl test
expect_log " -v shared-gradle:/root/.gradle"
expect_no_log " -v mood-clicker-gradle[^ ]*:/root/\\.gradle"

new_case "an empty FL_GRADLE_VOLUME is ignored"
FL_GRADLE_VOLUME= run fl test
expect_log " -v mood-clicker-gradle-[0-9a-f]\{8\}:/root/.gradle"

new_case "fl_dart does not mount a gradle volume"
run fl_dart format lib
expect_no_log ":/root/\\.gradle"

# --- tool/fl_dart ------------------------------------------------------------

new_case "fl_dart uses the dart next to the pinned local flutter"
fake_flutter "$PINNED"
fake_dart
run fl_dart format lib test
expect_rc 0
expect_log "^dart format lib test cwd=$ROOT\$"
expect_no_log "docker"

new_case "fl_dart falls back to docker without a dart next to flutter"
fake_flutter "$PINNED"
run fl_dart format lib
expect_log "^docker run .*dart"
expect_stderr "dart"

new_case "fl_dart falls back to docker when the version differs"
fake_flutter "0.0.1"
fake_dart
run fl_dart format lib
expect_log "^docker run"
expect_no_log "^dart"

new_case "fl_dart honours FL_DOCKER=1"
fake_flutter "$PINNED"
fake_dart
FL_DOCKER=1 run fl_dart format lib
expect_log "^docker run"
expect_no_log "^dart"

new_case "fl_dart uses docker when there is no flutter"
run fl_dart format lib
expect_log "^docker run"
expect_quiet

# --- tool/format.sh ----------------------------------------------------------

new_case "format.sh formats every hand-written dart file and skips generated ones"
fake_flutter "$PINNED"
fake_dart
run format.sh
expect_rc 0
expect_log "^dart format .*lib/design/app_theme.dart .* lib/main.dart "
expect_no_log "\.g\.dart"
expect_no_log "set-exit-if-changed"

new_case "format.sh --check only checks"
fake_flutter "$PINNED"
fake_dart
run format.sh --check
expect_rc 0
expect_log "^dart format --output=none --set-exit-if-changed .*lib/design/app_theme.dart .* lib/main.dart "
expect_no_log "\.g\.dart"

# --- bash 3.2 ----------------------------------------------------------------

CASE_NAME="bash 3.2 compatibility"
CASE="$WORK/static"
mkdir -p "$CASE"
LOG="$CASE/log"
: > "$LOG"
: > "$CASE/stderr"
FILES="$ROOT/tool/fl $ROOT/tool/fl_dart $ROOT/tool/format.sh $ROOT/tool/flutter_env.sh $ROOT/tool/setup.sh"
# shellcheck disable=SC2086
if grep -n -E 'mapfile|readarray|declare -A|\$\{[A-Za-z_]+(,,|\^\^)\}|&>>|\[\[ -v|coproc' $FILES > "$LOG"; then
  fail "bash 4 features found"
else
  pass
fi

echo "$CHECKS checks in $CASES cases, $FAILED failed"
[ "$FAILED" -eq 0 ]
