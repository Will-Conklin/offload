---
id: plan-codebase-audit-cleanup
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ios
  - ux
  - accessibility
  - design-system
last_updated: 2026-02-19
related:
  - plan-ux-accessibility-audit-fixes
  - plan-tab-shell-accessibility-hardening
depends_on: []
supersedes: []
accepted_by: "@Will-Conklin"
accepted_at: 2026-02-19
related_issues:
  - "https://github.com/Will-Conklin/Offload/issues/204"
  - "https://github.com/Will-Conklin/Offload/issues/224"
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Codebase Audit Cleanup

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix design system token violations, architecture pattern leaks, and missing contrast-safe helpers identified by codebase audit.

**Architecture:** Tokenize remaining hardcoded values, add a `buttonDarkText` contrast-safe helper, wrap animations with `Theme.Animations.motion()`, and encapsulate direct `modelContext.save()` calls behind repository methods. TDD throughout.

**Tech Stack:** SwiftUI, SwiftData, XCTest

---

## Overview

A full codebase audit on 2026-02-17 identified design system token violations,
animation accessibility gaps, and a repository pattern leak. No critical bugs
were found, but multiple CLAUDE.md compliance issues need cleanup.

## Goals

- Eliminate all hardcoded `.foregroundStyle(.white)` on colored backgrounds
- Replace hardcoded spacing and font literals with `Theme.*` tokens
- Wrap all manual `reduceMotion` ternaries with `Theme.Animations.motion()`
- Encapsulate direct `modelContext.save()` calls in repository methods
- Add missing `buttonDarkText` contrast-safe helper to Theme

## Phases

### Phase 1: Add `buttonDarkText` Contrast-Safe Helper

**Status:** Completed

- [ ] Red:
  - [ ] Add test asserting `Theme.Colors.buttonDarkText(colorScheme, style:)`
        returns appropriate contrast color for both light and dark modes.
- [ ] Green:
  - [ ] Add `buttonDarkText` to `Theme.Colors` in
        `ios/Offload/DesignSystem/Theme.swift`, returning `.white` for light
        mode and the appropriate contrast color for dark mode.
- [ ] Refactor:
  - [ ] Replace `.foregroundStyle(.white)` on `buttonDark` backgrounds:
    - `ios/Offload/Features/Organize/CollectionDetailSheets.swift:366`
    - `ios/Offload/Features/Capture/CaptureComposeView.swift:295`
- [ ] Commit: `fix(design-system): add buttonDarkText contrast-safe helper`

### Phase 2: Tokenize Hardcoded Spacing

**Status:** Completed

- [ ] Red:
  - [ ] Add snapshot or unit test verifying spacing tokens are used (optional
        — spacing is visual, may rely on grep-based lint).
