---
id: plan-fix-tag-usage-semantics
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - tags
  - capture
  - organize
last_updated: 2026-02-15
related:
  - plan-fix-tag-assignment
  - plan-tag-relationship-refactor
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/164
  - https://github.com/Will-Conklin/Offload/issues/181
implementation_pr: https://github.com/Will-Conklin/Offload/pull/168
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Fix Tag Usage Semantics

## Overview

Update tag usage logic so collection-linked tags count as "in use" across unused filters, safeguards, and usage counts.

## Context

Tag usage helpers currently only check item relationships. The data model also supports collection relationships (`Tag.collections`), so collection-only tags can be incorrectly treated as unused. Product decision is to include both item and collection usage.

## Goals

- Define a single canonical usage rule: in use = item usage + collection usage.
- Apply rule consistently in all repository usage helpers.
- Add tests for collection-only usage and mixed usage.

## Phases

### Phase 1: Canonical Usage Helper

**Status:** Not started

- [ ] Add helper for total usage count (`items.count + collections.count`).
- [ ] Rename internal comments/method intent away from "task count" terminology.

### Phase 2: Update Repository Methods

**Status:** Not started

- [ ] Update `fetchUnused()` to use total usage.
- [ ] Update `isTagInUse(tag:)` to use total usage.
- [ ] Update `updateUsageCount(_:)` to return total usage.

### Phase 3: Tests

**Status:** Not started

- [ ] Add test: collection-only tag is treated as in use.
- [ ] Add test: item-only tag remains in use.
- [ ] Add test: unused tag has zero combined usage.
- [ ] Add test: mixed item+collection usage returns combined count.

### Phase 4: Regression Verification

**Status:** Not started

- [ ] Verify tag management list behavior still matches UI expectations.
- [ ] Verify collection tagging flow still persists and reflects usage.

## Dependencies

- `ios/Offload/Data/Repositories/TagRepository.swift`
- `ios/Offload/Domain/Models/Tag.swift`
- `ios/OffloadTests/TagRepositoryTests.swift`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Existing UI assumes item-only counts | M | Validate counts in settings/tag-management flows |
| Semantic drift between helper names and behavior | L | Align names/comments with combined usage definition |

## User Verification

- [ ] A tag attached only to a collection is not shown as unused.
- [ ] Deletion safeguards treat collection-only tags as in use.
- [ ] Usage counts match combined item + collection relationships.

## Progress

- 2026-02-13: Plan created for issue #164.
- 2026-02-15: Implementation merged in PR #168; opened UAT follow-up issue
  #181.
