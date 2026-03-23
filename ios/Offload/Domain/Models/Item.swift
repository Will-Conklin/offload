// Purpose: SwiftData model definitions.
// Authority: Code-level
// Governed by: CLAUDE.md
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
    @Relationship(deleteRule: .nullify, inverse: \Tag.items)
    var tags: [Tag]
    var isStarred: Bool
    var followUpDate: Date?
    var completedAt: Date? // nullable timestamp for completion status
    var createdAt: Date
    @Transient
    var cachedAttachmentData: Data?
    @Transient
    var cachedMetadataModel: ItemMetadata?
    @Transient
    var cachedMetadataSource: String?

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
        tags = []
        self.isStarred = isStarred
        self.followUpDate = followUpDate
        self.completedAt = completedAt
        self.createdAt = createdAt
        cachedAttachmentData = nil
        cachedMetadataModel = nil
        cachedMetadataSource = nil
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

    // Compatibility bridge for legacy call sites.
    var metadataDict: [String: Any] {
        typedMetadata.dictionaryRepresentation
    }

    // Compatibility bridge for legacy call sites.
    func updateMetadata(_ dict: [String: Any]) {
        typedMetadata = ItemMetadata(dictionary: dict)
    }
}

enum ItemType: String, Codable, CaseIterable {
    case task
    case link
    case note
    case idea
    case question
    case decision
    case concern
    case reference
    case communication

    var displayName: String {
        switch self {
        case .task: "Task"
        case .link: "Link"
        case .note: "Note"
        case .idea: "Idea"
        case .question: "Question"
        case .decision: "Decision"
        case .concern: "Concern"
        case .reference: "Reference"
        case .communication: "Communication"
        }
    }

    var icon: String {
        switch self {
        case .task: Icons.checkCircleFilled
        case .link: Icons.externalLink
        case .note: Icons.typeNote
        case .idea: Icons.typeIdea
        case .question: Icons.typeQuestion
        case .decision: Icons.typeDecision
        case .concern: Icons.typeConcern
        case .reference: Icons.typeReference
        case .communication: Icons.typeCommunication
        }
    }

    /// Whether users can assign this type directly from the capture UI.
    /// `link` is an internal type for collection pointers and should not appear in pickers.
    var isUserAssignable: Bool {
        self != .link
    }
}

extension Item {
    var typedMetadata: ItemMetadata {
        get {
            if let cachedMetadataModel,
               cachedMetadataSource == metadata
            {
                return cachedMetadataModel
            }
            let decodedMetadata = ItemMetadata.decode(from: metadata)
            cachedMetadataModel = decodedMetadata
            cachedMetadataSource = metadata
            return decodedMetadata
        }
        set {
            let encodedMetadata = newValue.encodeToJSONString()
            metadata = encodedMetadata
            cachedMetadataModel = newValue
            cachedMetadataSource = encodedMetadata
        }
    }

    var attachmentFilePath: String? {
        get { typedMetadata.attachmentFilePath }
        set {
            var metadataValue = typedMetadata
            metadataValue.attachmentFilePath = newValue
            typedMetadata = metadataValue
        }
    }

    /// Communication metadata for items with type `.communication`.
    var communicationMetadata: CommunicationMetadata? {
        get { typedMetadata.communicationMetadata }
        set {
            var meta = typedMetadata
            meta.communicationMetadata = newValue
            typedMetadata = meta
        }
    }

    /// Stable color index based on item ID for consistent visual representation
    var stableColorIndex: Int {
        abs(id.hashValue) % 8 // Use 8 color palette
    }

    /// Formatted relative timestamp (e.g., "2 hours ago")
    var relativeTimestamp: String {
        createdAt.formatted(.relative(presentation: .named))
    }

    /// Number of words in the item content.
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    /// True when the item content is long enough to warrant a Brain Dump suggestion.
    var isBrainDumpCandidate: Bool {
        wordCount > 75
    }

    /// True when the item content contains signals that the user may be stuck.
    var isStuckCandidate: Bool {
        guard !isBrainDumpCandidate else { return false }
        let lower = content.lowercased()
        let stuckKeywords = [
            "can't start", "don't know where to begin", "stuck",
            "overwhelm", "too much", "can't decide", "procrastinat",
            "putting off", "don't know what to do", "can't figure out",
            "keep going back and forth", "paralyz",
        ]
        return stuckKeywords.contains { lower.contains($0) }
    }
}
