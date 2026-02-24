---
id: plan-fix-collection-form-dismissal
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ux
  - organize
  - bug-fix
  - forms
last_updated: 2026-02-17
related: []
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-13
related_issues:
  - https://github.com/Will-Conklin/offload/issues/146
  - https://github.com/Will-Conklin/offload/issues/159
implementation_pr: https://github.com/Will-Conklin/offload/pull/154
structure_notes:
  - "Section order: Overview; Root Cause; Goals; Phases; Dependencies; Risks; User Verification; Progress."
  - "Implementation merged 2026-02-13; UAT pending in issue #159"
---

# Plan: Fix Collection Form Sheet Dismissing on Save Failure

## Overview

`CollectionFormSheet` dismisses immediately after calling `onSave`, even if validation or persistence fails. This makes failed create operations appear successful from a UX perspective.

**Impact:**

- User confusion: sheet closes, error toast shows on background (user misses it)
- False positive UX: dismissal signals success even when save failed
- Inconsistent with other form sheets in codebase

**Location:** `ios/Offload/Features/Organize/OrganizeSheets.swift:28-30`

## Root Cause

The Save button calls `onSave(name)` then `dismiss()` unconditionally:

```swift
struct CollectionFormSheet: View {
    let onSave: (String) -> Void  // Non-throwing callback

    Button("Save") {
        onSave(name)  // Line 29
        dismiss()  // Line 30 - ALWAYS dismisses
    }
}
```

The callback signature is `(String) -> Void`, so validation errors inside the callback cannot prevent dismissal.

**Comparison to Correct Pattern:**

`CollectionTagPickerSheet` (lines 104-127) follows the correct pattern:

```swift
Button("Add") {
    do {
        try tagRepository.fetchOrCreate(trimmed)
        // ... more operations
        // NO dismiss() here - handled by view if needed
    } catch {
        errorPresenter.present(error)  // Sheet stays open
    }
}
```

## Goals

- Change `onSave` callback to throwing `(String) throws -> Void`
- Add error handling with conditional dismissal
- Dismiss only on successful save (inside try block)
- Display errors as toasts over the sheet (not background)
- Match pattern used by other sheets in codebase

## Phases

### Phase 1: Update CollectionFormSheet

**Status:** Not Started

- [ ] **Change callback signature** (line 12)
  - Change from: `let onSave: (String) -> Void`
  - Change to: `let onSave: (String) throws -> Void`

- [ ] **Add state for error handling**
  - Add: `@State private var errorPresenter = ErrorPresenter()`
  - Add: `@Environment(\.colorScheme) private var colorScheme`
  - Add: `@EnvironmentObject private var themeManager: ThemeManager`
  - Add computed: `private var style: ThemeStyle { themeManager.currentStyle }`

- [ ] **Wrap Save button in do-catch** (lines 28-32)
  - Change from:

    ```swift
    Button("Save") {
        onSave(name)
        dismiss()
    }
    ```

  - Change to:

    ```swift
    Button("Save") {
        do {
            try onSave(name)
            dismiss()  // Only dismiss on success
        } catch {
            errorPresenter.present(error)
        }
    }
    ```

- [ ] **Add theme styling to form**
  - Add `.scrollContentBackground(.hidden)` to Form
  - Add `.background(Theme.Colors.background(colorScheme, style: style))` to Form

- [ ] **Add error toast modifier**
  - Add `.errorToasts(errorPresenter)` to NavigationStack

### Phase 2: Update Call Site

**Status:** Not Started

- [ ] **Update OrganizeView.createSheet** (lines 294-310)
  - Change callback to throw instead of presenting errors:

    ```swift
    CollectionFormSheet(isStructured: selectedScope.isStructured) { name in
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError("Collection name cannot be empty.")
        }
        _ = try collectionRepository.create(
            name: trimmedName,
            isStructured: selectedScope.isStructured
        )
    }
    .environmentObject(themeManager)
    ```

  - Remove outer do-catch and error presenter (sheet handles it now)

### Phase 3: Testing

**Status:** Not Started

