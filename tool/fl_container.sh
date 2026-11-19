#!/bin/bash
# Runs inside the Flutter docker image. tool/fl starts it; do not run it on the host.
#
# For a command that builds for Android it first makes sure the NDK and CMake are installed. Their
# folders are volumes shared by every working tree (see tool/fl), so each is downloaded once. Installs are
# serialized with a lock in that folder, so two builds starting together do not download it twice
# or write into the same folder at the same time. The download is retried because a long
# download over a bad connection often breaks.
set -u
SDK_ROOT="${SDK_ROOT:-/opt/android-sdk-linux}"
SDKMANAGER="${SDKMANAGER:-$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager}"
APP_DIR="${APP_DIR:-/app}"

# The NDK version this Flutter SDK builds with, read from the SDK itself.
flutter_ndk_version() {
  local root
  root="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"
  sed -n 's/.*val ndkVersion: String = "\([^"]*\)".*/\1/p' \
    "$root/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt" 2> /dev/null | head -n 1
}

# ensure_package <folder> <version> <label>: installs "<folder>;<version>" into the SDK once.
ensure_package() {
  local folder="$1" version="$2" label="$3" dir
  [ -n "$version" ] || return 0
  dir="$SDK_ROOT/$folder/$version"
  [ -f "$dir/source.properties" ] && return 0
  mkdir -p "$SDK_ROOT/$folder"
  (
    flock 9
    [ -f "$dir/source.properties" ] && exit 0
    for attempt in 1 2 3; do
      "$SDKMANAGER" --sdk_root="$SDK_ROOT" "$folder;$version" && exit 0
      echo "tool/fl: $label $version download failed (attempt $attempt of 3)" >&2
    done
    echo "tool/fl: could not install the $label $version; Gradle will try on its own" >&2
  ) 9> "$SDK_ROOT/$folder/.install.lock"
}

ensure_ndk() {
  ensure_package ndk "${NDK_VERSION:-$(flutter_ndk_version)}" NDK
  # 3.22.1 is the CMake version the Android Gradle plugin asks for by default.
  ensure_package cmake "${CMAKE_VERSION:-3.22.1}" CMake
}

case "${1:-}" in
  build | run | install) ensure_ndk ;;
esac

flutter "$@"
rc=$?
# Files the container wrote as root belong to the user again.
if [ -n "${OWNER:-}" ]; then
  find "$APP_DIR" -xdev -uid 0 -exec chown "$OWNER" {} + 2> /dev/null
fi
exit $rc
