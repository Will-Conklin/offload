// Purpose: Shared utilities, logging, and app-wide notification names.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Prefer small, reusable helpers and avoid feature-specific coupling.

import Foundation
import OSLog
import UIKit

// MARK: - Notifications

extension Notification.Name {
    static let captureItemsChanged = Notification.Name("wc.Offload.captureItemsChanged")
}

// MARK: - Logging

enum AppLogger {
    static let subsystem = "wc.Offload"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let voice = Logger(subsystem: subsystem, category: "voice")
    static let workflow = Logger(subsystem: subsystem, category: "workflow")
}

/// Device-level identifiers shared across services and views.
enum DeviceInfo {
    /// Stable per-install ID derived from `identifierForVendor`. Resets only on full reinstall.
    static var installId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-install"
    }
}
