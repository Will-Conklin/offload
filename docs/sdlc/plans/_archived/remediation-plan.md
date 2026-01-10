<!-- Intent: Track critical remediation scope, priorities, and fix guidance for Offload releases. -->

> **⚠️ DEPRECATED:** This document has been superseded by [master-plan.md](./master-plan.md) as of January 9, 2026.
> Please refer to the master plan for the single source of truth on all implementation planning.

# Critical Issues Remediation Plan
**Created:** January 6, 2026
**Status:** Active remediation (Phase 2 in progress)
**Priority:** CRITICAL - Production Blockers
**Last Updated:** January 8, 2026

## Executive Summary

Based on the comprehensive adversarial security review, this codebase has **8 critical** and **12 high-priority** issues that block production release. This remediation plan provides a phased approach to fix these issues while maintaining development velocity.

**Estimated Effort:** 4-6 weeks
**Risk if Not Fixed:** Data corruption, crashes, silent failures, security vulnerabilities

## Implementation Update (January 8, 2026)

**Completed**
- Inbox deletion race condition fixed in `CapturesView` (serialized deletes + single refresh).
- `try?` save suppression removed across capture, organize, settings, and persistence flows with rollback/error messaging.
- Repository queries converted to predicate-based fetches (Capture, HandOff, Task, Suggestion decision queries).
- `CaptureEntry.acceptedSuggestion` relationship added to replace orphaned UUID usage.
- URL handling hardened (API client guards, Settings static URLs, API endpoint validation).
- Capture workflow synchronization tightened with `@MainActor` state ownership and explicit `internal(set)` access.
- Repository protocols added for DI.
- Permission caching added for voice recording.
- FormSheet component extracted and adopted across organize/settings flows.
- Logger scaffolding added and integrated across services.
- Repository + workflow tests added for core data flows.

**Remaining**
- Toast dismissal cancellation handling (still uses `try? Task.sleep`, cancellation guard missing).
- Fetch optimization for pending suggestions remains in-memory due to SwiftData relationship limits (denormalization candidate).
- Additional testing evidence/benchmarks for performance and error-path coverage.

---

## Issue Summary

| Severity | Count | Must Fix Before Production |
|----------|-------|---------------------------|
| CRITICAL | 8 | ✓ Yes |
| HIGH | 12 | ✓ Yes |
| MEDIUM | 18 | Recommended |
| LOW | 15 | Nice to have |

---

## PHASE 1: CRITICAL FIXES (Week 1-2)
**Goal:** Eliminate production blockers - data corruption and crashes

### 1.1 Fix CapturesView (Inbox) Race Condition ⚠️ CRITICAL

**File:** `ios/Offload/Features/Inbox/CapturesView.swift:70-99`
**Issue:** Multiple concurrent delete tasks causing data corruption
**Priority:** P0 - Must fix first

#### Current Code (BROKEN):
```swift
private func deleteEntries(offsets: IndexSet) {
    guard let workflowService = workflowService else { return }

    withAnimation {
        for index in offsets {
            let entry = entries[index]
            _Concurrency.Task {  // ⚠️ Creates N concurrent tasks
                do {
                    try await workflowService.deleteEntry(entry)
                    await loadInbox()  // ⚠️ All tasks reload concurrently
                } catch {
                    // Error handling
                }
            }
        }
    }
}
```

#### Fixed Code:
```swift
private func deleteEntries(offsets: IndexSet) {
    guard let workflowService = workflowService else { return }

    // Capture entries to delete BEFORE async operation
    let entriesToDelete = offsets.map { entries[$0] }

    _Concurrency.Task {
        do {
            // Serialize deletions
            for entry in entriesToDelete {
                try await workflowService.deleteEntry(entry)
            }

            // Single reload after all deletions complete
            await loadInbox()
        } catch {
            // Show error to user via toast or alert
            errorMessage = error.localizedDescription
        }
    }
}
```

