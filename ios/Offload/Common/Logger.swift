//  Intent: Centralized OSLog categories for consistent structured logging across the app.

import OSLog

// AGENT NAV
// - Loggers


enum AppLogger {
    static let subsystem = "wc.offload"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let voice = Logger(subsystem: subsystem, category: "voice")
    static let workflow = Logger(subsystem: subsystem, category: "workflow")
}
