#!/bin/bash
set -e

SDK=$(xcrun --show-sdk-path 2>/dev/null || echo "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")

SRCS=(
  MacMonitor_Thermal/MacMonitor.swift
  MacMonitor_Thermal/OnboardingWindowController.swift
  MacMonitor_Thermal/LocalizationManager.swift
  MacMonitor_Thermal/main.swift
)

FRAMEWORKS="-framework Cocoa -framework IOKit"

echo "→ Compiling arm64..."
swiftc -O -sdk "$SDK" -target arm64-apple-macosx13.0 $FRAMEWORKS "${SRCS[@]}" -o MacMonitor_arm64

echo "→ Compiling x86_64..."
swiftc -O -sdk "$SDK" -target x86_64-apple-macosx13.0 $FRAMEWORKS "${SRCS[@]}" -o MacMonitor_x86

echo "→ Creating Universal Binary..."
lipo -create MacMonitor_arm64 MacMonitor_x86 -output MacMonitor_universal
rm MacMonitor_arm64 MacMonitor_x86

echo "→ Assembling .app bundle..."
BUNDLE="MacMonitor.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp MacMonitor_universal "$BUNDLE/Contents/MacOS/MacMonitor"
cp MacMonitor_Thermal/Info.plist "$BUNDLE/Contents/Info.plist"
chmod +x "$BUNDLE/Contents/MacOS/MacMonitor"

echo "→ Copying icon..."
cp MacMonitor_Thermal/AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "→ Copying localizations..."
for lang in en pt es fr de it nl ja ko zh hi; do
  mkdir -p "$BUNDLE/Contents/Resources/${lang}.lproj"
  cp "MacMonitor_Thermal/${lang}.lproj/Localizable.strings" "$BUNDLE/Contents/Resources/${lang}.lproj/"
done

echo "→ Code signing (ad-hoc)..."
codesign --force --deep --sign - "$BUNDLE"

echo "→ Creating DMG..."
DMG_STAGE="/tmp/macmonitor_dmg"
rm -rf "$DMG_STAGE"; mkdir -p "$DMG_STAGE"
cp -R "$BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

VERSION=$(defaults read "$(pwd)/$BUNDLE/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")
hdiutil create -volname "MacMonitor" -srcfolder "$DMG_STAGE" -ov -format UDZO "MacMonitor-v${VERSION}.dmg"

echo ""
echo "✓ Universal Binary (arm64 + x86_64)"
lipo -archs "$BUNDLE/Contents/MacOS/MacMonitor"
echo "✓ DMG: MacMonitor-v${VERSION}.dmg"
