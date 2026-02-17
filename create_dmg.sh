#!/bin/bash

# Configuration
APP_NAME="Echo"
EXECUTABLE_NAME="Echo"
BUNDLE_ID="com.example.echo"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="dmg_staging"

# Ensure we are in the project root
if [ ! -f "Package.swift" ]; then
    echo "Error: Package.swift not found. Please run this script from the project root."
    exit 1
fi

# 1. Build the application in release mode
echo "🚀 Building ${APP_NAME}..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

# Locate the build artifact (SwiftPM universal builds land in apple/Products/Release usually, or simply .build/release if not universal)
# Since we didn't specify universal flags initially, let's stick to standard release path or find it.
# Simple swift build -c release usually outputs to .build/release or .build/arm64-apple-macosx/release
BUILD_PATH=$(swift build -c release --show-bin-path)
EXECUTABLE_PATH="$BUILD_PATH/$EXECUTABLE_NAME"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ Could not find executable at $EXECUTABLE_PATH"
    exit 1
fi

# 2. Create the App Bundle structure
echo "📦 Creating App Bundle..."
APP_BUNDLE="${APP_NAME}.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/"

# Generate App Icon
echo "🎨 Generating App Icon..."
cat > generate_icon.swift <<EOF
import Cocoa

func createIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let gradient = NSGradient(
        starting: NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
        ending: NSColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0))
    let path = NSBezierPath(roundedRect: rect, xRadius: s * 0.225, yRadius: s * 0.225)
    gradient?.draw(in: path, angle: -45)

    NSColor.white.setFill()
    let innerSize = s * 0.6
    let innerRect = NSRect(x: (s - innerSize) / 2, y: (s - innerSize) / 2, width: innerSize, height: innerSize * 1.1)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: s * 0.05, yRadius: s * 0.05)
    innerPath.fill()

    NSColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0).setFill()
    let clipSize = s * 0.3
    let clipRect = NSRect(x: (s - clipSize) / 2, y: innerRect.maxY - (clipSize * 0.2), width: clipSize, height: clipSize * 0.3)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: s * 0.02, yRadius: s * 0.02)
    clipPath.fill()

    let lineCount = 3
    let lineHeight = innerSize * 0.08
    let lineSpacing = innerSize * 0.15
    let startY = innerRect.maxY - (clipSize * 0.5) - lineSpacing

    NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).setFill()
    for i in 0..<lineCount {
        let y = startY - (CGFloat(i) * (lineHeight + lineSpacing))
        let lineRect = NSRect(x: innerRect.minX + (innerSize * 0.2), y: y, width: innerSize * 0.6, height: lineHeight)
        let linePath = NSBezierPath(roundedRect: lineRect, xRadius: lineHeight * 0.5, yRadius: lineHeight * 0.5)
        linePath.fill()
    }

    image.unlockFocus()
    return image
}

func saveImage(_ image: NSImage, to url: URL) {
    guard let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else { return }
    try? pngData.write(to: url)
}

let fileManager = FileManager.default
let iconSetURL = URL(fileURLWithPath: "AppIcon.iconset")
try? fileManager.removeItem(at: iconSetURL)
try? fileManager.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    let image = createIcon(size: size)
    saveImage(image, to: iconSetURL.appendingPathComponent("icon_\(size)x\(size).png"))
    saveImage(createIcon(size: size * 2), to: iconSetURL.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
EOF

swiftc generate_icon.swift -o generate_icon
./generate_icon
if [ -d "AppIcon.iconset" ]; then
    iconutil -c icns AppIcon.iconset
    if [ -f "AppIcon.icns" ]; then
        cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    fi
    rm -rf "AppIcon.iconset" "AppIcon.icns" "generate_icon" "generate_icon.swift"
fi

# Create Info.plist
# LSUIElement=true makes it a "agent" app (menu bar only, no dock icon)
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 3. Create DMG
echo "💿 Creating DMG..."

# Prepare staging directory
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Create DMG using hdiutil
rm -f "$DMG_NAME"
hdiutil create -volname "${APP_NAME}" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# Cleanup
echo "🧹 Cleaning up..."
rm -rf "$STAGING_DIR"
# rm -rf "$APP_BUNDLE" # Keep the .app for local testing if desired

echo "✅ Done! Created $DMG_NAME"
