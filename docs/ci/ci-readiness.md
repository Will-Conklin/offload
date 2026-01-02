<!-- Intent: Document the current iOS project CI readiness, including schemes, commands, and gaps. -->

# iOS CI readiness audit

## Findings summary
- iOS project is under `ios/Offload.xcodeproj` with no separate `.xcworkspace` committed.
- App target is `offload`; test targets are `offloadTests` (unit) and `offloadUITests` (UI). All share an `IPHONEOS_DEPLOYMENT_TARGET` of `26.2`.
- Shared scheme **offload** is committed at `ios/Offload.xcodeproj/xcshareddata/xcschemes/offload.xcscheme`.
- There are no reusable iOS CI scripts under `scripts/ios/`.

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
- No CI workflow files exist (e.g., `.github/workflows/` is empty for iOS).
- No helper scripts for simulator booting or derived data cleanup under `scripts/ios/`.

## Files to add or modify for CI readiness
- `.github/workflows/ios-ci.yml` (or similar): Define xcodebuild-based build + test job using the shared scheme.
- `scripts/ios/ci-build.sh` (optional but recommended): Encapsulate the build/test commands above for reuse across local and CI runs.
