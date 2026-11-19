#!/usr/bin/env bash
# Build Keepy Pro for iOS — must run on macOS with Xcode + CocoaPods.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "این اسکریپت فقط روی Mac کار می‌کند."
  exit 1
fi

command -v xcodebuild >/dev/null || { echo "Xcode نصب نیست."; exit 1; }
command -v pod >/dev/null || { echo "CocoaPods نصب نیست: sudo gem install cocoapods"; exit 1; }

echo "==> همگام‌سازی وب با Capacitor"
npm run cap:sync

echo "==> نصب Pods"
cd ios/App
pod install --repo-update

echo "==> ساخت برای شبیه‌ساز (Debug)"
xcodebuild \
  -workspace App.xcworkspace \
  -scheme App \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ../../dist/ios-derived \
  build

echo ""
echo "موفق. برای دستگاه واقعی در Xcode:"
echo "  open App.xcworkspace"
echo "سپس Team را انتخاب کن و Product → Archive"
echo ""
echo "خروجی derived: $ROOT/dist/ios-derived"
