---
id: plan-pagination-implementation
type: plan
status: archived
owners:
  - Will-Conklin
applies_to:
  - pagination
last_updated: 2026-01-17
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Problem Statement; Current State; Proposed Solution; Implementation Steps; Testing Strategy; Risks & Considerations; Success Criteria; Configuration; Next Steps; Related Documents."
  - "Keep the top-level section outline intact."
---

# Pagination Implementation Plan

**Priority**: Medium
**Estimated Effort**: Medium
**Impact**: Performance and scalability

## Overview

Implement pagination for item lists to improve performance with large datasets, reducing memory usage and improving initial load times.

## Problem Statement

### Current Issues

1. **Load All Items at Once**:
   - `@Query` fetches all matching items
   - CaptureView loads all uncompleted captures
   - CollectionDetailView loads all items in collection
   - No limit on result set size

2. **Memory Concerns**:
   - Large datasets (1000+ items) all in memory
   - Scrolling loads all items even if user never scrolls
   - Potential memory pressure on older devices

3. **Slow Initial Load**:
   - User waits for all items to load before seeing first item
   - Poor perceived performance with large datasets

4. **No Progressive Loading**:
   - LazyVStack helps with rendering but not data loading
   - All data fetched upfront regardless of visibility

## Current State

### Current Query Pattern (CaptureView.swift:19-25)

```swift
@Query(
    filter: #Predicate<Item> { $0.type == nil && $0.completedAt == nil },
    sort: \Item.createdAt,
    order: .reverse
) private var items: [Item]  // Loads ALL items
```

### Current Display Pattern

```swift
ScrollView {
    LazyVStack {  // Lazy rendering, but eager data loading
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
}
```

## Proposed Solution

### Pagination Strategy

#### 1. Offset-Based Pagination

Simple approach using FetchDescriptor with offset/limit:

```swift
// Data/Repositories/ItemRepository.swift
struct PaginationParams {
    let offset: Int
    let limit: Int

    static let defaultPageSize = 20
}

extension ItemRepository {
    func fetchCaptureItems(
        page: Int = 0,
        pageSize: Int = PaginationParams.defaultPageSize
    ) throws -> [Item] {
        let predicate = #Predicate<Item> {
            $0.type == nil && $0.completedAt == nil
        }

        var descriptor = FetchDescriptor<Item>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = page * pageSize

        return try modelContext.fetch(descriptor)
    }

    func fetchItemCount(predicate: Predicate<Item>? = nil) throws -> Int {
        var descriptor = FetchDescriptor<Item>(predicate: predicate)
        descriptor.fetchLimit = nil
        return try modelContext.fetchCount(descriptor)
    }
}
```

#### 2. Paginated View Model

Create observable view model to manage pagination state:

```swift
// Features/Capture/CaptureViewModel.swift
@MainActor
@Observable
final class CaptureViewModel {
    private let itemRepository: ItemRepository

    var items: [Item] = []
    var isLoading = false
    var hasMorePages = true
    var currentPage = 0

    private let pageSize = 20

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func loadInitialPage() async {
        await loadPage(reset: true)
    }

    func loadNextPage() async {
        guard !isLoading && hasMorePages else { return }
        await loadPage(reset: false)
    }

    private func loadPage(reset: Bool) async {
        isLoading = true

        if reset {
            currentPage = 0
            items = []
            hasMorePages = true
        }

        do {
            let newItems = try itemRepository.fetchCaptureItems(
                page: currentPage,
                pageSize: pageSize
            )

            items.append(contentsOf: newItems)
            hasMorePages = newItems.count == pageSize
            currentPage += 1

            Logger.ui.info("Loaded page \(currentPage) with \(newItems.count) items")
        } catch {
            Logger.ui.error("Failed to load items: \(error)")
            // Error handling
        }

        isLoading = false
    }

    func refresh() async {
        await loadInitialPage()
    }
}
```

#### 3. Infinite Scroll View

Implement infinite scroll with pagination:

```swift
// Features/Capture/CaptureView.swift
struct CaptureView: View {
    @Environment(\.itemRepository) private var itemRepository
    @State private var viewModel: CaptureViewModel

    init() {
        // ViewModel initialized with repository
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    ItemCard(item: item)
                        .onAppear {
                            // Load next page when approaching end
                            if item == viewModel.items.last {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                if !viewModel.hasMorePages && !viewModel.items.isEmpty {
                    Text("No more items")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadInitialPage()
        }
    }
}
```

#### 4. Alternative: Cursor-Based Pagination

More robust for real-time data, prevents skipped/duplicate items:

```swift
extension ItemRepository {
    func fetchCaptureItems(
        after cursor: Date? = nil,
        limit: Int = 20
    ) throws -> [Item] {
        let predicate: Predicate<Item>
        if let cursor = cursor {
            predicate = #Predicate<Item> {
                $0.type == nil &&
                $0.completedAt == nil &&
                $0.createdAt < cursor  // Items created before cursor
            }
        } else {
            predicate = #Predicate<Item> {
                $0.type == nil && $0.completedAt == nil
            }
        }

        var descriptor = FetchDescriptor<Item>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }
}

// ViewModel usage
private func loadPage(reset: Bool) async {
    isLoading = true

    if reset {
        cursor = nil
        items = []
        hasMorePages = true
    }

    do {
        let newItems = try itemRepository.fetchCaptureItems(
            after: cursor,
            limit: pageSize
        )

        items.append(contentsOf: newItems)
        hasMorePages = newItems.count == pageSize

        // Update cursor to last item's createdAt
        cursor = newItems.last?.createdAt

        Logger.ui.info("Loaded \(newItems.count) items")
    } catch {
        Logger.ui.error("Failed to load items: \(error)")
    }

    isLoading = false
}
```

## Implementation Steps

### Phase 1: Repository Pagination Support (2-3 hours)

#### 1.1 Add Pagination Types

- [ ] Create `PaginationParams` struct
- [ ] Add pagination constants (default page size, max page size)

#### 1.2 Update ItemRepository

- [ ] Add `fetchCaptureItems(page:pageSize:)` method
- [ ] Add `fetchItemCount(predicate:)` method
- [ ] Add cursor-based pagination methods (optional)
- [ ] Add pagination support for other queries:
  - `fetchByCollection(page:pageSize:)`
  - `fetchByTag(page:pageSize:)`
  - `searchByContent(page:pageSize:)`

#### 1.3 Update Other Repositories

- [ ] Add pagination to CollectionRepository
- [ ] Add pagination to TagRepository (if needed)

### Phase 2: View Models (3-4 hours)

#### 2.1 Create CaptureViewModel

- [ ] Implement pagination state management
- [ ] Add `loadInitialPage()` method
- [ ] Add `loadNextPage()` method
- [ ] Add `refresh()` method
- [ ] Handle loading and error states

#### 2.2 Create CollectionDetailViewModel

- [ ] Similar pagination logic for collection items
- [ ] Handle item additions/removals
- [ ] Maintain sorted order

#### 2.3 Create SearchViewModel (if applicable)

- [ ] Pagination for search results
- [ ] Debounce search queries

### Phase 3: View Updates (3-4 hours)

#### 3.1 Update CaptureView

- [ ] Replace `@Query` with ViewModel
- [ ] Implement infinite scroll trigger
- [ ] Add pull-to-refresh
- [ ] Add loading indicators
- [ ] Handle empty states

#### 3.2 Update CollectionDetailView

- [ ] Replace `@Query` with ViewModel
- [ ] Implement infinite scroll
- [ ] Add pull-to-refresh
- [ ] Handle item insertion into paginated list

#### 3.3 Update OrganizeView (if needed)

- [ ] Pagination for collections list (probably not needed unless many collections)

### Phase 4: Optimization (2-3 hours)

#### 4.1 Prefetching Strategy

```swift
// Prefetch when user is 5 items from bottom
.onAppear {
    if let index = viewModel.items.firstIndex(where: { $0.id == item.id }),
       index >= viewModel.items.count - 5 {
        Task {
            await viewModel.loadNextPage()
        }
    }
}
```