**Testing:**
- [ ] Test deleting single item
- [ ] Test deleting multiple items (2, 5, 10)
- [ ] Test rapid delete operations
- [ ] Verify UI updates only once after completion
- [ ] Test error handling when deletion fails midway

---

### 1.2 Eliminate Silent Error Suppression (21 instances) ⚠️ CRITICAL

**Files Affected:**
- `OrganizeView.swift` (5 instances)
- `ListDetailView.swift` (5 instances)
- `PlanDetailView.swift` (3 instances)
- `SettingsView.swift` (3 instances)
- Others (5 instances)

**Issue:** `try?` swallows errors, causing silent data loss
**Priority:** P0

#### Pattern to Replace:

**BEFORE (BROKEN):**
```swift
private func addQuickItem() {
    let item = ListItem(text: trimmed, list: list)
    modelContext.insert(item)
    try? modelContext.save()  // ⚠️ Silent failure
    newItemText = ""
}
```

**AFTER (FIXED):**
```swift
@Environment(\.toastManager) private var toastManager  // Inject toast manager

private func addQuickItem() {
    let item = ListItem(text: trimmed, list: list)
    modelContext.insert(item)

    do {
        try modelContext.save()
        newItemText = ""
        toastManager.show("Item added", type: .success)
    } catch {
        modelContext.rollback()
        toastManager.show("Failed to save: \(error.localizedDescription)", type: .error)
    }
}
```

#### Alternative Pattern (for forms with errorMessage state):
```swift
private func handleSave() {
    do {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ValidationError("Title is required")
        }

        try onSave(trimmedTitle, detail)
        dismiss()
    } catch {
        errorMessage = error.localizedDescription  // Show inline in form
    }
}
```

#### Implementation Checklist:
- [ ] Replace all 21 `try?` instances
- [ ] Add toast notifications for background operations
- [ ] Add inline error messages for forms
- [ ] Add modelContext.rollback() on save failures
- [ ] Test each error path

**Files to Update:**
1. `OrganizeView.swift:301,309,317,336,364`
2. `ListDetailView.swift:155,165,173,181,186`
3. `PlanDetailView.swift:175,184,189`
4. `SettingsView.swift:248,264,521`
5. `PersistenceController.swift:137`
6. `VoiceRecordingService.swift:148`
7. `ToastView.swift:96`

---

### 1.3 Fix N+1 Query Problems ⚠️ CRITICAL

**Files Affected:**
- `CaptureRepository.swift`
- `SuggestionRepository.swift`
- `TaskRepository.swift`
- `HandOffRepository.swift`

**Issue:** All queries fetch entire tables then filter in-memory
**Priority:** P0

#### Fix Template for Each Repository:

**BEFORE (BROKEN):**
```swift
func fetchInbox() throws -> [CaptureEntry] {
    let all = try fetchAll()  // ⚠️ Loads ALL entries
    return all.filter { $0.currentLifecycleState == .raw }  // ⚠️ Filter in memory
}
```

**AFTER (FIXED):**
```swift
func fetchInbox() throws -> [CaptureEntry] {
    let predicate = #Predicate<CaptureEntry> { entry in
        entry.currentLifecycleState == .raw
    }

    var descriptor = FetchDescriptor<CaptureEntry>(
        predicate: predicate,
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )

    return try modelContext.fetch(descriptor)
}
```

#### CaptureRepository Methods to Fix:
```swift
// 1. fetchInbox()
func fetchInbox() throws -> [CaptureEntry] {
    let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == .raw }
    var descriptor = FetchDescriptor<CaptureEntry>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}

// 2. fetchByState(_ state: LifecycleState)
func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry] {
    let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == state }
    var descriptor = FetchDescriptor<CaptureEntry>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}

// 3. fetchReady()
func fetchReady() throws -> [CaptureEntry] {
    let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == .ready }
    var descriptor = FetchDescriptor<CaptureEntry>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}
```

