#!/usr/bin/env bash
# Checks how tool/fl, tool/fl_dart and tool/format.sh choose between a local Flutter and docker.
# Fake flutter, dart and docker programs go first on PATH and record what they were asked to do.
# This must also run on bash 3.2 (the macOS default): no mapfile, associative arrays or ${var,,}.
set -u
unset FL_DOCKER FLUTTER_VERSION FLUTTER_IMAGE FL_GRADLE_VOLUME FL_ANDROID_SDK_VOLUME CMAKE_VERSION NDK_VERSION
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

new_case "fl caps docker tests and analysis at 4g with no extra swap"
run fl test
expect_log "^docker run .*--memory 4g --memory-swap 4g .*test"
new_case "fl analyze gets the same cap"
run fl analyze
expect_log "^docker run .*--memory 4g --memory-swap 4g .*analyze"

new_case "FL_TEST_MEMORY changes the cap"
FL_TEST_MEMORY=6g run fl test
expect_log "^docker run .*--memory 6g --memory-swap 6g"

new_case "fl does not cap builds, Gradle asks for more"
run fl build apk --debug
expect_log "^docker run"
expect_no_log "--memory"

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

new_case "shots.sh runs in docker even when the pinned local flutter exists"
fake_flutter "$PINNED"
run shots.sh --check
expect_log "^docker run .*flutter:$PINNED"
expect_no_log "^flutter"

# --- android sdk: the NDK lives in one shared volume --------------------------------

new_case "the NDK folder is a shared volume and nothing else of the SDK is mounted"
run fl build apk
expect_log " -v mood-clicker-android-sdk:/opt/android-sdk-linux/ndk "
expect_no_log ":/opt/android-sdk-linux "
expect_log " bash /app/tool/fl_container.sh build apk"

new_case "CMake is a second shared volume next to the NDK one"
run fl build apk
expect_log " -v mood-clicker-android-sdk-cmake:/opt/android-sdk-linux/cmake "

new_case "FL_ANDROID_SDK_VOLUME overrides the SDK volume and an empty one is ignored"
FL_ANDROID_SDK_VOLUME=my-sdk run fl build apk
expect_log " -v my-sdk:/opt/android-sdk-linux/ndk "
expect_log " -v my-sdk-cmake:/opt/android-sdk-linux/cmake "
: > "$LOG"
FL_ANDROID_SDK_VOLUME= run fl build apk
expect_log " -v mood-clicker-android-sdk:/opt/android-sdk-linux/ndk "

new_case "the SDK volume does not depend on the working tree"
run fl build apk
FIRST="$(sed -n 's/.* -v \([^ ]*\):\/opt\/android-sdk-linux\/ndk .*/\1/p' "$LOG" | head -n 1)"
OTHER="$CASE/other-tree"
mkdir -p "$OTHER/tool"
cp "$ROOT/tool/fl" "$ROOT/tool/flutter_env.sh" "$OTHER/tool/"
: > "$LOG"
FAKE_LOG="$LOG" PATH="$CASE/bin:/usr/bin:/bin:$BASH_DIR" "$OTHER/tool/fl" build apk > "$CASE/stdout" 2> "$CASE/stderr"
SECOND="$(sed -n 's/.* -v \([^ ]*\):\/opt\/android-sdk-linux\/ndk .*/\1/p' "$LOG" | head -n 1)"
if [ -n "$FIRST" ] && [ "$FIRST" = "$SECOND" ]; then pass; else fail "'$FIRST' and '$SECOND'"; fi

new_case "fl_dart does not mount the SDK volume"
run fl_dart format lib
expect_no_log "android-sdk"

