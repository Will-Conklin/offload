---
id: plan-tag-relationship-refactor
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - pending-confirmation
last_updated: 2026-02-17
related:
  - plan-roadmap
  - adr-0001-technology-stack-and-architecture
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/219
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Tag Relationship Refactor (Pending Confirmation)

## Overview

Execution plan for the optional tag relationship refactor listed as additional
proposed scope in the roadmap. Refactors tag storage from denormalized string
arrays to proper SwiftData relationships. Technical design is documented in
[archived plan](./_archived/plan-archived-tag-relationship-refactor.md). Work
should begin only after scope is confirmed via PRD/ADR updates.

## Goals

- Reduce migration risk tied to tag relationships.
- Maintain data integrity during any schema transitions.

## Phases

### Phase 1: Scope Confirmation

**Status:** Not Started

- [ ] Confirm scope approval in PRD/ADR updates.
- [ ] Identify impacted SwiftData models and repositories.

### Phase 2: Migration Planning

**Status:** Not Started

- [ ] Define migration steps and rollback plan.
- [ ] Document required data validation checks.

### Phase 3: Implementation & Validation

**Status:** Not Started

- [ ] Execute refactor and run migration checks.
- [ ] Validate tag queries and relationships.

## Dependencies

- Technology stack and SwiftData architecture:
  [adr-0001](../adrs/adr-0001-technology-stack-and-architecture.md)
- Archived technical design:
  [plan-archived-tag-relationship-refactor](./_archived/plan-archived-tag-relationship-refactor.md)
- SwiftData migration guidance and test coverage.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Migration causes data loss | H | Validate backups and run staged migration tests. |
| Scope shifts delay launch | M | Keep work gated behind scope confirmation. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-10 | Implementation started in [PR #138](https://github.com/Will-Conklin/Offload/pull/138). |
| 2026-01-20 | Plan created from roadmap split. |
| 2026-02-09 | Plan refined with cross-references to ADR-0001 and archived technical design. |