#### SuggestionRepository Methods to Fix:
```swift
// 1. fetchSuggestionsByKind(_ kind: SuggestionKind)
func fetchSuggestionsByKind(_ kind: SuggestionKind) throws -> [Suggestion] {
    let predicate = #Predicate<Suggestion> { $0.suggestionKind == kind }
    var descriptor = FetchDescriptor<Suggestion>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}

// 2. fetchPendingSuggestionsForEntry(_ entryId: UUID) - Complex case
func fetchPendingSuggestionsForEntry(_ entryId: UUID) throws -> [Suggestion] {
    // Note: This requires relationship traversal - may need in-memory filter
    // But fetch only suggestions for this entry first
    let allSuggestions = try fetchAllSuggestions()

    // Filter for entry
    let entrySuggestions = allSuggestions.filter { suggestion in
        suggestion.handOffRun?.handOffRequest?.captureEntry?.id == entryId
    }

    // Filter for pending (no accepted decision)
    return entrySuggestions.filter { suggestion in
        guard let decisions = suggestion.decisions else { return true }
        return !decisions.contains { $0.decisionType == .accepted }
    }
}
// TODO: Consider denormalizing entryId onto Suggestion for efficient querying

// 3. fetchDecisionsByType(_ type: DecisionType)
func fetchDecisionsByType(_ type: DecisionType) throws -> [SuggestionDecision] {
    let predicate = #Predicate<SuggestionDecision> { $0.decisionType == type }
    var descriptor = FetchDescriptor<SuggestionDecision>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}
```

#### TaskRepository Methods to Fix:
```swift
// 1. fetchByPlan(_ plan: Plan)
func fetchByPlan(_ plan: Plan) throws -> [Task] {
    let planId = plan.id
    let predicate = #Predicate<Task> { task in
        task.plan?.id == planId
    }
    var descriptor = FetchDescriptor<Task>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}

// 2. fetchByCategory(_ category: Category)
func fetchByCategory(_ category: Category) throws -> [Task] {
    let categoryId = category.id
    let predicate = #Predicate<Task> { task in
        task.category?.id == categoryId
    }
    var descriptor = FetchDescriptor<Task>(predicate: predicate)
    return try modelContext.fetch(descriptor)
}
```

**Testing:**
- [ ] Benchmark queries with 100, 1000, 10000 records
- [ ] Verify correct results for each method
- [ ] Test with empty database
- [ ] Test with nil relationships

---

### 1.4 Fix Orphaned Foreign Key - acceptedSuggestionId ⚠️ CRITICAL

**File:** `ios/Offload/Domain/Models/CaptureEntry.swift:23`
**Issue:** UUID field instead of proper relationship, no referential integrity
**Priority:** P0

**BEFORE (BROKEN):**
```swift
@Model
final class CaptureEntry {
    var id: UUID
    // ... other fields
    var acceptedSuggestionId: UUID?  // ⚠️ Not a relationship

    @Relationship(deleteRule: .cascade, inverse: \HandOffRequest.captureEntry)
    var handOffRequests: [HandOffRequest]?
}
```

**AFTER (FIXED):**
```swift
@Model
final class CaptureEntry {
    var id: UUID
    // ... other fields

    @Relationship(deleteRule: .nullify)
    var acceptedSuggestion: Suggestion?  // ✓ Proper relationship

    @Relationship(deleteRule: .cascade, inverse: \HandOffRequest.captureEntry)
    var handOffRequests: [HandOffRequest]?
}
```

**Migration Required:**
```swift
// In PersistenceController or migration handler
func migrateAcceptedSuggestionIds() throws {
    let entries = try modelContext.fetch(FetchDescriptor<CaptureEntry>())

    for entry in entries {
        if let oldId = entry.acceptedSuggestionId {
            // Fetch suggestion by ID
            let predicate = #Predicate<Suggestion> { $0.id == oldId }
            let descriptor = FetchDescriptor<Suggestion>(predicate: predicate)

            if let suggestion = try modelContext.fetch(descriptor).first {
                entry.acceptedSuggestion = suggestion
            }
            // Remove old field (mark as deprecated first)
        }
    }

    try modelContext.save()
}
```

