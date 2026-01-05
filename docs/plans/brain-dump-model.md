<!-- Intent: Keep the capture/organization model plan aligned with the current codebase and call out remaining gaps. -->

# Plan: Capture Event-Sourced Model

## Current State (January 2026)

- **Models shipped**: CaptureEntry + HandOffRequest/Run, Suggestion + SuggestionDecision, Placement, Plan, Task, Tag, Category, ListEntity/ListItem, CommunicationItem (`ios/Offload/Domain/Models/`).
- **Persistence**: `PersistenceController` and `SwiftDataManager` register the full schema for production and preview containers.
- **Data access**: Repositories exist for every model, plus `CaptureWorkflowService` for inbox + capture orchestration.
- **UI**: Capture list currently labeled "Inbox" and reads from `CaptureWorkflowService`; `CaptureSheetView` handles text + voice capture. Organize and settings flows remain placeholder-only and will need renaming per ADR-0002.
- **Tests**: Repository + workflow tests cover current CRUD/lifecycle behaviors with in-memory SwiftData.
- **Not implemented**: AI hand-off submission, suggestion presentation/decisions, placement flows, richer organization UI, and backend API client/server. These methods are stubbed in `CaptureWorkflowService` and TODOs remain across Organize/Settings.

## Updated Model Architecture

### Core Capture & Workflow Models

- **CaptureEntry**: rawText, inputType (text/voice), source (app/shortcut/shareSheet/widget), lifecycleState (raw/handedOff/ready/placed/archived), acceptedSuggestionId; inverse relationship to HandOffRequest (cascade).
- **HandOffRequest**: requestedAt, mode (manual/auto), status (pending/completed/error); inverse to CaptureEntry; cascade to HandOffRun.
- **HandOffRun**: startedAt/completedAt, modelId, promptVersion, inputSnapshot, runStatus, errorMessage; inverse to HandOffRequest; cascade to Suggestion.
- **Suggestion**: kind (plan/task/list/communication/mixed), payloadJSON; inverse to HandOffRun; cascade to SuggestionDecision.
- **SuggestionDecision**: decision (accepted/notNow), decidedAt, decidedBy, undoOfDecisionId; inverse to Suggestion.
- **Placement**: placedAt, targetType, targetId, sourceSuggestionId, notes (UUID-based linking, no direct relationships).

### Destination Models

- **Plan**: title, detail, createdAt, isArchived; tasks cascade on delete.
- **Task**: title, detail, createdAt, isDone, importance (1-5), dueDate; inverse to Plan, optional Category, and optional many-to-many Tags.
- **Tag** / **Category**: manual organization helpers with simplified relationships.
- **ListEntity/ListItem**: lightweight lists with cascade delete for items.
- **CommunicationItem**: communication follow-ups with channel/recipient/content/status.

## Terminology Alignment (ADR-0002)

- Canonical vocabulary: capture → hand-off → suggestion → decision → placement; use `CaptureEntry`, `HandOffRequest`/`HandOffRun`, `Suggestion`/`SuggestionDecision`, `Placement`, `Plan`, `ListEntity`/`ListItem`, and `CommunicationItem`.
- Deprecated labels present in the iOS scaffolding and docs include "Inbox" (as a destination/view), "Thought", and "BrainDump" variants; align code, tests, and copy with the canonical names.
- Early in the SDLC—no data migrations required; focus on renaming surfaces, service APIs, and documentation references.

## ADHD-Friendly UX Guardrails (ADR-0003)

- Adopt a capture-first default with immediate save and optional organization; keep a persistent capture control in the tab shell.
- Prefer undo banners over confirmation modals for destructive/move actions; reserve confirmations for batch deletes.
- Enforce a calm visual system with a restrained palette (base + primary/secondary accents), consistent spacing tokens, and accessible focus states.
- Keep navigation shallow (Inbox, Capture, Organize, Settings one tap away); mirror swipe actions with visible controls; use sheets for capture and full screens for editing.
- Present organization prompts as optional chips/cards with snooze/dismiss; avoid urgency language.
- Respect Dynamic Type, Reduce Motion, and minimum tap targets; pair focus states with color and stroke weight for clarity.

## Implementation Status by Phase

