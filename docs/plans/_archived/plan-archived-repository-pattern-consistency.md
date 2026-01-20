---
id: plan-repository-pattern-consistency
type: plan
status: active
owners:
  - Offload
applies_to:
  - repository
  - pattern
  - consistency
last_updated: 2026-01-17
related: []
structure_notes:
  - "Section order: Overview; Problem Statement; Current State; Proposed Solution; Implementation Steps; Testing Strategy; Risks & Considerations; Success Criteria; Migration Guide for Developers; Next Steps; Related Documents."
  - "Keep the top-level section outline intact."
---

# Repository Pattern Consistency Plan

**Priority**: High
**Estimated Effort**: Medium
**Impact**: Architecture consistency and maintainability

## Overview

Enforce consistent use of the repository pattern across all views, eliminating direct ModelContext manipulation and establishing a clear data access layer.

## Problem Statement

### Current Issues

1. **Inconsistent Data Access**:
   - Some views use repositories (good)
   - Others manipulate `modelContext` directly (bad)
   - Creates confusion about "the right way"

2. **Direct ModelContext Usage Examples**:
   - `CaptureView.swift:172-174` - Direct delete:

     ```swift
     private func deleteItem(_ item: Item) {
         modelContext.delete(item)
         try? modelContext.save()  // Also has error handling issue
     }
     ```

   - `CollectionDetailView.swift` - Mixed approach with some repository, some direct
   - `OrganizeView.swift` - Direct collection creation

3. **Maintainability Issues**:
   - Business logic scattered across views
   - Hard to test view logic independently
   - Difficult to add cross-cutting concerns (logging, analytics, etc.)

## Current State

### What Works (Repository Usage)

```swift
// ItemRepository.swift - Good abstraction
@MainActor
final class ItemRepository {
    private let modelContext: ModelContext

    func create(...) throws -> Item { }
    func update(_ item: Item, ...) throws { }
    func delete(_ item: Item) throws { }
    func fetchAll() throws -> [Item] { }
}
```

### What Doesn't Work (Direct Access)

```swift
// CaptureView.swift - Direct manipulation
@Environment(\.modelContext) private var modelContext

private func deleteItem(_ item: Item) {
    modelContext.delete(item)  // Should use repository
    try? modelContext.save()
}
```

## Proposed Solution

### Architectural Principle

**Single Responsibility**: Views render UI and handle user interaction. Repositories handle data operations.

```text
┌─────────────────┐
│   SwiftUI View  │
│  (Presentation) │
└────────┬────────┘
         │ calls
         ▼
┌─────────────────┐
│   Repository    │
│  (Data Access)  │
└────────┬────────┘
         │ uses
         ▼
┌─────────────────┐
│  ModelContext   │
│  (Persistence)  │
└─────────────────┘
```

### Implementation Strategy

#### 1. Repository Injection Pattern

Inject repositories into views via environment:

```swift
// Common/RepositoryEnvironment.swift
private struct ItemRepositoryKey: EnvironmentKey {
    static let defaultValue = ItemRepository.shared
}

extension EnvironmentValues {
    var itemRepository: ItemRepository {
        get { self[ItemRepositoryKey.self] }
        set { self[ItemRepositoryKey.self] = newValue }
    }
}

// App/AppRootView.swift
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    private var itemRepository: ItemRepository {
        ItemRepository(modelContext: modelContext)
    }

    var body: some View {
        MainTabView()
            .environment(\.itemRepository, itemRepository)
            // ... other repositories
    }
}
```

#### 2. Complete Repository API

Ensure repositories cover all operations views need:

```swift
// Data/Repositories/ItemRepository.swift
@MainActor
final class ItemRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // CRUD Operations
    func create(...) throws -> Item
    func update(_ item: Item, ...) throws
    func delete(_ item: Item) throws
    func save() throws

    // Queries
    func fetchAll() throws -> [Item]
    func fetchCaptureItems() throws -> [Item]
    func fetchByCollection(_ collection: Collection) throws -> [Item]
    func fetchByTag(_ tag: String) throws -> [Item]
    func searchByContent(_ query: String) throws -> [Item]

    // Bulk Operations
    func deleteAll(_ items: [Item]) throws
    func markCompleted(_ item: Item) throws
    func moveToCollection(_ item: Item, collection: Collection, position: Int?) throws

    // Validation
    func validate(_ item: Item) throws -> Bool
}
```