**Code Updates Required:**
- [ ] Update CaptureEntry model
- [ ] Find all uses of acceptedSuggestionId (grep)
- [ ] Replace with acceptedSuggestion relationship
- [ ] Update queries and filters
- [ ] Write migration
- [ ] Test migration with sample data

---

### 1.5 Remove Force Unwraps on URLs ⚠️ CRITICAL

**Files:**
- `SettingsView.swift:212, 578, 685`
- `APIClient.swift:24`

**Issue:** Force unwrap will crash if URL creation fails
**Priority:** P0

**BEFORE (BROKEN):**
```swift
Link(destination: URL(string: "https://github.com/Will-Conklin/offload")!) {
    Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
}
```

**AFTER (FIXED - Option 1: Static constant):**
```swift
// At top of file or in constants file
private enum Constants {
    static let githubURL = URL(string: "https://github.com/Will-Conklin/offload")!
    static let issuesURL = URL(string: "https://github.com/Will-Conklin/offload/issues")!
}

// In view
Link(destination: Constants.githubURL) {
    Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
}
```

**AFTER (FIXED - Option 2: Safe unwrap):**
```swift
if let githubURL = URL(string: "https://github.com/Will-Conklin/offload") {
    Link(destination: githubURL) {
        Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
    }
} else {
    // Fallback UI or just text
    Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
        .foregroundStyle(.secondary)
}
```

**For APIClient.swift:24:**
```swift
// BEFORE
self.baseURL = URL(string: "https://api.offload.app")!

// AFTER - Option 1: Fatal error with clear message
guard let baseURL = URL(string: "https://api.offload.app") else {
    fatalError("Invalid base URL configuration - this is a programmer error")
}
self.baseURL = baseURL

// AFTER - Option 2: Configurable with validation
struct APIConfiguration {
    static let baseURLString = "https://api.offload.app"

    static var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL: \(baseURLString)")
        }
        return url
    }
}

private init() {
    // ...
    self.baseURL = APIConfiguration.baseURL
}
```

**Testing:**
- [ ] Verify all links work
- [ ] Test with malformed URLs (unit test)
- [ ] Ensure no force unwraps remain (grep for `URL(.*?)!`)

---

### 1.6 Fix ToastView Task Cancellation ⚠️ CRITICAL

**File:** `ios/Offload/DesignSystem/ToastView.swift:87-102`
**Issue:** Incorrect use of Task.isCancelled - checking type not instance
**Priority:** P0

**BEFORE (BROKEN):**
```swift
func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
    dismissTask?.cancel()
    currentToast = Toast(message: message, type: type)

    dismissTask = _Concurrency.Task {
        try? await _Concurrency.Task.sleep(for: .seconds(duration))
        if !_Concurrency.Task.isCancelled {  // ⚠️ Wrong - checks type, not instance
            await MainActor.run {
                currentToast = nil
            }
        }
    }
}
```

**AFTER (FIXED):**
```swift
func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
    // Cancel previous toast
    dismissTask?.cancel()
    currentToast = Toast(message: message, type: type)

    dismissTask = _Concurrency.Task { [weak self] in
        guard let self else { return }

        do {
            try await _Concurrency.Task.sleep(for: .seconds(duration))

            // Check if THIS task was cancelled
            guard !_Concurrency.Task.isCancelled else { return }

            await MainActor.run {
                self.currentToast = nil
            }
        } catch is CancellationError {
            // Task was cancelled, ignore
            return
        } catch {
            // Other error, log it
            print("Toast auto-dismiss error: \(error)")
        }
    }
}
```

**Even Better - Structured Concurrency:**
```swift
func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
    dismissTask?.cancel()
    currentToast = Toast(message: message, type: type)

    dismissTask = _Concurrency.Task { @MainActor [weak self] in
        guard let self else { return }

        do {
            try await _Concurrency.Task.sleep(for: .seconds(duration))
            self.currentToast = nil
        } catch is CancellationError {
            // Expected when showing new toast before previous dismisses
        }
    }
}
```

