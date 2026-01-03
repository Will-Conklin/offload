<!-- Intent: Keep the capture/organization model plan aligned with the current codebase and call out remaining gaps. -->

# Plan: Capture Event-Sourced Model

## Current State (January 2026)

- **Models shipped**: CaptureEntry + HandOffRequest/Run, Suggestion + SuggestionDecision, Placement, Plan, Task, Tag, Category, ListEntity/ListItem, CommunicationItem (`ios/Offload/Domain/Models/`).
- **Persistence**: `PersistenceController` and `SwiftDataManager` register the full schema for production and preview containers.
- **Data access**: Repositories exist for every model, plus `CaptureWorkflowService` for inbox + capture orchestration.
- **UI**: Inbox reads from `CaptureWorkflowService`; `CaptureSheetView` handles text + voice capture. Organize and settings flows remain placeholder-only.
- **Tests**: Repository + workflow tests cover current CRUD/lifecycle behaviors with in-memory SwiftData.
- **Not implemented**: AI hand-off submission, suggestion presentation/decisions, placement flows, and richer organization UI. These methods are stubbed in `CaptureWorkflowService` and TODOs remain across Organize/Settings.

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

## Implementation Status by Phase

- **Phase 1 — Model Definition**: ✅ Complete with enum rawValue storage for SwiftData compatibility.
- **Phase 2 — Persistence Configuration**: ✅ `PersistenceController` + `SwiftDataManager` schemas updated; preview data seeded for captures/plans/tasks.
- **Phase 3 — Repository Implementation**: ✅ Capture, HandOff, Suggestion, Placement, Plan, Task, Tag, Category, List, and Communication repositories added with CRUD + lifecycle helpers.
- **Phase 4 — Service Integration**: 🚧 `CaptureWorkflowService` only implements capture, archive/delete, inbox/ready queries. AI hand-off, suggestion fetching, acceptance/rejection, and placement remain stubbed.
- **Phase 5 — Testing**: ✅ In-memory SwiftData tests cover repositories and workflow capture/inbox behaviors. No tests yet for AI submission or placement.
- **Phase 6 — UI Integration**: 🚧 Inbox wired to `CaptureWorkflowService`; CaptureSheetView uses voice + text; Organize tab has static lists and TODO add actions; Settings tab is placeholder; MainTabView exists but AppRoot currently routes directly to Inbox.

## Remaining Work

1. **AI hand-off orchestration**: Implement `submitForOrganization`, `fetchSuggestions`, `acceptSuggestion`, and `rejectSuggestion` in `CaptureWorkflowService`, plus supporting repository calls.
2. **Suggestion/placement UI**: Present suggestions in Inbox/Organize, collect decisions, and record placements targeting Plan/Task/List/Communication.
3. **Organize surfaces**: Add creation/editing flows for plans, categories, tags, lists, and communication items; replace TODOs in `OrganizeView`.
4. **App shell alignment**: Decide on `MainTabView` adoption vs. direct Inbox, add Settings screen, and ensure capture affordances are consistent across entry points.
5. **Testing expansion**: Add coverage for AI orchestration, placement flows, and new UI interactions once built.

## Success Criteria

1. Capture → hand-off → suggestion → decision → placement flow works end-to-end from the Inbox/Organize UI.
2. All capture/organization models remain registered in the shared and preview containers with migrations planned for future schema changes.
3. Repository + workflow tests validate lifecycle transitions, decisions, and placement recording.
4. Users can create/manage destinations (plans/tasks/tags/categories/lists/communication) from Organize.
5. App shell consistently exposes capture and organization entry points (tabs, floating action button, or equivalent).
