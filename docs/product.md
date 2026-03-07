# Offload — Product

## Vision

**Offload** is an iOS app (iPhone + iPad) that reduces mental overload by letting users quickly capture thoughts, tasks, and ideas, then optionally organize them. The app prioritizes **externalizing first**, **organizing later**, and **never forcing structure**.

Core user pain:
> "I need this out of my head now, but organizing it feels like too much."

---

## Philosophy

### Capture-first, organize never-forced

The primary action is always capture. Organization is optional, secondary, and never blocking. Every flow has an escape hatch. No item is ever auto-organized without explicit user approval.

### ADHD-first design

Offload is built for people who experience cognitive overload — particularly those with ADHD or similar executive function challenges. This means:

- **No shaming or urgency language.** Never use "overdue," "late," "behind," "easy," "simple," or "you should." Prefer: "You usually do this around now. Want to add it?" over "Time to do this."
- **Undo over confirmation.** Destructive actions use undo banners, not blocking modals (exception: batch destructive actions).
- **AI always suggests, never auto-acts.** Every AI output requires explicit user review and approval before anything changes.
- **Gentle prompts, dismissible.** All nudges (organize suggestions, pattern suggestions) can be snoozed or dismissed without penalty.
- **Calm visual system.** Restrained palette, consistent spacing, minimal simultaneous colors. Mid-Century Modern aesthetic.
- **Predictable navigation.** Core areas are one tap away. No deep stacks. Capture uses sheets; editing uses full screens.
- **Accessibility-first.** Dynamic Type, Reduce Motion, 44×44pt tap targets, VoiceOver/Switch Control parity.

### Privacy-forward

- On-device processing is the default for all AI features.
- Cloud AI requires explicit, per-feature user opt-in.
- No prompt or response content is persisted to durable storage.
- No account required for the app or for cloud AI (anonymous device sessions only).
- No training on user data.

---

## Terminology

| Term | Definition |
| --- | --- |
| `Item` | Unified model for all captures: tasks, notes, ideas, links, etc. |
| `Collection` | Container for Items. `isStructured = true` → Plan; `isStructured = false` → List |
| `CollectionItem` | Join table for Item ↔ Collection (many-to-many), stores `position` and `parentId` |
| `Tag` | User-defined label, stored as a `@Relationship` on `Item.tags` |
| `Plan` | UI name for a structured Collection (ordered, supports hierarchy) |
| `List` | UI name for an unstructured Collection (flat, ordered by position) |
| `Capture` | The act of creating an Item; also the inbox view showing unlinked Items |

---

## Non-goals

- No automatic task creation without confirmation
- No calendar scheduling or time-based reminders
- No collaboration or sharing
- No cross-platform support (iOS only)
- No multi-device sync at launch
- No complex onboarding

---

## Target Audience

- People experiencing high cognitive load (work, family, planning)
- Those who struggle with productivity tools that require upfront organization
- Particularly beneficial for people with ADHD or executive function challenges
- Comfortable with mobile-first, privacy-respecting tools

---

## Data Model

### Item

| Field | Type | Notes |
| --- | --- | --- |
| `id` | UUID | |
| `content` | String | |
| `type` | enum? | nil, task, note, idea, question, decision, concern, reference, link |
| `metadata` | String | JSON string for extended data |
| `linkedCollectionId` | UUID? | Used by `link` type only |
| `tags` | [Tag] | @Relationship |
| `isStarred` | Bool | |
| `followUpDate` | Date? | |
| `completedAt` | Date? | |
| `createdAt` | Date | |
| `collectionItems` | [CollectionItem] | Inverse relationship |

`ItemType.isUserAssignable` excludes `link` from the capture UI picker. `type = nil` means an untyped capture.

### Collection

| Field | Type | Notes |
| --- | --- | --- |
| `id` | UUID | |
| `name` | String | |
| `isStructured` | Bool | true = Plan, false = List |
| `createdAt` | Date | |
| `collectionItems` | [CollectionItem] | Inverse relationship |

### CollectionItem

| Field | Type | Notes |
| --- | --- | --- |
| `id` | UUID | |
| `collectionId` | UUID | |
| `itemId` | UUID | |
| `position` | Int? | Ordering in list or plan |
| `parentId` | UUID? | Hierarchy (plans only) |

