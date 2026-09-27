#!/usr/bin/env bash
#
# Builds the Android APKs.
#
#   ./Scripts/build_apk.sh assembleDebug
#   ./Scripts/build_apk.sh assembleRelease
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

export JAVA_HOME="${JAVA_HOME:-$HOME/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$PATH"

TASK="${1:-assembleDebug}"
shift || true

cd android

if [[ ! -x ./gradlew ]]; then
    echo "error: gradle wrapper missing" >&2
    exit 1
fi

./gradlew "$TASK" "$@"
