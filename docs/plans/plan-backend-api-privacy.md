---
id: plan-backend-api-privacy
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - backend
  - ai
  - privacy
last_updated: 2026-02-15
related:
  - plan-roadmap
  - adr-0008-backend-api-privacy-mvp
  - design-backend-api-privacy-mvp
  - prd-0007-smart-task-breakdown
  - research-on-device-ai-feasibility
  - research-privacy-learning-user-data
  - research-offline-ai-quota-enforcement
depends_on:
  - docs/adrs/adr-0008-backend-api-privacy-mvp.md
  - docs/design/design-backend-api-privacy-mvp.md
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-02-15
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/111
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
  - "Implementation scope is breakdown-first backend MVP with explicit cloud opt-in and zero content retention."
---

# Plan: Backend API + Privacy Constraints MVP (Breakdown-First)

## Overview

Implement a backend MVP that supports Smart Task Breakdown cloud fallback while
keeping Offload on-device first. This plan includes prerequisite docs,
FastAPI-based API scaffold, OpenAI adapter integration, anonymous device
sessions, consent gating, and usage reconciliation.

## Goals

- Deliver backend endpoints for session bootstrap, breakdown generation, usage
  reconciliation, and health checks.
- Enforce privacy defaults: explicit cloud opt-in and zero prompt/response
  retention.
- Add iOS scaffolding for cloud client, consent store, quota store, and
  breakdown service fallback.
- Activate backend CI checks with concrete lint/test commands.

## Phases

### Phase 1: Prerequisite docs and acceptance chain

**Status:** Completed

- [x] Add docs validation checklist:
  - [x] PRD alignment for breakdown-first backend scope.
  - [x] ADR decision for stack, identity, consent, and retention.
  - [x] Design doc for contracts and privacy enforcement.
- [x] Update PRD backend section in
  `docs/prds/prd-0007-smart-task-breakdown.md`.
- [x] Add ADR `docs/adrs/adr-0008-backend-api-privacy-mvp.md`.
- [x] Add design doc `docs/design/design-backend-api-privacy-mvp.md`.
- [x] Link new docs in plan + docs navigation indexes.

### Phase 2: Backend scaffold and health endpoint

**Status:** Completed

- [x] Add backend project metadata in `backend/api/pyproject.toml`.
- [x] Add FastAPI app factory and route registration.
- [x] Implement `GET /v1/health` with build metadata response.
- [x] Add structured API error envelope and request-id middleware.

### Phase 3: Anonymous session and auth gate

**Status:** Completed

- [x] Add token manager and session claim validation.
- [x] Implement `POST /v1/sessions/anonymous`.
- [x] Require bearer token for `/v1/ai/*` and `/v1/usage/*`.
- [x] Map missing/invalid/expired token paths to stable error codes.

### Phase 4: Breakdown endpoint with provider adapter

**Status:** Completed

- [x] Implement `POST /v1/ai/breakdown/generate`.
- [x] Add OpenAI adapter behind provider protocol.
- [x] Enforce explicit cloud opt-in signal (`X-Offload-Cloud-Opt-In`).
- [x] Enforce request-size limits and provider error mapping.
- [x] Keep response/content handling non-persistent.

### Phase 5: Quota reconciliation endpoint

**Status:** Completed

- [x] Implement `POST /v1/usage/reconcile`.
- [x] Add in-memory authoritative reconcile logic (`max(local, server)`).
- [x] Return effective remaining quota and reconcile timestamp.

### Phase 6: iOS integration scaffold

**Status:** Completed

- [x] Add backend contract types in
  `ios/Offload/Data/Networking/AIBackendContracts.swift`.
- [x] Add `NetworkAIBackendClient` + consent/token/quota stores in
  `ios/Offload/Data/Networking/AIBackendClient.swift`.
- [x] Add `DefaultBreakdownService` with on-device fallback in
  `ios/Offload/Data/Services/BreakdownService.swift`.
- [x] Add dependency injection environment keys in
  `ios/Offload/Common/AIBackendEnvironment.swift`.

### Phase 7: CI lane and developer workflow

**Status:** Completed

- [x] Replace placeholder backend checks in `scripts/ci/backend-checks.sh`.
- [x] Add backend setup/lint/test tasks to `justfile`.
- [x] Expand `backend/README.md` with MVP scope and run instructions.

## Dependencies

- [prd-0007-smart-task-breakdown](../prds/prd-0007-smart-task-breakdown.md)
- [adr-0008-backend-api-privacy-mvp](../adrs/adr-0008-backend-api-privacy-mvp.md)
- [design-backend-api-privacy-mvp](../design/design-backend-api-privacy-mvp.md)
- `backend/api` Python toolchain with FastAPI test/lint dependencies

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Backend provider outages degrade cloud flow | H | Keep on-device fallback as default and cloud as opt-in only. |
| Anonymous identity abuse potential | M | Use short TTL tokens and preserve adapter boundary for future auth. |
| Quota drift between offline and online states | M | Reconcile with `max(local, server)` and keep local UX non-blocking. |
| Privacy regressions via accidental logging | H | Restrict logs to request metadata only; avoid payload persistence. |

## User Verification

- [ ] Cloud opt-in toggle gates cloud requests correctly.
- [ ] Breakdown generation falls back on-device when cloud path fails.
- [ ] Session refresh occurs after expiry/401 without user-visible failure.
- [ ] Usage reconciliation preserves user-visible local counts while syncing with server.
- [ ] Backend logs/telemetry do not contain prompt or response content.

## Progress

- 2026-02-15: Implemented breakdown-first backend MVP scaffold and iOS client/service scaffolding.
- 2026-02-15: Added ADR-0008 and design-backend-api-privacy-mvp documents; updated PRD-0007 backend/privacy constraints.
- 2026-02-15: Added backend tests and iOS tests for auth, consent, fallback, and reconcile behavior.