### Tag

| Field | Type | Notes |
| --- | --- | --- |
| `id` | UUID | |
| `name` | String | |
| `color` | String? | |
| `createdAt` | Date | |
| `items` | [Item] | Inverse relationship |

---

## Core Features (Shipped)

### Capture

- Text input with immediate persistence
- Voice recording with on-device transcription (Apple Speech framework, iOS 17+, offline)
- Item type selection (Task, Note, Idea, Question, Decision, Concern, Reference)
- Photo attachments
- Tags, star, follow-up date
- Swipe-to-complete and swipe-to-delete with undo

### Organize

- Plans (structured, hierarchical) and Lists (flat)
- Drag-and-drop reordering within collections
- Plan ↔ List conversion (with warning for hierarchy loss)
- Item linking to collections via CollectionItem

### Search & Filter

- Full-text search on Item.content
- Tag-based filtering with selectable chips
- Type filter bar in Capture view

### Design System

Mid-Century Modern aesthetic with `Theme.*` tokens for all colors, fonts, spacing, and radii. See `CLAUDE.md` for the full design system reference.

---

## AI Features (Planned)

All AI features follow these invariants:

- On-device by default; cloud requires explicit per-feature opt-in
- AI always suggests, never auto-acts; every output requires user review
- No prompt/response content retained on the server
- Non-judgmental tone throughout; no urgency or pressure language
- Respect `accessibilityReduceMotion` in all animated feedback

### Smart Task Breakdown

Decomposes an overwhelming task into subtasks with adjustable granularity (1–5 scale from "just the main steps" to "tiny micro-steps"). Users review and edit subtasks before approving. Approved breakdown creates a structured Collection. Supports saving breakdown templates for recurring task types.

**Cloud endpoint:** `POST /v1/ai/breakdown/generate`

### Brain Dump Compiler

When a capture exceeds ~75 words, offers to extract and categorize distinct items (task, question, decision, idea, concern, reference) from the unstructured text. Suggests Collection groupings. User reviews, edits categories, and approves — then Collections are created. Original capture is preserved.

### Recurring Task Intelligence

Detects natural completion patterns (requires ≥3 completions). Gently surfaces suggestions at learned intervals — never rigid schedules, never "overdue" language. Learns from snooze/dismiss timing to refine future suggestion timing. Users can view, edit, or disable detected patterns in Settings.

**All processing on-device; no cloud requirement.**

### Tone Assistant

Transforms captures into communication-ready messages in different tones (formal, friendly, concise, empathetic, direct, neutral). Supports saving named presets. Multiple simultaneous previews. Copy/share without saving transformation. Does not auto-send; always user-controlled.

### Executive Function Prompts

Conversational scaffolding for users who are stuck. Detects challenge type (initiation, overwhelm, time blindness, decision paralysis) via clarifying questions, then offers concrete micro-strategies. Learns which strategies lead to task completion over time. User-initiated only — never interrupts.

### Decision Fatigue Reducer

Surfaces 2–3 "good enough" recommendations when a user faces competing options. Asks max 1–2 clarifying questions (or zero in "just pick for me" mode). Provides brief rationale for each suggestion. Learns from which recommendations the user accepts or rejects.

---

## Pricing & Limits

**Status: Deferred.** No pricing tiers are finalized. Launch is free-only.

Known direction:

- Free tier: 100 AI actions (one action = one successful call to any `/v1/ai/*` endpoint)
- Hybrid enforcement: local provisional counters (UserDefaults + Keychain mirror) reconciled with server via `POST /v1/usage/reconcile` using `max(local, server)`
- Quota UX: non-judgmental inline message only ("You've used X of 100 AI features this month"); no upgrade nudge at launch
- No billing integration until a paid tier is introduced post-launch

---

## Success Metrics

### Manual-only (current)

- ≥30% Day-30 retention for users who create ≥5 captures
- ≥20% of users create at least one Collection
- App Store rating ≥4.5
- <2% crash rate

### AI-enabled (future)

- ≥25% Day-30 retention for users who complete ≥1 AI organize action
