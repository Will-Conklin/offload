<!-- Intent: Provide the single source of truth for CI failure RCAs, timelines, and remediations across workflows. -->

# CI Failure RCA (Consolidated)

## Executive Summary
- Consolidated all locally available CI RCA notes into one document and stubbed prior files to reduce drift.
- Key failure clusters observed locally: simulator boot exit code **117**, missing coverage bundle leading to exit **1**, unit test job timeouts, and earlier simulator destination/compile issues.
- GitHub API access from this environment is blocked (HTTP 403), so remote run logs, artifacts, and additional failures in the last 90 days could not be retrieved. Only runs recorded in the repository are included.

## Scope
- Time window: 2026-01-01 to 2026-01-02 (based on locally stored RCAs; broader enumeration deferred until API access is available).
- Workflows referenced: iOS CI (Unit Tests with Coverage), upstream CI pipeline components that build and test iOS targets.
- Branches observed locally: `main` (others unknown due to missing API access).
- PR #17: No locally stored runs reference PR #17; enumeration is pending API access to confirm inclusion.

## Failure Clusters
### Simulator boot exit 117 (iOS CI)
- Symptom: `Boot simulator (timed)` step returned **117** when `xcrun simctl bootstatus "$SIMULATOR_UDID" -b -s` immediately followed `simctl boot`, so slower boots surfaced as failures without diagnostics.
- Associated run(s): 20662961598 (main).
- Evidence: Missing simulator diagnostics and absent `ios/TestResults.xcresult` artifact; exit code surfaced before tests executed.

### Coverage generation blocked by missing result bundle
- Symptom: `Generate coverage report` exited **1** because `ios/TestResults.xcresult` was absent when tests never ran.
- Associated run(s): 20662961598 (main).
- Evidence: Coverage command attempted `xcrun xccov view --report --json ios/TestResults.xcresult` even though the bundle was missing.

### Unit test job timeout
- Symptom: `xcodebuild test` performed a full rebuild on a clean runner and exceeded the 15-minute job budget; logs lacked per-phase timing.
- Associated run(s): 20659608247 (workflow job 59319225198).
- Evidence: Timeout occurred inside `Run unit tests` with no intermediate heartbeats; failure linked in prior RCA.

### Simulator destination unavailability and compile errors on newer Xcode
- Symptom: Multiple runs reported no available simulator destinations despite configuration changes; later runs reached Swift compilation and failed on missing symbols when selecting Xcode 26.1.1.
- Associated run(s): 20644510607, 20644585026, 20644627990, 20644654196, 20644872115, 20646313834, 20646427000, 20647277804, 20648070979.
- Evidence: Prior RCA log notes repeated destination resolution failures and later Swift compile errors (`brainDumpEntry` missing, generic inference error in `SuggestionRepository.swift`).

