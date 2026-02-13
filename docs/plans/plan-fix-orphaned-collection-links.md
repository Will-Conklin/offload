---
id: plan-fix-orphaned-collection-links
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - data-integrity
  - repositories
  - bug-fix
last_updated: 2026-02-12
related: []
depends_on: []
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-02-12
related_issues:
  - https://github.com/Will-Conklin/offload/issues/147
structure_notes:
  - "Section order: Overview; Root Cause; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Fix Orphaned Collection Links in CollectionItemRepository

## Overview

`CollectionItemRepository.addItemToCollection` can persist `CollectionItem` rows with nil relationships when referenced items or collections don't exist, violating data integrity and causing crashes in downstream queries.

**Impact:**

- Data corruption: orphaned CollectionItem rows in database
- Crashes in `fetchPage` when sorting by `item?.createdAt` on nil items
- Silent failures: no error thrown to caller

**Location:** `ios/Offload/Data/Repositories/CollectionItemRepository.swift:19-38, 161-173`

## Root Cause

The `addItemToCollection` method calls `fetchCollection(collectionId)` and `fetchItem(itemId)` which return `Optional<T>`, but uses results directly without nil checks:

```swift
func addItemToCollection(itemId: UUID, collectionId: UUID, ...) throws -> CollectionItem {
    let collection = try fetchCollection(collectionId)  // Returns Collection?
    let item = try fetchItem(itemId)  // Returns Item?
    let collectionItem = CollectionItem(...)
    collectionItem.collection = collection  // Sets nil if not found!
    collectionItem.item = item  // Sets nil if not found!
    modelContext.insert(collectionItem)
    try modelContext.save()  // Persists with nil relationships
    return collectionItem
}
```

**Data Corruption Path:**

1. Client calls `addItemToCollection(itemId: deletedItemId, collectionId: validId)`
2. `fetchItem(deletedItemId)` returns `nil`
3. `CollectionItem` is created with valid UUIDs
4. `collectionItem.item = nil` is set
5. `modelContext.save()` persists orphaned row
6. Queries fail on `item?.createdAt` access

## Goals

- Validate entity existence before creating CollectionItem relationships
- Throw user-friendly errors when entities not found
- Prevent data corruption from orphaned rows
- Maintain consistency with error handling patterns
- Add test coverage for error cases

## Phases

### Phase 1: Add Validation Guards

**Status:** Complete

- [x] **Update `addItemToCollection` method** (lines 19-46)
  - Added guard after `fetchCollection` with `ValidationError("Collection not found")`
  - Added `AppLogger.persistence.error` before throw with collection ID
  - Added guard after `fetchItem` with `ValidationError("Item not found")`
  - Added `AppLogger.persistence.error` before throw with item ID
  - Added OSLog import for AppLogger support

- [x] **Update `moveItemToCollection` method** (lines 173-185)
  - Added guard after `fetchCollection` with `ValidationError("Collection not found")`
  - Added `AppLogger.persistence.error` before throw with collection ID
  - Kept remaining logic unchanged

### Phase 2: Add Test Coverage

**Status:** Complete

- [x] **Extended `CollectionItemRepositoryTests.swift`**
  - Added `testAddItemToCollection_ThrowsWhenCollectionNotFound` (lines 158-171)
    - Creates item with valid ID
    - Calls `addItemToCollection` with invalid collection ID
    - Asserts throws `ValidationError` with message "Collection not found"
  - Added `testAddItemToCollection_ThrowsWhenItemNotFound` (lines 173-186)
    - Creates collection with valid ID
    - Calls `addItemToCollection` with invalid item ID
    - Asserts throws `ValidationError` with message "Item not found"
  - Added `testMoveItemToCollection_ThrowsWhenCollectionNotFound` (lines 188-206)
    - Creates collection, item, and collectionItem
    - Calls `moveItemToCollection` with invalid target collection ID
    - Asserts throws `ValidationError` with message "Collection not found"
  - All new tests pass successfully

### Phase 3: Verification

**Status:** Not Started

- [ ] **Run existing repository tests**
  - Execute `just test` to ensure no regressions
  - All existing tests should pass (use valid IDs)

- [ ] **Run new error case tests**
  - Verify ValidationError thrown with correct messages
  - Verify no orphaned rows created in database

- [ ] **Manual UI testing**
  - Test drag-and-drop item to collection
  - Delete collection mid-drag operation
  - Verify error toast appears
  - Verify no crash or data corruption

- [ ] **Check logging output**
  - Verify `AppLogger.general.error` statements appear in console
  - Confirm error messages include entity IDs for debugging

### Phase 4: Documentation

**Status:** Not Started

- [ ] Update plan status to `completed`
- [ ] Add comment to GitHub issue #147 with implementation summary
- [ ] Consider adding to MEMORY.md if pattern useful for future reference

## Dependencies

**Prerequisite:**

- `ValidationError` already exists in `ios/Offload/Common/ErrorHandling.swift:50-60`
- `ErrorPresenter` + `.errorToasts()` pattern handles validation errors in UI

**No blocking dependencies** — can proceed immediately.

## Risks

### Low: Breaking Changes

**Risk:** Method signature unchanged but now throws `ValidationError` on invalid IDs

**Mitigation:**

- All callers already use try-catch (standard repository pattern)
- UI already has `.errorToasts(errorPresenter)` for error display
- Existing tests use valid IDs, will continue to pass

### Low: Race Conditions

**Risk:** Entity deleted between fetch and save

**Assessment:**

- SwiftData transactions handle concurrent deletions
- Worst case: ValidationError thrown instead of silent corruption
- Improvement over current behavior (silent failure)

### Low: Performance Impact

**Risk:** Additional guard checks add overhead

**Assessment:**

- Nil checks are negligible (pointer comparison)
- Prevents costly downstream crashes
- No measurable performance impact expected

## User Verification

### Functional Requirements

- [ ] `addItemToCollection` throws `ValidationError` when collection not found
- [ ] `addItemToCollection` throws `ValidationError` when item not found
- [ ] `moveItemToCollection` throws `ValidationError` when target collection not found
- [ ] Error messages are user-friendly and actionable
- [ ] No orphaned CollectionItem rows created in database
- [ ] Existing valid operations continue to work correctly

### Testing Requirements

- [ ] All existing repository tests pass
- [ ] New error case tests pass
- [ ] Manual UI drag-and-drop test shows error toast on invalid operation
- [ ] `AppLogger.general` output shows detailed error messages with IDs
- [ ] Code coverage remains ≥50%

## Progress

### Completion Checklist

- [ ] Phase 1: Add Validation Guards (all checkboxes)
- [ ] Phase 2: Add Test Coverage (all checkboxes)
- [ ] Phase 3: Verification (all checkboxes)
- [ ] Phase 4: Documentation (all checkboxes)
- [ ] User Verification: Functional Requirements (all checkboxes)
- [ ] User Verification: Testing Requirements (all checkboxes)

**Next action**: Begin Phase 1 after plan acceptance.
