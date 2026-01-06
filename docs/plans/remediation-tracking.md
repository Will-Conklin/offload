# Remediation Progress Tracking
**Created:** January 6, 2026
**Status:** Not Started

This document tracks the implementation progress of the [Remediation Plan](./remediation-plan.md).

---

## PHASE 1: CRITICAL FIXES (Week 1-2)

### 1.1 Fix InboxView Race Condition ⚠️
**Status:** ❌ Not Started
**File:** `ios/Offload/Features/Inbox/InboxView.swift:68-84`
**Assigned:** TBD
**Completed:** N/A

**Checklist:**
- [ ] Capture entries to delete before async operation
- [ ] Serialize deletions in single Task
- [ ] Single reload after all deletions complete
- [ ] Add error handling with user feedback
- [ ] Test deleting single item
- [ ] Test deleting multiple items (2, 5, 10)
- [ ] Test rapid delete operations
- [ ] Verify UI updates only once

**Testing Evidence:**
```
TBD
```

---

### 1.2 Eliminate Silent Error Suppression (21 instances) ⚠️
**Status:** ❌ Not Started
**Progress:** 0/21 instances fixed

**Instances:**

#### OrganizeView.swift (5 instances)
- [ ] Line 301 - createPlan error handling
- [ ] Line 309 - createCategory error handling
- [ ] Line 317 - createTag error handling
- [ ] Line 336 - createList error handling
- [ ] Line 364 - createCommunication error handling

#### ListDetailView.swift (5 instances)
- [ ] Line 155 - addQuickItem save
- [ ] Line 165 - deleteUncheckedItems save
- [ ] Line 173 - deleteCheckedItems save
- [ ] Line 181 - deleteItem save
- [ ] Line 186 - toggle save

#### PlanDetailView.swift (3 instances)
- [ ] Line 175 - deleteTasks save
- [ ] Line 184 - addTask save
- [ ] Line 189 - toggle save

#### SettingsView.swift (3 instances)
- [ ] Line 248 - clearCompletedTasks error
- [ ] Line 264 - archiveOldCaptures error
- [ ] Line 521 - storage calculation error

#### Other files (5 instances)
- [ ] PersistenceController.swift:137
- [ ] VoiceRecordingService.swift:148
- [ ] ToastView.swift:96
- [ ] (Others TBD)

**Testing Evidence:**
```
TBD
```

---

### 1.3 Fix N+1 Query Problems ⚠️
**Status:** ❌ Not Started
**Progress:** 0/15 methods fixed

#### CaptureRepository.swift
- [ ] fetchInbox() - Add predicate for .raw state
- [ ] fetchByState() - Add predicate for state
- [ ] fetchReady() - Add predicate for .ready state
- [ ] Benchmark queries with 100, 1000, 10000 records

#### SuggestionRepository.swift
- [ ] fetchSuggestionsByKind() - Add predicate for kind
- [ ] fetchPendingSuggestionsForEntry() - Optimize or denormalize
- [ ] fetchDecisionsByType() - Add predicate for type
- [ ] Benchmark queries

#### TaskRepository.swift
- [ ] fetchByPlan() - Add predicate for plan.id
- [ ] fetchByCategory() - Add predicate for category.id
- [ ] Benchmark queries

#### HandOffRepository.swift
- [ ] Review and fix any similar patterns
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
**Status:** ❌ Not Started
**File:** `ios/Offload/Domain/Models/CaptureEntry.swift:23`

**Checklist:**
- [ ] Update CaptureEntry model - replace UUID with @Relationship
- [ ] Find all uses of acceptedSuggestionId (grep command)
- [ ] Replace all usages with acceptedSuggestion relationship
- [ ] Update queries and filters
- [ ] Write migration function
- [ ] Test migration with sample data
- [ ] Test relationship integrity (delete cascade/nullify)

**Migration Testing:**
```
TBD
```

---

### 1.5 Remove Force Unwraps on URLs ⚠️
**Status:** ❌ Not Started
**Progress:** 0/4 instances fixed

**Instances:**
- [ ] SettingsView.swift:212 - GitHub URL
- [ ] SettingsView.swift:578 - AboutSheet GitHub URL
- [ ] SettingsView.swift:685 - Issues URL
- [ ] APIClient.swift:24 - baseURL

**Checklist:**
- [ ] Create Constants enum with static URLs
- [ ] Replace all force unwraps with safe unwrapping
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
**Status:** ❌ Not Started
**File:** `ios/Offload/Data/Services/CaptureWorkflowService.swift`

