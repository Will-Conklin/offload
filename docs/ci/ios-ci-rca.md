<!-- Intent: Track iOS CI failures and applied fixes to avoid rework. -->

# iOS CI RCA Log

## Scope
This document tracks failed GitHub Actions runs, observed symptoms, and fixes
applied so we do not retry the same changes.

## Current Status
- Latest run: 20648070979 (PR #17) failed in "Build iOS App".
- Symptom: Swift compile errors after selecting Xcode 26.1.1 on the runner:
  - `HandOffRequest` has no member `brainDumpEntry` in
    `HandOffRepository.swift` and `SuggestionRepository.swift`.
  - `modelContext.fetch(descriptor)` fails with
    "generic parameter 'T' could not be inferred" in `SuggestionRepository.swift`.
- Fix in progress: Repository lookups now reference `captureEntry` and SwiftData
  fetches have explicit typing to avoid inference issues. Pending validation in
  the next CI run on `macos-26`.

## Constraints
- Local macOS cannot run Xcode 16, so downgrading locally is not viable.

## Applied Fixes (Chronological)

| Date | Commit | Change | Evidence | Result |
| --- | --- | --- | --- | --- |
| 2026-01-01 | 812f8bb | Fix deployment target from 26.2 to 17.0. | N/A | Did not resolve simulator destination issue. |
| 2026-01-01 | 787605e | Add initial iOS CI workflow. | N/A | CI runs failed to find simulator destinations. |
| 2026-01-01 | d86e279 | Remove `OS=latest` from simulator destination. | Run 20644510607 | Still failed to find destination. |
| 2026-01-01 | 4e3cd1a | Use generic iOS Simulator destination. | Run 20644510607 | Still failed to find destination. |
| 2026-01-01 | b593a30 | Use recommended destination pattern + diagnostics. | Run 20644585026 | Still failed to find destination. |
| 2026-01-01 | 2120a4c | Add SDK listing to debug platform availability. | Run 20644627990 | Still failed to find destination. |
| 2026-01-01 | 33c3042 | Explicitly specify iOS Simulator SDK. | Run 20644654196 | Still failed to find destination. |
| 2026-01-01 | 0c33369 | Add `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` at project level. | Run 20644872115 | Still failed to find destination. |
| 2026-01-01 | 7cc9490 | Select available simulator by UDID in CI. | Run 20646313834 | Still failed to find destination. |
| 2026-01-01 | a2286b8 | Add `SUPPORTED_PLATFORMS` to offload target configs. | Run 20646427000 | Still failed to find destination. |
| 2026-01-01 | c77090d | Add CI build-settings diagnostics for simulator SDK. | Run 20647277804 | Confirms scheme has no destinations. |
| 2026-01-01 | b612a13 | Select newest installed Xcode on runner. | Run 20648070979 | Now fails in Swift compilation (no `brainDumpEntry` member). |
| 2026-01-02 | Pending (this PR) | Use `captureEntry` relationship and typed SwiftData fetches to satisfy Xcode 26.1.1 compiler. | Pending next CI run | Pending |
| 2026-01-02 | N/A | Switch iOS workflow runners to `macos-26` for Xcode 26.x coverage. | Pending next CI run | Pending validation of simulator availability and build. |


## Additional Findings
- `origin/feature/ci-workflows` already includes multiple destination tweaks
  and the project-level `SUPPORTED_PLATFORMS` change (commit `0c33369`), but
  no other simulator-enabling changes.
- `ios/Offload.xcodeproj/project.pbxproj` shows `CreatedOnToolsVersion = 26.2`
  and `objectVersion = 77`, which may require a newer Xcode than 16.0 for
  simulator destinations to appear.
- No `.xcconfig` files exist; workspace settings are empty at
  `ios/Offload.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`.
- CI now logs build settings for the simulator SDK before the build step
  to surface effective values like `SUPPORTED_PLATFORMS` and `SDKROOT`.
- The diagnostics still report no destinations for the `offload` scheme even
  when `SDKROOT = iphonesimulator18.0` is selected.
- CI now detects installed Xcode apps, logs their versions, and selects the
  newest available Xcode for builds/tests.
- Latest CI run selected Xcode 26.1.1, and the build now reaches Swift compile
  before failing on missing `brainDumpEntry` and a generic inference error in
  `SuggestionRepository.swift`.

## How to Get an Older Xcode (Reference)
- Download older versions from
  [Apple Developer Downloads](https://developer.apple.com/download/all/)
  (requires Apple ID).
- Install alongside current Xcode by renaming the app, for example:
  `/Applications/Xcode_16.2.app`.
- Point command line tools to the older version:
  `sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer`.
- Verify the selected version:
  `xcodebuild -version`.
- If needed, open the project in that older Xcode to resave project metadata.

## Hosted Runner Path (Option 2)
- Use a GitHub-hosted macOS runner image that includes the required Xcode.
- Add a step to list installed Xcodes (e.g., `ls /Applications | grep Xcode`)
  so CI logs show what is available.
- Set `DEVELOPER_DIR` (or run `xcode-select`) to the chosen Xcode before builds.
- If the required Xcode is missing on the runner image, switch to a newer image.

## Known Non-Solutions
- Simulator destination string changes alone do not fix the issue.
- Adding simulator selection by UDID in CI does not fix the issue.
- Adding `SUPPORTED_PLATFORMS` at the project level alone does not fix the issue.

## Next Steps
- Inspect for build settings that override `SUPPORTED_PLATFORMS` or restrict
  `SUPPORTED_DEVICE_FAMILY` on the offload target during CI.
- Validate the shared scheme in Xcode to ensure it targets iOS (not visionOS)
  and that the `offload` target is selected for iOS Simulator builds.
- Monitor CI results on `macos-26` to confirm simulator availability and track
  any remaining compile-time errors.