**Testing:**
- [ ] Show toast and wait for auto-dismiss
- [ ] Show multiple toasts rapidly (test cancellation)
- [ ] Verify no memory leaks with weak self
- [ ] Test dismiss() method cancels task

---

### 1.7 Fix MainActor Synchronization in CaptureWorkflowService ⚠️ CRITICAL

**File:** `ios/Offload/Data/Services/CaptureWorkflowService.swift`
**Issue:** @MainActor service with shared mutable state accessed from background
**Priority:** P0

**BEFORE (BROKEN):**
```swift
@Observable
@MainActor
final class CaptureWorkflowService {
    var isProcessing = false  // ⚠️ Race condition risk
    var errorMessage: String?

    func captureEntry(...) async throws -> CaptureEntry {
        defer { isProcessing = false }  // ⚠️ Not atomic

        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }
        isProcessing = true
        // ...
    }
}
```

**AFTER (FIXED - Option 1: Actor isolation):**
```swift
@Observable
@MainActor
final class CaptureWorkflowService {
    private(set) var isProcessing = false
    private(set) var errorMessage: String?

    func captureEntry(...) async throws -> CaptureEntry {
        // Atomic check and set on MainActor
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }
        isProcessing = true

        defer {
            _Concurrency.Task { @MainActor in
                self.isProcessing = false
            }
        }

        do {
            // Actual work
            let entry = CaptureEntry(...)
            // ...
            return entry
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
}
```

**AFTER (FIXED - Option 2: Remove @MainActor, use explicit isolation):**
```swift
@Observable
final class CaptureWorkflowService {
    @MainActor private(set) var isProcessing = false
    @MainActor private(set) var errorMessage: String?

    func captureEntry(...) async throws -> CaptureEntry {
        // Check on main thread
        let currentlyProcessing = await MainActor.run { isProcessing }
        guard !currentlyProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        await MainActor.run { isProcessing = true }
        defer {
            _Concurrency.Task { @MainActor in
                self.isProcessing = false
            }
        }

        // Background work
        let entry = CaptureEntry(...)
        try captureRepo.create(entry: entry)

        // More work...
        return entry
    }
}
```

**Testing:**
- [ ] Test concurrent capture attempts
- [ ] Verify isProcessing flag correctness
- [ ] Test error message updates
- [ ] Benchmark performance impact

---

### 1.8 Add Input Validation for API Endpoint ⚠️ CRITICAL (Security)

**File:** `ios/Offload/Features/Settings/SettingsView.swift:322-325`
**Issue:** No validation on API endpoint, MITM attack possible
**Priority:** P0

**BEFORE (BROKEN):**
```swift
private struct APIConfigurationView: View {
    @Binding var apiEndpoint: String
    @State private var tempEndpoint: String = ""

    var body: some View {
        Form {
            Section {
                TextField("URL", text: $tempEndpoint)  // ⚠️ No validation
                    .keyboardType(.URL)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    apiEndpoint = tempEndpoint  // ⚠️ No validation
                    dismiss()
                }
            }
        }
    }
}
```

**AFTER (FIXED):**
```swift
private struct APIConfigurationView: View {
    @Binding var apiEndpoint: String
    @State private var tempEndpoint: String = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextField("URL", text: $tempEndpoint)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } footer: {
                Text("Must be a valid HTTPS URL")
                    .font(.caption)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    handleSave()
                }
            }
        }
    }

    private func handleSave() {
        errorMessage = nil

        // Validate URL
        let trimmed = tempEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "URL cannot be empty"
            return
        }

        guard let url = URL(string: trimmed) else {
            errorMessage = "Invalid URL format"
            return
        }

        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            errorMessage = "URL must use HTTPS for security"
            return
        }

        guard let host = url.host, !host.isEmpty else {
            errorMessage = "URL must have a valid hostname"
            return
        }

        // Optional: Additional validation
        guard trimmed.count <= 200 else {
            errorMessage = "URL is too long (max 200 characters)"
            return
        }

        // Valid - save and dismiss
        apiEndpoint = trimmed
        dismiss()
    }
}
```

