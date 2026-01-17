import Foundation
import SwiftData

// AGENT NAV
// - Container
// - Configuration


/// Manages SwiftData model container configuration and setup
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    private init() {}

    // TODO: Add migration strategies
    // TODO: Add backup/restore functionality
    // TODO: Add data export functionality
    // TODO: Add CloudKit sync configuration

    func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // TODO: Add CloudKit container configuration
            // TODO: Add groupContainer for app groups/widgets
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
