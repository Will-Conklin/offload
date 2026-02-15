---
id: design-backend-api-privacy-mvp
type: design
status: accepted
owners:
  - Will-Conklin
applies_to:
  - backend
  - ai
  - privacy
last_updated: 2026-02-15
related:
  - prd-0007-smart-task-breakdown
  - adr-0008-backend-api-privacy-mvp
  - plan-backend-api-privacy
depends_on:
  - docs/prds/prd-0007-smart-task-breakdown.md
  - docs/adrs/adr-0008-backend-api-privacy-mvp.md
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-02-15
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/111
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Backend API + Privacy Constraints MVP

## Overview

This design defines the MVP backend contract for Smart Task Breakdown cloud
fallback while preserving an on-device-first experience. It specifies endpoint
contracts, session model, consent gating, and usage reconciliation behavior.

## Architecture

### Components

- **iOS app layer**
  - `BreakdownService` chooses on-device first and cloud only when opt-in is enabled.
  - `NetworkAIBackendClient` manages session lifecycle and API calls.
  - `UsageCounterStore` tracks provisional local counters.
- **Backend API (FastAPI)**
  - Session endpoint for anonymous device token issuance.
  - Breakdown endpoint for cloud generation via provider adapter.
  - Usage reconcile endpoint for authoritative server count merge.
- **Provider adapter**
  - OpenAI adapter hidden behind provider protocol.

### API Surface

- `GET /v1/health`
- `POST /v1/sessions/anonymous`
- `POST /v1/ai/breakdown/generate`
- `POST /v1/usage/reconcile`

## Data Flow

### Session bootstrap

1. iOS client checks token validity.
2. If missing/expired, call `POST /v1/sessions/anonymous`.
3. Store token + expiry in session token store.

### Breakdown generation

1. User triggers breakdown generation.
2. `BreakdownService` checks cloud opt-in.
3. If disabled: use on-device generator only.
4. If enabled: call `/v1/ai/breakdown/generate` with bearer token and opt-in header.
5. On backend/provider failure, iOS falls back to on-device generation.

### Usage reconciliation

1. iOS increments local provisional usage counter.
2. When cloud-enabled and online, call `/v1/usage/reconcile` with merged local count.
3. Server stores max(local, server) as authoritative count.
4. iOS updates server mirror; UX preserves max(local, server).

## UI Behavior

- Cloud AI is **off by default**.
- Explicit opt-in controls whether cloud endpoint is used.
- Failure mode is non-blocking: breakdown generation falls back to on-device.
- No additional account setup required in MVP.

## Testing

### Backend automated tests

- Health endpoint returns status and build metadata.
- Session issuance and token validation paths.
- Missing/invalid/expired token behavior.
- Breakdown endpoint validation and provider error mapping.
- Request-size limits and consent-required enforcement.
- Reconcile conflict resolution (`max(local, server)`).

### iOS automated tests

- Consent-off fallback to on-device generation.
- Consent-on cloud call path.
- Token refresh before protected call and on 401 retry.
- Reconcile merge behavior preserving local UX.

### Manual checks

- Toggle cloud opt-in and verify path selection.
- Verify no prompt/response content is persisted in backend storage.
- Verify offline usage increments local counter and reconciles online.

## Constraints

- No prompt/response persistence to durable storage.
- Structured logs must exclude sensitive content.
- Single-provider (OpenAI) implementation behind protocol abstraction.
- Anonymous sessions only for MVP (no full auth system).
- Scope limited to Smart Task Breakdown API contract.
