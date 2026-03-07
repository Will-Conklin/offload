# Offload — Architecture

## Tech Stack

### iOS

| Concern | Choice | Rationale |
| --- | --- | --- |
| UI | SwiftUI | Declarative, automatic `@Query` updates, preview support |
| Persistence | SwiftData | Native Apple, seamless SwiftUI integration, CloudKit-ready |
| Architecture | Feature-based modules + repository pattern | Scales cleanly, clear separation of concerns |
| State | `@Query` + `@Environment` | Built-in, works seamlessly with SwiftData |
| Testing | XCTest + in-memory SwiftData containers | Current codebase uses XCTest |
| Min iOS | 17+ | Required for SwiftData and offline Speech recognition |

**Directory layout:**

```text
ios/Offload/
├── App/          — Entry point, MainTabView
├── Features/     — Capture, Home, Organize, Settings
├── Domain/       — Models (SwiftData)
├── Data/         — Repositories, persistence, services
└── DesignSystem/ — Theme, components, icons, textures
```

### Backend

| Concern | Choice | Rationale |
| --- | --- | --- |
| Framework | Python + FastAPI | Fast iteration, clean async support |
| Provider | OpenAI (single) behind adapter interface | Swap-safe for future multi-provider |
| Identity | Anonymous device session tokens | No account required at MVP |
| Persistence | SQLite for usage counts only | Zero content retention |

---

## Navigation Architecture

Five-destination tab shell with a persistent bottom tab bar:

| Tab | View | Notes |
| --- | --- | --- |
| Home | `HomeView` | Dashboard — stats, timeline |
| Review | `CaptureView` | Capture inbox |
| Offload (CTA) | `CaptureComposeView` (sheet) | Centered, visually distinct; expands to Write + Voice |
| Organize | `OrganizeView` | Plans and lists |
| Account | `AccountView` | Settings accessible from here |

**Rules:**

- Tab bar remains visible across all `NavigationStack` pushes
- Capture always opens as a sheet; editing flows are full-screen
- Settings is one tap from Account, not a top-level tab
- No deep navigation stacks (ADHD guardrail — shallow structure)

Implementation: `MainTabView` → custom `FloatingTabBar` → `NavigationStack` per tab → sheets for compose/edit.

---

## Data Model & Ordering

### Collection ordering

- `CollectionItem.position` persists ordering for both Lists and Plans
- `CollectionItem.parentId` persists hierarchy (meaningful only when `Collection.isStructured = true`)
- Collapsed/expanded state is session-only UI state — not persisted

### Plan ↔ List conversion

- Plan → List: clears `parentId` values, persists depth-first traversal order to `position`. **Hierarchy is lost by design** — user must be warned.
- List → Plan: sets `isStructured = true`, preserves existing `position` ordering, introduces no hierarchy.

### SwiftData notes

- Enum properties stored as strings with computed wrappers for type safety
- SwiftData predicates require explicit type references for enum cases
- `lowercased()` not supported in predicates — use case-sensitive search or fetch-and-filter
- Complex optional chaining not supported — fetch all and filter in memory for complex queries
- Attachment data should not be stored inline in model records — use file-backed storage with a metadata pointer

---

## CI/CD

### Provider

GitHub Actions. Workflow definitions live in `.github/workflows/`.

### Path-filtered lanes

| Lane | Paths | Checks |
| --- | --- | --- |
| Docs | `docs/**`, root `*.md`, `ios/README.md` | markdownlint |
| iOS | `ios/**` | Build + tests |
| Backend | `backend/**` | ruff, ty, pytest |
| Scripts | `scripts/**` | Script checks |

**Rules:**

- Docs-only changes (limited to docs paths above) skip all non-docs lanes
- Mixed changes run all relevant lanes
- `workflow_dispatch` with `full_run=true` forces all lanes
- Nightly schedule runs full suite to catch path filter gaps

