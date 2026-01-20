---
id: prd-0001-product-requirements
type: product-requirements
status: active
owners:
  - will-conklin
applies_to:
  - product
last_updated: 2026-01-19
related:
  - adr-0001-technology-stack-and-architecture
  - adr-0002-terminology-alignment-for-capture-and-organization
  - adr-0003-adhd-focused-ux-ui-guardrails
  - plan-v1-roadmap
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals (V1); 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (30-day post-launch); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model (V1); 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
  - "Keep the top-level section outline intact."
---

# Offload — V1 Product Requirements Document (PRD)

**Version:** 1.3
**Date:** 2026-01-19
**Status:** Active
**Owner:** Will Conklin

**Related ADRs:**

- [adr-0001: Technology Stack](../adrs/adr-0001-technology-stack-and-architecture.md)
- [adr-0002: Terminology Alignment](../adrs/adr-0002-terminology-alignment-for-capture-and-organization.md)
- [adr-0003: ADHD UX Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)

---

## 1. Product overview

**Offload** is an iOS app that reduces mental overload by allowing users to quickly capture entries (thoughts, tasks, ideas) and optionally organize them with AI. The app prioritizes **externalizing first**, **organizing later**, and **never forcing structure**.

---

## 2. Problem statement

Users experience stress when ideas, tasks, or plans accumulate faster than they can organize them. Existing tools require upfront categorization, which increases avoidance.

**Core user pain:**
> “I need this out of my head now, but organizing it feels like too much.”

---

## 3. Product goals (V1)

- Enable instant thought capture with minimal friction
- Provide optional, trustworthy AI-assisted organization
- Reduce cognitive load without introducing pressure or guilt
- Validate willingness to pay for AI-assisted relief

---

## 4. Non-goals (explicit)

- No automatic task creation without confirmation
- No calendar scheduling or reminders
- No collaboration or sharing
- No cross-platform support (iOS only; iPhone and iPad)
- No multi-device sync in v1
- No complex onboarding flows

---

## 5. Target audience

- People experiencing high cognitive load (work, family, planning)
- Those who struggle with traditional productivity tools that require upfront organization
- Comfortable with mobile-first tools
- Sensitive to stress-inducing UX patterns
- Particularly beneficial for people with ADHD or similar executive function challenges

---

## 6. Success metrics (30-day post-launch)

### V1 (Manual-only)

- ≥30% Day-30 retention for users who create ≥5 captures
- ≥20% of users create at least one Plan
- App Store rating ≥4.5
- <2% crash-free session rate

### Post-v1 (AI-enabled)

- ≥25% Day-30 retention for users who complete ≥1 AI organize action
- ≥40% of free users hit monthly AI limit
- 8–12% conversion from free → paid after limit hit

---

## 7. Core user flows

### 7.1 Primary flow (Capture → Organize Later)

1. User creates an **Item** (text or voice)
2. Item is immediately saved as an uncategorized capture (`type = nil`)
3. Item appears in the Capture inbox
4. User optionally organizes it into a **Collection** (Plan or List), adds tags,
   or marks it as a task

### 7.2 Fallback flow

- If the user does not organize immediately:
  - Item remains in the Capture inbox
  - User sees: "Saved. Organize later."

---

## 8. Functional requirements

### 8.1 Capture (Item)

- Text input (single field)
- Voice recording
  - One-tap record/stop
  - On-device transcription (Apple Speech framework)
  - Supported languages only; no fallback for unsupported languages
- Works offline
- Immediate persistence

### Stored data (Item)

- id (UUID)
- content (String)
- type (enum: nil, task, link)
- metadata (String, JSON)
- linkedCollectionId (UUID?)
- tags ([String])
- isStarred (Bool)
- followUpDate (Date?)
- completedAt (Date?)
- createdAt (Date)

---

### 8.2 Capture List View

- Chronological list of uncategorized Items (`type = nil`)
- Visual distinction by completion/star status
- Actions:
  - Mark complete
  - Star
  - Delete

Capture items are never auto-cleared; user controls retention.

---

### 8.3 AI organization (Post-v1)

Triggered only by user action.

AI analyzes Items and returns suggested organization such as:

- **Plan** (structured Collection) with task Items
- **List** (unstructured Collection) with Item entries
- **Task** (standalone Item)

#### AI output requirements

- Strict structured JSON
- Confidence score per suggestion
- Optional clarification questions
- Never invent items beyond user intent
- Each AI run is tracked for audit and debugging

---

### 8.4 Review screen (Post-v1)

User must be able to:

- Edit suggested titles
- Edit item text
- Remove individual suggestions
- Change destination (Plan, List, etc.)
- Cancel without losing original Item

**No changes are applied without explicit user decision.**

---

### 8.5 Plans & Lists

**Plan** (structured Collection)

- `isStructured = true`
- Ordered items with optional hierarchy
- No due dates required in V1

**List** (unstructured Collection)

- `isStructured = false`
- Items listed by creation time

#### Items

- Tasks are Items with `type = "task"`
- Links are Items with `type = "link"` pointing to a Collection

No reminders in V1.

---

## 9. Pricing & limits (hybrid model)

### Free tier

- 30 AI organization actions per month
- Unlimited capture
- Unlimited manual lists

### Paid tier (single SKU)

- Unlimited AI (soft caps enforced)
- Faster processing
- Early feature access

### Enforcement

