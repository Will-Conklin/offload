//
//  Icons.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

// AGENT NAV
// - Navigation Icons
// - Action Icons
// - Content Icons

/// Centralized icon definitions using SF Symbols
struct Icons {
    // MARK: - Navigation

    static let captures = "lightbulb"
    static let capture = "plus.circle.fill"
    static let organize = "folder"
    static let settings = "gearshape"
    static let plans = "folder"
    static let lists = "list.bullet"

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

    // MARK: - Content Types

    static let task = "checklist"
    static let project = "folder.fill"
    static let tag = "tag.fill"
    static let category = "square.grid.2x2"
    static let note = "note.text"

    // TODO: Add more icons as needed
    // TODO: Consider custom icon assets for branding
}
