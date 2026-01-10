# Offload — v1.0 Product Requirements Document (PRD)

**Version:** 1.3
**Date:** 2026-01-09
**Status:** Active
**Owner:** Will Conklin

**Related ADRs:**
- [ADR-0001: Technology Stack](../decisions/ADR-0001-stack.md)
- [ADR-0002: Terminology Alignment](../decisions/ADR-0002-terminology.md)
- [ADR-0003: ADHD UX Guardrails](../decisions/ADR-0003-adhd-ux-guardrails.md)

---

## 1. Product overview

**Offload** is an iOS app that reduces mental overload by allowing users to quickly capture entries (thoughts, tasks, ideas) and optionally organize them with AI. The app prioritizes **externalizing first**, **organizing later**, and **never forcing structure**.

---

## 2. Problem statement

Users experience stress when ideas, tasks, or plans accumulate faster than they can organize them. Existing tools require upfront categorization, which increases avoidance.

**Core user pain:**
> “I need this out of my head now, but organizing it feels like too much.”

---

## 3. Product goals (v1.0)

- Enable instant thought capture with minimal friction
- Provide optional, trustworthy AI-assisted organization
- Reduce cognitive load without introducing pressure or guilt
- Validate willingness to pay for AI-assisted relief

---

## 4. Non-goals (explicit)

- No automatic task creation without confirmation
- No calendar scheduling or reminders
- No collaboration or sharing
- No cross-platform support (iPhone only; no iPad in v1.0)
- No multi-device sync in v1.0
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

### V1.0 (On-device AI)
- ≥30% Day-30 retention for users who create ≥5 captures
- ≥50% of users use AI organize at least once
- ≥20% of users create at least one Plan
- App Store rating ≥4.5
- <2% crash rate

### Post-v1.0 (Cloud AI upgrade)
- ≥40% of users hit on-device AI limitations (drives cloud upgrade)
- 8–12% conversion from free → paid for cloud AI features

### Measurement approach

**V1.0 (Local-only):**
- App Store rating: App Store Connect
- Crash rate: Xcode Organizer / App Store Connect
- Retention & usage: *Deferred* — v1.0 ships without analytics to minimize complexity

**Post-v1.0:**
- Add privacy-respecting analytics (e.g., TelemetryDeck, Aptabase)
- No PII collection; aggregate metrics only
- Opt-out available in Settings
- Required for measuring retention, feature adoption, and conversion

> **Note:** V1.0 success evaluated qualitatively (App Store reviews, TestFlight feedback) until analytics are implemented.

---

## 7. Core user flows

### 7.1 Primary flow (Capture → Hand-off → Decision → Placement)

1. User creates a **CaptureEntry** (text or voice)
2. Entry is immediately saved with `pending` status
3. User optionally initiates **Hand-off** (AI organization request)
4. AI returns **Suggestions** with confidence scores
5. User reviews suggestions and makes **Decisions** (accept/reject/edit)
6. Accepted items create **Placements** in Plans or Lists

### 7.2 Fallback flow

- If AI unavailable or limit reached:
  - CaptureEntry remains in pending state
  - User sees: "Saved. Organize later."

---

## 8. Functional requirements

### 8.1 Capture (CaptureEntry)

- Text input (single field)
- Voice recording
  - One-tap record/stop
  - On-device transcription (Apple Speech framework)
  - Supported languages only; no fallback for unsupported languages
- Works offline
- Immediate persistence

**Stored data (CaptureEntry)**

- id (UUID)
- rawText (immutable)
- createdAt (timestamp)
- source (text / voice)
- status (pending / processing / completed / failed)

---

### 8.2 Capture List View

- Chronological list of all CaptureEntries
- Visual distinction by status:
  - Pending (not yet organized)
  - Processing (hand-off in progress)
  - Completed (suggestions accepted)
- Actions:
  - Hand-off (request AI organization)
  - Delete
  - Re-process

Captures are never auto-cleared; user controls retention.

---

### 8.3 AI organization (Hand-off)

Triggered only by user action (creates HandOffRequest).

#### V1.0: On-Device AI (Apple Natural Language Framework)

Uses Apple's on-device ML for instant, offline-capable organization:

**Capabilities:**
- **Intent detection** — Identifies if capture is a task, list, note, or multi-step plan
- **Entity extraction** — Pulls out items, quantities, names, dates from text
- **Categorization** — Suggests appropriate destination (Plan, List, Task)
- **Keyword tagging** — Auto-suggests tags based on content