# The script that runs inside the image. Fake sdkmanager and flutter record what they are asked.
# container <args...>: runs it against a fake SDK folder in $CASE/sdk.
container() {
  cat > "$CASE/bin/flutter" <<'SH'
#!/bin/sh
echo "flutter $*" >> "$FAKE_LOG"
exit "${FAKE_FLUTTER_RC:-0}"
SH
  cat > "$CASE/sdkmanager" <<'SH'
#!/bin/sh
echo "sdkmanager $*" >> "$FAKE_LOG"
[ -n "${FAKE_SDK_SLEEP:-}" ] && sleep "$FAKE_SDK_SLEEP"
for last; do pkg="$last"; done
n=$(grep -c "^sdkmanager .*$pkg\$" "$FAKE_LOG")
if [ "$n" -le "${FAKE_SDK_FAILS:-0}" ]; then exit 1; fi
folder="${pkg%%;*}"; version="${pkg#*;}"
mkdir -p "$SDK_ROOT/$folder/$version"
echo "Pkg.Revision=$version" > "$SDK_ROOT/$folder/$version/source.properties"
SH
  chmod +x "$CASE/bin/flutter" "$CASE/sdkmanager"
  mkdir -p "$CASE/sdk/ndk" "$CASE/sdk/cmake"
  FAKE_LOG="$LOG" SDK_ROOT="$CASE/sdk" NDK_VERSION=1.2.3 CMAKE_VERSION=4.5.6 SDKMANAGER="$CASE/sdkmanager" APP_DIR="$CASE/app" \
    PATH="$CASE/bin:/usr/bin:/bin:$BASH_DIR" bash "$ROOT/tool/fl_container.sh" "$@" > "$CASE/stdout" 2> "$CASE/stderr"
  RC=$?
}

new_case "container: a build installs the missing NDK once and then builds"
container build apk
expect_rc 0
expect_log "^sdkmanager .*ndk;1.2.3"
expect_log "^flutter build apk"

new_case "container: a build installs the missing CMake as well"
container build apk
expect_log "^sdkmanager .*cmake;4.5.6"

new_case "container: an installed NDK and CMake are not downloaded again"
mkdir -p "$CASE/sdk/ndk/1.2.3" "$CASE/sdk/cmake/4.5.6"
echo "Pkg.Revision=1.2.3" > "$CASE/sdk/ndk/1.2.3/source.properties"
echo "Pkg.Revision=4.5.6" > "$CASE/sdk/cmake/4.5.6/source.properties"
container build apk
expect_no_log "^sdkmanager"
expect_log "^flutter build apk"

new_case "container: commands that do not build skip the NDK"
container test
expect_no_log "^sdkmanager"
expect_log "^flutter test"

new_case "container: a failed download is tried again"
FAKE_SDK_FAILS=2 container build apk
if [ "$(grep -c '^sdkmanager.*ndk;' "$LOG")" -eq 3 ]; then pass; else fail "wanted 3 NDK downloads"; fi
expect_log "^flutter build apk"

new_case "container: a download that keeps failing does not stop the build"
FAKE_SDK_FAILS=9 container build apk
expect_log "^flutter build apk"
expect_stderr "could not install the NDK"
expect_stderr "could not install the CMake"

new_case "container: the exit code of flutter is passed on"
FAKE_FLUTTER_RC=7 container test
expect_rc 7

if command -v flock > /dev/null 2>&1; then
  new_case "container: two builds at once install the NDK only once"
  mkdir -p "$CASE/sdk/ndk"
  export_env() { FAKE_LOG="$LOG" SDK_ROOT="$CASE/sdk" NDK_VERSION=1.2.3 CMAKE_VERSION=4.5.6 SDKMANAGER="$CASE/sdkmanager" APP_DIR="$CASE/app" PATH="$CASE/bin:/usr/bin:/bin:$BASH_DIR" FAKE_SDK_SLEEP=1 "$@"; }
  container true > /dev/null 2>&1
  rm -rf "$CASE/sdk/ndk/1.2.3"
  : > "$LOG"
  export_env bash "$ROOT/tool/fl_container.sh" build apk > /dev/null 2>&1 &
  PID1=$!
  export_env bash "$ROOT/tool/fl_container.sh" build apk > /dev/null 2>&1 &
  PID2=$!
  wait $PID1
  wait $PID2
  if [ "$(grep -c '^sdkmanager.*ndk;' "$LOG")" -eq 1 ]; then pass; else fail "NDK installed $(grep -c '^sdkmanager.*ndk;' "$LOG") times"; fi
  if [ "$(grep -c '^sdkmanager.*cmake;' "$LOG")" -eq 1 ]; then pass; else fail "CMake installed $(grep -c '^sdkmanager.*cmake;' "$LOG") times"; fi
  if [ "$(grep -c '^flutter build' "$LOG")" -eq 2 ]; then pass; else fail "both builds should run"; fi
fi

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
