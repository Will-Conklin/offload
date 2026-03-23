// Purpose: Shared backend API contracts for AI and usage reconciliation.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep contract types stable and Codable.

import Foundation

struct AppleAuthRequest: Encodable {
    let appleIdentityToken: String
    let installId: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case appleIdentityToken = "apple_identity_token"
        case installId = "install_id"
        case displayName = "display_name"
    }
}

struct AppleAuthResponse: Decodable {
    let sessionToken: String
    let expiresAt: Date
    let userId: String

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresAt = "expires_at"
        case userId = "user_id"
    }
}

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

struct BrainDumpCompileRequest: Codable, Equatable {
    let inputText: String
    let contextHints: [String]

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case contextHints = "context_hints"
    }
}

struct BrainDumpItem: Codable, Equatable {
    let title: String
    let type: String
}

struct BrainDumpUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct BrainDumpCompileResponse: Codable, Equatable {
    let items: [BrainDumpItem]
    let provider: String
    let latencyMs: Int
    let usage: BrainDumpUsage

    enum CodingKeys: String, CodingKey {
        case items
        case provider
        case latencyMs = "latency_ms"
        case usage
    }
}

struct DecisionClarifyingAnswer: Codable, Equatable {
    let question: String
    let answer: String
}

struct DecisionRecommendRequest: Codable, Equatable {
    let inputText: String
    let contextHints: [String]
    let clarifyingAnswers: [DecisionClarifyingAnswer]

    init(
        inputText: String,
        contextHints: [String] = [],
        clarifyingAnswers: [DecisionClarifyingAnswer] = []
    ) {
        self.inputText = inputText
        self.contextHints = contextHints
        self.clarifyingAnswers = clarifyingAnswers
    }

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case contextHints = "context_hints"
        case clarifyingAnswers = "clarifying_answers"
    }
}

struct DecisionOption: Codable, Equatable {
    let title: String
    let description: String
    let isRecommended: Bool

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case isRecommended = "is_recommended"
    }
}

struct DecisionUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct DecisionRecommendResponse: Codable, Equatable {
    let options: [DecisionOption]
    let clarifyingQuestions: [String]
    let provider: String
    let latencyMs: Int
    let usage: DecisionUsage

    enum CodingKeys: String, CodingKey {
        case options
        case clarifyingQuestions = "clarifying_questions"
        case provider
        case latencyMs = "latency_ms"
        case usage
    }
}

// MARK: - Executive Function Prompts

struct ExecFunctionStrategyFeedback: Codable, Equatable {
    let challengeType: String
    let strategyId: String
    let thumbsUp: Bool
    let ledToCompletion: Bool

    enum CodingKeys: String, CodingKey {
        case challengeType = "challenge_type"
        case strategyId = "strategy_id"
        case thumbsUp = "thumbs_up"
        case ledToCompletion = "led_to_completion"
    }
}

struct ExecFunctionPromptRequest: Codable, Equatable {
    let inputText: String
    let contextHints: [String]
    let strategyHistory: [ExecFunctionStrategyFeedback]

    init(
        inputText: String,
        contextHints: [String] = [],
        strategyHistory: [ExecFunctionStrategyFeedback] = []
    ) {
        self.inputText = inputText
        self.contextHints = contextHints
        self.strategyHistory = strategyHistory
    }

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case contextHints = "context_hints"
        case strategyHistory = "strategy_history"
    }
}

struct ExecFunctionStrategy: Codable, Equatable {
    let strategyId: String
    let challengeType: String
    let title: String
    let description: String
    let actionPrompt: String

    enum CodingKeys: String, CodingKey {
        case strategyId = "strategy_id"
        case challengeType = "challenge_type"
        case title
        case description
        case actionPrompt = "action_prompt"
    }
}

struct ExecFunctionUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ExecFunctionPromptResponse: Codable, Equatable {
    let detectedChallenge: String
    let strategies: [ExecFunctionStrategy]
    let encouragement: String
    let provider: String
    let latencyMs: Int
    let usage: ExecFunctionUsage

    enum CodingKeys: String, CodingKey {
        case detectedChallenge = "detected_challenge"
        case strategies
        case encouragement
        case provider
        case latencyMs = "latency_ms"
        case usage
    }
}

// MARK: - Communication Draft

struct CommunicationDraftRequest: Codable, Equatable {
    let inputText: String
    let channel: String
    let contactName: String?
    let contextHints: [String]

    init(
        inputText: String,
        channel: String,
        contactName: String? = nil,
        contextHints: [String] = []
    ) {
        self.inputText = inputText
        self.channel = channel
        self.contactName = contactName
        self.contextHints = contextHints
    }

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case channel
        case contactName = "contact_name"
        case contextHints = "context_hints"
    }
}

struct CommunicationDraftUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct CommunicationDraftResponse: Codable, Equatable {
    let draftText: String
    let tone: String
    let provider: String
    let latencyMs: Int
    let usage: CommunicationDraftUsage

    enum CodingKeys: String, CodingKey {
        case draftText = "draft_text"
        case tone
        case provider
        case latencyMs = "latency_ms"
        case usage
    }
}
