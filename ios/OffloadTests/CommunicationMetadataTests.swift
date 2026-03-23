// Purpose: Tests for CommunicationChannel, CommunicationMetadata, and ItemMetadata communication accessors.
// Authority: Code-level
// Governed by: CLAUDE.md

import XCTest
@testable import Offload

final class CommunicationMetadataTests: XCTestCase {
    // MARK: - CommunicationChannel

    func testChannelDisplayNames() {
        XCTAssertEqual(CommunicationChannel.call.displayName, "Call")
        XCTAssertEqual(CommunicationChannel.text.displayName, "Text")
        XCTAssertEqual(CommunicationChannel.email.displayName, "Email")
    }

    func testChannelIcons() {
        XCTAssertEqual(CommunicationChannel.call.icon, Icons.channelCall)
        XCTAssertEqual(CommunicationChannel.text.icon, Icons.channelText)
        XCTAssertEqual(CommunicationChannel.email.icon, Icons.channelEmail)
    }

    func testChannelURLSchemes() {
        XCTAssertEqual(CommunicationChannel.call.urlScheme, "tel:")
        XCTAssertEqual(CommunicationChannel.text.urlScheme, "sms:")
        XCTAssertEqual(CommunicationChannel.email.urlScheme, "mailto:")
    }

    func testChannelAllCases() {
        XCTAssertEqual(CommunicationChannel.allCases.count, 3)
    }

    // MARK: - CommunicationMetadata Codable

    func testCommunicationMetadataEncodeDecode() throws {
        let meta = CommunicationMetadata(
            channel: .call,
            contactName: "Jane Doe",
            contactIdentifier: "ABC-123",
            contactValue: "+15551234567"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(meta)
        let decoded = try JSONDecoder().decode(CommunicationMetadata.self, from: data)

        XCTAssertEqual(decoded.channel, .call)
        XCTAssertEqual(decoded.contactName, "Jane Doe")
        XCTAssertEqual(decoded.contactIdentifier, "ABC-123")
        XCTAssertEqual(decoded.contactValue, "+15551234567")
    }

    func testCommunicationMetadataWithNilFields() throws {
        let meta = CommunicationMetadata(channel: .email)

        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(CommunicationMetadata.self, from: data)

        XCTAssertEqual(decoded.channel, .email)
        XCTAssertNil(decoded.contactName)
        XCTAssertNil(decoded.contactIdentifier)
        XCTAssertNil(decoded.contactValue)
    }

    // MARK: - ItemMetadata.communicationMetadata accessor

    func testItemMetadataGetSetCommunication() {
        var itemMeta = ItemMetadata()
        XCTAssertNil(itemMeta.communicationMetadata)

        let commMeta = CommunicationMetadata(
            channel: .text,
            contactName: "John",
            contactValue: "+15559876543"
        )
        itemMeta.communicationMetadata = commMeta

        let retrieved = itemMeta.communicationMetadata
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.channel, .text)
        XCTAssertEqual(retrieved?.contactName, "John")
        XCTAssertEqual(retrieved?.contactValue, "+15559876543")
    }

    func testItemMetadataCommunicationRemoval() {
        var itemMeta = ItemMetadata()
        itemMeta.communicationMetadata = CommunicationMetadata(channel: .call)
        XCTAssertNotNil(itemMeta.communicationMetadata)

        itemMeta.communicationMetadata = nil
        XCTAssertNil(itemMeta.communicationMetadata)
        XCTAssertNil(itemMeta.extensions[ItemMetadata.communicationKey])
    }

    func testItemMetadataCommunicationRoundTrip() {
        var itemMeta = ItemMetadata()
        itemMeta.communicationMetadata = CommunicationMetadata(
            channel: .email,
            contactName: "Alice",
            contactIdentifier: "XYZ-789",
            contactValue: "alice@example.com"
        )

        // Encode to JSON string and decode back
        let jsonString = itemMeta.encodeToJSONString()
        let decoded = ItemMetadata.decode(from: jsonString)

        let comm = decoded.communicationMetadata
        XCTAssertNotNil(comm)
        XCTAssertEqual(comm?.channel, .email)
        XCTAssertEqual(comm?.contactName, "Alice")
        XCTAssertEqual(comm?.contactIdentifier, "XYZ-789")
        XCTAssertEqual(comm?.contactValue, "alice@example.com")
    }

    func testItemMetadataCommunicationPreservesOtherExtensions() {
        var itemMeta = ItemMetadata(
            attachmentFilePath: "/path/to/file",
            extensions: ["custom_key": .string("custom_value")]
        )
        itemMeta.communicationMetadata = CommunicationMetadata(channel: .call)

        XCTAssertEqual(itemMeta.attachmentFilePath, "/path/to/file")
        XCTAssertEqual(itemMeta.extensions["custom_key"], .string("custom_value"))
        XCTAssertNotNil(itemMeta.communicationMetadata)
    }

    // MARK: - ItemType.communication

    func testCommunicationItemType() {
        XCTAssertEqual(ItemType.communication.displayName, "Communication")
        XCTAssertEqual(ItemType.communication.icon, Icons.typeCommunication)
        XCTAssertTrue(ItemType.communication.isUserAssignable)
    }

    func testCommunicationItemTypeRawValue() {
        XCTAssertEqual(ItemType.communication.rawValue, "communication")
        XCTAssertEqual(ItemType(rawValue: "communication"), .communication)
    }
}