**Testing:**
- [ ] Test valid HTTPS URL (success)
- [ ] Test HTTP URL (rejected)
- [ ] Test malformed URL (rejected)
- [ ] Test empty URL (rejected)
- [ ] Test URL without scheme (rejected)
- [ ] Test very long URL (rejected)

---

## PHASE 2: HIGH PRIORITY FIXES (Week 3-4)
**Goal:** Improve data integrity and eliminate common bugs

### 2.1 Convert Task.category to Proper Relationship

**File:** `ios/Offload/Domain/Models/Task.swift:28`
**Priority:** P1

**BEFORE:**
```swift
var category: Category?  // ⚠️ Not a @Relationship
```

**AFTER:**
```swift
@Relationship(deleteRule: .nullify)
var category: Category?
```

---

### 2.2 Fix Array Index Out of Bounds in Delete Operations

**Files:**
- `ListDetailView.swift:160-174`
- `PlanDetailView.swift:169-185`

**Priority:** P1

**BEFORE (BROKEN):**
```swift
private func deleteUncheckedItems(offsets: IndexSet) {
    for index in offsets {
        let item = uncheckedItems[index]  // ⚠️ Index into computed property
        modelContext.delete(item)
    }
    try? modelContext.save()
}
```

**AFTER (FIXED):**
```swift
private func deleteUncheckedItems(offsets: IndexSet) {
    // Capture items to delete before modifying
    let itemsToDelete = offsets.map { uncheckedItems[$0] }

    for item in itemsToDelete {
        modelContext.delete(item)
    }

    do {
        try modelContext.save()
    } catch {
        modelContext.rollback()
        errorMessage = "Failed to delete items: \(error.localizedDescription)"
    }
}
```

---

### 2.3 Standardize Error Handling Pattern

**Priority:** P1

Create centralized error handling:

```swift
// New file: ios/Offload/Common/ErrorHandling.swift
import SwiftUI

@Observable
@MainActor
class ErrorPresenter {
    var currentError: PresentableError?

    func present(_ error: Error) {
        currentError = PresentableError(error: error)
    }

    func clear() {
        currentError = nil
    }
}

struct PresentableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actions: [ErrorAction]

    init(error: Error) {
        if let workflowError = error as? WorkflowError {
            self.title = "Operation Failed"
            self.message = workflowError.localizedDescription
            self.actions = [.dismiss]
        } else if let validationError = error as? ValidationError {
            self.title = "Validation Error"
            self.message = validationError.message
            self.actions = [.dismiss]
        } else {
            self.title = "Error"
            self.message = error.localizedDescription
            self.actions = [.dismiss, .retry]
        }
    }
}

enum ErrorAction {
    case dismiss
    case retry
    case contact
}
```

---

### 2.4 Add Repository Protocols for Dependency Injection

**Priority:** P1

```swift
// New file: ios/Offload/Data/Repositories/RepositoryProtocol.swift

protocol CaptureRepositoryProtocol {
    func create(entry: CaptureEntry) throws
    func fetchAll() throws -> [CaptureEntry]
    func fetchInbox() throws -> [CaptureEntry]
    func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry]
    func update(entry: CaptureEntry) throws
    func delete(entry: CaptureEntry) throws
}

// Then update CaptureRepository to implement protocol
extension CaptureRepository: CaptureRepositoryProtocol {}

// Update CaptureWorkflowService to use protocol
final class CaptureWorkflowService {
    private let captureRepo: CaptureRepositoryProtocol

    init(
        modelContext: ModelContext,
        captureRepo: CaptureRepositoryProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.captureRepo = captureRepo ?? CaptureRepository(modelContext: modelContext)
    }
}
```

---

### 2.5 Fix Permission Request Pattern

**File:** `ios/Offload/Data/Services/VoiceRecordingService.swift`
**Priority:** P1

Add permission caching:

