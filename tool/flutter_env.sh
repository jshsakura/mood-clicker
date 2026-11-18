# Shared by tool/fl, tool/fl_dart and tool/setup.sh. Source it; do not run it.
# Keep this bash 3.2 compatible (the macOS default shell).

# The Flutter version the project is built and tested with. CI uses the same one.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.0}"
FLUTTER_IMAGE="${FLUTTER_IMAGE:-ghcr.io/cirruslabs/flutter:$FLUTTER_VERSION}"

# Prints the framework version of the flutter on PATH. Prints nothing when there is none,
# when it fails, or when its output has no version.
local_flutter_version() {
  command -v flutter > /dev/null 2>&1 || return 0
  local out
  out="$(flutter --version --machine 2> /dev/null)" || return 0
  printf '%s\n' "$out" \
    | sed -n 's/.*"frameworkVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1 || true
}

# Succeeds when the local flutter should be used: FL_DOCKER is not 1 and the flutter on PATH
# is exactly FLUTTER_VERSION. A different local version is reported on stderr, because
# formatting and analysis results can differ between versions.
use_local_flutter() {
  [ "${FL_DOCKER:-}" = "1" ] && return 1
  local have
  have="$(local_flutter_version)"
  [ -n "$have" ] || return 1
  if [ "$have" != "$FLUTTER_VERSION" ]; then
    echo "tool/fl: flutter $have is on PATH but $FLUTTER_VERSION is required; using docker (FL_DOCKER=1 skips this check)" >&2
    return 1
  fi
  return 0
}

# The docker volume for Gradle's cache. Each working tree gets its own, named from a checksum of its
# path, because Gradle locks its cache and two builds in one volume wait on each other until one times
# out. The pub cache stays shared (it has no such lock). FL_GRADLE_VOLUME overrides the name.
# cksum is POSIX, so this works on macOS and Linux alike.
gradle_volume() {
  if [ -n "${FL_GRADLE_VOLUME:-}" ]; then
    printf '%s\n' "$FL_GRADLE_VOLUME"
    return 0
  fi
  local sum
  sum="$(printf '%s' "$1" | cksum | cut -d ' ' -f 1)"
  printf 'mood-clicker-gradle-%08x\n' "$sum"
}

# The docker volume that holds the Android NDK (about 1 GB), shared by every working tree so it is
# downloaded once. Only the ndk folder is mounted: the rest of the SDK comes from the image.
# FL_ANDROID_SDK_VOLUME overrides the name.
android_sdk_volume() {
  printf '%s\n' "${FL_ANDROID_SDK_VOLUME:-mood-clicker-android-sdk}"
}

# The volume that holds the Android CMake, kept next to the NDK volume. Follows FL_ANDROID_SDK_VOLUME.
android_cmake_volume() {
  printf '%s-cmake\n' "$(android_sdk_volume)"
}
