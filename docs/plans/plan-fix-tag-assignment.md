---
id: plan-fix-tag-assignment
type: plan
status: completed
owners:
  - Will-Conklin
applies_to:
  - capture
  - organize
  - tags
last_updated: 2026-02-11
related:
  - plan-tag-relationship-refactor
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/141
  - https://github.com/Will-Conklin/offload/pull/144
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Fix Tag Assignment Persistence

## Overview

Diagnose and fix the tag assignment bug preventing tags from persisting when added to items or collections. This issue emerged after the tag-relationship-refactor that changed Item's tag storage mechanism.

## Context

The tag-relationship-refactor (commits 73f3c21-2b12b8d) changed Item's tag storage from `tags: [Tag]` to `tagLinks: [Tag]` with a computed property `tags` for backward compatibility. While the UI components correctly pass Tag objects to repositories and unit tests pass in isolation, tag assignment doesn't persist in production.

**Potential Root Causes:**

1. SwiftData may not detect changes through computed property setters
2. Inverse relationship tracking between Item.tagLinks and Tag.items may be incomplete
3. ModelContext save timing issues with tags created in sheets
4. Query auto-refresh not detecting tag relationship changes

**Key Evidence:**

- UI code correctly passes `[Tag]` objects (verified in CaptureComposeView, AddItemSheet, TagSelectionSheet)
- Repository methods exist and have passing unit tests (testAddTag, testCreateItemWithTags)
- Tag model has proper inverse relationships defined
- Issue affects both items and collections

## Goals

- Add diagnostic logging to identify exact failure point in tag assignment flow
- Fix root cause based on diagnostic findings
- Verify tags persist correctly across app restarts
- Prevent regression with additional integration tests

## Phases

### Phase 1: Add Diagnostic Logging

**Status:** Not started

Add OSLog statements to trace tag assignment from UI → repository → persistence:

- [ ] Add logging to Item.tags computed property getter/setter (Item.swift:113-116)
- [ ] Add logging to ItemRepository.create() after tag assignment (ItemRepository.swift:41)
- [ ] Add logging to ItemRepository.addTag() and removeTag() (ItemRepository.swift:178-188)
- [ ] Add logging to TagSelectionSheet.toggleSelection() (Components.swift:1016-1022)

**Manual Test:**

- [ ] Create capture with 2 tags
- [ ] Check Xcode console for log output
- [ ] Verify if setter is called and if tagLinks is populated
- [ ] Fetch item from repository and check if tags persist

### Phase 2: Identify Root Cause

**Status:** Not started

Based on diagnostic findings, identify which hypothesis is correct:

#### Hypothesis A: Computed Property Setter Issue

- Logs show setter called but tags don't persist after save
- SwiftData doesn't track changes through computed properties

#### Hypothesis B: ModelContext Save Timing

- Logs show tags assigned but not in context when saved
- Tags created in sheets may be in different ModelContext

#### Hypothesis C: SwiftData Inverse Relationship

- Logs show empty tagLinks after fetch
- Inverse relationship not properly maintained

### Phase 3: Implement Fix

**Status:** Not started

**If Hypothesis A (Computed Property):**

- [ ] Remove computed property from Item model
- [ ] Rename `tagLinks` directly to `tags`
- [ ] Update `@Attribute(originalName: "tags")` to point to legacy field
- [ ] Test SwiftData migration doesn't break existing data

**If Hypothesis B (Save Timing):**

- [ ] Ensure TagRepository.fetchOrCreate() saves before returning
- [ ] Add explicit modelContext.save() after tag assignment
- [ ] Verify TagSelectionSheet uses same ModelContext as Item

**If Hypothesis C (Inverse Relationship):**

- [ ] Add explicit bidirectional setup in addTag method
- [ ] When adding tag to item, also add item to tag.items
- [ ] Test with direct tagLinks access instead of computed property

### Phase 4: Add Integration Tests

**Status:** Not started

- [ ] Add test: create capture with tags via UI flow
- [ ] Add test: add tag to existing item
- [ ] Add test: add tag to collection
- [ ] Add test: verify tag persistence across app restart
- [ ] Add test: verify inverse relationship (tag.items contains item)
- [ ] Verify all existing unit tests still pass

### Phase 5: UI Verification

**Status:** Not started

- [ ] Tags show immediately in card after assignment
- [ ] Tags persist after app restart
- [ ] Tags can be removed and update immediately
- [ ] Test on both items and collections
- [ ] Test TagSelectionSheet correctly toggles selected tags

## Dependencies

**Files to Modify:**

- `ios/Offload/Domain/Models/Item.swift` (computed property, lines 113-116; tagLinks definition, lines 17-20)
- `ios/Offload/Domain/Models/Tag.swift` (inverse relationship, line 15)
- `ios/Offload/Data/Repositories/ItemRepository.swift` (tag assignment, lines 20-51, 178-188)
- `ios/Offload/Data/Repositories/CollectionRepository.swift` (tag operations, lines 204-214)
- `ios/Offload/Data/Repositories/TagRepository.swift` (fetchOrCreate, lines 73-82)
- `ios/Offload/DesignSystem/Components.swift` (TagSelectionSheet, lines 934-1023)

**Test Files:**

- `ios/OffloadTests/ItemRepositoryTests.swift` (verify existing tests pass)
- Create: `ios/OffloadTests/TagIntegrationTests.swift` (new integration tests)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| SwiftData migration breaks existing data | H | Test migration thoroughly; add fallback for legacy tags |
| Fix requires schema change | M | Use @Attribute(originalName:) to preserve compatibility |
| Issue is SwiftData framework bug | M | Add workaround with explicit relationship management |
| Tags work in tests but fail in UI | M | Add integration tests that mirror UI usage patterns |

## User Verification

- [ ] Console logs show clear path of tag assignment (Phase 1 complete)
- [ ] Root cause identified and documented (Phase 2 complete)
- [ ] Fix implemented and all tests passing (Phase 3 complete)
- [ ] Create capture with tags → tags persist and show in card
- [ ] Add tag to existing capture → tag updates immediately
- [ ] Add tag to collection → tags show in card
- [ ] Remove tag → tag disappears immediately
- [ ] Restart app → all tags still present
- [ ] Inverse relationship works (tag.items contains assigned items)
- [ ] All existing unit tests pass
- [ ] New integration tests pass

## Progress

| Date       | Update                     |
| ---------- | -------------------------- |
| 2026-02-10 | Plan created for Bug #141. |
