# Backlog

Known bugs, features, and enhancements that do not yet have a plan doc. Items are removed when a plan doc is created in `docs/plans/`.

---

## Release Prep

App Store submission and TestFlight distribution. Blocked by UAT (see `docs/plans/uat-checklist.md`). Requires Apple Developer Program membership + App Store Connect access.

**Scope:**

- Update README for shipped features; draft release notes
- App Store metadata: name, subtitle, description, keywords, category, screenshots (iPhone 6.7"/6.1" + iPad), 1024×1024 app icon, age rating, privacy policy URL, support URL, bundle ID + version verification
- TestFlight: release build archive, upload, configure internal testing group, triage feedback
- Security release gate (requires explicit sign-off): production secret policy, session rate limiting, privacy policy alignment, incident response + rollback runbook

**Related:** GitHub issue #113

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

**Feature 1 — Smart Task Breakdown** (implement first):
Decomposes a task into subtasks with adjustable granularity (1–5). Cloud endpoint: `POST /v1/ai/breakdown/generate`. UI: granularity slider, subtask preview, approve/edit before save. Saves reusable templates per task type.

**Feature 2 — Brain Dump Compiler** (after Feature 1):
Extracts and categorizes items from long captures (>75 words triggers suggestion). Creates Collections from approved compilations. Categories map to `ItemType` cases directly.

**Feature 3 — Recurring Task Intelligence** (after infra proven; ⚠️ needs human gate):
Detects natural completion patterns (≥3 completions), surfaces gentle suggestions at learned intervals. No rigid schedules, no "overdue" language. Learns from snooze/dismiss timing.
⚠️ Human gate: confirm minimum completion count and snooze learning behavior before implementation.

**Feature 4 — Tone Assistant** (after infra proven):
Transforms captures into toned messages (formal, friendly, concise, empathetic, direct, neutral). Saves named presets. Multiple simultaneous previews.

**Feature 5 — Executive Function Prompts** (after infra proven; ⚠️ needs human gate):
Conversational scaffolding when a user is stuck. Detects challenge type via clarifying questions, offers micro-strategies. Learns which strategies work per user.
⚠️ Human gate: define challenge detection heuristics and learning model before implementation.

**Feature 6 — Decision Fatigue Reducer** (after infra proven):
Surfaces max 2–3 "good enough" recommendations. Max 1–2 clarifying questions. "Just pick for me" mode.

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

