#!/usr/bin/env bash
# Builds a release version of the app and installs+launches it on Abiral's
# iPhone 15 Pro Max over USB/Wi-Fi. Run this any time you want to update
# what's on the phone, or once the 7-day free-signing cert is about to expire
# — a fresh build renews it. Existing task/event data is untouched (it lives
# in the app's data container, which persists across installs unless the app
# is deleted from the home screen first).
set -euo pipefail

DEVICE_ID="00008130-0006654E3A38001C"
FLUTTER="$HOME/development/flutter/bin/flutter"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_ROOT"

echo "==> Building release..."
"$FLUTTER" build ios --release -d "$DEVICE_ID"

echo "==> Installing on device..."
xcrun devicectl device install app --device "$DEVICE_ID" build/ios/iphoneos/Runner.app

echo "==> Launching..."
xcrun devicectl device process launch --device "$DEVICE_ID" com.abiraltuladhar.dailyApp

echo "==> Done."
