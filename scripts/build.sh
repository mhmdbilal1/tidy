#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/Tidy.app"
DIST_DIR="$REPO_ROOT/dist"

mkdir -p "$DIST_DIR"

xcodebuild \
  -project "$REPO_ROOT/Tidy.xcodeproj" \
  -scheme Tidy \
  -configuration Release \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  build

xattr -cr "$APP_BUNDLE"
codesign --force --sign - \
  --entitlements "$REPO_ROOT/Tidy/Tidy.entitlements" \
  "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

ditto -c -k --sequesterRsrc --keepParent \
  "$APP_BUNDLE" "$DIST_DIR/Tidy-macOS-arm64.zip"

echo "Built: $APP_BUNDLE"
echo "Packaged: $DIST_DIR/Tidy-macOS-arm64.zip"
