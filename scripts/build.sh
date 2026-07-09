#!/bin/bash
set -e

echo "=== PathDeck macOS App Bundle Builder ==="

# Define directories
WORKSPACE_DIR="$(pwd)"
SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
BUILD_DIR="$WORKSPACE_DIR/.build"
OUTPUT_APP_DIR="$WORKSPACE_DIR/PathDeck.app"
OUTPUT_DMG="$WORKSPACE_DIR/PathDeck.dmg"

# Set DEVELOPER_DIR to Xcode-beta if present locally and not already set in environment
if [ -z "$DEVELOPER_DIR" ] && [ -d "/Applications/Xcode-beta.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
fi

# 1. Check and compile logo.png into appicon.icns if present
if [ -f "$WORKSPACE_DIR/logo.png" ]; then
    echo "0. Found logo.png - generating macOS appicon.icns..."
    rm -rf "$WORKSPACE_DIR/pathdeck.iconset"
    mkdir -p "$WORKSPACE_DIR/pathdeck.iconset"
    
    sips -z 16 16   "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_16x16.png" >/dev/null 2>&1
    sips -z 32 32   "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_16x16@2x.png" >/dev/null 2>&1
    sips -z 32 32   "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_32x32.png" >/dev/null 2>&1
    sips -z 64 64   "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_32x32@2x.png" >/dev/null 2>&1
    sips -z 128 128 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_128x128.png" >/dev/null 2>&1
    sips -z 256 256 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_128x128@2x.png" >/dev/null 2>&1
    sips -z 256 256 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_256x256.png" >/dev/null 2>&1
    sips -z 512 512 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_256x256@2x.png" >/dev/null 2>&1
    sips -z 512 512 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_512x512.png" >/dev/null 2>&1
    sips -z 1024 1024 "$WORKSPACE_DIR/logo.png" --out "$WORKSPACE_DIR/pathdeck.iconset/icon_512x512@2x.png" >/dev/null 2>&1
    
    iconutil -c icns "$WORKSPACE_DIR/pathdeck.iconset" -o "$WORKSPACE_DIR/appicon.icns"
    rm -rf "$WORKSPACE_DIR/pathdeck.iconset"
    echo "appicon.icns generated successfully."
fi

echo "1. Building Swift Package executable in Release mode..."
swift build -c release

echo "2. Re-creating PathDeck.app bundle directory structure..."
rm -rf "$OUTPUT_APP_DIR"
mkdir -p "$OUTPUT_APP_DIR/Contents/MacOS"
mkdir -p "$OUTPUT_APP_DIR/Contents/Resources"

echo "3. Copying compiled binary into app bundle..."
cp "$BUILD_DIR/release/PathDeck" "$OUTPUT_APP_DIR/Contents/MacOS/PathDeck"

echo "4. Copying info.plist..."
cp "$SCRIPTS_DIR/info.plist" "$OUTPUT_APP_DIR/Contents/Info.plist"

# Copy generated appicon.icns into app bundle resources if it exists
if [ -f "$WORKSPACE_DIR/appicon.icns" ]; then
    echo "Copying appicon.icns into Resources folder..."
    cp "$WORKSPACE_DIR/appicon.icns" "$OUTPUT_APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo "5. Performing ad-hoc codesigning on PathDeck.app..."
codesign --force --deep --sign - "$OUTPUT_APP_DIR"

echo "6. Packaging PathDeck.app into a compressed DMG disk image..."
rm -f "$OUTPUT_DMG"

DMG_TEMP_DIR="$WORKSPACE_DIR/dmg_temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$OUTPUT_APP_DIR" "$DMG_TEMP_DIR/PathDeck.app"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

hdiutil create -volname "PathDeck" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$OUTPUT_DMG"
rm -rf "$DMG_TEMP_DIR"

echo "========================================="
echo "PathDeck.app and PathDeck.dmg built successfully!"
echo "App location: $OUTPUT_APP_DIR"
echo "DMG location: $OUTPUT_DMG"
echo "========================================="
