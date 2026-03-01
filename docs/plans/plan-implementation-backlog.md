---
id: plan-implementation-backlog
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - agents
last_updated: 2026-03-01
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

**Remaining (manual/QA only):**

- [ ] Complete on-device VoiceOver + Switch Control validation (testing checklist in `docs/design/testing/design-advanced-accessibility-testing-checklist.md`)
- [ ] Run refactored tests in CI-capable environment
- [ ] Adjust labels based on QA feedback
- [ ] Complete user verification

### Celebration Animations

Positive feedback animations for three moments: item completed, first capture, and collection fully completed. Uses `CelebrationStyle` enum + `.celebrationOverlay()` ViewModifier with pure SwiftUI particle system. All animations respect reduced motion via `Theme.Animations.motion()`. Collection completion detected from CaptureView via item relationships, shown as success toast. Design: `docs/plans/2026-02-24-celebration-animations-design.md`.

## Active

### Testing & Polish

Final launch testing and polish. Blocks Release Prep. Related issue: #116.

**Manual feature verification:**

- [ ] Run full manual testing checklist (text capture CRUD + undo, attachments, tags/star/follow-up, organize plan + list creation, item move, reorder persistence, mark complete, voice capture, settings, persistence across force-quit and background)
- [ ] Test on at least one iPhone + one iPad, physical device for voice capture
- [ ] Record results with device, OS, build, tester, pass/fail

**UX fixes:**

- [ ] Swipe-to-complete on collections needs a confirmation step and a visible affordance icon (current indicator overlaps with the card and is not visible; should match the trash icon pattern used by swipe-to-delete)
- [ ] +tag icon on collection items is oversized; should match the +tag icon size used on capture items
- [ ] Collection cards are too large; reduce content density — remove date display and limit visible tags (e.g., show max 2-3 with "+N more" overflow). When cards are oversized the decorative circle's bottom cutoff becomes visible, breaking the visual effect
- [ ] Collection list view scroll is broken — unable to scroll the list on the collection screen

**Performance & reliability:**

- [ ] Baseline launch/navigation timing on physical devices (current baseline: 112.8s full suite, iPhone 16 Pro, iOS 18.3.1)
- [ ] Run pagination under large data sets and measure breakdown latency
- [ ] Backend breakdown p95 latency under load

**Accessibility review:**

- [ ] VoiceOver on core views, contrast/tap targets/focus order
- [ ] Tab shell + floating CTA traversal end-to-end
- [ ] Dynamic Type at accessibility sizes for tab shell + CTA quick actions

**Non-functional launch gates (all must pass before Release Prep):**

- [ ] Define and record thresholds: backend p95 latency, iOS startup budget, iOS idle-memory budget, TestFlight crash-free rate
- [ ] Triage and fix issues from testing phases, retest affected flows

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

### Home Dashboard

The Home tab is currently empty (placeholder view). Needs to become a user dashboard with at-a-glance context: recent captures, active collections, progress summary. The Visual Timeline (below) could be a natural component here. Scope and layout TBD — requires brainstorming and design.

### Visual Timeline

Visual timeline component for ADHD-focused progress tracking. Related issue: #118.

**Constraints:** Must fit within existing tab shell or shallow sheets (no deep navigation stacks). Calm visual system, no urgency language, non-blocking with snooze/dismiss. Accessibility-first: Dynamic Type, Reduce Motion, 44x44pt tap targets. Must use Theme tokens exclusively.

**Open decisions:** Target views for placement TBD. Timeline states and transitions TBD. Design assets needed before build.

**Remaining:**

- [ ] Define placement and states
- [ ] Build timeline components with Theme tokens
- [ ] Validate accessibility

### Tag Relationship Refactor

Migrate tag storage from denormalized string arrays to proper SwiftData relationships.

**Current model:** `Item.tags: [String]` stores tag names directly. `Tag` model exists with `name` and `color` but has no relationship to `Item`. Tag lookup recomputes a `[String: Tag]` dictionary every view update. `fetchByTag` fetches ALL items into memory and filters client-side.

**Target model:** `Item.tags: [Tag]?` with `@Relationship(deleteRule: .nullify, inverse: \Tag.items)`. `Tag.items: [Item]?` inverse. `Tag.name` marked `@Attribute(.unique)`. `tagNames: [String]` computed property for backward compatibility. Queries use `#Predicate<Item>` for database-layer filtering.

**Migration:** Versioned schemas `OffloadSchemaV1` → `OffloadSchemaV2` via `SchemaMigrationPlan`. `willMigrate` hook collects unique tag strings, creates `Tag` objects, re-links items. `TagRepository` gets `findOrCreate(name:color:)`. Migrated tags will have `color: nil` unless matched to pre-existing `Tag` objects by name.

**Risks:** Migration failures could cause data loss (staged tests + backups required). All views referencing `item.tags` as `[String]` will break. `tagLookup` dictionary pattern must be removed entirely.

**Remaining:**

- [ ] Confirm scope approval
- [ ] Identify all impacted views (CaptureComposeView, CaptureView, CollectionDetailView, tag pickers)
- [ ] Implement versioned schema migration with tests
- [ ] Update repositories and views
- [ ] Validate migration on real data

### New Item Types

Expand the `ItemType` enum beyond the current `task` and `link` cases to support a richer capture vocabulary. The Brain Dump Compiler AI flow already references six categories (`task`, `question`, `decision`, `idea`, `concern`, `reference`) — formalizing these as first-class types lets the capture UI, filters, and AI features share a single source of truth.