#### 4.2 Memory Management

- [ ] Clear items when view disappears (if needed)
- [ ] Implement virtual scrolling for very large lists
- [ ] Monitor memory usage

#### 4.3 Caching Strategy

- [ ] Cache recent pages in memory
- [ ] Invalidate cache on data changes
- [ ] LRU cache for loaded pages

### Phase 5: Testing (2-3 hours)

#### 5.1 Unit Tests

```swift
// OffloadTests/PaginationTests.swift
@MainActor
class PaginationTests: XCTestCase {
    var repository: ItemRepository!
    var modelContext: ModelContext!

    override func setUp() async throws {
        let container = try ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        repository = ItemRepository(modelContext: modelContext)
    }

    func testFetchFirstPage() throws {
        // Create 50 items
        for i in 0..<50 {
            _ = try repository.create(content: "Item \(i)")
        }

        // Fetch first page (20 items)
        let page1 = try repository.fetchCaptureItems(page: 0, pageSize: 20)

        XCTAssertEqual(page1.count, 20)
    }

    func testFetchSecondPage() throws {
        // Create 50 items
        for i in 0..<50 {
            _ = try repository.create(content: "Item \(i)")
        }

        // Fetch second page
        let page2 = try repository.fetchCaptureItems(page: 1, pageSize: 20)

        XCTAssertEqual(page2.count, 20)

        // Verify different items than first page
        let page1 = try repository.fetchCaptureItems(page: 0, pageSize: 20)
        let page1Ids = Set(page1.map(\.id))
        let page2Ids = Set(page2.map(\.id))

        XCTAssertTrue(page1Ids.isDisjoint(with: page2Ids))
    }

    func testFetchPartialLastPage() throws {
        // Create 45 items
        for i in 0..<45 {
            _ = try repository.create(content: "Item \(i)")
        }

        // Fetch third page (should have 5 items)
        let page3 = try repository.fetchCaptureItems(page: 2, pageSize: 20)

        XCTAssertEqual(page3.count, 5)
    }

    func testCursorPagination() throws {
        // Create items with timestamps
        let items = try (0..<50).map { i in
            try repository.create(content: "Item \(i)")
        }

        // Fetch first page
        let page1 = try repository.fetchCaptureItems(after: nil, limit: 20)
        XCTAssertEqual(page1.count, 20)

        // Fetch second page using cursor
        let cursor = page1.last?.createdAt
        let page2 = try repository.fetchCaptureItems(after: cursor, limit: 20)
        XCTAssertEqual(page2.count, 20)

        // Verify no overlap
        let page1Ids = Set(page1.map(\.id))
        let page2Ids = Set(page2.map(\.id))
        XCTAssertTrue(page1Ids.isDisjoint(with: page2Ids))
    }
}
```

#### 5.2 ViewModel Tests

```swift
// OffloadTests/CaptureViewModelTests.swift
@MainActor
class CaptureViewModelTests: XCTestCase {
    var viewModel: CaptureViewModel!
    var repository: ItemRepository!

    func testLoadInitialPage() async throws {
        // Create 50 items
        for i in 0..<50 {
            _ = try repository.create(content: "Item \(i)")
        }

        await viewModel.loadInitialPage()

        XCTAssertEqual(viewModel.items.count, 20)
        XCTAssertTrue(viewModel.hasMorePages)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadNextPage() async throws {
        // Create 50 items
        for i in 0..<50 {
            _ = try repository.create(content: "Item \(i)")
        }

        await viewModel.loadInitialPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.items.count, 40)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    func testLoadAllPages() async throws {
        // Create 45 items
        for i in 0..<45 {
            _ = try repository.create(content: "Item \(i)")
        }

        await viewModel.loadInitialPage()
        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        XCTAssertEqual(viewModel.items.count, 45)
        XCTAssertFalse(viewModel.hasMorePages)
    }

    func testRefresh() async throws {
        // Load initial data
        await viewModel.loadInitialPage()
        let initialCount = viewModel.items.count

        // Add more items
        _ = try repository.create(content: "New item")

        // Refresh
        await viewModel.refresh()

        XCTAssertGreaterThan(viewModel.items.count, 0)
        XCTAssertEqual(viewModel.currentPage, 1)
    }
}
```

