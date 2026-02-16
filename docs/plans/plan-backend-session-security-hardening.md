---
id: plan-backend-session-security-hardening
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - backend
  - ai
  - security
last_updated: 2026-02-16
related:
  - plan-backend-api-privacy
  - adr-0008-backend-api-privacy-mvp
  - design-backend-api-privacy-mvp
depends_on:
  - docs/adrs/adr-0008-backend-api-privacy-mvp.md
  - docs/design/design-backend-api-privacy-mvp.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Backend Session Security Hardening

## Overview

This plan hardens anonymous session and token security for the backend MVP by
adding production-safe secret policy enforcement, abuse controls on session
issuance, and token metadata/version upgrades for key rotation readiness.

## Goals

- Enforce explicit production-safe session secret policy on startup.
- Add rate limiting for `POST /v1/sessions/anonymous` using IP and install ID
  signals.
- Upgrade session token format to versioned claims with key metadata and strict
  validation.
- Preserve stable API error codes for unauthorized/invalid/expired token paths.

## Phases

### Phase 1: Baseline Verification and Regression Lock

**Status:** Completed

- [x] Add tests that lock in current fixed behavior:
  - [x] Malformed base64 and malformed token segments return `invalid_token`.
  - [x] Session secret default is non-static and non-reused across
        instantiations.
- [x] Add tests that verify existing auth error code contracts remain stable.
- [x] Refactor auth test helpers for reusable token/session fixtures.

### Phase 2: Production Secret Policy Enforcement

**Status:** Completed

- [x] Red:
  - [x] Add startup/config tests for production-like environments requiring
        explicit `OFFLOAD_SESSION_SECRET`.
  - [x] Add tests rejecting weak or placeholder secret values.
- [x] Green:
  - [x] Implement config validation that fails closed when secrets are missing
        or weak outside development.
  - [x] Add explicit runtime guidance in backend docs.
- [x] Refactor: centralize secret strength validation in a dedicated utility.

### Phase 3: Session Issuance Rate Limiting

**Status:** Completed

- [x] Red:
  - [x] Add tests for per-IP and per-install throttling behavior on
        `/v1/sessions/anonymous`.
  - [x] Add tests for deterministic `429` error envelope and reset behavior.
- [x] Green:
  - [x] Implement rate limiting dependency/middleware for session issuance.
  - [x] Emit bounded, non-sensitive telemetry for throttled events.
- [x] Refactor: extract limiter interface to support future storage-backed
      implementations.

### Phase 4: Token V2 Claims and Key Metadata (Hard Cutover)

**Status:** Completed

- [x] Red:
  - [x] Add tests requiring claims: `v`, `kid`, `iat`, `nbf`, `iss`, `aud`,
        `exp`, `install_id`.
  - [x] Add tests requiring strict issuer/audience/key-id validation.
  - [x] Add tests verifying v1 tokens are rejected after cutover.
- [x] Green:
  - [x] Implement token v2 encode/decode with key-id aware signing and
        constant-time signature checks.
  - [x] Add token configuration for issuer, audience, active key ID, and key
        material.
- [x] Refactor:
  - [x] Inject deterministic clock for tests.
  - [x] Consolidate claim parsing and validation error mapping.

## Dependencies

- [plan-backend-api-privacy](./plan-backend-api-privacy.md)
- [adr-0008-backend-api-privacy-mvp](../adrs/adr-0008-backend-api-privacy-mvp.md)
- [design-backend-api-privacy-mvp](../design/design-backend-api-privacy-mvp.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Overly strict secret policy blocks local/dev workflows | M | Restrict fail-fast enforcement to production-like environments with clear dev bypass defaults. |
| Aggressive rate limits impact legitimate users | M | Start conservative, test boundary behavior, and tune with telemetry. |
| Hard token cutover causes short-lived session churn | M | Document rollout expectations and retest session refresh paths in iOS client integration tests. |

## User Verification

- [ ] Production deployment fails closed when secret policy is not satisfied.
- [ ] Session issuance throttles as expected under abusive request rates.
- [ ] Auth-protected endpoint behavior remains stable for missing/invalid/expired tokens.
- [ ] New token format validates end-to-end in backend + iOS integration flows.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-16 | Plan created from CODE_REVIEW_2026-02-15 security findings split. |
| 2026-02-16 | Completed Phases 1-3: auth regression lock, production secret policy enforcement, and session issuance rate limiting with deterministic 429/reset behavior and bounded telemetry. |
| 2026-02-16 | Completed Phase 4 hard cutover to token v2 claims (`v`,`kid`,`iat`,`nbf`,`iss`,`aud`,`exp`,`install_id`) with strict metadata validation, v1 rejection, deterministic clock tests, and key-id-aware signing config. |
