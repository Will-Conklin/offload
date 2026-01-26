---
id: plan-tag-relationship-refactor
type: plan
status: archived
owners:
  - Will-Conklin
applies_to:
  - tag
  - relationship
  - refactor
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

# Tag Relationship Refactor Plan

**Priority**: Medium
**Estimated Effort**: Medium-High
**Impact**: Performance, data integrity, and query capability

## Overview

Refactor tag storage from denormalized string arrays to proper SwiftData relationships, enabling efficient querying and maintaining data integrity.

## Problem Statement

### Current Issues

1. **Denormalized Tag Storage** (Item.swift:20):

   ```swift
   @Model final class Item {
       var tags: [String] = []  // Stored as string array
   }
   ```

2. **Inefficient Tag Queries** (ItemRepository.swift:84-90):

   ```swift
   func fetchByTag(_ tag: String) throws -> [Item] {
       let allItems = try modelContext.fetch(descriptor)
       return allItems.filter { $0.tags.contains(tag) }  // Client-side filtering!
   }
   ```

   - Fetches ALL items into memory
   - Filters in Swift code instead of database
   - O(n) complexity, slow with large datasets

3. **No Referential Integrity**:
   - Tag model exists but isn't used for relationships
   - Deleting a Tag doesn't update Items
   - Renaming a Tag requires manual string replacement
   - Tag colors aren't consistently applied

4. **Duplicate Tag Data**:
   - Tag name stored in both Tag model and Item.tags array
   - Tag color only in Tag model, needs lookup
   - No single source of truth

## Current State

### Current Schema

```swift
// Item.swift
@Model final class Item {
    var tags: [String] = []  // String array
}

// Tag.swift
@Model final class Tag {
    var name: String
    var color: String?
    // No relationship to Items
}
```

### Current Tag Lookup Pattern (CaptureView.swift:39-41)

```swift
private var tagLookup: [String: Tag] {
    Dictionary(uniqueKeysWithValues: allTags.map { ($0.name, $0) })
}
```

This is recreated on every view update - expensive!

## Proposed Solution

### New Schema with Relationships

```swift
// Domain/Models/Item.swift
@Model final class Item {
    // ... existing properties ...

    @Relationship(deleteRule: .nullify, inverse: \Tag.items)
    var tags: [Tag]?  // Changed from [String] to [Tag]?

    // Computed property for backwards compatibility during migration
    var tagNames: [String] {
        tags?.map(\.name) ?? []
    }
}

// Domain/Models/Tag.swift
@Model final class Tag {
    @Attribute(.unique) var name: String
    var color: String?

    @Relationship(deleteRule: .nullify, inverse: \Item.tags)
    var items: [Item]?  // New relationship

    init(name: String, color: String? = nil) {
        self.name = name
        self.color = color
    }
}
```

### Relationship Benefits

1. **Efficient Queries**:

   ```swift
   // Before: O(n) client-side filter
   return allItems.filter { $0.tags.contains(tag) }

   // After: O(log n) database query
   let predicate = #Predicate<Item> { item in
       item.tags.contains { $0.name == tagName }
   }
   ```

2. **Referential Integrity**:
   - Delete Tag → Items lose reference (nullify)
   - Update Tag.name → All Items see new name
   - Consistent Tag.color across all usages

3. **Data Normalization**:
   - Single source of truth for tag data
   - No duplicate storage
   - Easier maintenance

## Implementation Steps

### Phase 1: Schema Migration (3-4 hours)

#### 1.1 Create Migration Infrastructure

```swift
// Data/Persistence/Migration/SchemaMigrationPlan.swift
enum OffloadSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [OffloadSchemaV1.self, OffloadSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: OffloadSchemaV1.self,
        toVersion: OffloadSchemaV2.self,
        willMigrate: { context in
            // Tag string array migration logic
        },
        didMigrate: nil
    )
}

// V1 Schema (current)
enum OffloadSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV1.self, CollectionV1.self, TagV1.self, CollectionItemV1.self]
    }

    @Model final class ItemV1 {
        var tags: [String] = []  // Old string array
        // ... other properties
    }
}

// V2 Schema (new)
enum OffloadSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV2.self, CollectionV2.self, TagV2.self, CollectionItemV2.self]
    }

    @Model final class ItemV2 {
        @Relationship(deleteRule: .nullify, inverse: \TagV2.items)
        var tags: [TagV2]?  // New relationship
        // ... other properties
    }

    @Model final class TagV2 {
        @Attribute(.unique) var name: String
        var color: String?

        @Relationship(deleteRule: .nullify, inverse: \ItemV2.tags)
        var items: [ItemV2]?
    }
}
```

