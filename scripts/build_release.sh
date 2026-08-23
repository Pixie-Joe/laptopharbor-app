#!/usr/bin/env bash
set -euo pipefail

FLAVOR="${1-}"
DART_DEFINES="${2-}"

echo "Building release artifacts for LaptopHarbor"

flutter pub get

if [[ -n "$FLAVOR" ]]; then
  echo "Building Android appbundle for flavor: $FLAVOR"
  flutter build appbundle --flavor "$FLAVOR" --dart-define="$DART_DEFINES"
  echo "Also produce APK for internal testing"
  flutter build apk --release --flavor "$FLAVOR" --dart-define="$DART_DEFINES"
else
  echo "Building Android appbundle"
  flutter build appbundle --release --dart-define="$DART_DEFINES"
  flutter build apk --release --dart-define="$DART_DEFINES"
fi

# iOS builds require macOS
if [[ "$(uname)" == "Darwin" ]]; then
  echo "Building iOS archive (requires Xcode)"
  flutter build ipa --export-options-plist=ios/ExportOptions.plist --dart-define="$DART_DEFINES"
else
  echo "Skipping iOS build: not running on macOS. Use a macOS CI runner for iOS builds."
fi

echo "Builds completed."
echo "Note: Ensure signing keys and keystore.properties are configured before uploading artifacts to stores."
