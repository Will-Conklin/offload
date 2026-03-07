# Celebration Animations

Status: Implemented (2026-02-24)

Positive feedback animations for three key moments: item completed, first capture ever, and collection fully completed.

---

## Design Decisions

- **Moments:** Item completed, first capture ever, collection fully completed
- **Intensity:** Moderate — noticeable but not overwhelming
- **Collection detection:** Auto-detect on last item completion → dismissible success toast
- **Architecture:** `CelebrationStyle` enum + `.celebrationOverlay()` SwiftUI ViewModifier in a single new file. No new manager or environment object.
- **Reduced motion:** All visual animation gated via `Theme.Animations.motion()` and `@Environment(\.accessibilityReduceMotion)`. Haptic feedback fires regardless of reduced motion setting.

### CelebrationStyle parameters

| Style | Animation | Haptic | Duration |
| --- | --- | --- | --- |
| `.itemCompleted` | Scale pulse (1.0 → 1.15 → 1.0) + green tint flash | `.light` | ~0.4s |
| `.firstCapture` | Scale pulse + particle burst (5–8 shapes) | `.medium` | ~1.5s |
| `.collectionCompleted` | Border glow pulse + particle burst + success toast | `.medium` | ~2.0s |

### Particle system

`CelebrationParticlesView` — pure SwiftUI (no SpriteKit or CAEmitterLayer):

- 5–8 Circle or RoundedRectangle shapes
- Random offset, opacity fade, upward drift via `withAnimation`
- Colors from `Theme.Colors.cardColor(index:)` (5-color MCM cycling palette)
- Fades out over 1–1.5s then removes itself
- Constrained to parent view bounds — no full-screen takeover
- Entirely skipped when Reduce Motion is enabled

---

## What Was Built

### New file

- `ios/Offload/DesignSystem/CelebrationModifier.swift` — `CelebrationStyle` enum, `CelebrationParticlesView`, `CelebrationOverlayModifier`, `.celebrationOverlay(style:isActive:)` View extension

### Modified files

- `ios/Offload/Features/Capture/CaptureItemCard.swift` — `.celebrationOverlay(.itemCompleted, ...)` on swipe-complete
- `ios/Offload/Features/Capture/CaptureComposeView.swift` — `@AppStorage("hasCompletedFirstCapture")` flag + `.firstCapture` celebration on first save
- `ios/Offload/Features/Capture/CaptureView.swift` — `checkCollectionCompletion(for:)` → success toast via `ToastManager` when all items in a collection are completed

### Tests

- `ios/OffloadTests/CelebrationModifierTests.swift` — `CelebrationStyle` properties (haptic style, `showsParticles`, `particleCount` range, `scalePeak`); collection completion detection logic (`allSatisfy`, empty collection guard)

---

## Detection Logic

### Item completed

`CaptureItemCard` triggers `.itemCompleted` celebration after `itemRepository.complete(item)` succeeds via swipe leading action. Sets `@State var showCompleteCelebration = true`.

### First capture

`CaptureComposeView` checks `@AppStorage("hasCompletedFirstCapture")` on save. If false: triggers `.firstCapture` celebration, sets flag to true, dismisses after 1.5s. If already true: existing typewriterDing + amber flash behavior unchanged.

### Collection completed

`CaptureView.completeItem(_:)` calls `checkCollectionCompletion(for:)` after successful completion. Traverses `item.collectionItems → collection.collectionItems → item.completedAt`. If collection is non-empty and all items have `completedAt != nil`, fires medium haptic + `toastManager.show("Collection name complete!", type: .success)`.

---

## Task Log

### Task 1 — CelebrationStyle enum (complete)

`CelebrationStyle` enum with `hapticStyle`, `showsParticles`, `particleCount`, `scalePeak`, `duration` properties. TDD: tests written first, then implementation.

### Task 2 — Particle view (complete)

`CelebrationParticlesView` with MCM palette colors, random geometry, upward animation.

### Task 3 — CelebrationOverlay ViewModifier (complete)

`CelebrationOverlayModifier`: reads `reduceMotion`, fires haptic, runs scale pulse + color flash + particles per style, auto-resets `isActive` binding after duration.

### Task 4 — Item-completed wiring (complete)

`CaptureItemCard`: `@State var showCompleteCelebration`, set on swipe-complete, `.celebrationOverlay(.itemCompleted, ...)` applied to card content.

### Task 5 — First-capture wiring (complete)

`CaptureComposeView`: `@AppStorage` flag check on save, `.firstCapture` celebration path.

### Task 6 — Collection-completed wiring (complete)

`CaptureView.checkCollectionCompletion(for:)` → ToastManager success toast + haptic. Empty collection guard: `!allItems.isEmpty && allItems.allSatisfy { $0.completedAt != nil }`.

### Task 7 — Docs updated (complete)

Design doc marked as implemented. Backlog updated to reflect completion.

### Task 8 — Final verification (complete)

Full test suite passed. Lint clean.
