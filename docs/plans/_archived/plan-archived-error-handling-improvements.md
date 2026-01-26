---
id: plan-error-handling-improvements
type: plan
status: archived
owners:
  - Will-Conklin
applies_to:
  - error
  - handling
  - improvements
last_updated: 2026-01-17
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Problem Statement; Current State; Proposed Solution; Implementation Steps; Testing Strategy; Risks & Considerations; Success Criteria; Next Steps; Related Documents."
  - "Keep the top-level section outline intact."
---

# Error Handling Improvements Plan

**Priority**: High
**Estimated Effort**: Medium
**Impact**: Critical for user experience and debugging

## Overview

Improve error handling throughout the iOS app to provide better user feedback and debugging capabilities, replacing silent failures with proper error presentation and logging.

## Problem Statement

### Current Issues

1. **Silent Failures**: Many operations use `try?` which suppresses errors
   - Example: `CaptureComposeView.swift:294` - save failures are silent
   - Users don't know when operations fail
   - Developers can't debug issues without logs

2. **Unused Error Infrastructure**:
   - `ErrorPresenter` exists but is not utilized (ErrorHandling.swift)
   - `Logger` exists but inconsistently used
   - No centralized error handling strategy

3. **No User Feedback**:
   - Failed saves don't show toasts or alerts
   - Network errors not communicated
   - Voice recording errors silently fail

## Current State

**Existing Infrastructure** (Common/ErrorHandling.swift):

```swift
@Observable class ErrorPresenter {
    var currentError: Error?
    var isShowingError = false

    func present(_ error: Error) {
        currentError = error
        isShowingError = true
    }
}
```

**Problem Pattern** (CaptureComposeView.swift:294):

```swift
try? modelContext.save()  // Silently fails
dismiss()
```

## Proposed Solution

### 1. Error Hierarchy

Create structured error types for different domains:

```swift
// Domain/Models/AppError.swift
enum AppError: LocalizedError {
    case persistence(PersistenceError)
    case validation(ValidationError)
    case voice(VoiceRecordingError)
    case network(NetworkError)

    var errorDescription: String? {
        switch self {
        case .persistence(let error): return error.localizedDescription
        case .validation(let error): return error.localizedDescription
        case .voice(let error): return error.localizedDescription
        case .network(let error): return error.localizedDescription
        }
    }
}

enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case fetchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save your changes"
        case .deleteFailed: return "Failed to delete item"
        case .fetchFailed: return "Failed to load data"
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyContent
    case invalidMetadata
    case missingRequiredField(String)

    var errorDescription: String? {
        switch self {
        case .emptyContent: return "Content cannot be empty"
        case .invalidMetadata: return "Invalid metadata format"
        case .missingRequiredField(let field): return "\(field) is required"
        }
    }
}
```

### 2. Repository Error Handling

Update all repositories to throw structured errors:

```swift
// Data/Repositories/ItemRepository.swift
@MainActor
final class ItemRepository {
    func save() throws {
        do {
            try modelContext.save()
            Logger.data.info("Successfully saved items")
        } catch {
            Logger.data.error("Failed to save items: \(error)")
            throw AppError.persistence(.saveFailed(underlying: error))
        }
    }

    func delete(_ item: Item) throws {
        do {
            modelContext.delete(item)
            try modelContext.save()
            Logger.data.info("Deleted item: \(item.id)")
        } catch {
            Logger.data.error("Failed to delete item: \(error)")
            throw AppError.persistence(.deleteFailed(underlying: error))
        }
    }
}
```

### 3. View-Level Error Presentation

Use ErrorPresenter consistently across all views:

```swift
// Features/Capture/CaptureComposeView.swift
@Environment(\.errorPresenter) private var errorPresenter

private func saveItem() {
    do {
        let item = try itemRepository.create(
            content: itemText.trimmingCharacters(in: .whitespacesAndNewlines),
            // ... other params
        )
        try itemRepository.save()
        dismiss()
    } catch {
        errorPresenter.present(error)
        Logger.ui.error("Failed to save capture: \(error)")
    }
}
```

### 4. Toast Integration

Update ErrorPresenter to show toasts for errors:

```swift
// Common/ErrorHandling.swift
@Observable class ErrorPresenter {
    var currentError: Error?
    var isShowingError = false
    var shouldShowToast = false

    func present(_ error: Error, showToast: Bool = true) {
        currentError = error
        isShowingError = true
        shouldShowToast = showToast

        Logger.shared.error("Error presented: \(error.localizedDescription)")
    }

    func dismiss() {
        currentError = nil
        isShowingError = false
        shouldShowToast = false
    }
}

// Update ToastView to listen for errors
extension ToastView {
    func observeErrors() {
        // Show toast when error is presented
    }
}
```

