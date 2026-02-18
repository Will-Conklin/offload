---
id: plan-ux-accessibility-audit-fixes
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ios
last_updated: 2026-02-18
related:
  - plan-advanced-accessibility
  - adr-0003-adhd-focused-ux-ui-guardrails
  - plan-testing-polish
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-09
related_issues:
  - https://github.com/Will-Conklin/offload/issues/134
  - https://github.com/Will-Conklin/Offload/issues/216
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: UX & Accessibility Audit Fixes

## Overview

Fixes for issues found in the 2026-02-08 UX/accessibility audit covering touch
targets, loading states, color contrast, reduced motion, and VoiceOver support.
Organized into 5 phases by priority and blast radius. Aligned with
[adr-0003](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md) accessibility-first
guardrail.

## Goals

- Meet Apple HIG 44pt minimum touch targets on all interactive elements
- Reach WCAG AA 4.5:1 contrast ratio on all text pairings
- Respect `accessibilityReduceMotion` across all animations
- Add VoiceOver labels/hints/values to all custom interactive components
- Add loading states to sheets that fetch data asynchronously

## Phases

### Phase 1: Touch Targets

**Scope:** 3 components, ~5 files

**Estimated changes:** Small — frame sizes and constants only

- [ ] Change `Theme.Spacing.actionButtonSize` from 30 to 44 in `Theme.swift:319`
- [ ] Update `ItemActionButton` visual to use the new 44pt size (verify icon
      scales appropriately inside larger frame)
- [ ] Change toolbar `IconTile` usages from `tileSize: 32` to `tileSize: 44`:
  - `CollectionDetailView.swift` — Add item button (~line 207)
  - `CollectionDetailView.swift` — Edit collection button (~line 217)
  - `CaptureView.swift` — Search button (~line 96)
  - `CaptureView.swift` — Settings button (~line 108)
- [ ] Change expand/collapse chevron from `frame(width: 24, height: 24)` to
      `frame(width: 44, height: 44)` in `CollectionDetailView.swift:606`
      (keep icon size at 14pt, expand tappable area)
- [ ] Verify no layout regressions — toolbar spacing, card overlays, chevron
      alignment in hierarchical lists
- [ ] Build and test on device

### Phase 2: Color Contrast

**Scope:** `Theme.swift` color definitions, ~1 file

**Estimated changes:** Medium — add helper functions, adjust dark-mode semantic
colors