## Timeline
| Datetime (ET) | Branch | Workflow | Run / Job | Conclusion | Cluster | Link |
| --- | --- | --- | --- | --- | --- | --- |
| Not captured (API blocked; recorded date 2026-01-02) | main | iOS CI | Run 20662961598 | failure | Simulator boot exit 117; coverage bundle missing | N/A (logs blocked) |
| Not captured (API blocked; recorded date 2026-01-02) | unknown | iOS CI | Run 20659608247 / Job 59319225198 | cancelled (timeout) | Unit test job timeout | [GitHub Actions run](https://github.com/Will-Conklin/offload/actions/runs/20659608247/job/59319225198) |
| Not captured (API blocked; recorded dates 2026-01-01) | unknown | iOS CI | Runs 20644510607–20648070979 | failure | Simulator destination unavailable / compile errors | N/A (logs blocked) |

## Evidence (per cluster)
### Simulator boot exit 117
- Commands: `xcrun simctl boot "$SIMULATOR_UDID"` followed by `xcrun simctl bootstatus "$SIMULATOR_UDID" -b -s` (no timeout). Failure surfaced as exit **117** with no diagnostics when the simulator needed more time to boot.
- Post-fix command: `xcrun simctl bootstatus "$SIMULATOR_UDID" -b -t 180` inside `scripts/ios/boot-simulator.sh`, with `simctl diagnose` and `launchd_sim` logs on failure.
- Runner / Xcode / runtime: Not recorded in repository; GitHub API log download blocked (HTTP 403) so host details could not be extracted.

### Coverage generation blocked by missing result bundle
- Command: `xcrun xccov view --report --json ios/TestResults.xcresult` executed without verifying bundle presence, producing exit **1**.
- Post-fix behavior: Gate coverage on bundle existence and downgrade artifact upload failures to warnings.

### Unit test job timeout
- Cause: `xcodebuild test` rebuilt the app and tests on the test job despite a prior build, exceeding the 15-minute limit and stalling without watchdog logs.
- Mitigation: Switch build job to `xcodebuild build-for-testing`, reuse DerivedData, and run `xcodebuild test-without-building` with added timestamps and watchdog heartbeat; increase timeout to 20 minutes.

### Simulator destination unavailability and compile errors
- Observations: Multiple destination string and `SUPPORTED_PLATFORMS` adjustments failed to surface simulator destinations. Selecting the newest Xcode (26.1.1) progressed to Swift compilation, which then failed on missing `brainDumpEntry` and an inference error in `SuggestionRepository.swift`.
- Current status: Destination availability and compilation remain unverified pending fresh CI runs.

## Root Causes
### Confirmed
- Simulator boot step returned exit 117 because `bootstatus -b -s` was invoked immediately after `boot`, treating “not yet booted” as failure without retries.
- Coverage step returned exit 1 because `ios/TestResults.xcresult` was absent after tests never executed.
- Unit test job exceeded time limit due to redundant full build in the test job plus lack of heartbeat logging.

### Probable
- Simulator destination failures stem from project metadata created with Xcode 26.2 and missing shared scheme validation for iOS simulators; underlying runner/Xcode mismatches remain to be confirmed when logs are available.
- Compile errors on Xcode 26.1.1 suggest schema or model naming drift (`brainDumpEntry` vs. `captureEntry`) and type inference regressions in SwiftData queries.

## Remediations
### Immediate
- Keep `scripts/ios/allocate-simulator.sh` + `scripts/ios/boot-simulator.sh` with `bootstatus -t 180` to ensure blocking boot and diagnostics.
- Guard coverage generation behind the presence of `ios/TestResults.xcresult`; emit explicit error when missing.
- Maintain watchdog logging and reuse of DerivedData to prevent silent timeouts.

### Medium
- Re-run CI on `macos-26` with updated boot scripts to validate simulator availability and capture host/Xcode/runtime data.
- Align SwiftData model references (`captureEntry` vs. legacy names) and update `SuggestionRepository.swift` to satisfy Xcode 26.1.1 compiler checks.
- Add explicit simulator runtime/device logging (from `simctl list runtimes` and `simctl list devices`) at allocation time.

### Long
- Add automated CI health report that exports failed runs, artifacts, and host metadata to `docs/rca/ci-rca-inventory.json` on each failure.
- Establish alerting for repeated simulator boot exit 117 occurrences to catch regressions.
- Periodically validate CI against the minimum supported Xcode versions and record outcomes in the consolidated RCA.

## Preventative Actions
- Require blocking simulator boot with diagnostics in all workflows that start simulators.
- Enforce coverage gating and artifact existence checks before coverage commands.
- Standardize on build-for-testing + test-without-building pattern with cache reuse and heartbeat logging for long-running steps.
- Add a scheduled job (once API access is restored) to refresh the consolidated run inventory and artifact listings.

## Appendix
### Full run inventory (failed/cancelled)
| Run / Job | Workflow | Branch | Conclusion | Summary | Artifacts |
| --- | --- | --- | --- | --- | --- |
| 20662961598 | iOS CI | main | failure | Simulator boot exit 117 followed by missing `ios/TestResults.xcresult`; coverage step exited 1. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20659608247 / 59319225198 | iOS CI | unknown | cancelled (timeout) | `xcodebuild test` rebuilt app+tests and exceeded 15-minute limit without watchdog. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20644510607 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20644585026 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20644627990 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20644654196 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20644872115 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20646313834 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20646427000 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20647277804 | iOS CI | unknown | failure | No simulator destination available. | Not available locally; API log/artifact download blocked (HTTP 403). |
| 20648070979 | iOS CI | unknown | failure | Swift compilation failed after selecting Xcode 26.1.1 (`brainDumpEntry` missing; inference error in `SuggestionRepository.swift`). | Not available locally; API log/artifact download blocked (HTTP 403). |

### Artifact inventories
- No artifacts or log archives are present locally. Attempts to download via GitHub API returned HTTP 403 (tunnel blocked), so artifact names and sizes could not be enumerated.

### Prior RCA summaries and disposition
- `docs/ci/RCA.md` (superseded; stub retained) — content merged into this consolidated RCA.
- `docs/ci/ios-ci-rca.md` (superseded; stub retained) — chronology and findings merged here.
- `docs/testing/RCA.md` (superseded; stub retained) — unit test timeout analysis merged here.