### CI environment (pinned)

- macOS: 14 (GitHub runner)
- Xcode: 16.2
- Simulator: iPhone 16, iOS 18.2
- Architecture: arm64 (Apple Silicon); Intel unpinned

### Test runtime baselines

| Date | Duration | Notes |
| --- | --- | --- |
| 2026-01-03 | 112.818s | Full suite, iPhone 16 Pro, iOS 18.3.1 |

Full test command:

```bash
xcodebuild test -project ios/Offload.xcodeproj -scheme Offload \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
```

---

## Backend & Privacy Architecture

### API surface

| Endpoint | Description |
| --- | --- |
| `GET /v1/health` | Health + build metadata |
| `POST /v1/sessions/anonymous` | Issue anonymous device session token |
| `POST /v1/ai/breakdown/generate` | Smart Task Breakdown (cloud fallback) |
| `POST /v1/usage/reconcile` | Reconcile local provisional usage with server |

Protected endpoints require a bearer session token.

### Session token (JWT v2)

- Fields: install ID, `kid`, `iat`, `nbf`, `iss`, `aud`, expiry
- HMAC-signed with active key; supports key rotation via `kid`
- Constant-time comparison for validation

### Privacy invariants

- **Zero content retention:** prompts and model responses must not be persisted to durable storage
- **On-device default:** cloud AI requires explicit per-feature opt-in; endpoint fails closed if opt-in absent
- **Structured logs only:** request ID, route, status code, latency — no sensitive content in logs
- **Anonymous sessions only** for MVP; no full auth system

### Usage quota (hybrid enforcement)

- iOS maintains local provisional counter (UserDefaults + Keychain mirror for tamper resistance)
- On reconnect: `POST /v1/usage/reconcile` with local count; server stores `max(local, server)` as authoritative
- iOS UX preserves `max(local, server)` for display

### iOS ↔ backend flow

1. iOS checks session token validity on launch
2. If missing/expired: `POST /v1/sessions/anonymous` → store token + expiry
3. User triggers AI feature → check cloud opt-in
4. If opt-in disabled: use on-device model only
5. If opt-in enabled: call `/v1/ai/*` with bearer token
6. On backend/provider failure: fall back to on-device model
7. Increment local usage counter; reconcile with server when online

### Provider resilience

- Single provider (OpenAI) behind a protocol adapter for swap safety
- Provider errors normalized to API-level status codes
- Bounded retries with jitter for transient failures

---

## Known Risks (from 2026-02-15 code review)

### P0 — Security

- **Default session secret is insecure in non-dev environments.** `session_secret` defaults to a placeholder value. Production must fail-fast on startup if weak entropy is detected.
- **Anonymous session endpoint has no rate limiting.** `POST /v1/sessions/anonymous` needs IP/device-level rate limiting.
- **Token metadata fields were incomplete.** JWT v2 with `kid`, `iat`, `nbf`, `iss`, `aud` and formal rotation strategy is required.

### P1 — Reliability

- **Usage store was in-memory only.** Resolved: usage counts now persisted in SQLite. Must use atomic upsert semantics with multi-worker safety.
- **`reorderItems` was O(n²).** Pre-index by `itemId` using a Dictionary for O(n) reorder.
- **Attachment data stored inline.** Move to file-backed storage with a lightweight metadata pointer.
- **`Item.metadata` as raw JSON string.** Move to typed Codable structs; decode once per lifecycle.

### P1 — UX / Accessibility

- Custom tab bar uses hardcoded dimensions. Route sizing/spacing through design tokens and accessibility size categories.
- Floating CTA interactions need explicit accessibility labels, traits, hit targets, and VoiceOver order.

### Release gate (must complete before launch)

- Production secret policy validated in deployed environment
- Session endpoint rate limiting enabled and monitored
- Privacy policy aligned to backend behavior (no durable content retention)
- Incident response + rollback runbook current
