# Code Review — Offload (Swift/SwiftUI/FastAPI)

Date: 2026-02-15
Reviewer: Codex (GPT-5.2-Codex)
Scope: iOS app, backend API slice, and planned feature docs.

## Executive Summary

Offload has a clear architectural direction (feature-modular SwiftUI + repository pattern + FastAPI adapter layer) and solid product framing around ADHD-aware UX and privacy-first AI. The strongest aspects are:

- clear domain decomposition and ADR/PRD discipline;
- cloud-AI opt-in with on-device fallback in the iOS service layer;
- backend contracts that are intentionally narrow and testable.

Highest-priority improvements should focus on security hardening for session/auth controls, state durability for usage/quota enforcement, SwiftData performance scaling, and UX/accessibility consistency in custom navigation components.

## What Is Working Well

1. **Cloud AI is optional and fallback-safe**
   - `DefaultBreakdownService` routes to on-device generation unless consent exists, and falls back to on-device on cloud failure.
2. **Backend provider abstraction is clean**
   - Provider errors are normalized to API-level failures with explicit status codes.
3. **Repository and model layering in iOS is coherent**
   - Persistence concerns are mostly centralized in repositories and models.
4. **Planned feature lifecycle is disciplined**
   - Plans and PRDs separate concerns and reference dependencies/risks.

## Critical Findings (Priority Order)

### P0 — Security / Abuse Prevention

1. **Default session secret is insecure in production unless overridden**
   - `session_secret` defaults to `dev-secret-change-me`.
   - Recommendation: fail-fast on startup outside development when this value (or weak entropy) is detected.

2. **Anonymous session issuance has no visible abuse controls**
   - `POST /v1/sessions/anonymous` currently issues session tokens with install ID only.
   - Recommendation: add IP/device-level rate limiting and optional proof-of-work/challenge controls.

3. **Custom token format omits key-rotation and token metadata fields**
   - Current token includes only install ID + expiry and HMAC signature.
   - Recommendation: add `kid`, `iat`, `nbf`, `iss`, `aud`, version field; keep constant-time checks and include formal rotation strategy.

### P1 — Data Integrity / Reliability

4. **Usage reconciliation store is in-memory only**
   - `InMemoryUsageStore` will reset on restart and diverge across workers.
   - Recommendation: move to durable shared storage (SQLite/Postgres/Redis) with atomic upsert semantics.

5. **Position management can become expensive at scale**
   - Collection item reorder/compaction logic performs repeated fetch/sort/save workflows.
   - Recommendation: use batched updates and O(n) remap strategy for reorders.

### P1 — Performance

6. **`reorderItems` is O(n²)**
   - Current implementation iterates IDs and searches linearly in fetched items.
   - Recommendation: pre-index by `itemId` (`Dictionary<UUID, CollectionItem>`) and update in O(n).

7. **Large binary blobs in SwiftData entity**
   - `Item.attachmentData` stores attachments inline in model records.
   - Recommendation: move to file-backed storage + lightweight metadata pointer for memory and I/O control.

8. **Repeated JSON encode/decode via raw string metadata**
   - `Item.metadata` as raw JSON string incurs repeated conversion and weak typing.
   - Recommendation: move to typed Codable structs (or constrained key schema) and decode once per lifecycle.

### P1 — UX / Accessibility

9. **Custom tab bar uses many hardcoded dimensions and visual constants**
   - Hardcoded corner radii, heights, offsets, and divider dimensions can reduce adaptability across dynamic type and device classes.
   - Recommendation: route sizing and spacing through design tokens and accessibility size categories.

10. **Potentially inconsistent accessibility affordances in floating CTA interactions**
   - With custom tab shell and overlay CTA, ensure explicit accessibility labels/traits/hit targets and keyboard/VoiceOver order.

### P2 — API / Contract Governance

11. **Input guardrails are present but still broad**
   - Max input chars are enforced, but individual list field sizes (`context_hints`, `template_ids`) should also be bounded.
   - Recommendation: add Pydantic length constraints and reject pathological payloads early.

12. **Provider reliability can be improved**
   - OpenAI adapter currently has no retry/backoff/idempotency strategy.
   - Recommendation: add bounded retries with jitter for transient failures and stronger telemetry tags.

## Planned Features Review (Docs)

### Overall Assessment

Planned feature docs are strong in intent and decomposition, especially around privacy and ADHD-aware UX guardrails. The key risk is **scope expansion before launch stability**.

### Recommendations by Workstream

1. **AI Organization Flows (proposed)**
   - Keep gated behind launch criteria + backend privacy MVP completion.
   - Add explicit exit criteria for each PRD (0007–0012) before implementation starts.

2. **Release Prep (in progress)**
   - Add a “security release gate” checklist:
     - production secret validation;
     - rate-limiting enabled;
     - privacy policy + data retention statements aligned to backend behavior;
     - incident/rollback runbook.

3. **Testing & Quality Plans**
   - Expand non-functional acceptance criteria (p95 latency, memory thresholds, startup time, crash-free goals).

4. **UX/Accessibility Plans**
   - Add mandatory VoiceOver and Dynamic Type acceptance checks for custom navigation/tab shell flows.

## Suggested 30-Day Action Plan

### Week 1 — Security Baseline
- Enforce production-safe secret policy.
- Add session endpoint rate limiting.
- Add token version + key ID support.

### Week 2 — Reliability & Quotas
- Replace in-memory usage store with durable shared store.
- Add reconciliation conflict tests and multi-worker behavior validation.

### Week 3 — iOS Performance
- Refactor reorder path to O(n).
- Move attachment payloads to file-backed storage.
- Introduce typed metadata model.

### Week 4 — UX & Hardening
- Tokenize custom tab bar sizing/spacing.
- Complete accessibility audit for CTA/tab interactions.
- Add end-to-end test coverage for AI fallback + consent transitions.

## Risk Matrix

| Area | Risk | Impact | Likelihood | Priority |
| --- | --- | --- | --- | --- |
| Security | Weak/default secret in prod | High | Medium | P0 |
| Security | Session abuse without rate limits | High | High | P0 |
| Reliability | In-memory quota store divergence | High | Medium | P1 |
| Performance | O(n²) reorder scaling | Medium | High | P1 |
| UX | Custom tab accessibility regressions | Medium | Medium | P1 |
| Delivery | AI scope creep pre-launch | High | Medium | P1 |

## Final Recommendation

Proceed with **security and durability hardening before broad AI feature expansion**. The architecture is good enough to scale, but production readiness depends on closing the P0/P1 gaps above first.
