---
id: plan-implementation-backlog
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - agents
last_updated: 2026-03-03
related: []
depends_on: []
supersedes:
  - plan-advanced-accessibility
  - plan-tag-relationship-refactor
  - plan-ai-organization-flows
  - plan-ai-pricing-limits
  - plan-celebration-animations
  - plan-visual-timeline
  - plan-release-prep
  - plan-testing-polish
accepted_by: Will-Conklin
accepted_at: 2026-02-23
related_issues: []
---

# Implementation Backlog

## Completed

### Advanced Accessibility

Action parity and Dynamic Type hardening for VoiceOver/Switch Control users. Code implementation complete: `AdvancedAccessibilityActionPolicy`, `AdvancedAccessibilityLayoutPolicy`, `accessibilityActionIf()` extension, wired into `CaptureItemCard`, `CollectionDetailItemRows`, `OrganizeCollectionCards`. Unit tests passing.

On-device VoiceOver + Switch Control validation and user sign-off are tracked in `docs/plans/plan-uat-checklist.md`.

### Celebration Animations

Positive feedback animations for three moments: item completed, first capture, and collection fully completed. Uses `CelebrationStyle` enum + `.celebrationOverlay()` ViewModifier with pure SwiftUI particle system. All animations respect reduced motion via `Theme.Animations.motion()`. Collection completion detected from CaptureView via item relationships, shown as success toast. Design: `docs/plans/2026-02-24-celebration-animations-design.md`.

## Active

### Testing & Polish

Final launch testing and polish. Blocks Release Prep. Related issue: #116.

**UX fixes:** All resolved in PRs #232–#233.

- Collection scroll bug fixed (gesture direction guard added to ItemRow and DraggableCollectionCard)
- +tag icon sizing corrected to match MCMCardContent (8pt, 4/8pt spacing)
- Card density reduced: date removed, tags capped at 3 with muted "+N" overflow pill
- Swipe-to-convert affordance made visible (leading `SwipeAffordance` with `Icons.convert`; delete already had confirmation)

**Performance & reliability:** Baselines established; automated tests in place.

