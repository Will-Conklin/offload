# Celebration Animations Design

Status: Implemented (2026-02-24)

## Overview

Positive feedback animations for three key moments in Offload, using moderate
intensity (short particle bursts, satisfying haptics, brief visual
transformations). All animations respect reduced motion and stay within the
existing MCM design system.

## Decisions

- **Moments:** Item completed, first capture ever, collection fully completed
- **Intensity:** Moderate — noticeable but not overwhelming
- **Collection detection:** Auto-detect on last item completion, dismissible
  toast
- **Architecture:** CelebrationModifier (SwiftUI ViewModifier) with
  CelebrationStyle enum — no new manager or environment object

## CelebrationStyle Enum

Three styles with distinct animation parameters:

| Style | Animation | Haptic | Duration | Visual |
| --- | --- | --- | --- | --- |
| `.itemCompleted` | Scale pulse (1.0 -> 1.15 -> 1.0) + green tint | `.light` | ~0.4s | Checkmark icon scales up with success color flash |
| `.firstCapture` | Scale pulse + particle burst (5-8 shapes) | `.medium` | ~1.5s | Small geometric shapes float upward using MCM palette colors |
| `.collectionCompleted` | Border glow pulse + particle burst + success toast | `.medium` | ~2s | Card border pulses accentSecondary, particles rise, then toast |

## CelebrationOverlay ViewModifier

`.celebrationOverlay(style:isActive:)` applied to any view:

- Reads `@Environment(\.accessibilityReduceMotion)` — when true, skips all
  visual animation, keeps only haptic feedback
- Uses `Theme.Animations.motion()` for all animations
- Renders an overlay ZStack with animation content
- Auto-resets `isActive` binding to false after animation completes
- Uses only existing `Theme.Colors.*` tokens (success, accent, accentSecondary,
  cardColor palette)

## Particle System

`CelebrationParticlesView` — pure SwiftUI, no SpriteKit or CAEmitterLayer:

- Generates 5-8 Circle or RoundedRectangle shapes
- Random position offset, opacity fade, and upward drift via `withAnimation`
- Colors from `Theme.Colors.cardColor(index:)` (existing 5-color MCM cycling
  palette)
- Particles fade out over 1-1.5s, then the view removes itself
- Constrained to parent view bounds (no full-screen takeover)
- Reduced motion: entire particle view is skipped

Why pure SwiftUI: no new framework dependency, trivially cheap for 5-8 shapes,
stays within Theme.Animations.motion() system.

## Detection Logic

### Item Completed — CaptureItemCard

After `itemRepository.complete(item)` succeeds, set local
`@State var showCelebration = true`. Apply
`.celebrationOverlay(style: .itemCompleted, isActive: $showCelebration)` to the
card.

### First Capture — CaptureComposeView

`@AppStorage("hasCompletedFirstCapture")` flag. On save, if flag is false:
trigger `.firstCapture` celebration and set flag to true. If already captured
before: keep existing typewriterDing + amber flash (no change). First capture
celebration replaces the amber flash for that one time only.

### Collection Completed — CaptureView

When an item is completed in CaptureView, check if it belongs to any collection
via `item.collectionItems` relationship. If all sibling items in that collection
now have `completedAt` set, trigger a `.success` toast via ToastManager
("Collection name complete!") + medium haptic. Detection lives in CaptureView
since that is where item completion happens — collections themselves do not have
a complete action.

## File Organization

### New file

- `ios/Offload/DesignSystem/CelebrationModifier.swift` — CelebrationStyle enum,
  .celebrationOverlay() ViewModifier, CelebrationParticlesView

### Modified files

- `ios/Offload/Features/Capture/CaptureItemCard.swift` — add
  `.celebrationOverlay(.itemCompleted, ...)`
- `ios/Offload/Features/Capture/CaptureComposeView.swift` — add @AppStorage
  check + `.firstCapture` celebration
- `ios/Offload/Features/Organize/CollectionDetailView.swift` — add collection
  completion detection + `.collectionCompleted` celebration

## Testing

- **Unit tests:** CelebrationStyle properties (animation token, haptic style,
  duration per style). Particle count ranges. First-capture @AppStorage flag
  logic.
- **Manual testing:** Visual verification of each celebration on device
- **Accessibility tests:** Verify reduced motion skips all visual animation,
  verify haptic still fires

## Constraints

- No new dependencies (pure SwiftUI + existing Theme tokens +
  UIImpactFeedbackGenerator)
- All animations gated via `Theme.Animations.motion()` and
  `@Environment(\.accessibilityReduceMotion)`
- Only `Theme.Animations.*` tokens used
- No urgency language, no modals, non-blocking feedback only
- Calm visual system: restrained palette, minimal simultaneous colors
