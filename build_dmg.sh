#!/bin/bash

# Exit on error
set -e

APP_NAME="MoniGuard"
DMG_NAME="MoniGuard_Installer"
VERSION="1.2.9"

# Try to find flutter
FLUTTER_BIN=$(which flutter || echo "/Users/chinhpmgmail.com/flutter/bin/flutter")

if ! [ -x "$FLUTTER_BIN" ]; then
    echo "❌ Error: flutter command not found. Please install Flutter or add it to your PATH."
    exit 1
fi

# Signing Config
APPLE_CERT="Apple Development: Pham Chinh (JV32AR8KTW)"
ENTITLEMENTS="macos/Runner/Release.entitlements"

echo "🚀 Building Flutter macOS application..."
"$FLUTTER_BIN" build macos --release

# Define paths
APP_BUNDLE="build/macos/Build/Products/Release/${APP_NAME}.app"
X64_APP_BUNDLE="build/macos/Build/Products/Release/x86_64/${APP_NAME}.app" # For Intel
ARM_APP_BUNDLE="build/macos/Build/Products/Release/arm64/${APP_NAME}.app" # For Apple Silicon

# Check where the app bundle is (Flutter version dependent)
if [ -d "$APP_BUNDLE" ]; then
    SOURCE_APP="$APP_BUNDLE"
elif [ -d "$ARM_APP_BUNDLE" ]; then
    SOURCE_APP="$ARM_APP_BUNDLE"
else
    echo "❌ Error: Could not find app bundle at $APP_BUNDLE"
    exit 1
fi

echo "🔐 Code signing application..."

# 1. Sign frameworks recursively
echo "   - Signing nested frameworks..."
find "$SOURCE_APP/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read framework; do
    echo "     Signing: $(basename "$framework")"
    codesign --force --timestamp --options runtime --sign "$APPLE_CERT" "$framework"
done

# 2. Sign the app bundle
echo "   - Signing main app bundle with entitlements..."
codesign --force --timestamp --options runtime --entitlements "$ENTITLEMENTS" --sign "$APPLE_CERT" "$SOURCE_APP"

echo "📂 Creating DMG workspace..."
rm -rf build/dmg_workspace
mkdir -p build/dmg_workspace

echo "📦 Preparing DMG contents..."
cp -R "$SOURCE_APP" build/dmg_workspace/
ln -s /Applications build/dmg_workspace/Applications

echo "💿 Creating DMG file..."
FINAL_DMG="build/${DMG_NAME}_v${VERSION}.dmg"
rm -f "$FINAL_DMG"
hdiutil create -volname "${APP_NAME}" -srcfolder build/dmg_workspace -ov -format UDZO "$FINAL_DMG"

echo "🔐 Code signing DMG..."
codesign --force --timestamp --sign "$APPLE_CERT" "$FINAL_DMG"

echo "✅ DMG created and signed successfully at $FINAL_DMG"
echo "You can now distribute this file to users."
