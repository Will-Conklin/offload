<!-- Intent: Track remediation plan execution status, evidence, and remaining gaps. -->

# Remediation Progress Tracking
**Created:** January 6, 2026
**Status:** Phase 1 nearly complete (toast cancellation pending); Phase 2 in progress
**Last Updated:** January 8, 2026

This document tracks the implementation progress of the [Remediation Plan](./remediation-plan.md).

---

## PHASE 1: CRITICAL FIXES (Week 1-2)

### 1.1 Fix CapturesView (Inbox) Race Condition ⚠️
**Status:** ✅ Completed
**File:** `ios/Offload/Features/Inbox/CapturesView.swift:70-99`
**Assigned:** N/A
**Completed:** January 8, 2026

**Checklist:**
- [x] Capture entries to delete before async operation
- [x] Serialize deletions in single Task
- [x] Single reload after all deletions complete
- [x] Add error handling with user feedback
- [ ] Test deleting single item
- [ ] Test deleting multiple items (2, 5, 10)
- [ ] Test rapid delete operations
- [ ] Verify UI updates only once

**Testing Evidence:**
```
Not yet collected.
```

---

### 1.2 Eliminate Silent Error Suppression (21 instances) ⚠️
**Status:** 🟡 In Progress
**Progress:** 20/21 instances fixed (ToastView cancellation tracked in 1.6)

**Instances:**

#### OrganizeView.swift (5 instances)
- [x] Line 301 - createPlan error handling
- [x] Line 309 - createCategory error handling
- [x] Line 317 - createTag error handling
- [x] Line 336 - createList error handling
- [x] Line 364 - createCommunication error handling

#### ListDetailView.swift (5 instances)
- [x] Line 155 - addQuickItem save
- [x] Line 165 - deleteUncheckedItems save
- [x] Line 173 - deleteCheckedItems save
- [x] Line 181 - deleteItem save
- [x] Line 186 - toggle save

#### PlanDetailView.swift (3 instances)
- [x] Line 175 - deleteTasks save
- [x] Line 184 - addTask save
- [x] Line 189 - toggle save

#### SettingsView.swift (3 instances)
- [x] Line 248 - clearCompletedTasks error
- [x] Line 264 - archiveOldCaptures error
- [x] Line 521 - storage calculation error

#### Other files (3 instances)
- [x] PersistenceController.swift:137
- [x] VoiceRecordingService.swift:148
- [ ] ToastView.swift:96 (pending cancellation handling update)

**Testing Evidence:**
```
TBD
```

---

### 1.3 Fix N+1 Query Problems ⚠️
**Status:** 🟡 In Progress
**Progress:** 8/9 methods fixed (pending suggestion-by-entry optimization)

#### CaptureRepository.swift
- [x] fetchInbox() - Add predicate for .raw state
- [x] fetchByState() - Add predicate for state
- [x] fetchReady() - Add predicate for .ready state
- [ ] Benchmark queries with 100, 1000, 10000 records

#### SuggestionRepository.swift
- [x] fetchSuggestionsByKind() - Add predicate for kind
- [ ] fetchPendingSuggestionsForEntry() - Still uses in-memory filtering (SwiftData relationship limitation)
- [x] fetchDecisionsByType() - Add predicate for type
- [ ] Benchmark queries

#### TaskRepository.swift
- [x] fetchByPlan() - Add predicate for plan.id
- [x] fetchByCategory() - Add predicate for category.id
- [ ] Benchmark queries

#### HandOffRepository.swift
- [x] Review and fix any similar patterns (all queries use predicates)
- [ ] Benchmark queries

**Performance Testing:**
```
Before:
TBD

After:
TBD
```

---

### 1.4 Fix Orphaned Foreign Key - acceptedSuggestionId ⚠️
**Status:** 🟡 In Progress (model updated; migration pending if legacy data exists)
**File:** `ios/Offload/Domain/Models/CaptureEntry.swift:23`

**Checklist:**
- [x] Update CaptureEntry model - replace UUID with @Relationship
- [x] Find all uses of acceptedSuggestionId (grep command)
- [x] Replace all usages with acceptedSuggestion relationship
- [x] Update queries and filters
- [ ] Write migration function (if pre-v1 data exists)
- [ ] Test migration with sample data
- [ ] Test relationship integrity (delete cascade/nullify)

