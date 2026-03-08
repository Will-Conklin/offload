// Purpose: Unit tests for Offload.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

//  OffloadTests

@testable import Offload
import SwiftData
import XCTest

@MainActor
final class ItemRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ItemRepository!
    var attachmentStorage: AttachmentStorageService!
    var attachmentStorageDirectory: URL!

    override func setUp() async throws {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        attachmentStorageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("offload-item-repository-tests-\(UUID().uuidString)", isDirectory: true)
        attachmentStorage = AttachmentStorageService(baseDirectoryURL: attachmentStorageDirectory)
        repository = ItemRepository(
            modelContext: modelContext,
            attachmentStorage: attachmentStorage
        )
    }

    override func tearDown() {
        if let attachmentStorageDirectory {
            try? FileManager.default.removeItem(at: attachmentStorageDirectory)
        }
        attachmentStorage = nil
        attachmentStorageDirectory = nil
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    // MARK: - Create Tests

    func testCreateBasicItem() throws {
        let item = try repository.create(content: "Test item")

        XCTAssertEqual(item.content, "Test item")
        XCTAssertNil(item.type)
        XCTAssertFalse(item.isStarred)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertNil(item.completedAt)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
    }

    func testCreateItemWithType() throws {
        let item = try repository.create(type: "task", content: "Task item")

        XCTAssertEqual(item.type, "task")
        XCTAssertEqual(item.content, "Task item")
    }

    func testCreateStarredItem() throws {
        let item = try repository.create(content: "Important item", isStarred: true)

        XCTAssertTrue(item.isStarred)
    }

    func testCreateItemWithTags() throws {
        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        modelContext.insert(urgent)
        modelContext.insert(work)
        try modelContext.save()
        let item = try repository.create(content: "Tagged item", tags: [urgent, work])

        XCTAssertEqual(item.tags.count, 2)
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == work.id }))
    }

    func testCreateItemWithFollowUpDate() throws {
        let followUpDate = Date().addingTimeInterval(86400) // tomorrow
        let item = try repository.create(content: "Follow up item", followUpDate: followUpDate)

        XCTAssertNotNil(item.followUpDate)
        if let storedDate = item.followUpDate {
            XCTAssertEqual(storedDate.timeIntervalSince1970, followUpDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected followUpDate to be set")
        }
    }

    func testCreateItemWithAttachment_StoresFilePathAndClearsInlineData() throws {
        let attachmentData = Data([0x01, 0x02, 0x03, 0x04])

        let item = try repository.create(content: "Has attachment", attachmentData: attachmentData)

        XCTAssertNil(item.attachmentData)
        let attachmentPath = try XCTUnwrap(item.attachmentFilePath)
        XCTAssertTrue(attachmentStorage.attachmentExists(at: attachmentPath))
        XCTAssertEqual(try repository.attachmentData(for: item), attachmentData)
    }

    func testUpdateContent_PreservesFileBackedAttachment() throws {
        let attachmentData = Data([0x10, 0x20, 0x30])
        let item = try repository.create(content: "Attachment save path", attachmentData: attachmentData)
        let attachmentPath = try XCTUnwrap(item.attachmentFilePath)

        try repository.updateContent(item, content: "Updated content")

        XCTAssertEqual(item.content, "Updated content")
        XCTAssertEqual(item.attachmentFilePath, attachmentPath)
        XCTAssertTrue(attachmentStorage.attachmentExists(at: attachmentPath))
        XCTAssertEqual(try repository.attachmentData(for: item), attachmentData)
    }

    func testAttachmentData_RejectsOutsideManagedStorage() throws {
        let item = try repository.create(content: "Invalid path")
        item.attachmentFilePath = "/tmp/offload-outside-managed-storage.attachment"
        try modelContext.save()

        XCTAssertThrowsError(try repository.attachmentData(for: item)) { error in
            guard let validationError = error as? ValidationError else {
                return XCTFail("Expected ValidationError, got \(error)")
            }
            XCTAssertEqual(validationError.message, "Attachment path is outside app-managed storage.")
        }
    }

    func testUpdateAttachment_ReplacesFileAndRemovesOldFile() throws {
        let item = try repository.create(
            content: "Replace attachment",
            attachmentData: Data([0xAA, 0xBB])
        )
        let oldAttachmentPath = try XCTUnwrap(item.attachmentFilePath)
        XCTAssertTrue(attachmentStorage.attachmentExists(at: oldAttachmentPath))

        let replacementData = Data([0xCC, 0xDD, 0xEE])
        try repository.updateAttachment(item, attachmentData: replacementData)

        let newAttachmentPath = try XCTUnwrap(item.attachmentFilePath)
        XCTAssertNotEqual(oldAttachmentPath, newAttachmentPath)
        XCTAssertFalse(attachmentStorage.attachmentExists(at: oldAttachmentPath))
        XCTAssertTrue(attachmentStorage.attachmentExists(at: newAttachmentPath))
        XCTAssertEqual(try repository.attachmentData(for: item), replacementData)
    }

    func testUpdateAttachment_DoesNotRollbackWhenOldCleanupFails() throws {
        let isolatedDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("offload-item-repository-cleanup-fail-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: isolatedDirectory) }

        let cleanupStorage = ThrowingCleanupAttachmentStorage(baseDirectoryURL: isolatedDirectory)
        let cleanupRepository = ItemRepository(
            modelContext: modelContext,
            attachmentStorage: cleanupStorage
        )

        let item = try cleanupRepository.create(
            content: "Cleanup failure",
            attachmentData: Data([0x01, 0x02])
        )
        let oldAttachmentPath = try XCTUnwrap(item.attachmentFilePath)

        cleanupStorage.shouldThrowOnRemove = true
        let replacementData = Data([0x03, 0x04, 0x05])
        XCTAssertNoThrow(try cleanupRepository.updateAttachment(item, attachmentData: replacementData))

        let newAttachmentPath = try XCTUnwrap(item.attachmentFilePath)
        XCTAssertNotEqual(oldAttachmentPath, newAttachmentPath)
        XCTAssertTrue(cleanupStorage.attachmentExists(at: oldAttachmentPath))
        XCTAssertTrue(cleanupStorage.attachmentExists(at: newAttachmentPath))
        XCTAssertEqual(try cleanupRepository.attachmentData(for: item), replacementData)
    }

    func testDelete_RemovesAttachmentFile() throws {
        let item = try repository.create(
            content: "Delete attachment",
            attachmentData: Data([0x42, 0x43])
        )
        let attachmentPath = try XCTUnwrap(item.attachmentFilePath)
        XCTAssertTrue(attachmentStorage.attachmentExists(at: attachmentPath))

        try repository.delete(item)

        XCTAssertFalse(attachmentStorage.attachmentExists(at: attachmentPath))
    }

    func testTypedMetadata_RoundTripsUnknownKeys() throws {
        let item = try repository.create(content: "Metadata test")
        let metadata = ItemMetadata(
            attachmentFilePath: "/tmp/attachment.dat",
            extensions: [
                "priority": .string("high"),
                "retry_count": .int(3),
                "score": .double(9.5),
                "flags": .array([.string("urgent"), .bool(true)]),
                "nested": .object([
                    "enabled": .bool(true),
                    "channel": .string("beta"),
                ]),
            ]
        )

        try repository.updateMetadata(item, metadata: metadata)

        let reloaded = repository.metadata(for: item)
        XCTAssertEqual(reloaded, metadata)
    }

    func testTypedMetadata_BackwardCompatibleWithLegacyJSONString() throws {
        let item = try repository.create(content: "Legacy metadata")
        item.metadata = #"{"legacy_text":"hello","legacy_count":4,"legacy_nested":{"ok":true}}"#
        try modelContext.save()

        var decodedMetadata = repository.metadata(for: item)
        XCTAssertNil(decodedMetadata.attachmentFilePath)
        XCTAssertEqual(decodedMetadata.extensions["legacy_text"], .string("hello"))
        XCTAssertEqual(decodedMetadata.extensions["legacy_count"], .int(4))
        XCTAssertEqual(
            decodedMetadata.extensions["legacy_nested"],
            .object(["ok": .bool(true)])
        )

        decodedMetadata.attachmentFilePath = "/tmp/new-path.png"
        try repository.updateMetadata(item, metadata: decodedMetadata)

        let roundTripped = repository.metadata(for: item)
        XCTAssertEqual(roundTripped.attachmentFilePath, "/tmp/new-path.png")
        XCTAssertEqual(roundTripped.extensions["legacy_text"], .string("hello"))
        XCTAssertEqual(roundTripped.extensions["legacy_count"], .int(4))
        XCTAssertEqual(
            roundTripped.extensions["legacy_nested"],
            .object(["ok": .bool(true)])
        )
    }

    func testTypedMetadata_DictionaryBridgePreservesNSNumberNumericSemantics() {
        let metadata = ItemMetadata(dictionary: [
            "count": NSNumber(value: 1),
            "enabled": NSNumber(value: true),
            "ratio": NSNumber(value: 1.5),
        ])

        XCTAssertEqual(metadata.extensions["count"], .int(1))
        XCTAssertEqual(metadata.extensions["enabled"], .bool(true))
        XCTAssertEqual(metadata.extensions["ratio"], .double(1.5))
    }

    // MARK: - Fetch Tests

    func testFetchAll() throws {
        try repository.create(content: "Item 1")
        try repository.create(content: "Item 2")
        try repository.create(content: "Item 3")

        let items = try repository.fetchAll()
        XCTAssertEqual(items.count, 3)
    }

    func testFetchAllSortedByCreatedAt() throws {
        let item1 = try repository.create(content: "First")
        Thread.sleep(forTimeInterval: 0.01)
        let item2 = try repository.create(content: "Second")
        Thread.sleep(forTimeInterval: 0.01)
        let item3 = try repository.create(content: "Third")

        let items = try repository.fetchAll()

        // Should be sorted in reverse chronological order (newest first)
        XCTAssertEqual(items[0].id, item3.id)
        XCTAssertEqual(items[1].id, item2.id)
        XCTAssertEqual(items[2].id, item1.id)
    }

    func testFetchById() throws {
        let item = try repository.create(content: "Find me")

        let fetched = try repository.fetchById(item.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, item.id)
        XCTAssertEqual(fetched?.content, "Find me")
    }

    func testFetchByIdNotFound() throws {
        let fetched = try repository.fetchById(UUID())
        XCTAssertNil(fetched)
    }

    func testFetchByType() throws {
        try repository.create(type: "task", content: "Task 1")
        try repository.create(type: "task", content: "Task 2")
        try repository.create(type: "link", content: "Link 1")
        try repository.create(type: "idea", content: "Idea 1")
        try repository.create(type: "concern", content: "Concern 1")
        try repository.create(content: "Capture")

        let tasks = try repository.fetchByType("task")
        XCTAssertEqual(tasks.count, 2)

        let links = try repository.fetchByType("link")
        XCTAssertEqual(links.count, 1)

        let ideas = try repository.fetchByType("idea")
        XCTAssertEqual(ideas.count, 1)

        let concerns = try repository.fetchByType("concern")
        XCTAssertEqual(concerns.count, 1)
    }

    func testFetchCaptureItemsByTypeExcludesCompleted() throws {
        try repository.create(type: "idea", content: "Active idea")
        let completedIdea = try repository.create(type: "idea", content: "Completed idea")
        try repository.complete(completedIdea)

        let results = try repository.fetchCaptureItemsByType("idea", limit: 50, offset: 0)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].content, "Active idea")
    }

    func testFetchCaptureItemsByTypeExcludesLinked() throws {
        let linkedId = UUID()
        try repository.create(type: "note", content: "Standalone note")
        try repository.create(type: "note", content: "Linked note", linkedCollectionId: linkedId)

        let results = try repository.fetchCaptureItemsByType("note", limit: 50, offset: 0)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].content, "Standalone note")
    }

    func testFetchStarred() throws {
        try repository.create(content: "Not starred")
        try repository.create(content: "Starred 1", isStarred: true)
        try repository.create(content: "Starred 2", isStarred: true)

        let starred = try repository.fetchStarred()
        XCTAssertEqual(starred.count, 2)
        XCTAssertTrue(starred.allSatisfy(\.isStarred))
    }

    func testFetchWithFollowUp() throws {
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(86400 * 7)

        try repository.create(content: "No follow up")
        try repository.create(content: "Follow up 1", followUpDate: nextWeek)
        try repository.create(content: "Follow up 2", followUpDate: tomorrow)

        let items = try repository.fetchWithFollowUp()
        XCTAssertEqual(items.count, 2)

        // Should be sorted by followUpDate (earliest first)
        XCTAssertEqual(items[0].content, "Follow up 2")
        XCTAssertEqual(items[1].content, "Follow up 1")
    }

    func testFetchByTag() throws {
        let work = Tag(name: "work")
        let urgent = Tag(name: "urgent")
        let personal = Tag(name: "personal")
        modelContext.insert(work)
        modelContext.insert(urgent)
        modelContext.insert(personal)
        try modelContext.save()

        try repository.create(content: "Item 1", tags: [work])
        try repository.create(content: "Item 2", tags: [work, urgent])
        try repository.create(content: "Item 3", tags: [personal])

        let workItems = try repository.fetchByTag(work)
        XCTAssertEqual(workItems.count, 2)

        let urgentItems = try repository.fetchByTag(urgent)
        XCTAssertEqual(urgentItems.count, 1)

        let personalItems = try repository.fetchByTag(personal)
        XCTAssertEqual(personalItems.count, 1)
    }

    func testSearchByContent() throws {
        try repository.create(content: "Buy groceries at the store")
        try repository.create(content: "Call dentist for appointment")
        try repository.create(content: "Review budget analysis")

        let results = try repository.searchByContent("budget")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].content, "Review budget analysis")
    }

    func testSearchByContentCaseInsensitive() throws {
        try repository.create(content: "IMPORTANT MEETING")
        try repository.create(content: "important call")
        try repository.create(content: "Something else")

        let results = try repository.searchByContent("important")
        XCTAssertEqual(results.count, 2)
    }

    func testFetchUncategorized() throws {
        try repository.create(content: "Capture 1")
        try repository.create(type: "task", content: "Task")
        try repository.create(content: "Capture 2")

        let captures = try repository.fetchUncategorized()
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.allSatisfy { $0.type == nil })
    }

    func testFetchCompleted() throws {
        let item1 = try repository.create(content: "Complete me")
        try repository.complete(item1)

        try repository.create(content: "Incomplete")

        let item2 = try repository.create(content: "Also complete")
        try repository.complete(item2)

        let completed = try repository.fetchCompleted()
        XCTAssertEqual(completed.count, 2)
        XCTAssertTrue(completed.allSatisfy { $0.completedAt != nil })
    }

    func testFetchIncomplete() throws {
        let item = try repository.create(content: "Complete this")
        try repository.complete(item)

        try repository.create(content: "Incomplete 1")
        try repository.create(content: "Incomplete 2")

        let incomplete = try repository.fetchIncomplete()
        XCTAssertEqual(incomplete.count, 2)
        XCTAssertTrue(incomplete.allSatisfy { $0.completedAt == nil })
    }

    func testFetchCaptures() throws {
        // Captures are: not linked to a collection AND not completed (type is irrelevant)
        try repository.create(content: "Active capture")

        let completed = try repository.create(content: "Completed capture")
        try repository.complete(completed)

        try repository.create(type: "task", content: "Task")

        let captures = try repository.fetchCaptureItems()
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.allSatisfy { $0.linkedCollectionId == nil && $0.completedAt == nil })
    }

    func testFetchCaptureItemsPage() throws {
        let base = Date()
        let item1 = try repository.create(content: "Older")
        let item2 = try repository.create(content: "Middle")
        let item3 = try repository.create(content: "Newest")

        item1.createdAt = base.addingTimeInterval(-30)
        item2.createdAt = base.addingTimeInterval(-10)
        item3.createdAt = base
        try modelContext.save()

        let firstPage = try repository.fetchCaptureItems(limit: 2, offset: 0)
        XCTAssertEqual(firstPage.map(\.id), [item3.id, item2.id])

        let secondPage = try repository.fetchCaptureItems(limit: 2, offset: 2)
        XCTAssertEqual(secondPage.map(\.id), [item1.id])
    }

    // MARK: - Update Tests

    func testUpdate() throws {
        let item = try repository.create(content: "Original")

        item.content = "Modified"
        try repository.update(item)

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.content, "Modified")
    }

    func testUpdateType() throws {
        let item = try repository.create(content: "Item")
        XCTAssertNil(item.type)

        try repository.updateType(item, type: "task")
        XCTAssertEqual(item.type, "task")

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.type, "task")
    }

    func testUpdateContent() throws {
        let item = try repository.create(content: "Old content")

        try repository.updateContent(item, content: "New content")

        XCTAssertEqual(item.content, "New content")

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.content, "New content")
    }

    func testToggleStar() throws {
        let item = try repository.create(content: "Item")
        XCTAssertFalse(item.isStarred)

        try repository.toggleStar(item)
        XCTAssertTrue(item.isStarred)

        try repository.toggleStar(item)
        XCTAssertFalse(item.isStarred)
    }

    func testAddTag() throws {
        let item = try repository.create(content: "Item")
        XCTAssertTrue(item.tags.isEmpty)

        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        modelContext.insert(urgent)
        modelContext.insert(work)
        try modelContext.save()

        try repository.addTag(item, tag: urgent)
        XCTAssertEqual(item.tags.count, 1)
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))

        try repository.addTag(item, tag: work)
        XCTAssertEqual(item.tags.count, 2)
        XCTAssertTrue(item.tags.contains(where: { $0.id == work.id }))
    }

    func testAddDuplicateTag() throws {
        let urgent = Tag(name: "urgent")
        modelContext.insert(urgent)
        try modelContext.save()
        let item = try repository.create(content: "Item", tags: [urgent])

        try repository.addTag(item, tag: urgent)

        // Should not add duplicate
        XCTAssertEqual(item.tags.count, 1)
    }

    func testRemoveTag() throws {
        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        let personal = Tag(name: "personal")
        modelContext.insert(urgent)
        modelContext.insert(work)
        modelContext.insert(personal)
        try modelContext.save()
        let item = try repository.create(content: "Item", tags: [urgent, work, personal])

        try repository.removeTag(item, tag: work)

        XCTAssertEqual(item.tags.count, 2)
        XCTAssertFalse(item.tags.contains(where: { $0.id == work.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == personal.id }))
    }

    func testUpdateFollowUpDate() throws {
        let item = try repository.create(content: "Item")
        XCTAssertNil(item.followUpDate)

        let tomorrow = Date().addingTimeInterval(86400)
        try repository.updateFollowUpDate(item, date: tomorrow)

        XCTAssertNotNil(item.followUpDate)
        if let storedDate = item.followUpDate {
            XCTAssertEqual(storedDate.timeIntervalSince1970, tomorrow.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected followUpDate to be set")
        }

        // Can clear follow up date
        try repository.updateFollowUpDate(item, date: nil)
        XCTAssertNil(item.followUpDate)
    }

    func testComplete() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)

        try repository.complete(item)

        XCTAssertNotNil(item.completedAt)
        XCTAssertTrue(item.isCompleted)
    }

    func testUncomplete() throws {
        let item = try repository.create(content: "Task")
        try repository.complete(item)

        XCTAssertNotNil(item.completedAt)

        try repository.uncomplete(item)

        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)
    }

    func testToggleCompletion() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)

        try repository.toggleCompletion(item)
        XCTAssertNotNil(item.completedAt)
        XCTAssertTrue(item.isCompleted)

        try repository.toggleCompletion(item)
        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)
    }

    func testMarkCompleted() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)

        try repository.markCompleted(item)
        XCTAssertNotNil(item.completedAt)

        let firstCompletion = item.completedAt
        try repository.markCompleted(item)
        XCTAssertEqual(item.completedAt, firstCompletion)
    }

    func testMarkAllCompleted() throws {
        let item1 = try repository.create(content: "Task 1")
        let item2 = try repository.create(content: "Task 2")
        let item3 = try repository.create(content: "Task 3")

        try repository.markAllCompleted([item1, item2, item3])

        XCTAssertNotNil(item1.completedAt)
        XCTAssertNotNil(item2.completedAt)
        XCTAssertNotNil(item3.completedAt)
    }

    func testMoveToCollection() throws {
        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")

        try repository.moveToCollection(item, collection: collection, position: 0)

        let fetchedCollection = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(fetchedCollection?.collectionItems?.count, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.itemId, item.id)
    }

    func testMoveToCollectionAtomicallyUpdatesTypeAndCreatesLink() throws {
        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")

        try repository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: 0)

        let fetchedCollection = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(item.type, "task")
        XCTAssertEqual(fetchedCollection?.collectionItems?.count, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.itemId, item.id)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.position, 0)
    }

    func testMoveToCollectionAtomicallyDoesNotCreateDuplicateLink() throws {
        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")

        try repository.moveToCollection(item, collection: collection, position: 0)
        try repository.moveToCollectionAtomically(item, collection: collection, targetType: "task", position: 5)

        let fetchedCollection = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(item.type, "task")
        XCTAssertEqual(fetchedCollection?.collectionItems?.count, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.position, 5)
    }

    func testMoveToCollectionAtomicallyRollsBackWhenCollectionNotPersisted() throws {
        let item = try repository.create(content: "Move me")
        let missingCollection = Collection(name: "Missing", isStructured: true)

        XCTAssertThrowsError(
            try repository.moveToCollectionAtomically(
                item,
                collection: missingCollection,
                targetType: "task",
                position: 0
            )
        )

        XCTAssertNil(item.type)
        let itemId = item.id
        let links = try modelContext.fetch(
            FetchDescriptor<CollectionItem>(
                predicate: #Predicate { $0.itemId == itemId }
            )
        )
        XCTAssertTrue(links.isEmpty)
    }

    func testMoveToCollectionAtomicallyRollsBackWhenSaveActionThrows() throws {
        enum TestError: Error { case expected }

        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")

        XCTAssertThrowsError(
            try repository.moveToCollectionAtomically(
                item,
                collection: collection,
                targetType: "task",
                position: 0,
                saveAction: { throw TestError.expected }
            )
        )

        XCTAssertNil(item.type)
        let itemId = item.id
        let links = try modelContext.fetch(
            FetchDescriptor<CollectionItem>(
                predicate: #Predicate { $0.itemId == itemId }
            )
        )
        XCTAssertTrue(links.isEmpty)
    }

    func testMoveToCollectionAtomicallyRestoresExistingLinkWhenSaveActionThrows() throws {
        enum TestError: Error { case expected }

        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")
        try repository.moveToCollection(item, collection: collection, position: 1)

        XCTAssertThrowsError(
            try repository.moveToCollectionAtomically(
                item,
                collection: collection,
                targetType: "task",
                position: 9,
                saveAction: { throw TestError.expected }
            )
        )

        XCTAssertNil(item.type)
        let fetchedCollection = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(fetchedCollection?.collectionItems?.count, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.position, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.parentId, nil)
    }

    func testValidate() throws {
        let item = try repository.create(content: "  ")
        XCTAssertFalse(try repository.validate(item))

        try repository.updateContent(item, content: "Valid")
        XCTAssertTrue(try repository.validate(item))
    }

    // MARK: - Delete Tests

    func testDelete() throws {
        let item = try repository.create(content: "Delete me")

        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(item)

        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testDeleteMultiple() throws {
        let item1 = try repository.create(content: "Item 1")
        let item2 = try repository.create(content: "Item 2")
        let item3 = try repository.create(content: "Item 3")

        XCTAssertEqual(try repository.fetchAll().count, 3)

        try repository.deleteMultiple([item1, item3])

        let remaining = try repository.fetchAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, item2.id)
    }

    func testDeleteAll() throws {
        let item1 = try repository.create(content: "Item 1")
        let item2 = try repository.create(content: "Item 2")

        try repository.deleteAll([item1, item2])

        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    // MARK: - Home Dashboard Fetch Tests

    func testFetchCapturedThisWeek() throws {
        let item1 = try repository.create(content: "This week 1")
        let item2 = try repository.create(content: "This week 2")
        let oldItem = try repository.create(content: "Old item")

        // Push oldItem's createdAt to 8 days ago
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        oldItem.createdAt = eightDaysAgo
        try modelContext.save()

        let results = try repository.fetchCapturedThisWeek()
        let resultIds = Set(results.map(\.id))

        XCTAssertTrue(resultIds.contains(item1.id))
        XCTAssertTrue(resultIds.contains(item2.id))
        XCTAssertFalse(resultIds.contains(oldItem.id))
        XCTAssertEqual(results.count, 2)
    }

    func testFetchCompletedThisWeek() throws {
        let completedToday1 = try repository.create(content: "Done 1")
        completedToday1.completedAt = Date()
        let completedToday2 = try repository.create(content: "Done 2")
        completedToday2.completedAt = Date()

        let completedOld = try repository.create(content: "Done long ago")
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        completedOld.completedAt = eightDaysAgo

        _ = try repository.create(content: "Incomplete")

        try modelContext.save()

        let results = try repository.fetchCompletedThisWeek()
        let resultIds = Set(results.map(\.id))

        XCTAssertTrue(resultIds.contains(completedToday1.id))
        XCTAssertTrue(resultIds.contains(completedToday2.id))
        XCTAssertFalse(resultIds.contains(completedOld.id))
        XCTAssertEqual(results.count, 2)
    }

    func testFetchItemsWithFollowUpDate() throws {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let inTwo = Calendar.current.date(byAdding: .day, value: 2, to: now)!
        let inFive = Calendar.current.date(byAdding: .day, value: 5, to: now)!
        let inTen = Calendar.current.date(byAdding: .day, value: 10, to: now)!

        let pastItem = try repository.create(content: "Past", followUpDate: yesterday)
        let inTwoItem = try repository.create(content: "In 2", followUpDate: inTwo)
        let inFiveItem = try repository.create(content: "In 5", followUpDate: inFive)
        let inTenItem = try repository.create(content: "In 10", followUpDate: inTen)
        _ = pastItem; _ = inTenItem // referenced for clarity

        let sevenDaysOut = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let results = try repository.fetchItemsWithFollowUpDate(from: now, to: sevenDaysOut)
        let resultIds = Set(results.map(\.id))

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(resultIds.contains(inTwoItem.id))
        XCTAssertTrue(resultIds.contains(inFiveItem.id))
    }

    func testFetchItemsWithFollowUpDate_excludesCompleted() throws {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        let completedItem = try repository.create(content: "Completed", followUpDate: tomorrow)
        completedItem.completedAt = Date()
        try modelContext.save()

        let results = try repository.fetchItemsWithFollowUpDate(from: now, to: nextWeek)
        XCTAssertTrue(results.isEmpty, "Completed items should not appear in timeline")
    }
}

private final class ThrowingCleanupAttachmentStorage: AttachmentStorage {
    private let backingStorage: AttachmentStorageService
    var shouldThrowOnRemove = false

    init(baseDirectoryURL: URL) {
        backingStorage = AttachmentStorageService(baseDirectoryURL: baseDirectoryURL)
    }

    func storeAttachment(_ data: Data, for itemId: UUID) throws -> String {
        try backingStorage.storeAttachment(data, for: itemId)
    }

    func loadAttachment(at path: String) throws -> Data {
        try backingStorage.loadAttachment(at: path)
    }

    func removeAttachment(at path: String) throws {
        if shouldThrowOnRemove {
            throw NSError(domain: "OffloadTests.ThrowingCleanupAttachmentStorage", code: 1)
        }
        try backingStorage.removeAttachment(at: path)
    }

    func attachmentExists(at path: String) -> Bool {
        backingStorage.attachmentExists(at: path)
    }
}
