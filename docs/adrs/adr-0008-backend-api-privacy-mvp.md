---
id: adr-0008-backend-api-privacy-mvp
type: architecture-decision
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
  - plan-backend-api-privacy
  - research-privacy-learning-user-data
  - research-offline-ai-quota-enforcement
  - research-on-device-ai-feasibility
depends_on:
  - docs/prds/prd-0007-smart-task-breakdown.md
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-02-15
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/111
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-02-15
decision-makers:
  - Will-Conklin
---

# adr-0008: Backend API + Privacy Constraints MVP

**Status:** Accepted  
**Decision Date:** 2026-02-15  
**Deciders:** Will-Conklin  
**Tags:** backend, ai, privacy

## Context

Offload currently runs as a local-only iOS app. Smart Task Breakdown requires a
cloud fallback path for quality and future pricing/limits enforcement, while
preserving offline-first behavior and strict privacy boundaries.

ADR-0001 deferred backend stack decisions. The backend implementation plan now
requires a concrete MVP decision for:

- Backend stack and endpoint shape
- Identity model without launch-time account requirement
- Privacy and retention guarantees for cloud AI processing
- Quota reconciliation behavior when offline usage occurs

## Decision

1. **Backend stack:** Python + FastAPI for MVP.
2. **Provider strategy:** Single provider (OpenAI) behind an adapter interface.
3. **Identity model:** Anonymous device session tokens (no account requirement).
4. **Consent policy:** On-device default; cloud processing requires explicit
   user opt-in.
5. **Retention policy:** Zero content retention for prompts/responses.
6. **Quota policy:** Local provisional counters in app with server
   reconciliation when online.
7. **MVP backend scope:** Smart Task Breakdown endpoint first, with reusable
   envelope for future AI endpoints.

## Consequences

### Positive

- Enables backend MVP quickly while preserving privacy defaults.
- Keeps app usable offline and avoids account system complexity for MVP.
- Creates a reusable API contract pattern for additional AI features.
- Minimizes data-retention risk by avoiding content persistence.

### Negative

- Anonymous sessions are weaker for abuse prevention than full auth.
- Single-provider MVP can create short-term provider lock-in risk.
- Server reconciliation introduces temporary quota drift during offline usage.

### Neutral

- Additional ADRs may be required for full production auth and multi-provider
  routing.
- Future pricing-tier enforcement can build on this reconciliation baseline.

## Alternatives Considered

### Swift + Vapor backend

- Pros: single-language stack with iOS.
- Cons: slower backend iteration for current team and fewer existing backend
  scripts.
- Decision: deferred in favor of Python/FastAPI MVP speed.

### Managed serverless/BaaS-first

- Pros: reduced custom backend code.
- Cons: higher coupling to vendor-specific APIs and less explicit contract
  control.
- Decision: rejected for MVP contract clarity.

### Server-only quota enforcement

- Pros: stronger central authority.
- Cons: poor offline UX and hard block while disconnected.
- Decision: rejected due to offline-first product requirements.

## Implementation Notes

- API endpoints:
  - `POST /v1/sessions/anonymous`
  - `POST /v1/ai/breakdown/generate`
  - `POST /v1/usage/reconcile`
  - `GET /v1/health`
- Protected endpoints require bearer session token.
- Cloud AI endpoint must fail closed without explicit opt-in signal.
- Logs may include request ID, route, status, and latency only.
- Prompts and model responses must not be persisted to durable storage.

## References

- [plan-backend-api-privacy](../plans/plan-backend-api-privacy.md)
- [prd-0007-smart-task-breakdown](../prds/prd-0007-smart-task-breakdown.md)
- [research-privacy-learning-user-data](../research/research-privacy-learning-user-data.md)
- [research-offline-ai-quota-enforcement](../research/research-offline-ai-quota-enforcement.md)
- [research-on-device-ai-feasibility](../research/research-on-device-ai-feasibility.md)

## Revision History

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-02-15 | Initial MVP backend/privacy decision. |