#### 5.3 Integration Tests

- [ ] Test infinite scroll in UI
- [ ] Test pull-to-refresh
- [ ] Test adding item updates view
- [ ] Test deleting item updates view

### Phase 6: Documentation (1 hour)

- [ ] Update AGENTS.md with pagination pattern
- [ ] Add code comments explaining pagination
- [ ] Create developer guide for adding pagination to new views

## Testing Strategy

### Performance Benchmarks

```swift
// OffloadTests/PaginationPerformanceTests.swift
class PaginationPerformanceTests: XCTestCase {
    func testPaginatedFetchPerformance() throws {
        // Create 1000 items
        for i in 0..<1000 {
            try repository.create(content: "Item \(i)")
        }

        // Measure paginated fetch
        measure {
            _ = try! repository.fetchCaptureItems(page: 0, pageSize: 20)
        }
    }

    func testFullFetchPerformance() throws {
        // Create 1000 items
        for i in 0..<1000 {
            try repository.create(content: "Item \(i)")
        }

        // Measure full fetch (current approach)
        measure {
            _ = try! repository.fetchAllCaptureItems()
        }
    }
}
```

### Manual Testing Checklist

- [ ] Scroll through long list (100+ items)
- [ ] Pull to refresh
- [ ] Add new item (appears at top)
- [ ] Delete item (removes from list)
- [ ] Edit item (updates in place)
- [ ] Fast scroll to trigger multiple page loads
- [ ] Switch views and return (preserves scroll position?)
- [ ] Test with slow network (if applicable)

## Risks & Considerations

### Risks

1. **Complexity**: Pagination adds state management complexity
   - **Mitigation**: Well-tested view models, clear patterns

2. **UX Changes**: Users might expect to see all items
   - **Mitigation**: Smooth infinite scroll, fast loading

3. **Data Consistency**: Items could change between pages
   - **Mitigation**: Use cursor-based pagination for real-time data

4. **Memory**: Infinite scroll could eventually load everything
   - **Mitigation**: Virtual scrolling, clear old pages

### Trade-offs

**Offset-Based Pagination**:

- ✅ Simple to implement
- ✅ Works well with static data
- ❌ Can skip/duplicate items if data changes
- ❌ Slow for large offsets

**Cursor-Based Pagination**:

- ✅ Consistent results with changing data
- ✅ Fast for any page
- ❌ More complex to implement
- ❌ Can't jump to arbitrary page

**Recommendation**: Start with offset-based, migrate to cursor-based if needed.

## Success Criteria

### Performance

- [ ] Initial page loads in <100ms (20 items)
- [ ] Subsequent pages load in <100ms
- [ ] Memory usage scales with visible items, not total items
- [ ] Smooth scrolling with no stuttering

### Functionality

- [ ] All items eventually loadable via scroll
- [ ] Pull-to-refresh works
- [ ] New items appear correctly
- [ ] Deleted items removed correctly
- [ ] No duplicate items in list

### UX

- [ ] Loading indicators show during fetch
- [ ] Empty state displays when no items
- [ ] "No more items" message at end
- [ ] Scroll position preserved on view return

### Testing

- [ ] Unit tests for pagination logic >90% coverage
- [ ] ViewModel tests pass
- [ ] Performance benchmarks show improvement

## Configuration

### Pagination Settings

```swift
// Common/PaginationConfig.swift
enum PaginationConfig {
    static let defaultPageSize = 20
    static let maxPageSize = 100
    static let prefetchThreshold = 5  // Load next page when 5 items from end
}
```

## Next Steps

1. Review pagination strategy with team
2. Decide: offset-based vs cursor-based
3. Implement Phase 1 (repository support)
4. Create PR for review
5. Proceed with remaining phases

## Related Documents

- `plan-repository-pattern-consistency.md` - Repository changes needed
- `plan-error-handling-improvements.md` - Error handling for failed loads
- `AGENTS.md` - Architecture overview
