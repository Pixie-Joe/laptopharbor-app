Release checklist for LaptopHarbor

Pre-release
- [ ] Update version and build number in pubspec.yaml (version: x.y.z+build)
- [ ] Run flutter analyze and fix high-severity warnings
- [ ] Run flutter test and ensure all tests pass
- [ ] Update CHANGELOG.md with notable changes (if present)

Android signing
- [ ] Create an upload key / signing key (keystore) if not present
- [ ] Add keystore to secure storage (do NOT commit keystore to repo)
- [ ] Create android/key.properties file locally (ignored by git) with keystore path and passwords:
  storePassword=<password>
  keyPassword=<password>
  keyAlias=<alias>
  storeFile=<path-to-keystore>
- [ ] Configure android/app/build.gradle to read key.properties for signingConfigs
- [ ] Test release build locally: scripts/build_release.ps1 or ./scripts/build_release.sh
- [ ] Upload AAB to Google Play Console using internal test track first

iOS signing (requires macOS)
- [ ] Enroll in Apple Developer Program and set up App ID
- [ ] Create and install provisioning profiles and certificates (or use Xcode automatic signing)
- [ ] Configure code signing in Xcode project and export options (ExportOptions.plist)
- [ ] Test archive locally and validate on TestFlight

Environment & secrets
- [ ] Configure CI secrets:
  - STRIPE_SECRET_KEY (on server)
  - STRIPE_PUBLISHABLE_KEY (client as dart-define or env)
  - ANDROID_KEYSTORE_BASE64 (optionally store keystore as base64 and decode in CI)
  - KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS
- [ ] Use secure parameter stores (GitHub Secrets / CI secrets) and never check plaintext keys into code

Payments
- [ ] Ensure backend (server) has STRIPE_SECRET_KEY and that /create-payment-intent is reachable
- [ ] Wire server webhooks in production and verify webhook endpoint signature verification

Post-release
- [ ] Monitor analytics and crash reporting
- [ ] Verify order processing and payment flows in production

Notes
- Use the scripts/ directory to build artifacts. For CI builds, use macOS runners for iOS and a Linux/Windows runner for Android.
- For automated store uploads consider fastlane or publisher APIs for Play/App Store.
