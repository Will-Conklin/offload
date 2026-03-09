// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Preserve established theme defaults and component APIs.

import SwiftUI

/// Centralized icon definitions using SF Symbols
enum Icons {
    // MARK: - Navigation

    static let home = "house"
    static let homeSelected = "house.fill"
    static let review = "tray"
    static let reviewSelected = "tray.fill"
    static let captureList = "tray"
    static let captureListSelected = "tray.fill"
    static let capture = "lightbulb.fill"
    static let organize = "folder"
    static let organizeSelected = "folder.fill"
    static let settings = "gearshape"
    static let account = "person.circle"
    static let accountSelected = "person.circle.fill"
    static let plans = "folder"
    static let lists = "list.bullet"

    // MARK: - Actions

    static let add = "plus"
    static let addCircleFilled = "plus.circle.fill"
    static let write = "pencil"
    static let deleteFilled = "trash.fill"
    static let more = "ellipsis"
    static let convert = "arrow.2.squarepath"
    static let breakdown = "list.number"
    static let externalLink = "arrow.up.right.square"
    static let closeCircleFilled = "xmark.circle.fill"
    static let check = "checkmark"
    static let checkCircleFilled = "checkmark.circle.fill"
    static let warningFilled = "exclamationmark.triangle.fill"
    static let infoCircleFilled = "info.circle.fill"
    static let microphone = "mic"
    static let stopFilled = "stop.fill"
    static let camera = "camera"
    static let cameraFilled = "camera.fill"
    static let star = "star"
    static let starFilled = "star.fill"
    static let tag = "tag"
    static let tagFilled = "tag.fill"
    static let search = "magnifyingglass"
    static let chevronDown = "chevron.down"
    static let chevronRight = "chevron.right"
    static let heart = "heart"
    static let clock = "clock"
    static let xmark = "xmark"
    static let calendar = "calendar"

    // MARK: - Item Types

    static let typeNote = "note.text"
    static let typeIdea = "lightbulb"
    static let typeQuestion = "questionmark.circle"
    static let typeDecision = "arrow.triangle.branch"
    static let typeConcern = "exclamationmark.triangle"
    static let typeReference = "doc.text"
}