- Limits enforced server-side
- Graceful fallback messaging
- No dark patterns

---

## 10. AI & backend requirements

> **Note:** This section applies to post-v1 releases. V1 is manual-only with no backend dependency.

### Architecture (Post-v1)

iOS App → Backend API → LLM Provider

### Backend responsibilities

- User/session identification
- Quota enforcement
- LLM request/response handling
- JSON schema validation
- Minimal logging

### Privacy constraints

- No API keys on device
- No training on user data
- Minimal retention
- Clear privacy policy

---

## 11. Data model (V1)

> See [adr-0001](../adrs/adr-0001-technology-stack-and-architecture.md) for implementation details and [adr-0002](../adrs/adr-0002-terminology-alignment-for-capture-and-organization.md) for terminology.

### Core Models

Plans and Lists are implemented as Collections: `isStructured = true` for plans,
`isStructured = false` for lists.

#### Item

- id (UUID)
- content (String)
- type (enum: nil, task, link)
- metadata (String, JSON)
- linkedCollectionId (UUID?)
- tags ([String])
- isStarred (Bool)
- followUpDate (Date?)
- completedAt (Date?)
- createdAt (Date)
- **Relationships:**
  - collectionItems (← CollectionItem[])

#### Collection

- id (UUID)
- name (String)
- isStructured (Bool)
- createdAt (Date)
- **Relationships:**
  - collectionItems (← CollectionItem[])

#### CollectionItem

- id (UUID)
- collectionId (UUID)
- itemId (UUID)
- position (Int?)
- parentId (UUID?)
- **Relationships:**
  - collection (→ Collection)
  - item (→ Item)

#### Tag

- id (UUID)
- name (String)
- color (String?)
- createdAt (Date)
- **Notes:**
  - Item tag values are stored on `Item.tags`

---

## 12. UX & tone requirements

> See [adr-0003: ADHD UX Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md) for detailed design constraints.

### Tone

- No shaming or urgency language
- No productivity guilt framing
- Optional light humor (off by default)
- Copy emphasizes control and relief

**Example:**
> "Saved. You don't have to deal with this right now."

### ADHD-Focused Design Principles

#### Capture-first default

- Persistent capture control with immediate-save behavior
- Organizing is optional and secondary

#### Undo over confirmation

- Destructive actions use undo banners/snackbars (not blocking modals)
- Exception: batch destructive actions may use confirmation

#### Calm visual system

- Restrained palette: base + primary accent + secondary accent
- Accessible contrast ratios
- Consistent spacing tokens to reduce visual noise

#### Predictable navigation

- Core areas one tap away via main tab shell
- Capture uses sheets; editing uses full screens
- Swipe actions mirrored with visible buttons

#### Gentle organization prompts

- Non-blocking chips/cards (e.g., "Ready to organize")
- Snooze/dismiss options on all prompts
- No urgency language or forced flows

### Accessibility Requirements

- Dynamic Type support (all text scales)
- Reduce Motion support (disable animations when enabled)
- Minimum 44×44 pt tap targets
- Focus states combine color and stroke weight

---

## 13. Risks & mitigations

| Risk              | Mitigation                   |
| ----------------- | ---------------------------- |
| AI cost spikes    | Hard per-user caps           |
| Misclassification | Review screen + confidence   |
| User distrust     | Raw text preserved           |
| Overbuilding      | Strict V1 scope lock         |

---

## 14. Implementation tracking

> **Note:** Detailed implementation status is tracked in the
> [v1 Roadmap](../plans/plan-v1-roadmap.md), which is the single source of
> truth for progress.

### Current status (Jan 19, 2026)

- ✅ **Core Infrastructure** — SwiftData models, repositories, capture foundation
- ✅ **UI/UX Foundation** — Flat design system (Elijah theme), ADHD-focused UX
- ✅ **Repository Pattern** — Environment injection, all views use repositories
- ⏳ **Testing & Polish** — Manual testing, performance benchmarks
- ⏸️ **AI Integration** — Deferred to post-v1

See [plan-v1-roadmap.md](../plans/plan-v1-roadmap.md) for current status.

---

## 15. Open decisions (tracked)

> **Note:** See [plan-v1-roadmap.md](../plans/plan-v1-roadmap.md) decision log
> for resolution status.

| Decision                   | Status  | Notes                                     |
| -------------------------- | ------- | ----------------------------------------- |
| Final app name             | Decided | "Offload"                                 |
| v1 scope                   | Decided | Manual-only; AI in post-v1                |
| Platform                   | Decided | iOS (iPhone and iPad)                     |
| UI direction               | Decided | Flat design (Elijah theme) - Jan 13, 2026 |
| AI provider/model          | Decided | Deferred to post-v1                       |
| Paid tier soft cap numbers | Decided | Deferred to post-v1                       |
| Sign in with Apple         | Decided | Not required for local-only v1            |

---

## 16. Revision history

| Version | Date       | Changes                                                                              |
| ------- | ---------- | ------------------------------------------------------------------------------------ |
| 1.0     | 2025-12-30 | Initial PRD                                                                          |
| 1.1     | 2026-01-09 | Terminology alignment, ADHD UX guardrails, updated data model                        |
| 1.2     | 2026-01-09 | Clarified v1 scope (manual-only), split success metrics, marked AI as post-v1        |
| 1.3     | 2026-01-19 | Updated platform to iPhone+iPad, resolved open decisions, linked to v1-roadmap       |