#### 3. View Updates

Replace direct ModelContext usage with repository calls:

**Before**:

```swift
// CaptureView.swift
@Environment(\.modelContext) private var modelContext

private func deleteItem(_ item: Item) {
    modelContext.delete(item)
    try? modelContext.save()
}
```

**After**:

```swift
// CaptureView.swift
@Environment(\.itemRepository) private var itemRepository

private func deleteItem(_ item: Item) {
    do {
        try itemRepository.delete(item)
    } catch {
        errorPresenter.present(error)
    }
}
```

#### 4. Query Optimization

Keep @Query for reactive data but use repositories for mutations:

```swift
// CaptureView.swift
@Query(
    filter: #Predicate<Item> { $0.type == nil && $0.completedAt == nil },
    sort: \Item.createdAt,
    order: .reverse
) private var items: [Item]  // Good - reactive query

@Environment(\.itemRepository) private var itemRepository  // For mutations

private func deleteItem(_ item: Item) {
    do {
        try itemRepository.delete(item)
        // @Query automatically updates
    } catch {
        errorPresenter.present(error)
    }
}
```

## Implementation Steps

### Phase 1: Repository Infrastructure (2-3 hours)

#### 1.1 Create Repository Environment Keys

- [ ] Create `Common/RepositoryEnvironment.swift`
- [ ] Add environment keys for all repositories:
  - ItemRepository
  - CollectionRepository
  - CollectionItemRepository
  - TagRepository

#### 1.2 Update Repository Initialization

- [ ] Add singleton/factory pattern for repositories
- [ ] Ensure repositories can be injected via environment
- [ ] Add preview repositories for SwiftUI previews

#### 1.3 Inject Repositories in App Root

- [ ] Update `AppRootView.swift` to create repositories
- [ ] Inject into environment
- [ ] Update preview providers

### Phase 2: Complete Repository APIs (3-4 hours)

#### 2.1 ItemRepository Enhancements

- [ ] Add `markCompleted(_ item: Item)` method
- [ ] Add `moveToCollection(_ item: Item, collection: Collection, position: Int?)` method
- [ ] Add bulk operations (`deleteAll`, `markAllCompleted`)
- [ ] Add validation methods

#### 2.2 CollectionRepository Enhancements

- [ ] Add `addItem(_ item: Item, position: Int?)` method
- [ ] Add `removeItem(_ item: Item)` method
- [ ] Add `reorderItems(_ items: [Item])` method
- [ ] Add `fetchWithItems()` method (eager loading)

#### 2.3 CollectionItemRepository Enhancements

- [ ] Add `updatePosition(_ collectionItem: CollectionItem, position: Int)` method
- [ ] Add `updateParent(_ collectionItem: CollectionItem, parentId: UUID?)` method
- [ ] Add `reorder(for collection: Collection)` method

#### 2.4 TagRepository Enhancements

- [ ] Add `fetchOrCreate(_ name: String, color: String?)` method
- [ ] Add `updateUsageCount(_ tag: Tag)` method
- [ ] Add `fetchUnused()` method for cleanup

### Phase 3: View Refactoring (4-6 hours)

#### 3.1 CaptureView Updates

- [ ] Replace direct `modelContext.delete()` with `itemRepository.delete()`
- [ ] Replace direct saves with repository saves
- [ ] Update `moveToCollection` to use repository method
- [ ] Update `markCompleted` to use repository method

**Current code to replace**:

- Lines 172-174: deleteItem
- Lines 434-454: moveItem functions
- Line 176: completeItem

#### 3.2 CaptureComposeView Updates

- [ ] Replace direct item creation with `itemRepository.create()`
- [ ] Replace direct saves with repository saves
- [ ] Add validation before save

**Current code to replace**:

- Lines 283-296: Item creation and save

#### 3.3 CollectionDetailView Updates

- [ ] Replace direct item operations with repository
- [ ] Replace direct collection item operations with repository
- [ ] Update add/edit/delete operations