- [ ] **Manual UI test: Validation error keeps sheet open**
  - Navigate to Organize tab
  - Tap "Add Plan" button
  - Enter whitespace-only name: "   "
  - Clear and re-enter single space: " "
  - Tap Save button
  - **Expected:** Sheet stays open, error toast appears over sheet
  - **Expected:** Toast message contains "empty"

- [ ] **Manual UI test: Successful save dismisses sheet**
  - Navigate to Organize tab
  - Tap "Add Plan" button
  - Enter valid name: "My New Plan"
  - Tap Save button
  - **Expected:** Sheet dismisses immediately
  - **Expected:** "My New Plan" appears in collection list
  - **Expected:** No error toast

- [ ] **Optional: Add UI test cases**
  - `testCollectionFormSheet_DoesNotDismissOnValidationError`
  - `testCollectionFormSheet_DismissesOnSuccessfulSave`

### Phase 4: Verification

**Status:** Not Started

- [ ] **Run existing tests**
  - Execute `just test`
  - Verify no regressions

- [ ] **Test both Plan and List creation**
  - Verify error handling for both isStructured: true and false
  - Verify theme styling renders correctly in light/dark mode

- [ ] **Check for other CollectionFormSheet usages**
  - Grep search confirmed only one call site (OrganizeView.swift)
  - No other updates needed

### Phase 5: Documentation

**Status:** Not Started

- [ ] Update plan status to `completed`
- [ ] Add comment to GitHub issue #146 with implementation summary
- [ ] Consider adding to MEMORY.md as pattern reference

## Dependencies

**Prerequisites:**

- `ValidationError` exists in `ios/Offload/Common/ErrorHandling.swift:50-60`
- `ErrorPresenter` pattern used throughout codebase
- `ThemeManager` already injected in OrganizeView (line 35)

**No blocking dependencies** — can proceed immediately.

## Risks

### Medium: Breaking Change to Callback

**Risk:** Callback signature changes from `(String) -> Void` to `(String) throws -> Void`

**Impact Assessment:**

- Only one call site found: `OrganizeView.createSheet` (lines 294-310)
- Call site already has validation logic that can be converted to throws
- Change is localized to Organize feature

**Mitigation:**

- Grep search confirms single call site
- Update call site in same commit
- Test both code paths (validation error + successful save)

### Low: ThemeManager Injection

**Risk:** ThemeManager might not be available in parent view

**Assessment:**

- OrganizeView already has `@EnvironmentObject private var themeManager: ThemeManager` (line 35)
- Sheet inherits environment from parent
- No additional setup needed

### Low: Visual Consistency

**Risk:** Adding theme styling might not match existing sheets

**Assessment:**

- Other sheets already use `Theme.Colors.background(colorScheme, style: style)`
- Adds consistency rather than breaking it
- MCM design system supports this pattern

## User Verification

### Functional Requirements

- [ ] Save button with valid name dismisses sheet immediately
- [ ] Save button with empty/whitespace name keeps sheet open
- [ ] Error toast appears over the sheet (not background view)
- [ ] Error message is clear and actionable
- [ ] Cancel button always dismisses sheet
- [ ] Both Plan and List creation follow same pattern

### UX Requirements

- [ ] Error feedback is immediate and visible
- [ ] User can correct input without re-opening sheet
- [ ] No false positive (sheet closing suggests success)
- [ ] Theme styling matches other sheets
- [ ] Works correctly in light and dark mode

### Testing Requirements

- [ ] Manual test: validation error scenario passes
- [ ] Manual test: successful save scenario passes
- [ ] All existing tests continue to pass
- [ ] No visual regressions in sheet appearance

## Progress

### Completion Checklist

- [ ] Phase 1: Update CollectionFormSheet (all checkboxes)
- [ ] Phase 2: Update Call Site (all checkboxes)
- [ ] Phase 3: Testing (all checkboxes)
- [ ] Phase 4: Verification (all checkboxes)
- [ ] Phase 5: Documentation (all checkboxes)
- [ ] User Verification: Functional Requirements (all checkboxes)
- [ ] User Verification: UX Requirements (all checkboxes)
- [ ] User Verification: Testing Requirements (all checkboxes)

**Next action**: Begin Phase 1 after plan acceptance.
