//
//  CommunicationRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class CommunicationRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: CommunicationRepository!

    override func setUp() async throws {
        let schema = Schema([
            CaptureEntry.self,
            HandOffRequest.self,
            HandOffRun.self,
            Suggestion.self,
            SuggestionDecision.self,
            Placement.self,
            Plan.self,
            Task.self,
            Tag.self,
            Category.self,
            ListEntity.self,
            ListItem.self,
            CommunicationItem.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        repository = CommunicationRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreateCommunicationItem() throws {
        let item = CommunicationItem(
            channel: .email,
            recipient: "john@example.com",
            content: "Ask about project status"
        )

        try repository.create(item: item)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.communicationChannel, .email)
        XCTAssertEqual(fetched.first?.recipient, "john@example.com")
        XCTAssertEqual(fetched.first?.communicationStatus, .draft)
    }

    func testFetchByChannel() throws {
        let item1 = CommunicationItem(channel: .email, recipient: "john@example.com", content: "Test 1")
        let item2 = CommunicationItem(channel: .call, recipient: "Jane", content: "Test 2")
        let item3 = CommunicationItem(channel: .email, recipient: "bob@example.com", content: "Test 3")

        try repository.create(item: item1)
        try repository.create(item: item2)
        try repository.create(item: item3)

        let emails = try repository.fetchByChannel(.email)
        XCTAssertEqual(emails.count, 2)

        let calls = try repository.fetchByChannel(.call)
        XCTAssertEqual(calls.count, 1)
    }

    func testFetchByStatus() throws {
        let item1 = CommunicationItem(channel: .email, recipient: "john@example.com", content: "Test 1", status: .draft)
        let item2 = CommunicationItem(channel: .call, recipient: "Jane", content: "Test 2", status: .sent)
        let item3 = CommunicationItem(channel: .text, recipient: "Bob", content: "Test 3", status: .draft)

        try repository.create(item: item1)
        try repository.create(item: item2)
        try repository.create(item: item3)

        let drafts = try repository.fetchByStatus(.draft)
        XCTAssertEqual(drafts.count, 2)

        let sent = try repository.fetchByStatus(.sent)
        XCTAssertEqual(sent.count, 1)
    }

    func testFetchDrafts() throws {
        let item1 = CommunicationItem(channel: .email, recipient: "john@example.com", content: "Test 1", status: .draft)
        let item2 = CommunicationItem(channel: .call, recipient: "Jane", content: "Test 2", status: .sent)

        try repository.create(item: item1)
        try repository.create(item: item2)

        let drafts = try repository.fetchDrafts()
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.content, "Test 1")
    }

    func testFetchByRecipient() throws {
        let item1 = CommunicationItem(channel: .email, recipient: "john@example.com", content: "Test 1")
        let item2 = CommunicationItem(channel: .call, recipient: "Jane Doe", content: "Test 2")
        let item3 = CommunicationItem(channel: .email, recipient: "john@work.com", content: "Test 3")

        try repository.create(item: item1)
        try repository.create(item: item2)
        try repository.create(item: item3)

        let johnItems = try repository.fetchByRecipient("john")
        XCTAssertEqual(johnItems.count, 2)

        let janeItems = try repository.fetchByRecipient("Jane")
        XCTAssertEqual(janeItems.count, 1)
    }

    func testMarkAsSent() throws {
        let item = CommunicationItem(
            channel: .email,
            recipient: "john@example.com",
            content: "Test",
            status: .draft
        )

        try repository.create(item: item)
        XCTAssertEqual(item.communicationStatus, .draft)

        try repository.markAsSent(item: item)
        XCTAssertEqual(item.communicationStatus, .sent)
    }

    func testMarkAsDeferred() throws {
        let item = CommunicationItem(
            channel: .call,
            recipient: "Jane",
            content: "Test",
            status: .draft
        )

        try repository.create(item: item)
        XCTAssertEqual(item.communicationStatus, .draft)

        try repository.markAsDeferred(item: item)
        XCTAssertEqual(item.communicationStatus, .deferred)
    }

    func testUpdateItem() throws {
        let item = CommunicationItem(
            channel: .email,
            recipient: "john@example.com",
            content: "Original content"
        )

        try repository.create(item: item)

        item.content = "Updated content"
        try repository.update(item: item)

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.content, "Updated content")
    }

    func testDeleteItem() throws {
        let item = CommunicationItem(
            channel: .email,
            recipient: "john@example.com",
            content: "Test"
        )

        try repository.create(item: item)
        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(item: item)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }
}
