<!-- Intent: Document the current iOS project CI readiness, including schemes, commands, and gaps. -->

# iOS CI readiness audit

## Findings summary
- iOS project is under `ios/Offload.xcodeproj` with no separate `.xcworkspace` committed.
- App target is `offload`; test targets are `offloadTests` (unit) and `offloadUITests` (UI). All share an `IPHONEOS_DEPLOYMENT_TARGET` of `26.2`.
- Shared scheme **offload** is committed at `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`.
- Reusable iOS CI scripts live under `scripts/ios/` with shared environment parsing in `scripts/ci/readiness_env.sh`.

## Pinned CI Environment
CI_MACOS_RUNNER: macos-14
CI_XCODE_VERSION: 16.0
CI_SIM_DEVICE: iPhone 15
CI_SIM_OS: 17.5

## Local build and test commands (xcodebuild)
Use the project file directly with the shared `offload` scheme.

```bash
# Clean build the app
xcodebuild \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  clean build

# Run unit and UI tests (code coverage optional)
xcodebuild \
  -project ios/Offload.xcodeproj \
  -scheme offload \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  -enableCodeCoverage YES \
  test
```

## Shared test scheme
- **Scheme name**: `offload`
- **Location**: `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`

## Targets and deployment settings
- **offload (app)**: iOS deployment target `26.2`.
- **offloadTests (unit tests)**: Dependent on the `offload` host app, deployment target `26.2`.
- **offloadUITests (UI tests)**: Launches `offload`, deployment target `26.2`.

## Known CI gaps
- Build-only GitHub Actions workflow exists at `.github/workflows/ios-build.yml`; add automated tests when ready.
- Simulator boot/install automation remains manual; improve `scripts/ios/` helpers as simulator coverage expands.
