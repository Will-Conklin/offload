---
id: plan-release-prep
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - launch-release
last_updated: 2026-02-09
related:
  - plan-roadmap
  - plan-testing-polish
  - prd-0001-product-requirements
  - adr-0001-technology-stack-and-architecture
depends_on:
  - plan-testing-polish
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/113
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Release Prep

## Overview

Execution plan for release preparation tasks required after testing and polish
are complete. This plan covers documentation updates, release notes, App Store
metadata, and TestFlight distribution.

## Goals

- Prepare documentation and release notes for launch.
- Finalize App Store metadata and assets.
- Distribute builds via TestFlight for final validation.

## Phases

### Phase 1: Documentation & Release Notes

**Status:** Not Started

- [ ] Update README.md with current feature set and installation instructions.
- [ ] Review and update docs/ for accuracy against shipped features.
- [ ] Archive completed plans per plan lifecycle (move to `docs/plans/_archived/`).
- [ ] Draft release notes highlighting launch features: capture, organize,
      collections, tags, search, drag-drop ordering.

### Phase 2: App Store Metadata

**Status:** Not Started

- [ ] Finalize App Store listing: app name, subtitle, description, keywords,
      and category.
- [ ] Capture App Store screenshots on required device sizes (iPhone 6.7",
      6.1", iPad).
- [ ] Create app icon assets for App Store (1024x1024).
- [ ] Set age rating, privacy policy URL, and support URL.
- [ ] Verify bundle ID (`wc.Offload`) and version number.

### Phase 3: TestFlight Distribution

**Status:** Not Started

- [ ] Create Release build configuration and archive.
- [ ] Upload build to App Store Connect.
- [ ] Configure TestFlight internal testing group.
- [ ] Distribute build and establish feedback window (minimum 1 week).
- [ ] Triage TestFlight feedback and create issues for blockers.

## Dependencies

- Completion of testing and polish: [plan-testing-polish](./plan-testing-polish.md)
- Product requirements for feature scope: [prd-0001](../prds/prd-0001-product-requirements.md)
- Active Apple Developer Program membership.
- App Store Connect access configured.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Documentation gaps | M | Review PRDs and ADRs before updates. |
| App Store assets outdated | M | Audit assets early in Phase 2. |
| TestFlight feedback delays | L | Schedule buffer before final submission. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Plan created from roadmap split. |
| 2026-02-09 | Plan refined with concrete tasks and cross-references. |