- [ ] Add `accentButtonText(_ colorScheme:)` helper to `Theme.Colors`:
  - Light mode: return `.white` (5.15:1 on #D35400 — passes)
  - Dark mode: return `textPrimary` (#FFF8E1 on #E67E22 = 5.54:1 — passes)
- [ ] Add `secondaryButtonText(_ colorScheme:)` helper:
  - Light mode: return `.white` (3.92:1 — borderline, acceptable for large
    text buttons)
  - Dark mode: return `textPrimary` (#FFF8E1 on #27AE60 = 5.6:1 — passes)
- [ ] Fix dark-mode semantic colors for text-on-color:
  - Success: darken from #66BB6A to #2E7D32 (or use dark text on light green)
  - Caution: use dark text (#2C1810) on #FFB300 (17:1 — passes)
  - Destructive: darken from #E57373 to #C62828 (or use dark text)
- [ ] Audit all call sites using `.white` on accent/semantic colors and switch
      to the new helpers
- [ ] Verify light-mode accent (#D35400) on background (#F5F0E8) is only used
      at display text sizes (Bebas Neue 20pt+ = large text, 3:1 passes at 4.30)
- [ ] Build and visually verify both color schemes

### Phase 3: Accessibility Labels & VoiceOver

**Scope:** Components.swift, MainTabView.swift, CaptureView.swift,
OrganizeView.swift

**Estimated changes:** Medium — modifier additions, no layout changes

- [ ] **FloatingActionButton** — add `.accessibilityLabel(title)` to the Button
- [ ] **ItemActionButton** — add `accessibilityLabel: String` parameter to
      init; apply `.accessibilityLabel()` modifier
  - Update all call sites to pass a label string
- [ ] **StarButton** — add `.accessibilityValue(isStarred ? "starred" : "not starred")`
      and `.accessibilityHint("Toggles favorite status")`
- [ ] **TabButton** — add `.accessibilityValue(isSelected ? "selected" : "")`
      in MainTabView
- [ ] **Swipe actions** — add `.accessibilityCustomAction` for complete and
      delete on ItemCard in CaptureView:
  - `AccessibilityCustomAction("Complete", action: { onComplete() })`
  - `AccessibilityCustomAction("Delete", action: { onDelete() })`
- [ ] **Drag-and-drop** — add `.accessibilityCustomAction` for "Move up" and
      "Move down" on DraggableCollectionCard in OrganizeView
  - Same for ItemRow in CollectionDetailView
- [ ] **OffloadQuickActionButton** — add `.accessibilityHint("Opens \(title)
      capture")` in MainTabView
- [ ] Build and test with VoiceOver on device

### Phase 4: Loading States

**Scope:** CaptureView.swift (MoveToPlanSheet, MoveToListSheet),
OrganizeView.swift (search), CaptureView.swift (search)

**Estimated changes:** Small — add `@State isLoading` + ProgressView

- [ ] **MoveToPlanSheet** — add `@State private var isLoading = true`; set
      false after `loadCollections()` completes; show `ProgressView()` when
      `isLoading`
- [ ] **MoveToListSheet** — same pattern as MoveToPlanSheet
- [ ] **CaptureSearchView** — add `@State private var isSearching = false`;
      set true before `performSearch()`, false after; show `ProgressView()`
      when `isSearching && !searchQuery.isEmpty`
- [ ] **OrganizeSearchView** — same pattern as CaptureSearchView
- [ ] Build and verify loading indicators appear briefly on slower data

### Phase 5: Reduced Motion

**Scope:** Theme.swift, Components.swift, MainTabView.swift, ToastView.swift,
all feature views with animations

**Estimated changes:** Large — systemic, touches many files

- [ ] Add reduced-motion-aware animation helper to `Theme.Animations`:

      ```swift
      static func animation(
          _ animation: Animation,
          reduceMotion: Bool
      ) -> Animation {
          reduceMotion ? .none : animation
      }
      ```

- [ ] Add `@Environment(\.accessibilityReduceMotion)` to these components:
  - FloatingActionButton
  - CardSurface
  - TagPill
  - ToastView
  - FloatingTabBar / TabButton
  - OffloadCTA / OffloadMainButton / OffloadQuickActionTray
- [ ] Guard all `withAnimation()` calls with reduced motion check:

      ```swift
      withAnimation(reduceMotion ? .none : Theme.Animations.mechanicalSlide) {
          // state change
      }
      ```

- [ ] Guard all `.animation()` modifiers:

      ```swift
      .animation(reduceMotion ? .none : Theme.Animations.mechanicalSlide, value: x)
      ```

- [ ] Guard `.transition()` modifiers — use `.opacity` only (no `.move` or
      `.scale`) when reduced motion is on
- [ ] Guard ThemeManager `withAnimation` calls in `setTheme()` and `didSet`
- [ ] Guard drag-drop feedback animations in OrganizeView and
      CollectionDetailView
- [ ] Build and test with Settings > Accessibility > Reduce Motion enabled

## Dependencies

- None — all fixes are internal to existing code
- No new dependencies or packages required

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Touch target size increase causes layout overlap | M | Verify spacing in toolbar and card overlays after resize |
| Dark-mode color changes affect brand identity | L | Keep same hue, only adjust text color on colored backgrounds |
| Reduced motion guards miss edge cases | M | Grep for `withAnimation`, `.animation(`, `.transition(` after phase 5 |
| Accessibility custom actions for drag-drop are non-obvious | L | Keep visual drag-drop as primary; custom actions are VoiceOver fallback |

## User Verification

- [ ] Touch targets feel comfortable on device (no accidental taps, no cramped buttons)
- [ ] Dark mode colors readable on all screens
- [ ] VoiceOver navigation of full app flow works end-to-end
- [ ] Loading spinners visible in MoveToPlan/MoveToList sheets
- [ ] Reduce Motion setting disables all animations

## Progress

| Date | Update |
| --- | --- |
| 2026-02-08 | Plan created from UX/accessibility audit results |
| 2026-02-08 | All 5 phases implemented — build passes |
| 2026-02-09 | All 5 phases implemented and tested; issue #134 closed. Awaiting user verification. |