- Launch/navigation baseline: 112.8s full suite, iPhone 16 Pro, iOS 18.3.1
- Pagination benchmarks added (first-page and deep-page at 100/1000/10000 items, PR #228)
- Backend p95 latency load test added (~72ms p95 observed, <100ms threshold, PR #228)

Manual verification, accessibility review, and non-functional launch gates are tracked in `docs/plans/plan-uat-checklist.md`.

## Ready to Start

### Release Prep

App Store preparation, TestFlight distribution, security release gate. Blocked by Testing & Polish. Related issue: #113. Requires Apple Developer Program membership + App Store Connect access.

**Docs & release notes:**

- [ ] Update README for shipped features
- [ ] Draft release notes (capture, organize, collections, tags, search, drag-drop ordering)

**App Store metadata:**

- [ ] App name, subtitle, description, keywords, category
- [ ] Screenshots: iPhone 6.7"/6.1" and iPad
- [ ] 1024x1024 app icon
- [ ] Age rating, privacy policy URL, support URL
- [ ] Verify bundle ID (`wc.Offload`) and version number

**TestFlight:**

- [ ] Release build archive, upload to App Store Connect
- [ ] Configure internal testing group, minimum 1-week feedback window
- [ ] Triage feedback and file blocker issues

**Security release gate (requires explicit sign-off):**

- [ ] Production secret policy validated in deployed environment
- [ ] Session rate limiting enabled and monitored
- [ ] Privacy policy matches backend behavior (no durable prompt/response persistence)
- [ ] Incident response + rollback runbook current

## Future Work

> **Session pickup guide:** Items below are labeled **[Ready]**, **[Needs Decision]**, or **[Needs Design]**.
> **[Ready]** items have enough context for a session to start immediately.
> **[Needs Decision]** items are blocked on a human choice; look for tasks marked `⚠️ Human gate` and stop there.
> **[Needs Design]** items require design or scoping work before implementation tasks can be written.

### Tag Relationship Refactor [Ready]

Migrate tag storage from denormalized string arrays to proper SwiftData relationships.

**Current model:** `Item.tags: [String]` stores tag names directly. `Tag` model exists with `name` and `color` but has no relationship to `Item`. Tag lookup recomputes a `[String: Tag]` dictionary every view update. `fetchByTag` fetches ALL items into memory and filters client-side.

**Target model:** `Item.tags: [Tag]?` with `@Relationship(deleteRule: .nullify, inverse: \Tag.items)`. `Tag.items: [Item]?` inverse. `Tag.name` marked `@Attribute(.unique)`. `tagNames: [String]` computed property for backward compatibility. Queries use `#Predicate<Item>` for database-layer filtering.

**Remaining:**

- [ ] ⚠️ Human gate: Confirm scope approval before starting
- [ ] Identify all impacted views (CaptureComposeView, CaptureView, CollectionDetailView, tag pickers)
- [ ] Update model and repositories in place
- [ ] Update all views referencing `item.tags` as `[String]`; remove `tagLookup` dictionary pattern

### New Item Types [Ready]

Expand the `ItemType` enum beyond the current `task` and `link` cases to support a richer capture vocabulary. The Brain Dump Compiler AI flow already references six categories (`task`, `question`, `decision`, `idea`, `concern`, `reference`) — formalizing these as first-class types lets the capture UI, filters, and AI features share a single source of truth.

**Implemented:** Six new `ItemType` cases added (`note`, `idea`, `question`, `decision`, `concern`, `reference`) with `displayName`, `icon`, and `isUserAssignable` properties. SF Symbol constants added to `Icons.swift`. Type picker chip row added to `CaptureComposeView`. `CaptureItemCard` updated to use `displayName`. `fetchCaptureItems` predicate updated to include typed captures (excludes `linkedCollectionId != nil`). `fetchCaptureItemsByType(_:limit:offset:)` added to `ItemRepository`. Type filter chip bar added to `CaptureView` via `CaptureListViewModel.setTypeFilter(_:using:)`. `ItemRepositoryTests` updated with new type cases and two new tests for `fetchCaptureItemsByType`.

**Decided:** `link` is kept as-is (Collection-pointer type using `linkedCollectionId`). `reference` is a new independent type for external URLs saved in item metadata. `isUserAssignable` property on `ItemType` excludes `link` from the capture UI picker and filter bar.

**Remaining:**

- [ ] Voice capture: map AI-inferred category to new `ItemType` enum cases (see `VoiceCaptureViewModel`; AI returns a string category, needs mapping to `ItemType.rawValue`)
- [ ] Align Brain Dump Compiler category labels with `ItemType.rawValue` (no translation layer needed now)
- [ ] Type-aware grouping option in Organize tab (future; do not implement until AI Organization Flows are underway)

### AI Organization Flows [Needs Decision]

Six AI-assisted features for neurodivergent users. All depend on backend API/privacy infrastructure being confirmed production-ready. **Do not implement any feature until the human gate below is cleared.**

**Backend/privacy constraints:** On-device processing is default; cloud requires explicit per-feature opt-in. Zero content retention (no durable storage of prompts/responses). Anonymous device session tokens only (`POST /v1/sessions/anonymous`). Python + FastAPI backend, single provider (OpenAI) behind adapter interface. Cloud endpoint fails closed if opt-in absent. Logs: request ID, route, status, latency only.

**ADHD design rules:** AI always suggests, never auto-acts. No judgmental language ("overdue," "late," "easy," "simple," "you should"). Tone is collaborative. All features optional and dismissible. Concerns acknowledged as valid. Animations respect `accessibilityReduceMotion`.

**Open decisions:** On-device model selection (Core ML, model size/latency budgets). Minimum completion count for pattern detection (Recurring Task Intelligence). Whether learning is implicit or explicit to user.

**Remaining — prerequisites:**

- [ ] ⚠️ Human gate: Confirm backend API/privacy infrastructure is production-ready
- [ ] ⚠️ Human gate: Define on-device model constraints per device class (Core ML model ID, max size, acceptable latency)

**Feature 1 — Smart Task Breakdown** (implement first):

Decomposes a task item into subtasks with adjustable granularity. Cloud endpoint: `POST /v1/ai/breakdown/generate`. UI: 1-5 granularity slider, subtask preview list, approve/edit before save. Saves reusable templates per task type.

- [ ] Add `BreakdownService` calling `POST /v1/ai/breakdown/generate` with item text + granularity
- [ ] Build `TaskBreakdownSheet` (granularity slider, subtask list, approve/dismiss)
- [ ] Wire sheet into `CaptureItemCard` context menu and `CaptureComposeView` toolbar
- [ ] Save approved subtasks as new `Item` records linked to parent via collection
- [ ] Add unit tests for `BreakdownService` (mock network, assert subtask count + types)

**Feature 2 — Brain Dump Compiler** (after Feature 1):

Extracts and categorizes items from long captures (>75 words triggers suggestion). Creates Collections from approved compilations. Categories map to `ItemType` cases — no translation layer needed.

- [ ] Add word-count trigger in `CaptureComposeView` (>75 words → show "Compile" suggestion)
- [ ] Add `BrainDumpService` calling backend to extract and categorize items
- [ ] Build `BrainDumpReviewSheet` (categorized item list, type chips, approve/edit/dismiss)
- [ ] On approve: create `Collection` + child `Item` records from result
- [ ] Add unit tests for `BrainDumpService`

**Feature 3 — Recurring Task Intelligence** (after infrastructure proven with Features 1–2):

Detects natural completion patterns (min 3 completions), surfaces gentle suggestions. No rigid schedules, no "overdue" language. Learns from snooze/dismiss timing.

- [ ] ⚠️ Human gate: Confirm minimum completion count and snooze learning behavior before implementation
- [ ] Add pattern detection logic (completion timestamps → interval model)
- [ ] Surface suggestion as dismissible toast or inline card; never modal
- [ ] Record snooze/dismiss events for learning

**Feature 4 — Tone Assistant** (after infrastructure proven):

Transforms captures into toned messages (formal, friendly, concise, empathetic, direct, neutral). Saves presets. Multiple simultaneous previews.

- [ ] Add `ToneService` calling backend with item text + selected tone
- [ ] Build `ToneAssistantSheet` (tone picker chips, multi-preview grid, copy/save/dismiss)
- [ ] Allow saving named presets to `UserDefaults`

**Feature 5 — Executive Function Prompts** (after infrastructure proven):

Conversational scaffolding when a user is stuck. Detects challenge type (initiation, overwhelm, time blindness, decision paralysis). Learns which strategies work per user.

- [ ] ⚠️ Human gate: Define challenge detection heuristics and learning model before implementation
- [ ] Add entry point (e.g., "I'm stuck" button on `CaptureItemCard`)
- [ ] Build `ExecutiveFunctionSheet` (conversational prompt flow, strategy suggestions, feedback collection)

**Feature 6 — Decision Fatigue Reducer** (after infrastructure proven):

Surfaces max 2-3 "good enough" recommendations. Max 1-2 clarifying questions. "Just pick for me" mode.

- [ ] Add `DecisionService` calling backend with item options + context
- [ ] Build `DecisionSheet` (recommendation list, clarifying question flow, "just pick" mode)

### AI Pricing & Limits [Needs Decision]

Free/paid tier boundaries, quota enforcement, billing integration. **Cannot implement until pricing tiers are defined by owner.**

**Decided:** Hybrid enforcement model — local provisional counters (UserDefaults) + Keychain mirror for tamper resistance, reconciled with server on reconnect via `POST /v1/usage/reconcile` at `max(local, server)`. Server-only enforcement rejected (poor offline UX). UX tone: non-judgmental, shame-free, no pressure language.

**Research findings:** UserDefaults counters lightweight but not tamper-proof. Keychain provides moderate resistance. DeviceCheck requires network, viable as defense-in-depth. Core ML suitable for smaller models; large LLMs need optimization or cloud fallback. Hybrid on-device-first + optional cloud recommended.

**Remaining:**

- [ ] ⚠️ Human gate: Define free tier AI action counts, paid tier soft caps, and what constitutes one "AI action"
- [ ] ⚠️ Human gate: Decide billing integration approach (RevenueCat, StoreKit direct, or other)
- [ ] Implement local quota enforcement (`QuotaStore`: UserDefaults counter + Keychain mirror)
- [ ] Build server reconciliation: `POST /v1/usage/reconcile`, `max(local, server)` merge
- [ ] Add quota-exceeded UX (non-judgmental inline message, upgrade nudge if paid tier exists)
- [ ] Integrate billing per chosen approach

### Visual Timeline [Needs Design]

Visual timeline component for ADHD-focused progress tracking. Related issue: #118.

**Constraints:** Must fit within existing tab shell or shallow sheets (no deep navigation stacks). Calm visual system, no urgency language, non-blocking with snooze/dismiss. Accessibility-first: Dynamic Type, Reduce Motion, 44x44pt tap targets. Must use Theme tokens exclusively.

**Blocked on design:** Target view placement, timeline states, and visual design assets must be defined before implementation tasks can be written. The planning task below must be completed first.

**Remaining:**

- [ ] ⚠️ Human gate: Define target placement (Home tab, Organize tab, or sheet), timeline states (empty, active, completed), and provide or approve visual design before implementation begins
- [ ] Build timeline component(s) with Theme tokens per approved design
- [ ] Validate accessibility (Dynamic Type, Reduce Motion, 44pt targets)

### Home Dashboard [Needs Design]

The Home tab is currently empty (placeholder view). Needs to become a user dashboard with at-a-glance context: recent captures, active collections, progress summary. The Visual Timeline could be a natural component here.

**Blocked on design:** No scope, layout, or data requirements defined. Cannot implement until design is complete.

**Remaining:**

- [ ] ⚠️ Human gate: Define Home tab scope — which data surfaces (recent captures, collection progress, timeline), layout (grid, list, cards), and interaction model. Produce wireframe or written spec before implementation begins
- [ ] Implement Home tab layout per approved design using existing `CardSurface`/`MCMCardContent` components
- [ ] Add data queries to `ItemRepository`/`CollectionRepository` as needed for dashboard data
- [ ] Validate accessibility and performance (pagination if lists are unbounded)