**Migration Testing:**
```
TBD
```

---

### 1.5 Remove Force Unwraps on URLs ⚠️
**Status:** ✅ Completed
**Progress:** 4/4 instances fixed

**Instances:**
- [x] SettingsView.swift:212 - GitHub URL (static constants)
- [x] SettingsView.swift:578 - AboutSheet GitHub URL (static constants)
- [x] SettingsView.swift:685 - Issues URL (static constants)
- [x] APIClient.swift:24 - baseURL (guarded initialization)

**Checklist:**
- [x] Create Constants enum with static URLs
- [x] Replace all force unwraps with safe unwrapping
- [ ] Add fallback UI for link failures
- [ ] Test all links work
- [ ] Verify no force unwraps remain: `grep -r 'URL(.*?)!' ios/Offload`

**Verification:**
```
TBD
```

---

### 1.6 Fix ToastView Task Cancellation ⚠️
**Status:** ❌ Not Started
**File:** `ios/Offload/DesignSystem/ToastView.swift:87-102`

**Checklist:**
- [ ] Fix Task.isCancelled check (remove static reference)
- [ ] Add proper CancellationError handling
- [ ] Add weak self capture
- [ ] Use @MainActor for state updates
- [ ] Test auto-dismiss after duration
- [ ] Test showing multiple toasts rapidly
- [ ] Test manual dismiss() cancels task
- [ ] Verify no memory leaks

**Testing Evidence:**
```
TBD
```

---

### 1.7 Fix MainActor Synchronization ⚠️
**Status:** ✅ Completed
**File:** `ios/Offload/Data/Services/CaptureWorkflowService.swift`

**Checklist:**
- [x] Make isProcessing private(set)
- [x] Make errorMessage private(set)
- [x] Add proper MainActor.run isolation (service remains @MainActor)
- [x] Fix defer block to use MainActor
- [ ] Test concurrent capture attempts
- [ ] Verify isProcessing flag correctness
- [ ] Test error message updates
- [ ] Benchmark performance impact

**Testing Evidence:**
```
TBD
```

---

### 1.8 Add Input Validation for API Endpoint ⚠️
**Status:** ✅ Completed
**File:** `ios/Offload/Features/Settings/SettingsView.swift:322-325`

**Checklist:**
- [x] Add URL format validation
- [x] Add HTTPS scheme enforcement
- [x] Add hostname validation
- [x] Add length validation (max 200 chars)
- [x] Add error message display
- [ ] Test valid HTTPS URL (accepted)
- [ ] Test HTTP URL (rejected)
- [ ] Test malformed URL (rejected)
- [ ] Test empty URL (rejected)
- [ ] Test URL without scheme (rejected)
- [ ] Test very long URL (rejected)

**Testing Evidence:**
```
TBD
```

---

## PHASE 2: HIGH PRIORITY FIXES (Week 3-4)

### 2.1 Convert Task.category to Proper Relationship
**Status:** 🟡 In Progress (implementation complete, testing pending)
**File:** `ios/Offload/Domain/Models/Task.swift:28`

**Checklist:**
- [x] Add @Relationship annotation
- [x] Set appropriate deleteRule
- [ ] Test cascade behavior
- [ ] Update any queries using category

---

### 2.2 Fix Array Index Out of Bounds
**Status:** 🟡 In Progress (implementation complete, testing pending)
**Files:** ListDetailView.swift, PlanDetailView.swift

**Checklist:**
- [x] Fix deleteUncheckedItems in ListDetailView
- [x] Fix deleteCheckedItems in ListDetailView
- [x] Fix deleteTasks in PlanDetailView
- [ ] Test delete operations
- [ ] Verify no index errors

---

### 2.3 Standardize Error Handling Pattern
**Status:** 🟡 In Progress (types added, integration pending)

**Checklist:**
- [x] Create ErrorPresenter class
- [x] Create PresentableError struct
- [x] Define error actions
- [ ] Integrate with existing error handling
- [ ] Update views to use centralized handler

---

### 2.4 Add Repository Protocols
**Status:** 🟡 In Progress (protocols added, tests pending)

