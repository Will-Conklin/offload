// Purpose: Shared utilities and helpers.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Prefer small, reusable helpers and avoid feature-specific coupling.

import OSLog

enum AppLogger {
    static let subsystem = "wc.Offload"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let voice = Logger(subsystem: subsystem, category: "voice")
    static let workflow = Logger(subsystem: subsystem, category: "workflow")
}