- [ ] Green:
  - [ ] Replace hardcoded `.padding(4)` with `Theme.Spacing.xs`:
    - `ios/Offload/Features/Organize/CollectionDetailSheets.swift:251`
    - `ios/Offload/Features/Capture/CaptureComposeView.swift:204`
  - [ ] Replace hardcoded `HStack(spacing: 4)` with
        `HStack(spacing: Theme.Spacing.xs)`:
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:205`
  - [ ] Replace hardcoded `.padding(.horizontal, 8)` with
        `.padding(.horizontal, Theme.Spacing.sm)`:
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:212`
  - [ ] Replace hardcoded `.padding(.vertical, 4)` with
        `.padding(.vertical, Theme.Spacing.xs)`:
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:213`
- [ ] Refactor: verify no remaining hardcoded spacing in modified files.
- [ ] Commit: `fix(design-system): tokenize hardcoded spacing values`

### Phase 3: Tokenize Hardcoded Fonts

**Status:** Completed

- [ ] Red:
  - [ ] Grep-verify no `.font(.system(` calls exist in Features/ after fix.
- [ ] Green:
  - [ ] Replace `.font(.system(.title2, design: .default).weight(.bold))` with
        `Theme.Typography.title2` or `Theme.Typography.cardTitle`:
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:189`
  - [ ] Replace `.font(.system(size: 8, weight: .bold, design: .default))`
        with `Theme.Typography.badge` (or add a new `xxs` token if 8pt is
        needed):
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:208`
- [ ] Refactor: confirm typography consistency in OrganizeCollectionCards.
- [ ] Commit: `fix(design-system): replace hardcoded fonts with theme tokens`

### Phase 4: Standardize Animation Guards

**Status:** Completed

- [ ] Red:
  - [ ] Add test verifying `Theme.Animations.motion()` returns `.default` when
        `reduceMotion` is true (if not already tested).
- [ ] Green:
  - [ ] Replace manual `reduceMotion ? .default : .easeInOut(...)` ternaries
        with `Theme.Animations.motion()` in:
    - `ios/Offload/Features/Organize/OrganizeCollectionCards.swift:64, 78, 141`
    - `ios/Offload/Features/Organize/CollectionDetailView.swift:136, 186`
    - `ios/Offload/Features/Organize/CollectionDetailItemRows.swift:125, 139,
      220, 300`
    - `ios/Offload/Features/Capture/CaptureItemCard.swift:84`
    - `ios/Offload/Features/Capture/CaptureComposeView.swift:369`
  - [ ] Replace custom `.spring(response: 0.3, dampingFraction: 0.7/0.8)`
        with `Theme.Animations.springDefault` or `Theme.Animations.snapToGrid`
        where appropriate:
    - `ios/Offload/Features/Organize/CollectionDetailView.swift:136, 186`
    - `ios/Offload/Features/Organize/CollectionDetailItemRows.swift:397`
    - `ios/Offload/Features/Capture/CaptureItemCard.swift:84`
- [ ] Refactor: grep-verify no raw `withAnimation(reduceMotion ?` patterns
      remain in Features/.
- [ ] Commit: `fix(accessibility): standardize animation reduced-motion guards`

### Phase 5: Encapsulate Direct ModelContext Access

**Status:** Completed

- [ ] Red:
  - [ ] Add test for new `CollectionItemRepository.saveReorder()` method (or
        equivalent batch-save method) that persists position/parent changes.
- [ ] Green:
  - [ ] Add repository method(s) to `CollectionItemRepository` that handle
        batch reordering with internal `modelContext.save()`.
  - [ ] Replace direct `collectionItemRepository.modelContext.save()` calls in
        `CollectionDetailView` (lines ~360, 396, 479, 519) with the new
        repository method.
- [ ] Refactor: verify `modelContext` is no longer accessed directly from any
      view file.
- [ ] Commit: `refactor(data): encapsulate modelContext access in repository`

## Dependencies

- None — all changes are internal cleanup.

## Risks

- **Spacing/font token changes may subtly alter layout** — verify visually
  after each phase.
- **Animation changes may feel different** — the `Theme.Animations.motion()`
  wrapper should produce identical behavior, but verify drag-drop and card
  animations remain smooth.
- **Repository refactor touches CollectionDetailView reordering** — test
  drag-drop ordering thoroughly after Phase 5.

## User Verification

- [ ] Verify card text remains legible on dark buttons in both light/dark mode
- [ ] Verify spacing looks correct in Organize and Capture views
- [ ] Verify card title fonts in collection cards look correct
- [ ] Verify drag-drop animations remain smooth with reduced motion off
- [ ] Verify reduced motion mode disables all animations properly
- [ ] Verify drag-drop reordering still persists correctly after repository
      refactor

## Progress

| Phase | Description | Status |
| --- | --- | --- |
| 1 | buttonDarkText helper | Completed |
| 2 | Tokenize spacing | Completed |
| 3 | Tokenize fonts | Completed |
| 4 | Animation guards | Completed |
| 5 | ModelContext encapsulation | Completed |

| Date | Update |
| --- | --- |
| 2026-02-19 | Implementation resumed on `fix/codebase-audit-cleanup`; standardized remaining animation tokens/guards, removed final direct view `modelContext` usage, and added repository coverage for child detection plus batch hierarchy/position persistence. |
| 2026-02-19 | PR [#223](https://github.com/Will-Conklin/Offload/pull/223) merged; plan moved to `uat` and follow-up verification issue [#224](https://github.com/Will-Conklin/Offload/issues/224) created in Offload project status `Ready`. |
