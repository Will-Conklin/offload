---
id: plan-ai-organization-flows
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - pending-confirmation
last_updated: 2026-02-09
related:
  - plan-roadmap
  - plan-backend-api-privacy
  - prd-0007-smart-task-breakdown
  - prd-0008-brain-dump-compiler
  - prd-0009-recurring-task-intelligence
  - prd-0010-tone-assistant
  - prd-0011-executive-function-prompts
  - prd-0012-decision-fatigue-reducer
  - adr-0003-adhd-focused-ux-ui-guardrails
  - research-on-device-ai-feasibility
  - research-privacy-learning-user-data
depends_on:
  - plan-backend-api-privacy
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/109
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: AI Organization Flows & Review Screen (Pending Confirmation)

## Overview

Execution plan for the optional AI organization flows and review screen listed
as additional proposed scope in the roadmap. Covers six AI feature PRDs
(prd-0007 through prd-0012): smart task breakdown, brain dump compiler, recurring
task intelligence, tone assistant, executive function prompts, and decision
fatigue reducer. Work should begin only after scope is confirmed via PRD/ADR
updates and backend API/privacy constraints are resolved.

## Goals

- Define the workflow for AI-assisted organization across PRDs 0007-0012.
- Ensure review screens align with approved product requirements and
  [adr-0003](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md) ADHD UX
  guardrails.
- Align with privacy and on-device AI constraints from completed research.

## Phases

### Phase 1: Scope Confirmation

**Status:** Not Started

- [ ] Confirm scope approval in PRD/ADR updates.
- [ ] Identify target user flows and review surfaces.

### Phase 2: Workflow Definition

**Status:** Not Started

- [ ] Document flow steps and handoffs.
- [ ] Align with privacy and backend constraints.

### Phase 3: Implementation & Validation

**Status:** Not Started

- [ ] Build UI flow scaffolding.
- [ ] Validate with manual testing and UX review.

## Dependencies

- Backend API + privacy constraints:
  [plan-backend-api-privacy](./plan-backend-api-privacy.md)
- On-device AI feasibility:
  [research-on-device-ai-feasibility](../research/research-on-device-ai-feasibility.md)
- Privacy implications:
  [research-privacy-learning-user-data](../research/research-privacy-learning-user-data.md)
- ADHD UX guardrails:
  [adr-0003](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- AI feature PRDs: prd-0007 through prd-0012 in `docs/prds/`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| AI scope expands beyond launch | H | Keep work gated until scope is approved. |
| Privacy constraints unclear | H | Align with backend/privacy plan before build. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Plan created from roadmap split. |
| 2026-02-09 | Plan refined with cross-references to 6 feature PRDs, research docs, and ADRs. |
