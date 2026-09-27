#!/usr/bin/env bash
#
# Builds the app, then produces the release artifacts:
#   build/LingoSwift-<version>.dmg
#   build/LingoSwift-<version>.zip
#   build/SHA256SUMS.txt
#
#   VERSION=1.0.0 ./Scripts/package.sh
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

APP_NAME="LingoSwift"
VERSION="${VERSION:-1.0.0}"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
ZIP_PATH="$BUILD_DIR/$APP_NAME-$VERSION.zip"
STAGING_DIR="$BUILD_DIR/dmg-staging"

VERSION="$VERSION" ./Scripts/build_app.sh

echo "==> Creating $ZIP_PATH"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo "==> Creating $DMG_PATH"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH" > /dev/null
rm -rf "$STAGING_DIR"

echo "==> Checksums"
rm -f "$BUILD_DIR/SHA256SUMS.txt"
( cd "$BUILD_DIR" && shasum -a 256 "$(basename "$DMG_PATH")" "$(basename "$ZIP_PATH")" > SHA256SUMS.txt )
cat "$BUILD_DIR/SHA256SUMS.txt"

echo "Packaged $APP_NAME $VERSION"
