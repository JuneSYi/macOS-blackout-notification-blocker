#!/bin/bash
set -e

APP_NAME="BlackoutNotiBlocker"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

echo "Building $APP_NAME..."

# Create Bundle Structure
mkdir -p "$MACOS_DIR"

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/Info.plist"

# Compile Swift Code (targeting current macOS)
swiftc -parse-as-library Sources/*.swift -o "$MACOS_DIR/$APP_NAME"

echo "Build successful! App bundle created at $APP_BUNDLE"