```swift
private var cachedMicrophonePermission: Bool?
private var cachedSpeechPermission: Bool?

func checkPermissions() -> Bool {
    // Check cached values first
    if let mic = cachedMicrophonePermission,
       let speech = cachedSpeechPermission {
        return mic && speech
    }

    // Update cache
    let micStatus = AVAudioApplication.shared.recordPermission
    cachedMicrophonePermission = (micStatus == .granted)

    // For speech, check authorization status
    let speechStatus = SFSpeechRecognizer.authorizationStatus()
    cachedSpeechPermission = (speechStatus == .authorized)

    return (cachedMicrophonePermission ?? false) && (cachedSpeechPermission ?? false)
}
```

---

## PHASE 3: ARCHITECTURE IMPROVEMENTS (Week 5-6)
**Goal:** Reduce technical debt, improve maintainability

### 3.1 Extract Generic FormSheet Component

**Priority:** P2

Create reusable form component to eliminate 400+ lines of duplication:

```swift
// New file: ios/Offload/DesignSystem/FormSheet.swift

struct FormSheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let saveButtonTitle: String
    let isSaveDisabled: Bool
    let onSave: () async throws -> Void
    @ViewBuilder let content: () -> Content

    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                content()

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Theme.Typography.errorText)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        handleSave()
                    }
                    .disabled(isSaveDisabled || isSaving)
                }
            }
        }
    }

    private func handleSave() {
        isSaving = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                try await onSave()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// Usage example:
struct CreatePlanSheet: View {
    @State private var title = ""
    @State private var detail = ""

    let onCreate: (String, String?) async throws -> Void

    var body: some View {
        FormSheet(
            title: "New Plan",
            saveButtonTitle: "Create",
            isSaveDisabled: title.isEmpty,
            onSave: {
                try await onCreate(title, detail.isEmpty ? nil : detail)
            }
        ) {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Description (optional)", text: $detail, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
}
```

---

### 3.2 Add Comprehensive Test Suite

**Priority:** P2

Create test files for critical paths:

```swift
// Tests/OffloadTests/CaptureWorkflowServiceTests.swift
import XCTest
import SwiftData
@testable import Offload

@MainActor
final class CaptureWorkflowServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: CaptureWorkflowService!

    override func setUp() async throws {
        // In-memory container for testing
        let schema = Schema([
            CaptureEntry.self,
            HandOffRequest.self,
            // ... other models
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        service = CaptureWorkflowService(modelContext: modelContext)
    }

    func testCaptureEntry_CreatesEntry() async throws {
        // Given
        let text = "Test entry"

        // When
        let entry = try await service.captureEntry(
            rawText: text,
            inputType: .text,
            audioURL: nil
        )

        // Then
        XCTAssertEqual(entry.rawText, text)
        XCTAssertEqual(entry.entryInputType, .text)
        XCTAssertEqual(entry.currentLifecycleState, .raw)
    }

    func testCaptureEntry_PreventsSimultaneousProcessing() async throws {
        // Given
        let text = "Test"

        // When - start two concurrent operations
        async let entry1 = service.captureEntry(rawText: text, inputType: .text, audioURL: nil)
        async let entry2 = service.captureEntry(rawText: text, inputType: .text, audioURL: nil)

        // Then - one should fail
        do {
            _ = try await entry1
            _ = try await entry2
            XCTFail("Should have thrown error for concurrent processing")
        } catch WorkflowError.alreadyProcessing {
            // Expected
        }
    }
}
```

---

### 3.3 Add Logging and Monitoring

**Priority:** P2

```swift
// New file: ios/Offload/Common/Logger.swift
import OSLog

enum AppLogger {
    static let subsystem = "com.offload.app"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let voice = Logger(subsystem: subsystem, category: "voice")
    static let workflow = Logger(subsystem: subsystem, category: "workflow")
}

// Usage:
func captureEntry(...) async throws -> CaptureEntry {
    AppLogger.workflow.info("Starting capture entry workflow")

    // ... work

    AppLogger.workflow.debug("Created entry with ID: \(entry.id)")
    return entry
}
```

---

