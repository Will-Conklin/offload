---
id: plan-advanced-accessibility
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - ios
  - accessibility
  - ux
last_updated: 2026-02-21
related:
  - plan-roadmap
  - plan-ux-accessibility-audit-fixes
  - adr-0003-adhd-focused-ux-ui-guardrails
  - design-advanced-accessibility-testing-checklist
depends_on: []
supersedes: []
accepted_by: "@Will-Conklin"
accepted_at: 2026-02-21
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/108
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Advanced Accessibility Features

## Overview

Execution plan for advanced accessibility features beyond the baseline work
completed in
[plan-ux-accessibility-audit-fixes](./plan-ux-accessibility-audit-fixes.md).
Builds on touch targets, color contrast, VoiceOver labels, reduced motion, and
loading states already shipped. This plan is now active and will finalize scope
as part of Phase 1 before implementation slices begin.

## Goals

- Deliver accessibility enhancements beyond baseline launch requirements.
- Ensure features are validated with assistive technologies.

## Phases

### Phase 1: Scope Confirmation

**Status:** In Progress

- [ ] Confirm scope approval in PRD/ADR updates.
- [x] Define the advanced accessibility feature set.

**Advanced feature set (current scope):**

- Improve VoiceOver/Switch Control action parity for gesture-first card and row interactions.
- Expand accessible actions so swipe-only operations (delete/move/convert/star/open/edit)
  are also available from accessibility action menus.
- Validate action labels and behavior for linked-item navigation versus item editing.

### Phase 2: Implementation Planning

**Status:** In Progress

- [x] Map features to affected views and components.
- [ ] Identify testing requirements and tooling.

**Mapped first-slice components:**

- `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Capture/CaptureItemCard.swift`
- `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Organize/CollectionDetailItemRows.swift`
- `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Organize/OrganizeCollectionCards.swift`
- `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/App/AdvancedAccessibilityActionPolicy.swift`

### Phase 3: Implementation & Validation

**Status:** In Progress

- [ ] Implement enhancements.
- [ ] Validate with VoiceOver, Switch Control, and dynamic type.

**TDD slices:**

- [ ] Slice 1: Accessibility action parity for cards and rows
  - [x] Red: Add `AdvancedAccessibilityActionPolicy` unit tests for deterministic labels.
  - [x] Green: Implement policy and wire star/move/open/edit accessibility actions into capture and organize card/row views.
  - [x] Refactor: remove no-op optional accessibility actions when convert/move handlers are unavailable.
  - [ ] Refactor: run tests in CI-capable environment and adjust labels/hints based on QA feedback.
- [ ] Slice 2: Dynamic Type control-size hardening for organize interactions
  - [x] Red: Add `AdvancedAccessibilityLayoutPolicy` unit tests for control and drop-zone sizing at regular and accessibility Dynamic Type sizes.
  - [x] Green: Apply layout policy to chevron/action controls and drag-drop zones in organize views.
  - [x] Refactor: create an on-device VoiceOver/Switch Control + Dynamic Type validation checklist.
  - [ ] Refactor: execute checklist and validate no visual regressions at accessibility text sizes on-device.

## Dependencies

- Baseline accessibility fixes:
  [plan-ux-accessibility-audit-fixes](./plan-ux-accessibility-audit-fixes.md)
  (completed 2026-02-09)
- ADHD UX guardrails:
  [adr-0003](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- Accessibility testing guidance and tooling:
  [advanced-accessibility-testing-checklist](../design/testing/design-advanced-accessibility-testing-checklist.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Feature creep delays launch | M | Keep work gated until scope is approved. |
| Accessibility regressions | M | Run regression testing after each change. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Plan created from roadmap split. |
| 2026-02-09 | Plan refined with cross-references to baseline accessibility audit and ADR-0003. |
| 2026-02-21 | User approved this as the next feature; plan moved to `in-progress` and implementation issue moved to project status `In progress`. |
| 2026-02-21 | Started Slice 1 (accessibility action parity): added shared action-label policy, unit tests, and wired richer accessibility actions for capture cards and organize rows/cards. |
| 2026-02-21 | Started Slice 2 (Dynamic Type sizing): added layout policy tests and applied larger accessibility-size control/drop-zone dimensions in organize interaction surfaces. |
| 2026-02-21 | Refined optional-action behavior so accessibility menus only expose convert/move actions when corresponding handlers are available. |
| 2026-02-21 | Added an on-device advanced accessibility testing checklist (VoiceOver, Switch Control, Dynamic Type, Reduce Motion); execution and evidence capture remain pending. |
