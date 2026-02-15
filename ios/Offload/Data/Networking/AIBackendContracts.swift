// Purpose: Shared backend API contracts for AI and usage reconciliation.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep contract types stable and Codable.

import Foundation

struct AnonymousSessionRequest: Codable, Equatable {
    let installId: String
    let appVersion: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case installId = "install_id"
        case appVersion = "app_version"
        case platform
    }
}

struct AnonymousSessionResponse: Codable, Equatable {
    let sessionToken: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresAt = "expires_at"
    }
}

struct BreakdownGenerateRequest: Codable, Equatable {
    let inputText: String
    let granularity: Int
    let contextHints: [String]
    let templateIds: [String]

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case granularity
        case contextHints = "context_hints"
        case templateIds = "template_ids"
    }
}

struct BreakdownStep: Codable, Equatable {
    let title: String
    let substeps: [BreakdownStep]

    init(title: String, substeps: [BreakdownStep] = []) {
        self.title = title
        self.substeps = substeps
    }
}

struct BreakdownUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct BreakdownGenerateResponse: Codable, Equatable {
    let steps: [BreakdownStep]
    let provider: String
    let latencyMs: Int
    let usage: BreakdownUsage

    enum CodingKeys: String, CodingKey {
        case steps
        case provider
        case latencyMs = "latency_ms"
        case usage
    }
}

struct UsageReconcileRequest: Codable, Equatable {
    let installId: String
    let feature: String
    let localCount: Int
    let since: Date?

    init(installId: String, feature: String, localCount: Int, since: Date? = nil) {
        self.installId = installId
        self.feature = feature
        self.localCount = localCount
        self.since = since
    }

    enum CodingKeys: String, CodingKey {
        case installId = "install_id"
        case feature
        case localCount = "local_count"
        case since
    }
}

struct UsageReconcileResponse: Codable, Equatable {
    let serverCount: Int
    let effectiveRemaining: Int
    let reconciledAt: Date

    enum CodingKeys: String, CodingKey {
        case serverCount = "server_count"
        case effectiveRemaining = "effective_remaining"
        case reconciledAt = "reconciled_at"
    }
}