## PHASE 4: TESTING & VALIDATION (Ongoing)
**Goal:** Ensure fixes work and prevent regressions

### Test Checklist

#### Unit Tests
- [ ] Repository query tests (verify predicates work)
- [ ] Validation logic tests
- [ ] Error handling tests
- [ ] URL validation tests
- [ ] Permission caching tests

#### Integration Tests
- [ ] Full capture workflow
- [ ] Delete operations with multiple items
- [ ] Concurrent operations
- [ ] Save/rollback behavior
- [ ] Relationship integrity

#### Manual Testing
- [ ] Delete single item from inbox
- [ ] Delete multiple items from inbox
- [ ] Rapid delete operations
- [ ] Form validation (empty, invalid, valid)
- [ ] Error display (toast + inline)
- [ ] API endpoint validation
- [ ] Permission requests
- [ ] Voice recording lifecycle

#### Performance Testing
- [ ] Query performance with 1000+ entries
- [ ] Memory usage during bulk operations
- [ ] UI responsiveness during async operations

---

## IMPLEMENTATION TIMELINE

### Week 1: Critical Data Safety
- Day 1-2: Fix CapturesView (Inbox) race condition
- Day 3-4: Eliminate error suppression (21 instances)
- Day 5: Testing and validation

### Week 2: Data Integrity
- Day 1-3: Fix N+1 queries in all repositories
- Day 4: Fix acceptedSuggestionId relationship
- Day 5: Testing and validation

### Week 3: Security & Stability
- Day 1: Remove force unwraps
- Day 2: Fix ToastView cancellation
- Day 3: Fix MainActor synchronization
- Day 4: Add input validation
- Day 5: Testing and validation

### Week 4: High Priority Fixes
- Day 1-2: Fix Task.category relationship + index bounds
- Day 3-4: Standardize error handling
- Day 5: Add repository protocols

### Week 5-6: Architecture (Optional)
- Extract generic FormSheet
- Add comprehensive test suite
- Add logging/monitoring
- Code cleanup

---

## SUCCESS CRITERIA

### Phase 1 Complete When:
- [ ] Zero race conditions in concurrent operations
- [ ] Zero `try?` instances (all have proper error handling)
- [ ] All repository queries use predicates
- [ ] All relationships properly declared
- [ ] Zero force unwraps on dynamic values
- [ ] All async patterns correctly implemented
- [ ] Input validation on all user inputs

### Phase 2 Complete When:
- [ ] All data model relationships validated
- [ ] Delete operations safe from index errors
- [ ] Consistent error handling pattern across app
- [ ] Repository protocols defined and used
- [ ] Permission handling optimized

### Phase 3 Complete When:
- [ ] Generic FormSheet implemented and adopted
- [ ] Test coverage >60% for critical paths
- [ ] Logging added to all major operations
- [ ] Code duplication eliminated

---

## RISK MITIGATION

### Testing Strategy
- Manual testing after each fix
- Automated tests for regressions
- Performance benchmarks before/after

### Rollback Plan
- Git branch per phase
- Can revert to working state
- Feature flags for major changes

### Communication
- Update stakeholders weekly
- Document breaking changes
- Migration guides for data model changes

---

## APPENDIX: Verification Commands

### Find Remaining Issues

```bash
# Find try? instances
grep -r "try?" ios/Offload --include="*.swift" | grep -v "test"

# Find force unwraps
grep -r "!" ios/Offload --include="*.swift" | grep "URL(string:"

# Find fetch-all-then-filter pattern
grep -r "fetchAll()" ios/Offload/Data/Repositories --include="*.swift" -A 1

# Find @Environment usages
grep -r "@Environment" ios/Offload --include="*.swift"

# Count TODOs
grep -r "TODO" ios/Offload --include="*.swift" | wc -l

# Find print statements (should use Logger)
grep -r "print(" ios/Offload --include="*.swift" | grep -v "test"
```

---

**Document Version:** 1.0
**Last Updated:** January 6, 2026
**Status:** Ready for Review
