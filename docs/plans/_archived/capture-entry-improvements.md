> **Status: Shipped** — All phases (1–4) implemented. Archived 2026-03-22.
> Remaining polish items tracked in `docs/plans/backlog.md`.

# Capture Entry Improvements — Proposal

## Problem

Capturing a thought currently requires: open app → wait for load → tap
"Offload" button → tap "Quick Write" or "Quick Voice" → type/speak → save.
That's 4-5 steps minimum before content is being entered. For an app whose
core promise is "get this out of my head *now*," every extra tap is friction
that risks losing the thought.

There is also no way to capture from outside the app — no Share Sheet, no
Siri, no widgets. Every capture requires a full context switch into Offload.

---

## Proposed Improvements

### Phase 1: In-App Quick Capture (reduce taps inside the app)

**1a. Single-Tap Capture with Inline Text Field**

Replace the current two-step tray (tap Offload → tap Quick Write) with a
single-tap action that immediately opens `CaptureComposeView` in write mode.
The tray expansion adds a decision point ("write or voice?") that slows things
down.

- Tap the Offload button → opens compose sheet directly in write mode
  (keyboard auto-focused)
- Long-press the Offload button → opens compose in voice mode (recording
  starts immediately)
- This eliminates one tap and one decision from the most common flow

**1b. Persistent Capture Bar on CaptureView**

Add a pinned text field at the top (or bottom) of CaptureView itself — like a
chat input bar. Typing and hitting return creates an Item instantly without
opening a sheet at all. No type, no tags, no attachments — just raw text in,
item created. Users can enrich later from the inbox.

- Single-line `TextField` with send button
- Creates Item with `type: nil`, no tags, no attachment
- Item appears in list immediately with haptic confirmation
- Voice mic button on the bar for quick dictation (uses system dictation, not
  custom voice recording — lower friction than the full voice flow)

**1c. iPad Keyboard Shortcuts**

For iPad users with keyboards:

- `⌘N` → open CaptureComposeView
- `⌘Return` → save current capture
- `⌘.` → dismiss compose sheet

### Phase 2: Share Sheet Extension (capture from any app)

Create a Share Extension target that accepts text, URLs, and images from any
app's share sheet. This is the highest-impact system integration — users can
capture a link from Safari, a quote from a book, or an image from Photos
without switching to Offload.

**Architecture:**

- New target: `OffloadShareExtension`
- Shared App Group container (`group.wc.Offload`) for SwiftData access
- Minimal UI: shows a compact compose view with pre-filled content
- Accepts `public.text`, `public.url`, `public.image` UTTypes

**User flow:**

1. In any app, tap Share → Offload
2. Extension shows content preview + optional type selector + save button
3. Tap Save → item created in shared SwiftData store
4. Next time Offload opens, item appears in Capture inbox

**Implementation considerations:**

- SwiftData `ModelContainer` must be configured with App Group path so both
  the main app and extension can read/write
- Extension has 120MB memory limit — keep UI minimal
- Share Extensions cannot use full SwiftUI navigation stacks; use a single
  view with `@Environment(\.extensionContext)` for dismissal
- Need to migrate existing SwiftData store to App Group location on first
  launch after update (one-time migration)

### Phase 3: App Intents + Siri (voice capture without opening the app)

Use the modern App Intents framework (iOS 16+) to enable:

**3a. Siri Voice Capture**

- "Hey Siri, offload [thought]" → creates an Item with the spoken text
- "Hey Siri, offload" (no text) → prompts "What would you like to capture?"
- Confirmation shown inline in Siri UI; no app launch needed
- Uses `AppIntent` with `@Parameter` for the content string

**3b. Shortcuts Integration**

App Intents automatically surface in the Shortcuts app. Users can build
automations like:

- "When I arrive at work, ask me what's on my mind and offload it"
- "Every morning at 9am, open Offload capture"
- Shortcut actions: "Create Capture", "List Recent Captures", "Search
  Captures"

**3c. Spotlight / Action Button**

- App Intents make the capture action discoverable via Spotlight search
  ("Offload a thought")
- iPhone 15 Pro+ users can map the Action Button to the Offload capture
  intent

**Implementation:**

- Define `OffloadCaptureIntent: AppIntent` with `title`, `description`,
  `@Parameter content: String`
- Define `AppShortcutsProvider` with suggested phrases
- Return `IntentResult` with confirmation snippet
- Shares the same App Group SwiftData container as the Share Extension

### Phase 4: Home Screen Widget (optional, lower priority)

Interactive widget (iOS 17+) with a tap-to-capture button on the home screen.

- Small widget: single "Offload" button → taps deep-link into app with
  compose sheet open
- Medium widget: shows 2-3 recent captures + "Offload" button
- Uses `AppIntentTimelineProvider` and `Button` with intent for interactive
  capture

This is lower priority because widgets have significant limitations (no text
input in widget itself, can only launch the app or trigger an intent).

---

## Shared Infrastructure (required for Phases 2-4)

### App Group Migration

All phases beyond Phase 1 require shared data access:

1. Create App Group: `group.wc.Offload`
2. Move SwiftData container to App Group shared directory
3. Add one-time migration on app launch: detect old store location → copy to
   App Group path → update `ModelContainer` configuration
4. All targets (app, share extension, intents, widget) use the shared
   container

### Shared Capture Module

Extract a lightweight `CaptureService` that both the main app and extensions
can use:

- `func quickCapture(content: String, type: ItemType?, sourceURL: String?) throws -> Item`
- Handles SwiftData insertion, notification posting, and validation
- No UI dependencies — pure data layer
- Lives in a shared framework or Swift package target

---

## Priority Recommendation

| Phase | Impact | Effort | Recommendation |
| --- | --- | --- | --- |
| 1a: Single-tap capture | Medium | Low | Do first — quick win |
| 1b: Persistent capture bar | High | Medium | Do first — biggest in-app improvement |
| 1c: iPad shortcuts | Low | Low | Do with Phase 1 |
| 2: Share Extension | High | High | Do second — most-requested iOS integration |
| 3a: Siri capture | High | Medium | Do third — captures without app switch |
| 3b: Shortcuts | Medium | Low | Free with 3a |
| 3c: Spotlight/Action Button | Medium | Low | Free with 3a |
| 4: Widget | Low | Medium | Defer — limited input capability |

**Suggested order:** Phase 1 → Phase 2 → Phase 3 → Phase 4 (optional)

---

## Open Questions

1. **Persistent bar vs. sheet**: Should the capture bar replace the compose
   sheet entirely for text-only captures, or coexist alongside it?
2. **Share Extension UI**: Minimal (just save button) or full (type selector +
   tags)?
3. **Siri phrase**: "Offload" as the trigger word, or something else? Apple
   requires the app name in the phrase.
4. **SwiftData migration**: The App Group migration is a one-way door — should
   we gate Phases 2-4 behind a feature flag until the migration is proven
   stable?
5. **Scope for first pass**: Should we tackle Phase 1 only initially, or
   bundle Phase 1 + Phase 2 together?
