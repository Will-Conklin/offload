<!-- Intent: Document the CI unit test timeout investigation and remediation. -->

# Unit Test CI Timeout RCA

## Summary
- The "Unit Tests with Coverage" job timed out because `xcodebuild test` rebuilt the entire app and test bundle on a fresh runner, then attempted to run tests and generate coverage, exceeding the 15-minute job cap.
- The workflow lacked timestamps or watchdog logging, so the stall looked like a hang with no clarity on which phase consumed time.

## Evidence
- The test job runs on a clean macOS runner and invokes `xcodebuild test`, which performs a full build before running tests. With coverage enabled and no prebuilt artifacts, this duplicated the work already done in the separate build job.
- The linked failing run shows the `Run unit tests` step running until the 15-minute timeout, confirming the time was spent inside the combined build+test command: https://github.com/Will-Conklin/offload/actions/runs/20659608247/job/59319225198.

## Time breakdown
- Setup tasks (checkout, Xcode selection, simulator selection) complete before the `Run unit tests` step and did not hit the timeout.
- At least ~13 minutes elapsed inside `xcodebuild test` (the full 15-minute budget minus short setup), indicating the rebuild+test phase is the bottleneck.
- Prior to this change there was no per-phase timing, so the updated workflow now emits timestamps for simulator boot, build-for-testing, and test execution, plus a one-minute watchdog heartbeat.

## Fix
- Build job now uses `xcodebuild build-for-testing` and logs start/end times so we only compile once per pipeline.
- Test job reuses the cached DerivedData and runs `xcodebuild test-without-building` with a fallback `build-for-testing` only when the cache misses.
- Added simulator pre-boot timing, environment/version logging, and a watchdog that emits status every minute to surface stalls.
- Increased the test job timeout to 20 minutes for headroom while the reuse path keeps expected runtime well under that limit.

## Before/after
- Before: failing run above timed out at 15 minutes during `Run unit tests`.
- After: the next CI runs will capture durations for each phase via the new logging and are expected to finish under the new timeout by avoiding the second full build.