- **Phase 1 — Model Definition**: ✅ Complete with enum rawValue storage for SwiftData compatibility.
- **Phase 2 — Persistence Configuration**: ✅ `PersistenceController` + `SwiftDataManager` schemas updated; preview data seeded for captures/plans/tasks.
- **Phase 3 — Repository Implementation**: ✅ Capture, HandOff, Suggestion, Placement, Plan, Task, Tag, Category, List, and Communication repositories added with CRUD + lifecycle helpers.
- **Phase 4 — Service Integration**: 🚧 `CaptureWorkflowService` only implements capture, archive/delete, inbox/ready queries. AI hand-off, suggestion fetching, acceptance/rejection, and placement remain stubbed. Backend API client is empty; backend service is scaffolding only.
- **Phase 5 — Testing**: ✅ In-memory SwiftData tests cover repositories and workflow capture/inbox behaviors. No tests yet for AI submission or placement.
- **Phase 6 — UI Integration**: 🚧 Inbox wired to `CaptureWorkflowService`; CaptureSheetView uses voice + text; Organize tab has static lists and TODO add actions; Settings tab is placeholder; MainTabView exists but AppRoot currently routes directly to Inbox.

## Near-Term Milestones (post-2026-01-04 review)

1. **AI hand-off + backend delivery**
   - Choose backend stack per ADR-0001 (FastAPI recommended), define auth (JWT/OAuth), and wire AI provider integration.
   - Implement `APIClient` contracts used by `CaptureWorkflowService` and add end-to-end tests covering `submitForOrganization`, `fetchSuggestions`, `acceptSuggestion`, and `rejectSuggestion`.
   - Add failure/timeout handling, retries, and audit events for hand-off runs.
2. **App shell and organization surfaces**
   - Restore `MainTabView` as the root entry (Inbox/Organize/Settings) and align capture affordances across entry points.
   - Deliver Organize tab MVP for creating/editing plans, tags, categories, lists, and communication items; ship a basic Settings surface (preferences, quotas, AI/legal copy).
3. **Design system + error UX**
   - Fill in design tokens (colors, typography, shadows), add dark mode support, and replace hardcoded colors in shared components.
   - Define a shared error/toast/alert pattern and retrofit Inbox and Capture flows to surface service errors consistently.
4. **Reliability and coverage**
   - Add UI and integration tests for happy-path capture → hand-off → organize, plus voice capture.
   - Simplify CI with reusable actions/fallback simulator selection; document SwiftData migration strategy and locale configuration (remove en-US hardcode by defaulting to system locale with override).
5. **Terminology and configuration hygiene**
   - Execute ADR-0002 terminology cleanup across views, services, repositories, tests, and docs.
   - Introduce centralized configuration for environment-specific values (API endpoints, feature flags, strings) to reduce scattered constants.
6. **ADHD-friendly UX + design system**
   - Implement the ADR-0003 guardrails: persistent capture control, undo-first patterns, calm palette/spacing tokens, shallow navigation, and optional organization prompts.
   - Respect Dynamic Type/Reduce Motion across Capture, Inbox, and Organize screens; audit tap targets and focus states in shared components.

## Remaining Work

1. **AI hand-off orchestration + backend**: Implement `submitForOrganization`, `fetchSuggestions`, `acceptSuggestion`, and `rejectSuggestion` with real backend calls and error/retry handling; stand up the backend API and `APIClient` auth/transport layer.
2. **Suggestion/placement UI**: Present suggestions in Inbox/Organize, collect decisions, and record placements targeting Plan/Task/List/Communication.
3. **Organize + Settings surfaces**: Add creation/editing flows for plans, categories, tags, lists, and communication items; replace TODOs in `OrganizeView`; ship initial Settings screen for preferences/quotas/AI disclosures.
4. **App shell alignment**: Route through `MainTabView` and align capture affordances (toolbar vs. floating action button) across screens.
5. **Terminology cleanup (ADR-0002)**: Rename Inbox surfaces, repository/service APIs (e.g., `fetchInbox`), and tests to reflect the capture → hand-off workflow; update docs/PRD to remove "Thought"/"BrainDump" references.
6. **Design system + error UX**: Finalize tokens (colors/typography/shadows), enable dark mode, and apply shared error/toast patterns to Inbox and Capture.
7. **Testing + reliability**: Add UI/integration coverage for capture → hand-off → organize flows, voice capture, and CI hardening (reusable actions, simulator fallback); document SwiftData migration approach and locale configuration.

## Success Criteria

1. Capture → hand-off → suggestion → decision → placement flow works end-to-end from the Inbox/Organize UI, backed by live API calls with retries and surfaced errors.
2. All capture/organization models remain registered in the shared and preview containers with migrations planned and documented for future schema changes.
3. Repository + workflow + UI/integration tests validate lifecycle transitions, decisions, placement recording, and voice capture paths under CI.
4. Users can create/manage destinations (plans/tasks/tags/categories/lists/communication) from Organize and configure key preferences in Settings.
5. App shell consistently exposes capture and organization entry points (tabs, floating action button, or equivalent) using shared design tokens in light/dark modes.
