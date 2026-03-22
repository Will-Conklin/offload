# Backlog

Known bugs, features, and enhancements that do not yet have a plan doc. Items are removed when a plan doc is created in `docs/plans/`.

---

## New Item Types — Remaining Tasks

`ItemType` enum expanded and shipped. Two deferred items remain:

- Voice capture type mapping: `VoiceCaptureViewModel` does not exist yet; implement after voice capture feature is built
- Type-aware grouping option in Organize tab: defer until AI Organization Flows are underway (Brain Dump Compiler categories align with `ItemType.rawValue` — no translation layer needed)

---

## AI Organization Flows

Six AI-assisted features for neurodivergent users. Backend infrastructure is production-ready (confirmed). On-device model scope deferred post-launch; all features use cloud endpoints for initial release.

**Shared invariants:**

- On-device by default; cloud requires explicit per-feature opt-in
- Cloud endpoint fails closed if opt-in absent
- Zero content retention (no durable storage of prompts/responses)
- Anonymous device session tokens only
- AI always suggests, never auto-acts; no urgency language; all features optional and dismissible

**Feature 1 — Smart Task Breakdown** (implemented 2026-03-09):
Decomposes a task into subtasks with adjustable granularity (1–5). Cloud endpoint: `POST /v1/ai/breakdown/generate`. UI: granularity slider, subtask preview, approve/edit before save. Core implementation shipped: `BreakdownSheet.swift` (ViewModel + UI), wired into `CaptureItemCard` context menu and accessibility actions, and `CaptureView` sheet presentation. Template persistence deferred post-launch.

**Feature 2 — Brain Dump Compiler** (implemented 2026-03-09):
Extracts and categorizes items from long captures (>75 words triggers suggestion). Creates Collections from approved compilations. Categories map to `ItemType` cases directly. Core implementation shipped: `BrainDumpSheet.swift` (ViewModel + UI), `BrainDumpService.swift`, backend `POST /v1/ai/braindump/compile` endpoint, wired into `CaptureItemCard` context menu, accessibility action, and visual suggestion badge for long-content items. `CaptureView` sheet presentation.

**Feature 3 — Recurring Task Intelligence** (after infra proven; ⚠️ needs human gate):
Detects natural completion patterns (≥3 completions), surfaces gentle suggestions at learned intervals. No rigid schedules, no "overdue" language. Learns from snooze/dismiss timing.
⚠️ Human gate: confirm minimum completion count and snooze learning behavior before implementation.

**Feature 4 — Tone Assistant** (after infra proven):
Transforms captures into toned messages (formal, friendly, concise, empathetic, direct, neutral). Saves named presets. Multiple simultaneous previews.

**Feature 5 — Executive Function Prompts** (after infra proven; ⚠️ needs human gate):
Conversational scaffolding when a user is stuck. Detects challenge type via clarifying questions, offers micro-strategies. Learns which strategies work per user.
⚠️ Human gate: define challenge detection heuristics and learning model before implementation.

**Feature 6 — Decision Fatigue Reducer** (implemented 2026-03-09):
Surfaces max 2–3 "good enough" recommendations with optional 1–2 clarifying questions for refinement and a "Just pick for me" mode. Cloud endpoint: `POST /v1/ai/decide/recommend`. Core implementation shipped: `DecisionFatigueSheet.swift` (ViewModel + UI), `DecisionFatigueService.swift`, backend router with schemas and OpenAI/Anthropic provider methods, wired into `CaptureItemCard` context menu and accessibility actions, and `CaptureView` sheet presentation. Fully on-device fallback (parses "or"-style alternatives; falls back to generic options).

---

## AI Pricing & Limits

Local quota enforcement, server reconciliation, and usage UX.

**Decided:**

- Free only at launch; no paid tier until after TestFlight feedback
- Free tier: 100 AI actions (one action = one successful `/v1/ai/*` call)
- Hybrid enforcement: UserDefaults counter + Keychain mirror, reconciled via `POST /v1/usage/reconcile` at `max(local, server)`
- Quota UX: non-judgmental inline message ("You've used X of 100 AI features this month"); no upgrade nudge at launch
- Billing: deferred to post-launch

**Remaining:**

- Implement local quota enforcement (`QuotaStore`: UserDefaults counter + Keychain mirror)
- Build server reconciliation (`max(local, server)` merge)
- Add quota-approached UX (non-judgmental; no upgrade nudge)
