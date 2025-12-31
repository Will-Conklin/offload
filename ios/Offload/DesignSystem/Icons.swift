//
//  Icons.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

/// Centralized icon definitions using SF Symbols
struct Icons {
    // MARK: - Navigation

    static let inbox = "tray"
    static let capture = "plus.circle.fill"
    static let organize = "folder"
    static let settings = "gearshape"

    // MARK: - Actions

    static let add = "plus"
    static let delete = "trash"
    static let edit = "pencil"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    static let sort = "arrow.up.arrow.down"

    // MARK: - Task Status

    static let complete = "checkmark.circle.fill"
    static let incomplete = "circle"
    static let waiting = "clock"
    static let someday = "calendar"

    // MARK: - Priority

    static let highPriority = "exclamationmark.3"
    static let mediumPriority = "exclamationmark.2"
    static let lowPriority = "exclamationmark"

    // MARK: - Content Types

    static let task = "checklist"
    static let project = "folder.fill"
    static let tag = "tag.fill"
    static let category = "square.grid.2x2"
    static let note = "note.text"

    // TODO: Add more icons as needed
    // TODO: Consider custom icon assets for branding
}