**Limitations (drives cloud upgrade):**
- No complex reasoning or multi-step decomposition
- Limited context awareness (single capture only)
- No clarification questions
- English-primary (other languages best-effort)

#### Post-v1.0: Cloud AI Enhancement

Cloud LLM for advanced organization:
- Multi-step project decomposition
- Cross-capture context awareness
- Clarification questions
- Higher accuracy for complex inputs

**AI output (Suggestion)**

- Confidence score per suggestion
- Never invent items beyond user intent
- Each HandOffRun tracks the AI attempt and response

---

### 8.4 Review screen (SuggestionDecision)

User must be able to:

- Edit suggested titles
- Edit item text
- Remove individual suggestions
- Change destination (Plan, List, etc.)
- Cancel without losing original CaptureEntry

**No Placement is created without explicit user decision.**

Each user action creates a SuggestionDecision record (accepted/rejected/edited).

---

### 8.5 Plans & Lists

**Plan** (lightweight project)
- Contains Tasks
- Supports parent/child hierarchy
- No due dates required in v1.0

**ListEntity** (general-purpose lists)
- Contains ListItems
- Types: shopping, packing, reference, etc.

**CommunicationItem** (calls, emails, messages) — *Post-v1.0*
- Standalone items for follow-up actions
- Future: iOS integration (Contacts, Mail, Messages)

No reminders in v1.0.

---

## 9. Pricing & limits

### V1.0: Free (On-Device AI)

- Unlimited on-device AI organization
- Unlimited capture
- Unlimited Plans and Lists
- No account required

### Post-v1.0: Freemium (Cloud AI)

**Free tier:**
- On-device AI (unlimited)
- 30 cloud AI actions per month
- All v1.0 features

**Paid tier (single SKU):**
- Unlimited cloud AI
- Advanced organization features
- Priority processing

### Enforcement

- On-device: No limits (v1.0)
- Cloud: Limits enforced server-side (post-v1.0)
- No dark patterns

---

## 10. AI & backend requirements

### V1.0: On-Device AI

**Architecture:**
```
iOS App → Apple Natural Language Framework (on-device)
```

**Framework:** Apple Natural Language + Create ML (if custom model needed)

**Capabilities used:**
- `NLTagger` — Part-of-speech, named entity recognition
- `NLEmbedding` — Semantic similarity for categorization
- `NLLanguageRecognizer` — Language detection

**Benefits:**
- No backend dependency
- Works offline
- No API costs
- Data never leaves device
- Instant responses (<100ms)

**Privacy:**
- All processing on-device
- No network calls for AI
- No data collection

### Post-v1.0: Cloud AI (Optional Upgrade)

**Architecture:**
```
iOS App → Backend API → LLM Provider (Claude/GPT)
```

**Backend responsibilities:**
- User/session identification
- Quota enforcement
- LLM request/response handling
- JSON schema validation
- Minimal logging

**Privacy constraints:**
- No API keys on device
- No training on user data
- Minimal retention
- Clear privacy policy

---

## 11. Data model (v1.0)

> See [ADR-0001](../decisions/ADR-0001-stack.md) for implementation details and [ADR-0002](../decisions/ADR-0002-terminology.md) for terminology.

### Capture Workflow Models

#### CaptureEntry
- id (UUID)
- createdAt (Date)
- rawText (String, immutable)
- source (enum: text, voice)
- status (enum: pending, processing, completed, failed)
- **Relationships:**
  - handOffRequests (→ HandOffRequest[])

#### HandOffRequest
- id (UUID)
- createdAt (Date)
- **Relationships:**
  - captureEntry (→ CaptureEntry)
  - runs (→ HandOffRun[])

#### HandOffRun
- id (UUID)
- createdAt (Date)
- status (enum: pending, running, completed, failed)
- **Relationships:**
  - request (→ HandOffRequest)
  - suggestions (→ Suggestion[])

#### Suggestion
- id (UUID)
- title (String)
- confidence (Double)
- destinationType (enum: task, plan, list, communication)
- **Relationships:**
  - run (→ HandOffRun)
  - decision (→ SuggestionDecision?)

#### SuggestionDecision
- id (UUID)
- decision (enum: accepted, rejected, edited)
- createdAt (Date)
- **Relationships:**
  - suggestion (→ Suggestion)
  - placement (→ Placement?)

#### Placement
- id (UUID)
- createdAt (Date)
- **Relationships:**
  - decision (→ SuggestionDecision)
  - destination (→ Task | Plan | ListItem | CommunicationItem)

### Destination Models

