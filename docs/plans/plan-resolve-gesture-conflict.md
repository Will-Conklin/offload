---
id: plan-resolve-gesture-conflict
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - ui
  - organize
  - ux
  - accessibility
last_updated: 2026-02-12
related:
  - plan-drag-drop-ordering
  - prd-0004-drag-drop-ordering
  - design-drag-drop-ordering
  - reference-drag-drop-ordering
depends_on: []
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-02-12
related_issues:
  - https://github.com/Will-Conklin/offload/issues/142
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Resolve Gesture Conflict on Collection Cards

## Overview

Collection cards in OrganizeView currently have two conflicting long-press gestures:

1. `.draggable()` for drag-to-reorder collections (inherent long-press to initiate drag)
2. `.contextMenu` for converting between Plan/List types (long-press to show menu)

Both gestures compete for the same long-press trigger, causing unpredictable behavior and poor UX. Users expect long-press to initiate drag-to-reorder, but the context menu intercepts this gesture.

This plan implements the **overlay menu button pattern** (following the existing ItemRow approach in `CollectionDetailItemRows.swift`) to completely separate the conversion action from the drag-to-reorder gesture.

**Why overlay menu button**:

- Completely eliminates gesture conflict (button vs. drag are distinct interactions)
- Follows established codebase pattern (ItemRow already uses this exact approach)
- Maximizes discoverability (always-visible button)
- Simplest implementation (minimal code changes)
- Inherently accessible (button labels + hints)
- Uses existing IconTile component from design system

**Affected location**: `ios/Offload/Features/Organize/OrganizeView.swift` lines 174-203

## Goals

- Eliminate long-press gesture conflict between drag-to-reorder and type conversion
- Maintain all existing functionality (drag-to-reorder, Plan/List conversion)
- Follow established UI patterns and design system
- Ensure accessibility compliance
- Keep discoverability high

## Phases

### Phase 1: Implementation

**Status:** Complete

- [x] **Verify Icons.more exists** in `ios/Offload/DesignSystem/Icons.swift` (expected at line ~33)
  - Already exists at line 33: `static let more = "ellipsis"`
- [x] **Add onConvert parameter** to `DraggableCollectionCard` struct in `ios/Offload/Features/Organize/OrganizeCollectionCards.swift`
  - Added optional `onConvert: (() -> Void)?` parameter at line 18
  - Added overlay menu button after accessibility actions (lines 87-101)
  - Used `.topTrailing` alignment to avoid conflict with star button
  - Used `IconTile` with `.secondaryOutlined` style and `textSecondary` color
  - Added accessibility label "Collection actions" and hint "Show options for this collection"
- [x] **Update OrganizeView** in `ios/Offload/Features/Organize/OrganizeView.swift`
  - Removed `.contextMenu` block (previously lines 194-203)
  - Added `onConvert: { handleConvert(collection) }` parameter to `DraggableCollectionCard` call
  - Kept existing `handleConvert(_:)`, `performConversion(_:)`, and confirmation dialog logic unchanged

**Implementation reference**: Follow ItemRow pattern from `ios/Offload/Features/Organize/CollectionDetailItemRows.swift` lines 343-363

### Phase 2: Manual Testing

**Status:** Not Started

- [ ] **Build and run** app in iOS Simulator
- [ ] **Navigate** to Organize view (Plans or Lists tab)
- [ ] **Verify drag-to-reorder**:
  - Long-press any collection card
  - Drag should initiate smoothly without context menu appearing
  - Drop card at different position
  - Confirm collection reordered correctly
- [ ] **Verify conversion button**:
  - Locate small menu button (three dots) at top-right of each collection card
  - Tap button
  - Confirm confirmation dialog appears (if Plan→List) or conversion executes (if List→Plan)
  - Verify collection type changes correctly
- [ ] **Verify visual layout**:
  - Menu button should not overlap star button (bottom-right)
  - Menu button should be clearly visible but not visually overwhelming
  - Theme tokens should render correctly (secondaryOutlined style)

### Phase 3: Accessibility Testing

**Status:** Not Started

- [ ] **Enable VoiceOver** on iOS Simulator/device
- [ ] **Focus on collection card** and verify VoiceOver announces card content
- [ ] **Navigate to menu button** and verify "Collection actions" label is announced
- [ ] **Activate button** via VoiceOver gesture (double-tap)
- [ ] **Verify conversion works** through VoiceOver interaction
- [ ] **Test with accessibility features enabled**:
  - Reduce Motion
  - Bold Text
  - Larger Text sizes

### Phase 4: Documentation & Cleanup

**Status:** Not Started

- [ ] Update plan status to `completed`
- [ ] Document pattern in MEMORY.md if useful for future reference
- [ ] Consider adding automated UI tests for gesture conflict prevention (optional)

## Dependencies

**Prerequisite work** (already completed):

- Drag-and-drop ordering implemented ([plan-drag-drop-ordering](./plan-drag-drop-ordering.md))
- Collection type conversion logic implemented
- IconTile component available in design system
- Confirmation dialog for destructive conversions

**No blocking dependencies** — can proceed immediately.

## Risks

### Low: Visual Clutter

**Risk**: Adding menu button to every card may feel visually busy

**Mitigation**:

- Use `.secondaryOutlined` style with `textSecondary` color for visual subtlety
- Position at `.topTrailing` (top-right) away from other interactive elements
- MCM design system supports functional clarity over minimalism

### Low: Pattern Inconsistency

**Risk**: Different patterns for item actions vs. collection actions

**Assessment**: ItemRow already uses overlay menu button pattern, so this creates consistency across Organize feature rather than inconsistency

## User Verification

### Functional Requirements

- [ ] Long-press on collection card initiates drag-to-reorder without showing context menu
- [ ] Drag-and-drop reordering works smoothly and correctly updates collection positions
- [ ] Menu button visible at top-right of each collection card
- [ ] Tapping menu button triggers conversion flow
- [ ] Plan→List conversion shows confirmation dialog warning about hierarchy loss
- [ ] List→Plan conversion executes directly without confirmation
- [ ] Collection type updates correctly after conversion
- [ ] Visual layout follows MCM design system (tokens, spacing, colors)

### Accessibility Requirements

- [ ] VoiceOver announces "Collection actions" label on menu button
- [ ] VoiceOver announces appropriate hint ("Show options for this collection")
- [ ] Menu button activatable via VoiceOver gestures
- [ ] Drag-to-reorder alternative actions ("Move up"/"Move down") still work
- [ ] All animations respect Reduce Motion setting
- [ ] Touch target for menu button meets 44pt minimum size
- [ ] Color contrast for button meets WCAG AA standards

## Progress

### Completion Checklist

- [ ] Phase 1: Implementation (all checkboxes)
- [ ] Phase 2: Manual Testing (all checkboxes)
- [ ] Phase 3: Accessibility Testing (all checkboxes)
- [ ] Phase 4: Documentation & Cleanup (all checkboxes)
- [ ] User Verification: Functional Requirements (all checkboxes)
- [ ] User Verification: Accessibility Requirements (all checkboxes)

**Next action**: Begin Phase 1 implementation after plan acceptance.
