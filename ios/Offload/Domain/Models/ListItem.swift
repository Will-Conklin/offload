//
//  ListItem.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//

import Foundation
import SwiftData

@Model
final class ListItem {
    var id: UUID
    var text: String
    var isChecked: Bool

    // Relationships
    @Relationship(deleteRule: .nullify)
    var list: ListEntity?

    init(
        id: UUID = UUID(),
        text: String,
        isChecked: Bool = false,
        list: ListEntity? = nil
    ) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
        self.list = list
    }
}