#### Plan
- id (UUID)
- name (String)
- notes, color, icon (String?)
- createdAt, updatedAt, archivedAt (Date)
- **Relationships:**
  - tasks (← Task[])
  - parentPlan (→ Plan?)

#### Task
- id (UUID)
- title (String)
- notes (String?)
- createdAt, updatedAt, completedAt, dueDate (Date)
- priority (enum: low, medium, high, urgent)
- status (enum: pending, next, waiting, someday, completed, archived)
- **Relationships:**
  - plan (→ Plan?)
  - category (→ Category?)
  - tags (↔ Tag[])

#### Category
- id (UUID)
- name, icon (String)
- createdAt (Date)
- **Relationships:**
  - tasks (← Task[])

#### Tag
- id (UUID)
- name, color (String)
- createdAt (Date)
- **Relationships:**
  - tasks (↔ Task[])

#### ListEntity
- id (UUID)
- name (String)
- listType (enum: shopping, packing, reference, custom)
- createdAt (Date)
- **Relationships:**
  - items (← ListItem[])

#### ListItem
- id (UUID)
- text (String)
- isCompleted (Bool)
- createdAt (Date)
- **Relationships:**
  - list (→ ListEntity)

#### CommunicationItem
- id (UUID)
- title (String)
- contactName (String?)
- communicationType (enum: call, email, message)
- createdAt, completedAt (Date)

---

## 12. UX & tone requirements

> See [ADR-0003: ADHD UX Guardrails](../decisions/ADR-0003-adhd-ux-guardrails.md) for detailed design constraints.

### Tone
- No shaming or urgency language
- No productivity guilt framing
- Optional light humor (off by default)
- Copy emphasizes control and relief

**Example:**
> "Saved. You don't have to deal with this right now."

### ADHD-Focused Design Principles

**Capture-first default**
- Persistent capture control with immediate-save behavior
- Organizing is optional and secondary

**Undo over confirmation**
- Destructive actions use undo banners/snackbars (not blocking modals)
- Exception: batch destructive actions may use confirmation

**Calm visual system**
- Restrained palette: base + primary accent + secondary accent
- Accessible contrast ratios
- Consistent spacing tokens to reduce visual noise

**Predictable navigation**
- Core areas one tap away via main tab shell
- Capture uses sheets; editing uses full screens
- Swipe actions mirrored with visible buttons

**Gentle organization prompts**
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

| Risk | Mitigation |
|---|---|
| AI cost spikes | Hard per-user caps |
| Misclassification | Review screen + confidence |
| User distrust | Raw text preserved |
| Overbuilding | Strict v1.0 scope lock |

---

## 14. Implementation tracking

> **Note:** Detailed implementation status is tracked in the [Master Plan](../plans/master-plan.md), which is the single source of truth for progress.

### High-level phases

1. **Core Infrastructure** — SwiftData models, repositories, capture foundation
2. **Critical Remediation** — Bug fixes, error handling, architecture improvements
3. **UI/UX Modernization** — Design system, component library, ADHD enhancements
4. **AI Integration** — Hand-off flow, backend proxy, usage limits
5. **Release** — TestFlight beta, App Store submission

See [master-plan.md](../plans/master-plan.md) for current status and detailed task breakdown.

---

## 15. Open decisions (tracked)

> **Note:** See [master-plan.md](../plans/master-plan.md) decision log for resolution status.

| Decision | Status | Notes |
|----------|--------|-------|
| Final app name | Decided | "Offload" |
| v1.0 scope | Decided | On-device AI; cloud AI in post-v1.0 |
| v1.0 AI approach | Decided | Apple Natural Language Framework (on-device) |
| Platform | Decided | iPhone only; no iPad in v1.0 |
| Cloud AI provider | Open | Evaluate Claude/GPT in post-v1.0 phase |
| Paid tier pricing | Open | Determine based on cloud AI costs (post-v1.0) |
| Sign in with Apple | Deferred | Not required for on-device v1.0 |
| Glassmorphism implementation level | Open | Due Jan 15, 2026 |

---

## 16. Revision history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-30 | Initial PRD |
| 1.1 | 2026-01-09 | Terminology alignment (ADR-0002), ADHD UX guardrails (ADR-0003), updated data model, linked to master-plan |
| 1.2 | 2026-01-09 | Clarified v1.0 scope (manual-only, iPhone-only), split success metrics, marked AI/backend as post-v1.0, added Speech framework details |
| 1.3 | 2026-01-09 | **Scope change:** v1.0 now includes on-device AI via Apple Natural Language Framework. Updated §6 metrics, §8.3 AI capabilities, §9 pricing, §10 architecture |