**Checklist:**
- [ ] Make isProcessing private(set)
- [ ] Make errorMessage private(set)
- [ ] Add proper MainActor.run isolation
- [ ] Fix defer block to use MainActor
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
**Status:** ❌ Not Started
**File:** `ios/Offload/Features/Settings/SettingsView.swift:322-325`

**Checklist:**
- [ ] Add URL format validation
- [ ] Add HTTPS scheme enforcement
- [ ] Add hostname validation
- [ ] Add length validation (max 200 chars)
- [ ] Add error message display
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
**Status:** ❌ Not Started
**File:** `ios/Offload/Domain/Models/Task.swift:28`

**Checklist:**
- [ ] Add @Relationship annotation
- [ ] Set appropriate deleteRule
- [ ] Test cascade behavior
- [ ] Update any queries using category

---

### 2.2 Fix Array Index Out of Bounds
**Status:** ❌ Not Started
**Files:** ListDetailView.swift, PlanDetailView.swift

**Checklist:**
- [ ] Fix deleteUncheckedItems in ListDetailView
- [ ] Fix deleteCheckedItems in ListDetailView
- [ ] Fix deleteTasks in PlanDetailView
- [ ] Test delete operations
- [ ] Verify no index errors

---

### 2.3 Standardize Error Handling Pattern
**Status:** ❌ Not Started

**Checklist:**
- [ ] Create ErrorPresenter class
- [ ] Create PresentableError struct
- [ ] Define error actions
- [ ] Integrate with existing error handling
- [ ] Update views to use centralized handler

---

### 2.4 Add Repository Protocols
**Status:** ❌ Not Started

**Checklist:**
- [ ] Define CaptureRepositoryProtocol
- [ ] Define SuggestionRepositoryProtocol
- [ ] Define TaskRepositoryProtocol
- [ ] Define HandOffRepositoryProtocol
- [ ] Update services to use protocols
- [ ] Enable dependency injection
- [ ] Write unit tests with mocks

---

### 2.5 Fix Permission Request Pattern
**Status:** ❌ Not Started
**File:** VoiceRecordingService.swift

**Checklist:**
- [ ] Add permission caching
- [ ] Check cached values before requesting
- [ ] Update cache on changes
- [ ] Test permission flows

---

## PHASE 3: ARCHITECTURE IMPROVEMENTS (Week 5-6)

### 3.1 Extract Generic FormSheet Component
**Status:** ❌ Not Started

**Checklist:**
- [ ] Create FormSheet.swift
- [ ] Implement generic component
- [ ] Migrate PlanFormSheet
- [ ] Migrate CategoryFormSheet
- [ ] Migrate TagFormSheet
- [ ] Migrate ListFormSheet
- [ ] Migrate CommunicationFormSheet
- [ ] Delete old form sheet code
- [ ] Verify ~400 lines removed

---

### 3.2 Add Comprehensive Test Suite
**Status:** ❌ Not Started

**Checklist:**
- [ ] Setup test target
- [ ] Create CaptureWorkflowServiceTests
- [ ] Create repository tests
- [ ] Create validation tests
- [ ] Achieve >60% coverage on critical paths

---

### 3.3 Add Logging and Monitoring
**Status:** ❌ Not Started

**Checklist:**
- [ ] Create Logger.swift
- [ ] Define log categories
- [ ] Add logging to workflows
- [ ] Add logging to repositories
- [ ] Remove debug print statements

---

## OVERALL PROGRESS

### Phase 1: Critical Fixes
**Progress:** 0/8 tasks (0%)
- [ ] 1.1 InboxView Race Condition
- [ ] 1.2 Silent Error Suppression (0/21)
- [ ] 1.3 N+1 Query Problems (0/15)
- [ ] 1.4 Orphaned Foreign Key
- [ ] 1.5 Force Unwraps (0/4)
- [ ] 1.6 ToastView Cancellation
- [ ] 1.7 MainActor Synchronization
- [ ] 1.8 Input Validation

### Phase 2: High Priority
**Progress:** 0/5 tasks (0%)
- [ ] 2.1 Task.category Relationship
- [ ] 2.2 Index Out of Bounds
- [ ] 2.3 Error Handling Pattern
- [ ] 2.4 Repository Protocols
- [ ] 2.5 Permission Caching

### Phase 3: Architecture
**Progress:** 0/3 tasks (0%)
- [ ] 3.1 Generic FormSheet
- [ ] 3.2 Test Suite
- [ ] 3.3 Logging

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

**Last Updated:** January 6, 2026
**Next Review:** TBD
