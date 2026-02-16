---
id: plan-backend-reliability-durability
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - backend
  - ai
  - reliability
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

# Plan: Backend Reliability and Durability Hardening

## Overview

This plan upgrades backend durability and provider resilience for Smart Task
Breakdown by replacing in-memory usage reconciliation with SQLite-backed
persistence and adding bounded provider retry/backoff behavior. It also includes
explicit regression verification for already-fixed payload guardrails.

## Goals

- Replace volatile in-memory usage reconciliation with durable SQLite storage.
- Ensure reconcile writes are atomic and correct under concurrency.
- Add bounded retry/backoff for transient provider failures.
- Preserve and verify request-size and list-field guardrails.

## Phases

### Phase 1: Guardrail Verification Lock (Already Fixed)

**Status:** Not Started

- [ ] Red:
  - [ ] Add boundary tests for `context_hints`/`template_ids` list lengths and
        per-element max lengths.
  - [ ] Add tests proving aggregate request size rejects oversized combined
        payloads.
- [ ] Green: keep existing schema/router enforcement intact while adding any
      missing assertions.
- [ ] Refactor: consolidate breakdown request fixture builders.

### Phase 2: Durable Usage Store (SQLite First)

**Status:** Not Started

- [ ] Red:
  - [ ] Add usage-store contract tests for persistence across app restart.
  - [ ] Add concurrency tests verifying atomic `max(local, server)` upsert
        semantics.
- [ ] Green:
  - [ ] Introduce usage store protocol and SQLite implementation.
  - [ ] Wire app dependencies to use SQLite store by default.
  - [ ] Preserve API response shape for `/v1/usage/reconcile`.
- [ ] Refactor:
  - [ ] Separate schema/bootstrap from reconcile operations.
  - [ ] Add deterministic test database setup helpers.

### Phase 3: Provider Retry and Backoff

**Status:** Not Started

- [ ] Red:
  - [ ] Add adapter tests for retries on timeout/429/5xx and no-retry behavior
        on non-retriable 4xx.
  - [ ] Add tests that bound max attempts and total delay.
- [ ] Green:
  - [ ] Implement bounded exponential backoff with jitter for transient
        provider errors.
  - [ ] Add telemetry tags for attempt count and terminal error class.
- [ ] Refactor:
  - [ ] Extract retry policy into reusable configuration.
  - [ ] Keep provider error mapping stable at router boundary.

## Dependencies

- [plan-backend-api-privacy](./plan-backend-api-privacy.md)
- [adr-0008-backend-api-privacy-mvp](../adrs/adr-0008-backend-api-privacy-mvp.md)
- [design-backend-api-privacy-mvp](../design/design-backend-api-privacy-mvp.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| SQLite locking behavior causes intermittent reconcile failures | M | Use explicit transactions and test concurrent write scenarios. |
| Retry policy increases response latency under provider degradation | M | Bound attempts and enforce max timeout budget per request. |
| Regression in existing payload guards | M | Keep phase-1 regression tests required before merge. |

## User Verification

- [ ] Usage counters persist across backend restart.
- [ ] Reconcile behavior remains monotonic (`max(local, server)`) under repeated sync cycles.
- [ ] Breakdown generation remains available during transient provider failures with bounded latency impact.
- [ ] Oversized list-field payloads are rejected with stable error responses.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-16 | Plan created from CODE_REVIEW_2026-02-15 reliability/performance backend findings split. |