**Current state:** `ItemType` has two cases: `task` and `link`. `Item.type` stores the raw string, defaulting to `nil` for uncategorized captures.

**Proposed new types:**

| Type | Purpose |
| --- | --- |
| `note` | General free-form capture with no action required |
| `idea` | Creative or exploratory thought to revisit |
| `question` | Open question needing an answer or research |
| `decision` | A choice that needs to be made or was made |
| `concern` | Something worrying or at risk, flagged for attention |
| `reference` | External material (URL, quote, source) saved for later |

**Model changes:** Add new cases to `ItemType` in `Domain/Models/Item.swift`. No SwiftData migration required — `type` is stored as a raw `String?` and existing values remain valid. Remove or repurpose the existing `link` case: consider whether `link` becomes a metadata property on `reference` items rather than a standalone type (decision required before implementing).

**UI changes:**

- Update type picker in `CaptureComposeView` to show all types with icons and short descriptions
- Add type-specific icons to `Icons.swift` for each new type
- Display type chip on capture cards (`CaptureItemCard`) using `TypeChip` component
- Filter bar in `CaptureView` — filter by type alongside existing starred/follow-up filters

**Capture flow:**

- Voice capture: map AI-inferred category to new type enum cases
- Brain Dump Compiler: align category labels with `ItemType.rawValue` to eliminate translation layer

**Search & organize:**

- `ItemRepository.fetchByType` predicate (requires explicit enum raw value — see SwiftData predicate gotcha in CLAUDE.md)
- Type-aware grouping option in Organize tab

**Remaining:**

- [ ] Decide fate of `link`/`linkedCollectionId` — keep as distinct type or absorb into `reference` with metadata URL field
- [ ] Add new `ItemType` cases with `displayName` and `icon`
- [ ] Add SF Symbol constants to `Icons.swift` for each new type
- [ ] Update `CaptureComposeView` type picker
- [ ] Update `CaptureItemCard` to display type chip
- [ ] Add type filter to `CaptureView`
- [ ] Add `fetchByType` to `ItemRepository`
- [ ] Align Brain Dump Compiler category labels with `ItemType.rawValue`
- [ ] Update tests (`ItemRepositoryTests`, `CaptureViewTests` if applicable)

### AI Organization Flows

Six AI-assisted features for neurodivergent users. All depend on backend API/privacy infrastructure.

**Features:**

- **Smart Task Breakdown:** Decomposes tasks into subtasks with adjustable granularity (1-5 slider). Saves reusable templates. Cloud endpoint: `POST /v1/ai/breakdown/generate`.
- **Brain Dump Compiler:** Extracts/categorizes items (task, question, decision, idea, concern, reference) from long captures (>75 words triggers suggestion). Creates Collections from approved compilations.
- **Recurring Task Intelligence:** Detects natural completion patterns (min 3 completions), surfaces gentle suggestions. No rigid schedules, no "overdue" language. Learns from snooze/dismiss timing.
- **Tone Assistant:** Transforms captures into toned messages (formal, friendly, concise, empathetic, direct, neutral). Saves presets, multiple simultaneous previews.
- **Executive Function Prompts:** Conversational scaffolding when stuck. Detects challenge type (initiation, overwhelm, time blindness, decision paralysis). Learns which strategies work per user.
- **Decision Fatigue Reducer:** Surfaces max 2-3 "good enough" recommendations. Max 1-2 clarifying questions. "Just pick for me" mode.

**Backend/privacy constraints:** On-device processing is default; cloud requires explicit per-feature opt-in. Zero content retention (no durable storage of prompts/responses). Anonymous device session tokens only (`POST /v1/sessions/anonymous`). Python + FastAPI backend, single provider (OpenAI) behind adapter interface. Cloud endpoint fails closed if opt-in absent. Logs: request ID, route, status, latency only.

**ADHD design rules:** AI always suggests, never auto-acts. No judgmental language ("overdue," "late," "easy," "simple," "you should"). Tone is collaborative. All features optional and dismissible. Concerns acknowledged as valid. Animations respect `accessibilityReduceMotion`.

**Open decisions:** On-device model selection (Core ML, model size/latency budgets). Minimum completion count for pattern detection. Whether learning is implicit or explicit to user.

**Remaining:**

- [ ] Confirm backend API/privacy infrastructure readiness
- [ ] Define on-device model constraints per device class
- [ ] Implement features incrementally (breakdown first, then others)
- [ ] Validate UX with manual testing

### AI Pricing & Limits

Free/paid tier boundaries, quota enforcement, billing integration. No tiers or limits defined yet — this is a placeholder awaiting decisions.

**Decided:** Hybrid enforcement model — local provisional counters (UserDefaults) + Keychain mirror for tamper resistance, reconciled with server on reconnect via `POST /v1/usage/reconcile` at `max(local, server)`. Server-only enforcement rejected (poor offline UX). UX tone: non-judgmental, shame-free, no pressure language.

**Research findings:** UserDefaults counters lightweight but not tamper-proof. Keychain provides moderate resistance. DeviceCheck requires network, viable as defense-in-depth. Core ML suitable for smaller models; large LLMs need optimization or cloud fallback. Hybrid on-device-first + optional cloud recommended.

**Open decisions:** Free tier AI action counts and paid tier soft caps. Definition of one "AI action." Cloud vs on-device quota reconciliation edge cases. Billing integration approach.

**Remaining:**

- [ ] Define pricing tiers and action counts
- [ ] Implement local quota enforcement (UserDefaults + Keychain)
- [ ] Build server reconciliation endpoint
- [ ] Integrate billing
