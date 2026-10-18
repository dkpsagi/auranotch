#!/bin/bash
set -e

echo "🔨 Building AuraNotch Release Build..."
cd "$(dirname "$0")"

swift build -c release

APP_NAME="AuraNotch"
# Find the actual Mach-O executable and explicitly exclude .dSYM companion bundles
BUILD_BIN="$(find .build -type f -name "$APP_NAME" ! -path "*.dSYM*" | grep -i release | head -n 1)"

if [ -z "$BUILD_BIN" ]; then
    BUILD_BIN="$(find .build -type f -name "$APP_NAME" ! -path "*.dSYM*" | head -n 1)"
fi

echo "📦 Found executable: $BUILD_BIN"
file "$BUILD_BIN"

APP_BUNDLE="build/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

cp "$BUILD_BIN" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>app.auranotch.AuraNotch</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.5.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSCameraUsageDescription</key>
    <string>AuraNotch uses the camera to provide the under-notch mirror preview.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>AuraNotch uses the microphone to provide quick on-device voice memos.</string>
</dict>
</plist>
EOF

# Ad-hoc code sign the bundle for seamless macOS execution
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Successfully built and signed $APP_BUNDLE"
echo "To run: open $APP_BUNDLE"
