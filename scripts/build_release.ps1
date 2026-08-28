param(
  [string]$flavor = "",
  [string]$dartDefines = ""
)

Write-Host "Building release artifacts for LaptopHarbor"

# Ensure Flutter is on PATH
flutter pub get

# Android: build APK/AAB
# For releasing to Play Store prefer "flutter build appbundle" and upload the AAB.
if ($flavor -ne "") {
  Write-Host "Building Android appbundle for flavor: $flavor"
  flutter build appbundle --flavor $flavor --dart-define="$dartDefines"
  Write-Host "Also produce APK for internal testing"
  flutter build apk --release --flavor $flavor --dart-define="$dartDefines"
} else {
  Write-Host "Building Android appbundle"
  flutter build appbundle --release --dart-define="$dartDefines"
  flutter build apk --release --dart-define="$dartDefines"
}

# iOS: requires macOS and codesigning set up. Run only on macOS build hosts.
if ($IsMacOS) {
  Write-Host "Building iOS archive (requires macOS & Xcode)"
  flutter build ipa --export-options-plist=ios/ExportOptions.plist --dart-define="$dartDefines"
} else {
  Write-Host "Skipping iOS build: not running on macOS. Use a macOS CI runner for iOS builds."
}

Write-Host "Builds completed."
Write-Host "Note: Ensure signing keys and keystore.properties are configured before uploading artifacts to stores."
