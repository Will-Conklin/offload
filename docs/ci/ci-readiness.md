<!-- Intent: Document the current iOS project CI readiness, including schemes, commands, and gaps. -->

# iOS CI readiness audit

## Findings summary
- iOS project is under `ios/Offload.xcodeproj` with no separate `.xcworkspace` committed.
- App target is `offload`; test targets are `offloadTests` (unit) and `offloadUITests` (UI). All share an `IPHONEOS_DEPLOYMENT_TARGET` of `26.2`.
- Shared scheme **offload** is committed at `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`.
- Reusable iOS CI scripts live under `scripts/ios/` with shared environment parsing in `scripts/ci/readiness_env.sh`.

## Pinned CI Environment
CI_MACOS_RUNNER: macos-14
CI_XCODE_VERSION: 16.2
CI_SIM_DEVICE: iPhone 16
CI_SIM_OS: 18.1

> Note: macos-14 GitHub runners no longer provide Xcode 16.0; they ship Xcode 16.2+. Pin CI_XCODE_VERSION to 16.2 to avoid resolution failures.

On macos-14 runners with Xcode 16.2, `xcrun simctl list runtimes` exposes the iOS 18.1 runtime, and `xcrun simctl list devices iOS 18.1` includes an **iPhone 16** simulator. Pinning the destination to that pairing prevents `xcodebuild` from falling back to "latest".

## Local build and test commands (xcodebuild)
Use the project file directly with the shared `offload` scheme.

```bash
# Clean build the app
xcodebuild \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.1" \
  clean build

# Run unit and UI tests (code coverage optional)
xcodebuild \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.1" \
  -enableCodeCoverage YES \
  test
```

## Shared test scheme
- **Scheme name**: `offload`
- **Location**: `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`

## Targets and deployment settings
- **offload (app)**: iOS deployment target `17.0`.
- **offloadTests (unit tests)**: Dependent on the `offload` host app, deployment target `17.0`.
- **offloadUITests (UI tests)**: Launches `offload`, deployment target `17.0`.

## Known CI gaps
- Build-only GitHub Actions workflow exists at `.github/workflows/ios-build.yml`; add automated tests when ready.
- Simulator boot/install automation remains manual; improve `scripts/ios/` helpers as simulator coverage expands.