**Current code to replace**:

- Various locations throughout the 782-line file

#### 3.4 OrganizeView Updates

- [ ] Replace direct collection creation with repository
- [ ] Update collection operations

### Phase 4: Testing (2-3 hours)

#### 4.1 Unit Tests for Repositories

```swift
// OffloadTests/RepositoryTests.swift
@MainActor
class ItemRepositoryTests: XCTestCase {
    var modelContext: ModelContext!
    var repository: ItemRepository!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        repository = ItemRepository(modelContext: modelContext)
    }

    func testDeleteItem() throws {
        // Create item
        let item = try repository.create(content: "Test")

        // Delete item
        try repository.delete(item)

        // Verify deletion
        let items = try repository.fetchAll()
        XCTAssertEqual(items.count, 0)
    }
}
```

#### 4.2 Integration Tests

- [ ] Test repository injection in views
- [ ] Test error propagation from repository to view
- [ ] Test @Query reactivity with repository mutations

#### 4.3 Manual Testing

- [ ] Verify all CRUD operations work in UI
- [ ] Verify error messages appear correctly
- [ ] Verify no regressions in functionality

### Phase 5: Cleanup & Documentation (1-2 hours)

- [ ] Remove unused `@Environment(\.modelContext)` from views
- [ ] Update AGENTS.md with repository pattern guidelines
- [ ] Add code comments explaining pattern
- [ ] Create migration guide for future developers

## Testing Strategy

### Test Coverage Goals

- [ ] 100% of repository methods have unit tests
- [ ] All view-repository interactions tested
- [ ] Error handling paths tested

### Manual Testing Checklist

- [ ] Create capture item
- [ ] Edit capture item
- [ ] Delete capture item
- [ ] Move item to collection
- [ ] Add item to collection
- [ ] Remove item from collection
- [ ] Create collection
- [ ] Delete collection
- [ ] Add tags to items
- [ ] Remove tags from items

## Risks & Considerations

### Risks

1. **Breaking Changes**: Refactoring could introduce bugs
   - **Mitigation**: Comprehensive testing, incremental rollout

2. **Performance**: Extra layer could slow operations
   - **Mitigation**: Repositories are lightweight wrappers, no significant overhead

3. **Learning Curve**: Team needs to understand pattern
   - **Mitigation**: Clear documentation and code examples

### Benefits

1. **Testability**: Views can be tested with mock repositories
2. **Maintainability**: Clear separation of concerns
3. **Flexibility**: Easy to add caching, analytics, etc.
4. **Consistency**: One way to do data operations

## Success Criteria

### Code Quality

- [ ] Zero direct `modelContext` mutations in views
- [ ] All data operations go through repositories
- [ ] Repository injection via environment throughout

### Testing

- [ ] All repositories have >90% test coverage
- [ ] Integration tests pass
- [ ] Manual testing checklist complete

### Documentation

- [ ] AGENTS.md updated with pattern
- [ ] Code comments explain repository usage
- [ ] Migration guide created

### Performance

- [ ] No measurable performance degradation
- [ ] App feels as responsive as before

## Migration Guide for Developers

### Before (Direct Access)

```swift
@Environment(\.modelContext) private var modelContext

private func deleteItem(_ item: Item) {
    modelContext.delete(item)
    try? modelContext.save()
}
```

### After (Repository Pattern)

```swift
@Environment(\.itemRepository) private var itemRepository

private func deleteItem(_ item: Item) {
    do {
        try itemRepository.delete(item)
    } catch {
        errorPresenter.present(error)
    }
}
```

### Key Principles

1. **Views should never import `ModelContext`** (except for @Query)
2. **All mutations go through repositories**
3. **Repositories handle persistence and error throwing**
4. **Views handle error presentation**

## Next Steps

1. Review plan with team
2. Get approval for architecture change
3. Implement Phase 1 (infrastructure)
4. Create PR for review
5. Proceed with remaining phases incrementally

## Related Documents

- `plan-error-handling-improvements.md` - Complementary error handling plan
- `AGENTS.md` - Architecture overview
- `docs/adrs/adr-0001-technology-stack-and-architecture.md` - Technology choices