#### 1.2 Implement Migration Logic

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: OffloadSchemaV1.self,
    toVersion: OffloadSchemaV2.self,
    willMigrate: { context in
        // 1. Fetch all items with tag strings
        let items = try context.fetch(FetchDescriptor<ItemV1>())

        // 2. Collect unique tag names
        var tagNameSet = Set<String>()
        for item in items {
            tagNameSet.formUnion(item.tags)
        }

        // 3. Create Tag objects for each unique name
        var tagDict: [String: TagV2] = [:]
        for tagName in tagNameSet {
            let tag = TagV2(name: tagName, color: nil)
            context.insert(tag)
            tagDict[tagName] = tag
        }

        // 4. Convert items to V2 schema
        for oldItem in items {
            let newItem = ItemV2()
            // Copy properties...
            newItem.id = oldItem.id
            newItem.content = oldItem.content
            // ... other properties

            // Convert tag strings to Tag relationships
            newItem.tags = oldItem.tags.compactMap { tagDict[$0] }

            context.insert(newItem)
            context.delete(oldItem)
        }

        try context.save()
    },
    didMigrate: nil
)
```

#### 1.3 Update SwiftDataManager

```swift
// Data/Persistence/SwiftDataManager.swift
@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    let container: ModelContainer

    private init() {
        let schema = Schema(versionedSchema: OffloadSchemaV2.self)
        let config = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: OffloadSchemaMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
}
```

### Phase 2: Repository Updates (2-3 hours)

#### 2.1 Update ItemRepository Tag Methods

```swift
// Data/Repositories/ItemRepository.swift
extension ItemRepository {
    // Create with Tag relationships
    func create(
        type: String? = nil,
        content: String,
        tags: [Tag] = [],  // Changed from [String]
        // ... other params
    ) throws -> Item {
        let item = Item(
            type: type,
            content: content,
            // ... other properties
        )
        item.tags = tags

        modelContext.insert(item)
        try modelContext.save()

        Logger.data.info("Created item with \(tags.count) tags")
        return item
    }

    // Efficient tag query using predicate
    func fetchByTag(_ tag: Tag) throws -> [Item] {
        let tagName = tag.name
        let predicate = #Predicate<Item> { item in
            item.tags?.contains { $0.name == tagName } ?? false
        }

        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    // Fetch by tag name (for convenience)
    func fetchByTagName(_ tagName: String) throws -> [Item] {
        let predicate = #Predicate<Item> { item in
            item.tags?.contains { $0.name == tagName } ?? false
        }

        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    // Add tag to item
    func addTag(_ tag: Tag, to item: Item) throws {
        if item.tags == nil {
            item.tags = []
        }

        if !item.tags!.contains(where: { $0.id == tag.id }) {
            item.tags!.append(tag)
            try modelContext.save()

            Logger.data.info("Added tag '\(tag.name)' to item \(item.id)")
        }
    }

    // Remove tag from item
    func removeTag(_ tag: Tag, from item: Item) throws {
        item.tags?.removeAll { $0.id == tag.id }
        try modelContext.save()

        Logger.data.info("Removed tag '\(tag.name)' from item \(item.id)")
    }

    // Update tags for item
    func updateTags(_ tags: [Tag], for item: Item) throws {
        item.tags = tags
        try modelContext.save()

        Logger.data.info("Updated item tags to: \(tags.map(\.name).joined(separator: ", "))")
    }
}
```

#### 2.2 Update TagRepository

```swift
// Data/Repositories/TagRepository.swift
extension TagRepository {
    // Find or create tag by name
    func findOrCreate(name: String, color: String? = nil) throws -> Tag {
        // Try to find existing
        let predicate = #Predicate<Tag> { $0.name == name }
        let descriptor = FetchDescriptor<Tag>(predicate: predicate)

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        // Create new
        let tag = Tag(name: name, color: color)
        modelContext.insert(tag)
        try modelContext.save()

        Logger.data.info("Created new tag: \(name)")
        return tag
    }

    // Get item count for tag (for usage stats)
    func itemCount(for tag: Tag) throws -> Int {
        return tag.items?.count ?? 0
    }

    // Find unused tags (for cleanup)
    func fetchUnusedTags() throws -> [Tag] {
        let allTags = try fetchAll()
        return allTags.filter { ($0.items?.isEmpty ?? true) }
    }