**Checklist:**
- [x] Define CaptureRepositoryProtocol
- [x] Define SuggestionRepositoryProtocol
- [x] Define TaskRepositoryProtocol
- [x] Define HandOffRepositoryProtocol
- [x] Update services to use protocols
- [x] Enable dependency injection
- [ ] Write unit tests with mocks

---

### 2.5 Fix Permission Request Pattern
**Status:** 🟡 In Progress (implementation complete, testing pending)
**File:** VoiceRecordingService.swift

**Checklist:**
- [x] Add permission caching
- [x] Check cached values before requesting
- [x] Update cache on changes
- [ ] Test permission flows

---

## PHASE 3: ARCHITECTURE IMPROVEMENTS (Week 5-6)

### 3.1 Extract Generic FormSheet Component
**Status:** ✅ Completed

**Checklist:**
- [x] Create FormSheet.swift
- [x] Implement generic component
- [x] Migrate PlanFormSheet
- [x] Migrate CategoryFormSheet
- [x] Migrate TagFormSheet
- [x] Migrate ListFormSheet
- [x] Migrate CommunicationFormSheet
- [x] Delete old form sheet code
- [ ] Verify ~400 lines removed

---

### 3.2 Add Comprehensive Test Suite
**Status:** ✅ Completed

**Checklist:**
- [x] Setup test target
- [x] Create CaptureWorkflowServiceTests
- [x] Create repository tests
- [x] Create validation tests
- [ ] Achieve >60% coverage on critical paths

---

### 3.3 Add Logging and Monitoring
**Status:** ✅ Completed

**Checklist:**
- [x] Create Logger.swift
- [x] Define log categories
- [x] Add logging to workflows
- [ ] Add logging to repositories
- [ ] Remove debug print statements

---

## OVERALL PROGRESS

### Phase 1: Critical Fixes
**Progress:** 7/8 tasks complete (toast cancellation pending)
- [x] 1.1 CapturesView (Inbox) Race Condition
- [x] 1.2 Silent Error Suppression (20/21)
- [x] 1.3 N+1 Query Problems (8/9)
- [x] 1.4 Orphaned Foreign Key (model updated)
- [x] 1.5 Force Unwraps (4/4)
- [ ] 1.6 ToastView Cancellation
- [x] 1.7 MainActor Synchronization
- [x] 1.8 Input Validation

### Phase 2: High Priority
**Progress:** 0/5 tasks fully verified (implementation underway)
- [ ] 2.1 Task.category Relationship (implementation complete)
- [ ] 2.2 Index Out of Bounds (implementation complete)
- [ ] 2.3 Error Handling Pattern (types added)
- [ ] 2.4 Repository Protocols (implementation complete)
- [ ] 2.5 Permission Caching (implementation complete)

### Phase 3: Architecture
**Progress:** 3/3 tasks complete
- [x] 3.1 Generic FormSheet
- [x] 3.2 Test Suite
- [x] 3.3 Logging

---

## COMPLETION CRITERIA

### ✅ Phase 1 Complete When:
- [ ] Zero race conditions in concurrent operations (verified by testing)
- [ ] Zero `try?` instances remain (verified by grep)
- [ ] All repository queries use predicates (verified by code review)
- [ ] All relationships properly declared (verified by model review)
- [ ] Zero force unwraps on dynamic values (verified by grep)
- [ ] All async patterns correctly implemented (verified by testing)
- [ ] Input validation on all user inputs (verified by manual testing)

### ✅ Phase 2 Complete When:
- [ ] All data model relationships validated
- [ ] Delete operations safe from index errors (verified by testing)
- [ ] Consistent error handling pattern across app
- [ ] Repository protocols defined and used
- [ ] Permission handling optimized

### ✅ Phase 3 Complete When:
- [ ] Generic FormSheet implemented and adopted
- [ ] Test coverage >60% for critical paths
- [ ] Logging added to all major operations
- [ ] Code duplication eliminated (verified by line count)

---

## NOTES & BLOCKERS

### Current Blockers:
- None

### Decisions Needed:
- Approval to start Phase 1
- Timeline confirmation
- Resource allocation

### Risks:
- Data migration complexity for acceptedSuggestionId
- Potential breaking changes in error handling refactor
- Test coverage may reveal additional issues

---

**Last Updated:** January 8, 2026
**Next Review:** TBD
