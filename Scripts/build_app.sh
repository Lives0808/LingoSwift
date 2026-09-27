#!/usr/bin/env bash
#
# Builds LingoSwift.app (a real macOS app bundle) from the SwiftPM executable.
#
#   VERSION=1.0.0 ./Scripts/build_app.sh
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

APP_NAME="LingoSwift"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_ID="${BUNDLE_ID:-com.lives0808.LingoSwift}"
MINIMUM_SYSTEM_VERSION="${MINIMUM_SYSTEM_VERSION:-15.0}"
COPYRIGHT="${COPYRIGHT:-© 2026 Lives0808 – MIT License}"
ARCHS="${ARCHS:-arm64 x86_64}"

BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICNS_PATH="$BUILD_DIR/AppIcon.icns"

BINARIES=()

for arch in $ARCHS; do
    triple="$arch-apple-macos$MINIMUM_SYSTEM_VERSION"
    echo "==> Building $APP_NAME $VERSION for: $triple"
    swift build -c release --triple "$triple"
    bin_dir="$(swift build -c release --triple "$triple" --show-bin-path)"
    binary="$bin_dir/$APP_NAME"
    if [[ ! -x "$binary" ]]; then
        echo "error: built binary not found at $binary" >&2
        exit 1
    fi
    BINARIES+=("$binary")
done

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

if [[ ${#BINARIES[@]} -gt 1 ]]; then
    lipo -create -output "$APP_DIR/Contents/MacOS/$APP_NAME" "${BINARIES[@]}"
else
    cp "${BINARIES[0]}" "$APP_DIR/Contents/MacOS/$APP_NAME"
fi

sed \
    -e "s|__VERSION__|$VERSION|g" \
    -e "s|__BUILD_NUMBER__|$BUILD_NUMBER|g" \
    -e "s|__BUNDLE_ID__|$BUNDLE_ID|g" \
    -e "s|__MINIMUM_SYSTEM_VERSION__|$MINIMUM_SYSTEM_VERSION|g" \
    -e "s|__COPYRIGHT__|$COPYRIGHT|g" \
    Packaging/Info.plist > "$APP_DIR/Contents/Info.plist"
plutil -lint "$APP_DIR/Contents/Info.plist" > /dev/null

printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

cp -R Resources/*.lproj "$APP_DIR/Contents/Resources/"

if [[ ! -f "$ICNS_PATH" ]]; then
    echo "==> Rendering app icon"
    rm -rf "$ICONSET_DIR"
    swift Scripts/make_icon.swift "$ICONSET_DIR"
    iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
fi
cp "$ICNS_PATH" "$APP_DIR/Contents/Resources/$APP_NAME.icns"

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --verbose=1 "$APP_DIR"

echo "==> Result"
lipo -info "$APP_DIR/Contents/MacOS/$APP_NAME"
du -sh "$APP_DIR"
echo "Built $APP_DIR"