    // Delete unused tags
    func deleteUnused() throws -> Int {
        let unused = try fetchUnusedTags()
        for tag in unused {
            modelContext.delete(tag)
        }
        try modelContext.save()

        Logger.data.info("Deleted \(unused.count) unused tags")
        return unused.count
    }
}
```

### Phase 3: View Updates (3-4 hours)

#### 3.1 Update CaptureComposeView

```swift
// Features/Capture/CaptureComposeView.swift

// Before: @State private var selectedTags: [String] = []
// After:
@State private var selectedTags: [Tag] = []

// Tag picker needs to work with Tag objects
private func toggleTag(_ tag: Tag) {
    if selectedTags.contains(where: { $0.id == tag.id }) {
        selectedTags.removeAll { $0.id == tag.id }
    } else {
        selectedTags.append(tag)
    }
}

// Save with Tag relationships
private func saveItem() {
    do {
        let item = try itemRepository.create(
            content: itemText.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: selectedTags,  // Now Tag array, not String array
            // ... other params
        )
        dismiss()
    } catch {
        errorPresenter.present(error)
    }
}
```

#### 3.2 Update CaptureView

```swift
// Features/Capture/CaptureView.swift

// Remove tagLookup - no longer needed!
// Tag colors now accessed directly via relationship

// Display tags directly
ForEach(item.tags ?? [], id: \.id) { tag in
    TagPill(
        text: tag.name,
        color: Color(hex: tag.color) ?? .blue,
        onRemove: {
            do {
                try itemRepository.removeTag(tag, from: item)
            } catch {
                errorPresenter.present(error)
            }
        }
    )
}
```

#### 3.3 Update CollectionDetailView

```swift
// Features/Organize/CollectionDetailView.swift

// Similar updates for tag display and management
// Use Tag relationships instead of string arrays
```

### Phase 4: Testing (2-3 hours)

#### 4.1 Migration Tests

```swift
// OffloadTests/MigrationTests.swift
@MainActor
class TagMigrationTests: XCTestCase {
    func testMigrateStringTagsToRelationships() throws {
        // 1. Create V1 container with string tags
        let v1Container = try createV1Container()
        let context = v1Container.mainContext

        let item = ItemV1()
        item.tags = ["work", "urgent"]
        context.insert(item)
        try context.save()

        // 2. Run migration
        let v2Container = try ModelContainer(
            for: OffloadSchemaV2.self,
            migrationPlan: OffloadSchemaMigrationPlan.self
        )

        // 3. Verify migration
        let migratedItems = try v2Container.mainContext.fetch(FetchDescriptor<ItemV2>())
        XCTAssertEqual(migratedItems.count, 1)

        let migratedItem = migratedItems[0]
        XCTAssertEqual(migratedItem.tags?.count, 2)
        XCTAssertTrue(migratedItem.tags?.contains { $0.name == "work" } ?? false)
        XCTAssertTrue(migratedItem.tags?.contains { $0.name == "urgent" } ?? false)
    }

    func testDuplicateTagConsolidation() throws {
        // Test that multiple items with same tag name share one Tag object
    }
}
```

#### 4.2 Repository Tests

```swift
// OffloadTests/ItemRepositoryTests.swift
extension ItemRepositoryTests {
    func testFetchByTagUsesPredicateNotFilter() throws {
        // Create items with tags
        let workTag = try tagRepository.create(name: "work")
        let personalTag = try tagRepository.create(name: "personal")

        let item1 = try itemRepository.create(content: "Task 1", tags: [workTag])
        let item2 = try itemRepository.create(content: "Task 2", tags: [personalTag])
        let item3 = try itemRepository.create(content: "Task 3", tags: [workTag, personalTag])

        // Fetch by tag
        let workItems = try itemRepository.fetchByTag(workTag)

        XCTAssertEqual(workItems.count, 2)
        XCTAssertTrue(workItems.contains { $0.id == item1.id })
        XCTAssertTrue(workItems.contains { $0.id == item3.id })
    }

    func testAddTagToItem() throws {
        let item = try itemRepository.create(content: "Test")
        let tag = try tagRepository.create(name: "urgent")

        try itemRepository.addTag(tag, to: item)

        XCTAssertEqual(item.tags?.count, 1)
        XCTAssertEqual(item.tags?.first?.name, "urgent")
    }

