---
id: plan-decision-fatigue-reducer
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ios
  - capture
  - ai
  - backend
last_updated: 2026-03-09
related:
  - plan-testing-polish
  - docs/plans/backlog.md
depends_on: []
supersedes: []
accepted_by: "@Will-Conklin"
accepted_at: 2026-03-09
structure_notes:
  - "Section order: Overview; Goals; Architecture; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Decision Fatigue Reducer

## Overview

Feature 6 of the AI Organization Flows. Helps users overcome decision fatigue by
surfacing 2–3 "good enough" options from a capture. Max 1–2 optional clarifying
questions surface when the AI needs more context; users can answer or skip. A
"Just pick for me" mode highlights the recommended option.

No options are saved — the sheet is purely advisory. AI always suggests, never
auto-acts.

## Goals

- Surface 2–3 actionable options from any decision-style capture.
- Allow optional refinement via 1–2 clarifying questions.
- Provide a "Just pick for me" mode that selects the recommended option.
- Respect all shared AI invariants: consent-gated, zero content retention,
  on-device fallback, no urgency language.

## Architecture

### Backend

- **Endpoint:** `POST /v1/ai/decide/recommend`
- **Request:** `input_text`, `context_hints[]`, `clarifying_answers[]` (max 2)
- **Response:** `options[]` (max 3), `clarifying_questions[]` (max 2), `usage`
- **Router:** `backend/api/src/offload_backend/routers/decide.py`
- **Schemas:** `DecisionRecommendRequest`, `DecisionOption`, `DecisionRecommendResponse`, `DecisionUsage` in `schemas.py`
- **Provider:** `suggest_decisions()` added to `AIProvider` protocol, `OpenAIProviderAdapter`, and `AnthropicProviderAdapter`

### iOS

- **Service:** `DecisionFatigueService` protocol + `DefaultDecisionFatigueService` in `DecisionFatigueService.swift`
- **On-device fallback:** `SimpleOnDeviceDecisionGenerator` — parses "or/vs" alternatives from text; falls back to generic 3-option set
- **Sheet:** `DecisionFatigueSheet.swift` — ViewModel + 3-phase UI (configure → options → decided)
- **Contracts:** `DecisionRecommendRequest`, `DecisionOption`, `DecisionRecommendResponse`, `DecisionUsage` in `AIBackendContracts.swift`
- **Environment:** `decisionFatigueService` key in `AIBackendEnvironment.swift`
- **Icon:** `Icons.decisionFatigue = "arrow.triangle.branch"`
- **Accessibility:** `AdvancedAccessibilityActionPolicy.decisionFatigueActionName = "Get Options"`
- **Wiring:** `CaptureItemCard` context menu + accessibility action; `CaptureView` sheet state

### UI Flow

1. User opens sheet from context menu or accessibility action on any capture
2. **Configure phase:** shows capture preview + optional clarifying question fields (pre-populated from prior generation if any) + "Get Options" button
3. **Options phase:** shows 2–3 option cards with title, description, and optional "Best match" badge + "Just pick for me" secondary button + "Refine" toolbar button
4. **Decided phase:** shows recommended option at full width with checkmark + dismissal note

## Phases

### Phase 1: Backend (TDD)

**Status:** Completed

- [x] Red: Add `test_decide.py` covering success, auth, consent, rate limit, oversized input, timeout, and provider failure paths.
- [x] Green: Add schemas, provider protocol method, router, and register in `main.py`.
- [x] Implement `suggest_decisions()` in `OpenAIProviderAdapter` and `AnthropicProviderAdapter`.

### Phase 2: iOS Service (TDD)

**Status:** Completed

- [x] Red: Add `DecisionFatigueServiceTests.swift` covering consent-off on-device, consent-on cloud, transport/server fallback, policy error surfacing, usage tracking, on-device generator "or" parsing, and generic fallback.
- [x] Green: Implement `DecisionFatigueService.swift` with `DefaultDecisionFatigueService` and `SimpleOnDeviceDecisionGenerator`.
- [x] Add `DecisionRecommendRequest/Response/Option/Usage` to `AIBackendContracts.swift`.
- [x] Add `suggestDecisions()` to `AIBackendClient` protocol and `NetworkAIBackendClient`.
- [x] Add `decisionFatigueService` environment key to `AIBackendEnvironment.swift`.
- [x] Add stub `suggestDecisions` to existing `MockBreakdownBackendClient` and `MockBrainDumpBackendClient` in test files.

### Phase 3: iOS UI

**Status:** Completed

- [x] Add `Icons.decisionFatigue` to `Icons.swift`.
- [x] Add `AdvancedAccessibilityActionPolicy.decisionFatigueActionName` to `AdvancedAccessibilityActionPolicy.swift`.
- [x] Build `DecisionFatigueSheet.swift`: ViewModel + 3-phase sheet UI with clarifying questions, option cards, "Just pick for me", and "decided" single-option view.
- [x] Wire into `CaptureItemCard`: `onDecisionFatigue` callback + context menu item + accessibility action.
- [x] Wire into `CaptureView`: `decisionFatigueItem` state + `.sheet(item:)` presentation.

### Phase 4: Docs + Backlog

**Status:** Completed

- [x] Create this plan doc.
- [x] Update backlog to mark Feature 6 as implemented.

## Dependencies

- `AIBackendClient` protocol and `NetworkAIBackendClient` — extended in-place.
- `AIBackendEnvironment.swift` — service environment key added.
- `CaptureItemCard`, `CaptureView` — minimal additions only; no structural changes.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Users confused by "not saved" advisory-only options | L | Dismissal note in decided phase; no save button present |
| Clarifying questions UX feels like extra work | L | Questions are optional and skippable; clearly labeled |
| On-device fallback options feel generic | M | Cloud path provides tailored options; fallback is transparent |

## User Verification

- [ ] "Get Options" context menu item appears on capture item cards.
- [ ] Sheet opens with item preview and "Get Options" button.
- [ ] Options phase shows 2–3 option cards, at least one marked "Best match".
- [ ] Clarifying questions appear after a cloud result returns questions; answers are optional.
- [ ] "Just pick for me" button highlights the recommended option in decided phase.
- [ ] "Refine" toolbar button returns to configure phase with existing answers preserved.
- [ ] "All Options" toolbar button returns from decided to options phase.
- [ ] VoiceOver "Get Options" accessibility action works from capture item cards.
- [ ] On-device fallback works when cloud AI opt-in is disabled.
- [ ] No options are saved; sheet is purely advisory.

## Progress

| Date | Update |
| --- | --- |
| 2026-03-09 | Feature implemented: backend (router + schemas + OpenAI/Anthropic providers), iOS service + fallback, sheet UI, wiring into CaptureItemCard/CaptureView, tests, and plan doc. Moved to `uat`. |
