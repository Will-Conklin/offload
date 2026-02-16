---
id: plan-testing-polish
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - launch-release
last_updated: 2026-02-16
related:
  - plan-roadmap
  - plan-ux-accessibility-audit-fixes
  - plan-tab-shell-accessibility-hardening
  - design-manual-testing-checklist
  - design-manual-testing-results
  - prd-0001-product-requirements
  - prd-0003-convert-plans-lists
  - prd-0004-drag-drop-ordering
  - prd-0005-item-search-tags
  - adr-0003-adhd-focused-ux-ui-guardrails
depends_on:
  - plan-ux-accessibility-audit-fixes
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/116
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Testing & Polish

## Overview

Execution plan for the final launch testing and polish work identified in the
roadmap. This plan sequences manual testing, performance validation, bug fixes,
and accessibility review before release prep begins.

## Goals

- Validate core capture, organize, and collection workflows against approved
  scope.
- Resolve defects discovered during manual testing.
- Confirm accessibility, permissions, and offline behavior are stable for launch.
- Enforce explicit non-functional launch gates (latency, startup, memory,
  crash-free health) before release prep.

## Phases

### Phase 1: Manual Feature Verification

**Status:** Not Started

- [ ] Run the [launch manual testing checklist](../design/testing/design-manual-testing-checklist.md)
      end-to-end.
- [ ] Record results in [manual testing results](../design/testing/design-manual-testing-results.md).
- [ ] Verify capture list actions (complete, star, delete) match
      [PRD intent](../prds/prd-0001-product-requirements.md).
- [ ] Confirm voice recording (permissions, start/stop, transcription) per
      [voice capture testing guide](../design/testing/design-voice-capture-testing-guide.md).
- [ ] Validate offline capture and persistence.
- [ ] Review UX tone requirements in core capture/organize flows.

### Phase 2: Performance & Reliability

**Status:** Not Started

- [ ] Capture baseline launch and navigation timing notes.
- [ ] Run pagination flows under large data sets.
- [ ] Measure backend breakdown latency and track p95 under representative load.
- [ ] Capture startup-time and idle-memory baselines on physical devices.
- [ ] Document any regressions or slow paths to address in Phase 3.

### Phase 3: Bug Fixes & Polish

**Status:** Not Started

- [ ] Triage issues found in Phases 1-2.
- [ ] Implement fixes and retest affected flows.
- [ ] Confirm no regressions in core navigation.

### Phase 4: Accessibility Review

**Status:** Not Started

Baseline accessibility work (touch targets, color contrast, VoiceOver labels,
reduced motion, loading states) was completed in
[plan-ux-accessibility-audit-fixes](./plan-ux-accessibility-audit-fixes.md).
This phase validates that work and catches any remaining gaps.

- [ ] Review VoiceOver support for core views.
- [ ] Validate contrast, tap targets, and focus order.
- [ ] Validate custom tab shell and floating CTA VoiceOver traversal end-to-end.
- [ ] Validate Dynamic Type layout at accessibility sizes for tab shell + CTA
      quick actions.
- [ ] Log any launch blockers and confirm resolution.

### Phase 5: Non-Functional Launch Gates

**Status:** Not Started

- [ ] Define and record release gate thresholds:
  - [ ] Backend breakdown latency p95.
  - [ ] iOS startup timing budget.
  - [ ] iOS idle-memory budget.
  - [ ] TestFlight crash-free goal.
- [ ] Verify observed metrics meet gate thresholds before entering release prep.
- [ ] Record gate results in the testing artifacts and link blocking issues for
      any misses.

## Dependencies

- Launch testing checklist: [design-manual-testing-checklist](../design/testing/design-manual-testing-checklist.md)
- Testing results log: [design-manual-testing-results](../design/testing/design-manual-testing-results.md)
- Baseline accessibility fixes: [plan-ux-accessibility-audit-fixes](./plan-ux-accessibility-audit-fixes.md)
  (completed 2026-02-09)
- Stable build of the iOS app for QA execution.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Late defects extend timeline | M | Prioritize blockers and defer non-critical polish. |
| Accessibility gaps found late | M | Run accessibility checks early in Phase 4. |
| Performance regressions | M | Track baseline results and retest after fixes. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Plan created from roadmap split. |
| 2026-02-09 | Plan refined with cross-references to testing artifacts, PRDs, and accessibility audit. |
| 2026-02-16 | Added non-functional launch gates and mandatory tab-shell accessibility validation tasks from review follow-up. |
