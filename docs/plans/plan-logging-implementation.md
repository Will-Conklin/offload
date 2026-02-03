---
id: plan-logging-implementation
type: plan
status: accepted
owners:
  - Will-Conklin
applies_to:
  - plans
last_updated: 2026-01-25
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Comprehensive Logging Implementation (Proposed)

## Overview

Proposed plan to expand OSLog coverage to diagnose crashes on physical devices
using the existing `wc.Offload` subsystem. This plan focuses on sequencing and
execution for logging coverage across critical paths and user workflows.

Execution notes:

- Scope: Implementation across all 5 phases; OSLog only (no third-party crash
  reporting).
- Existing categories: `general`, `persistence`, `networking`, `voice`,
  `workflow`.
- Current coverage: limited (~6 log statements across 3 files).

Logging standards:

- Log levels:
  - `.debug`: Development details (offsets, intermediate states)
  - `.info`: Notable operations (user actions, completions)
  - `.warning`: Recoverable issues
  - `.error`: Failures needing attention
  - `.critical`: App-threatening issues (before `fatalError`)
- Privacy annotations:
  - Safe for logs (IDs, counts, status)
  - User content is redacted by default

Example patterns:

```swift
// Repository CRUD
func delete(_ item: Item) throws {
    let itemId = item.id
    AppLogger.persistence.debug("Deleting item - id: \(itemId, privacy: .public)")
    modelContext.delete(item)
    do {
        try modelContext.save()
        AppLogger.persistence.info("Item deleted - id: \(itemId, privacy: .public)")
    } catch {
        AppLogger.persistence.error("Delete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
        throw error
    }
}

// ViewModel pagination
func loadNextPage(using repository: ItemRepository) throws {
    AppLogger.workflow.debug("Fetching page - offset: \(offset, privacy: .public)")
    let page = try repository.fetchCaptureItems(limit: pageSize, offset: offset)
    AppLogger.workflow.debug("Page loaded - count: \(page.count, privacy: .public), hasMore: \(hasMore, privacy: .public)")
}
```

## Goals

- Provide sufficient logging to diagnose crashes on physical devices.
- Ensure logging coverage for critical error paths, repositories, view models,
  lifecycle events, and key user actions.
- Standardize log levels and privacy usage across the codebase.

## Phases

### Phase 1: Critical Error Paths (Priority: Highest)

**Status:** Not Started

- [ ] PersistenceController: log before `fatalError` in production container.
  - File: `ios/Offload/Data/Persistence/PersistenceController.swift`
  - Line: 35
- [ ] PersistenceController: log before `fatalError` in preview container.
  - File: `ios/Offload/Data/Persistence/PersistenceController.swift`
  - Line: 126
- [ ] ErrorPresenter: log all presented errors in `present(_ error:)`.
  - File: `ios/Offload/Common/ErrorHandling.swift`
  - Line: 15-17
- [ ] Repository CRUD logging with error handling.
  - `ios/Offload/Data/Repositories/ItemRepository.swift`
    - `create()`, `delete()`, `deleteAll()`, `update()`
  - `ios/Offload/Data/Repositories/CollectionRepository.swift`
    - `create()`, `delete()`, `update()`
  - `ios/Offload/Data/Repositories/CollectionItemRepository.swift`
    - `addItemToCollection()`, `removeItemFromCollection()`
  - `ios/Offload/Data/Repositories/TagRepository.swift`
    - `create()`, `delete()`, `findOrCreate()`

### Phase 2: VoiceRecordingService (Priority: High)

**Status:** Not Started

- [ ] `requestPermissions()` logs permission outcomes.
- [ ] `startRecording()` logs audio session setup, recognition task start, and
  errors.
- [ ] `stopRecording()` logs duration and transcription length.
- [ ] `cancelRecording()` logs cancellation.

Files:

- `ios/Offload/Data/Services/VoiceRecordingService.swift`

### Phase 3: ViewModel State Transitions (Priority: Medium)

**Status:** Not Started

Add pagination and state change logging:

- `ios/Offload/Features/Capture/CaptureListViewModel.swift`
  - `loadInitial()`, `loadNextPage()`, `remove()`, `reset()`
- `ios/Offload/Features/Organize/OrganizeListViewModel.swift`
  - `setScope()`, `loadNextPage()`, `refresh()`
- `ios/Offload/Features/Organize/CollectionDetailViewModel.swift`
  - `setCollection()`, `loadNextPage()`, `remove()`

### Phase 4: App Lifecycle (Priority: Medium)

**Status:** Not Started

- [ ] `offloadApp.swift`: log app version on init.
- [ ] `AppRootView.swift`: log repository initialization.

Files:

- `ios/Offload/App/offloadApp.swift`
- `ios/Offload/App/AppRootView.swift`

### Phase 5: User Actions in Views (Priority: Lower)

**Status:** Not Started

- `ios/Offload/Features/Capture/CaptureView.swift`
  - `deleteItem()`, `completeItem()`, `toggleStar()`
- `ios/Offload/Features/Capture/CaptureComposeView.swift`
  - `handleVoice()`, `save()`

Verification (post-phase checklist):

- Access logs on device via Console.app, `log stream`, or Xcode console.
- Manual QA checklist:
  - App launch logs version info.
  - Create item logs success with ID.
  - Delete item logs success.
  - Voice recording logs permission requests and outcomes.
  - Voice recording logs start/stop with duration.
  - Pagination logs offset and count.
  - Errors display toast and log to console.
  - `fatalError` paths log critical message before crash.
- Crash diagnosis scenarios:
  - Kill app during voice recording; verify logs show state.
  - Create/delete items rapidly; verify CRUD logs.
  - Navigate between tabs; verify pagination logs.
- Deny microphone permission; verify denial logged.

## Dependencies

- Existing OSLog infrastructure with subsystem `wc.Offload`.
- Logging category definitions in AppLogger.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Log noise reduces signal | M | Follow log level guidance and avoid overusing `.debug` in production paths. |
| Sensitive data exposed | H | Use privacy annotations; keep user content `.private`. |
| Missed crash context | M | Prioritize Phase 1 coverage and verify fatal paths. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Drafted proposed plan for review. |
