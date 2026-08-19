#!/bin/bash
SDK=$(xcrun --show-sdk-path)
swiftc -O \
  -sdk "$SDK" \
  -target x86_64-apple-macosx13.0 \
  -framework Cocoa \
  -framework IOKit \
  MacMonitor_Thermal/MacMonitor.swift \
  -o MacMonitor
mkdir -p MacMonitor.app/Contents/MacOS
cp MacMonitor MacMonitor.app/Contents/MacOS/MacMonitor
cp MacMonitor_Thermal/Info.plist MacMonitor.app/Contents/Info.plist
codesign --force --deep --sign - MacMonitor.app
echo "Build OK → MacMonitor.app"