## Implementation Steps

### Phase 1: Infrastructure (1-2 hours)

1. Create `AppError.swift` with error hierarchy
2. Update `ErrorPresenter` with toast integration
3. Add error presentation to root view (AppRootView.swift)
4. Create environment key for ErrorPresenter injection

### Phase 2: Repository Updates (2-3 hours)

1. Update `ItemRepository` with proper error handling
2. Update `CollectionRepository` with proper error handling
3. Update `CollectionItemRepository` with proper error handling
4. Update `TagRepository` with proper error handling
5. Add validation methods to repositories

### Phase 3: View Updates (3-4 hours)

1. Update `CaptureComposeView` to use ErrorPresenter
2. Update `CaptureView` to use ErrorPresenter
3. Update `CollectionDetailView` to use ErrorPresenter
4. Update `OrganizeView` to use ErrorPresenter
5. Update all other views with try? statements

### Phase 4: Service Updates (1-2 hours)

1. Update `VoiceRecordingService` error handling
2. Update `APIClient` error handling (if applicable)
3. Add network error types and handling

### Phase 5: Testing & Polish (2-3 hours)

1. Test error scenarios (save failures, delete failures, etc.)
2. Verify error messages are user-friendly
3. Verify logs are being written correctly
4. Add unit tests for error handling paths
5. Update documentation

## Testing Strategy

### Unit Tests

```swift
// OffloadTests/ErrorHandlingTests.swift
class ErrorHandlingTests: XCTestCase {
    func testPersistenceErrorPresentation() {
        let presenter = ErrorPresenter()
        let error = AppError.persistence(.saveFailed(underlying: NSError()))

        presenter.present(error)

        XCTAssertTrue(presenter.isShowingError)
        XCTAssertNotNil(presenter.currentError)
    }

    func testRepositorySaveErrorThrows() throws {
        // Test that repository properly throws on save failure
    }
}
```

### Manual Testing Scenarios

1. **Save Failure**: Force save to fail (full disk simulation)
2. **Network Error**: Test with airplane mode
3. **Voice Error**: Test with microphone permissions denied
4. **Validation Error**: Try to save empty content
5. **Delete Error**: Test cascade delete failures

### User Acceptance Criteria

- [ ] All errors show user-friendly messages
- [ ] Toasts appear for non-critical errors
- [ ] Alerts appear for critical errors
- [ ] Errors are logged for debugging
- [ ] No silent failures remain in codebase

## Risks & Considerations

### Risks

1. **User Fatigue**: Too many error messages could be annoying
   - Mitigation: Use toasts for minor errors, alerts for critical ones

2. **Performance**: Error logging could impact performance
   - Mitigation: Use appropriate log levels, disable verbose logging in production

3. **Error Message Quality**: Generic messages aren't helpful
   - Mitigation: Write clear, actionable error messages

### Breaking Changes

- None - this is additive functionality

### Migration Considerations

- No data migration needed
- Existing code will continue to work
- Can be implemented incrementally

## Success Criteria

### Functional

- [ ] Zero uses of `try?` for operations that users should know about
- [ ] All repository methods throw structured errors
- [ ] All views handle errors from repositories
- [ ] ErrorPresenter is injected and used consistently
- [ ] Toasts show for minor errors
- [ ] Alerts show for critical errors

### Non-Functional

- [ ] Error messages are clear and actionable
- [ ] Logs include sufficient context for debugging
- [ ] No performance degradation from error handling
- [ ] Code coverage for error paths >80%

### User Experience

- [ ] Users understand when operations fail
- [ ] Users know what to do when errors occur
- [ ] App doesn't crash due to unhandled errors
- [ ] Error recovery is smooth (e.g., retry options)

## Next Steps

1. Review this plan with team
2. Get approval for error message copy
3. Implement Phase 1 (infrastructure)
4. Create PR for review
5. Proceed with remaining phases

## Related Documents

- `AGENTS.md` - Architecture overview
- `docs/adrs/adr-0001-technology-stack-and-architecture.md` - Technology choices
- `ios/Offload/Common/ErrorHandling.swift` - Current error handling
- `ios/Offload/Common/Logger.swift` - Logging infrastructure
