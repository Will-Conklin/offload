---
id: plan-diagnose-idle-memory-pressure
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - diagnostics
  - memory
  - startup
last_updated: 2026-02-18
related: []
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-15
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/175
implementation_pr: https://github.com/Will-Conklin/Offload/pull/176
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Diagnose Idle Memory Pressure

## Overview

Implement a diagnostics-only pass to identify idle and startup memory-pressure
causes without changing app behavior. This plan focuses on startup migration and
lifecycle memory telemetry so mitigation work can be evidence-driven.

## Goals

- Add resident memory diagnostics helper utilities for reusable snapshot output.
- Instrument startup and migration phases with launch-correlated memory logs.
- Add migration counters to quantify scan and mutation work.
- Capture app memory warning lifecycle events with launch correlation.
- Validate diagnostics behavior with build/test and manual verification.

## Phases

### Phase 1: Add Memory Snapshot Utility

**Status:** Completed

- [x] Add `MemoryDiagnostics` helper in `ios/Offload/Common/MemoryDiagnostics.swift`.
- [x] Implement:
  - [x] `residentMemoryBytes() -> UInt64?`
  - [x] `residentMemoryMBString() -> String`
  - [x] `deltaMBString(before: UInt64?, after: UInt64?) -> String`
- [x] Use task-info APIs and fallback `"unavailable"` when unavailable.

### Phase 2: Instrument Startup + Migration

**Status:** Completed

- [x] Add one launch correlation ID for each `AppRootView` lifetime.
- [x] Log startup diagnostics begin/end in `.task`.
- [x] Log migration start/end timing and memory delta.
- [x] Keep existing migration behavior unchanged.

### Phase 3: Instrument Tag Migration Internals

**Status:** Completed

- [x] Add counters:
  - [x] `tagsScanned`
  - [x] `duplicateTagsMerged`
  - [x] `duplicateTagsDeleted`
  - [x] `itemsScanned`
  - [x] `itemsWithLegacyTags`
  - [x] `tagsCreatedFromLegacy`
  - [x] `itemTagLinksAdded`
  - [x] `legacyTagArraysCleared`
  - [x] `didSave`
- [x] Emit one structured migration summary log.
- [x] Avoid per-item verbose logging.

### Phase 4: Instrument Memory Warning Lifecycle Event

**Status:** Completed

- [x] Add memory warning observer in `AppRootView`.
- [x] Log launch ID, timestamp, and resident memory snapshot on warning.

### Phase 5: Validation and Evidence Collection

**Status:** UAT

- [x] Run `just build`.
- [x] Run `just test`.
- [ ] Manual validation:
  - [ ] Fresh launch idle baseline.
  - [ ] Launch with populated local store.
  - [ ] Simulated memory warning in Xcode.
- [ ] Confirm expected logs in subsystem `wc.Offload`.

## Dependencies

- Existing logging categories in `ios/Offload/Common/Logger.swift`.
- Existing startup migration entrypoint in `ios/Offload/App/AppRootView.swift`.
- Existing migration implementation in
  `ios/Offload/Data/Migrations/TagMigration.swift`.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Diagnostic logs are noisy | M | Keep summary logs at startup/migration boundaries only |
| Resident memory API unavailable on edge environments | L | Return optional bytes and use `"unavailable"` fallback strings |
| Diagnostics perceived as behavior change | L | Keep migration logic unchanged and avoid control-flow edits |

## User Verification

- [ ] Logs show one launch-correlated startup diagnostic sequence per launch.
- [ ] Migration summary includes all counters and `didSave`.
- [ ] Memory warning event includes launch ID, timestamp, and memory snapshot.
- [ ] Capture, Organize, and Settings flows remain unaffected.
- [ ] No noticeable startup slowdown from diagnostics alone.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-14 | Plan created and linked to issue #175. |
| 2026-02-14 | Phases 1-4 implemented; Phase 5 validation in progress. |
| 2026-02-14 | `just build`, `just test`, and `just lint` passed. |
| 2026-02-15 | Diagnostics instrumentation merged in PR #176; issue #175 remains open for ongoing investigation/validation. |
| 2026-02-18 | Plan moved to `uat`; remaining work is user verification and validation follow-up via issue #175. |
