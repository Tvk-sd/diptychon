#!/usr/bin/env bash
# Build Diptychon with SwiftPM, wrap the binary in a minimal .app bundle, launch.
# Needed because we build with Command Line Tools (no Xcode) — see PLAN.md.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
APP="Diptychon.app"

echo "==> swift build ($CONFIG)"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)/Diptychon"

echo "==> wrapping $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/Diptychon"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "==> launching"
open "$APP"