    func testRemoveTagFromItem() throws {
        let tag = try tagRepository.create(name: "work")
        let item = try itemRepository.create(content: "Test", tags: [tag])

        try itemRepository.removeTag(tag, from: item)

        XCTAssertEqual(item.tags?.count, 0)
    }
}
```

#### 4.3 Integration Tests

```swift
// OffloadTests/TagIntegrationTests.swift
@MainActor
class TagIntegrationTests: XCTestCase {
    func testTagRenameAffectsAllItems() throws {
        // Create tag and items
        let tag = try tagRepository.create(name: "oldname")
        let item1 = try itemRepository.create(content: "Item 1", tags: [tag])
        let item2 = try itemRepository.create(content: "Item 2", tags: [tag])

        // Rename tag
        tag.name = "newname"
        try tagRepository.save()

        // Verify items reflect new name
        XCTAssertEqual(item1.tags?.first?.name, "newname")
        XCTAssertEqual(item2.tags?.first?.name, "newname")
    }

    func testDeleteTagNullifiesItemRelationships() throws {
        let tag = try tagRepository.create(name: "temp")
        let item = try itemRepository.create(content: "Test", tags: [tag])

        // Delete tag
        try tagRepository.delete(tag)

        // Item should have empty tags
        XCTAssertEqual(item.tags?.count, 0)
    }
}
```

### Phase 5: Performance Verification (1-2 hours)

#### 5.1 Benchmark Tag Queries

```swift
// OffloadTests/PerformanceTests.swift
class TagQueryPerformanceTests: XCTestCase {
    func testFetchByTagPerformance() throws {
        // Create 1000 items with various tags
        let workTag = try tagRepository.create(name: "work")
        for i in 0..<1000 {
            let tags = i % 3 == 0 ? [workTag] : []
            try itemRepository.create(content: "Item \(i)", tags: tags)
        }

        // Measure fetch performance
        measure {
            _ = try! itemRepository.fetchByTag(workTag)
        }
    }
}
```

### Phase 6: Documentation & Cleanup (1 hour)

- [ ] Update AGENTS.md with new tag relationship model
- [ ] Add migration notes to SwiftDataManager comments
- [ ] Update any diagrams or documentation
- [ ] Remove deprecated tagLookup patterns

## Testing Strategy

### Test Coverage

- [ ] Migration logic: 100%
- [ ] Repository tag methods: 100%
- [ ] View tag operations: Manual testing

### Manual Testing Checklist

- [ ] Create new item with tags
- [ ] Add tag to existing item
- [ ] Remove tag from item
- [ ] Edit tag name (verify all items update)
- [ ] Edit tag color (verify all items update)
- [ ] Delete tag (verify items lose reference)
- [ ] Filter items by tag
- [ ] Search for items with specific tag
- [ ] Migrate existing data from V1 to V2

## Risks & Considerations

### Risks

1. **Migration Complexity**: String → Relationship migration could fail
   - **Mitigation**: Comprehensive migration tests, backup before migration

2. **Breaking Changes**: Views expecting string arrays will break
   - **Mitigation**: Phased rollout, backwards-compatible computed properties

3. **Performance**: More complex queries could be slower
   - **Mitigation**: Benchmark tests, ensure predicates are efficient

### Migration Safety

1. **Backup User Data**: Before migration, export data to JSON
2. **Version Check**: Only run migration once
3. **Rollback Plan**: Keep old schema for emergency rollback

## Success Criteria

### Functional

- [ ] Tag relationships work correctly
- [ ] Migration from string tags to relationships succeeds
- [ ] All tag operations function as before
- [ ] Tag colors display consistently

### Performance

- [ ] Tag queries use predicates, not client-side filtering
- [ ] Fetch by tag is O(log n) database query
- [ ] No performance regression in UI

### Data Integrity

- [ ] No duplicate Tag objects for same name
- [ ] Deleting Tag properly nullifies Item relationships
- [ ] Renaming Tag affects all Items

### Testing

- [ ] Migration tests pass
- [ ] Repository tests pass
- [ ] Integration tests pass
- [ ] Performance benchmarks meet targets

## Next Steps

1. Review migration strategy
2. Implement migration infrastructure
3. Test migration with sample data
4. Roll out to views incrementally
5. Monitor for issues

## Related Documents

- `plan-error-handling-improvements.md` - Error handling for migration failures
- `plan-repository-pattern-consistency.md` - Repository updates needed
- `AGENTS.md` - Architecture overview
- `ios/Offload/Domain/Models/Tag.swift` - Current Tag model
- `ios/Offload/Domain/Models/Item.swift` - Current Item model
