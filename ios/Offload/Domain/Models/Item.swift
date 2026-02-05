// Purpose: SwiftData model definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Maintain explicit type references in predicates and preserve relationship rules.

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var type: String? // "task", "link" - nullable for uncategorized captures
    var content: String
    var metadata: String // JSON string for flexible future features
    var attachmentData: Data? // Optional attachment data (photo, etc.)
    var linkedCollectionId: UUID? // for type="link" items pointing to collections
    @Attribute(originalName: "tags")
    var legacyTags: [String] // legacy tag names for migration
    @Relationship(deleteRule: .nullify, inverse: \Tag.items)
    var tagLinks: [Tag]
    var isStarred: Bool
    var followUpDate: Date?
    var completedAt: Date? // nullable timestamp for completion status
    var createdAt: Date

    // Relationship to collections through CollectionItem
    @Relationship(deleteRule: .cascade, inverse: \CollectionItem.item)
    var collectionItems: [CollectionItem]?

    init(
        id: UUID = UUID(),
        type: String? = nil,
        content: String,
        metadata: String = "{}",
        attachmentData: Data? = nil,
        linkedCollectionId: UUID? = nil,
        tags: [String] = [],
        isStarred: Bool = false,
        followUpDate: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.metadata = metadata
        self.attachmentData = attachmentData
        self.linkedCollectionId = linkedCollectionId
        legacyTags = tags
        tagLinks = []
        self.isStarred = isStarred
        self.followUpDate = followUpDate
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    // Computed properties for type-safe access
    var itemType: ItemType? {
        get {
            guard let type else { return nil }
            return ItemType(rawValue: type)
        }
        set {
            type = newValue?.rawValue
        }
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    // Computed property to decode metadata
    var metadataDict: [String: Any] {
        guard let data = metadata.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return dict
    }

    // Helper to update metadata
    func updateMetadata(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let jsonString = String(data: data, encoding: .utf8)
        {
            metadata = jsonString
        }
    }
}

enum ItemType: String, Codable, CaseIterable {
    case task
    case link

    var displayName: String {
        switch self {
        case .task: "Task"
        case .link: "Link"
        }
    }

    var icon: String {
        switch self {
        case .task: Icons.checkCircleFilled
        case .link: Icons.externalLink
        }
    }
}

extension Item {
    // Keep a stable API name while the stored relationship is tagLinks.
    var tags: [Tag] {
        get { tagLinks }
        set { tagLinks = newValue }
    }

    /// Stable color index based on item ID for consistent visual representation
    var stableColorIndex: Int {
        abs(id.hashValue) % 8 // Use 8 color palette
    }

    /// Formatted relative timestamp (e.g., "2 hours ago")
    var relativeTimestamp: String {
        createdAt.formatted(.relative(presentation: .named))
    }
}
