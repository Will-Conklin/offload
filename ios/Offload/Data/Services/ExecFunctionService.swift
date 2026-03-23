// Purpose: Executive function prompts service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep cloud usage opt-in and fallback-safe.

import Foundation

/// Challenge types that executive function prompts can detect and address.
enum ExecFunctionChallengeType: String, CaseIterable {
    case taskInitiation = "task_initiation"
    case prioritization = "prioritization"
    case overwhelm = "overwhelm"
    case decisionParalysis = "decision_paralysis"

    var displayName: String {
        switch self {
        case .taskInitiation: "Task Initiation"
        case .prioritization: "Prioritization"
        case .overwhelm: "Overwhelm"
        case .decisionParalysis: "Decision Paralysis"
        }
    }

    var icon: String {
        switch self {
        case .taskInitiation: "play.circle"
        case .prioritization: "list.number"
        case .overwhelm: "cloud.heavyrain"
        case .decisionParalysis: "arrow.triangle.branch"
        }
    }
}

protocol OnDeviceExecFunctionGenerating {
    /// Generates executive function strategies without cloud access.
    func promptExecFunction(
        inputText: String,
        contextHints: [String]
    ) async throws -> ExecFunctionPromptResponse
}

/// On-device fallback using keyword-based challenge detection and rotating strategies.
final class SimpleOnDeviceExecFunctionGenerator: OnDeviceExecFunctionGenerating {
    func promptExecFunction(
        inputText: String,
        contextHints: [String]
    ) async throws -> ExecFunctionPromptResponse {
        _ = contextHints
        let challenge = detectChallenge(from: inputText)
        let strategies = strategiesForChallenge(challenge)
        return ExecFunctionPromptResponse(
            detectedChallenge: challenge.rawValue,
            strategies: strategies,
            encouragement: encouragementForChallenge(challenge),
            provider: "on_device",
            latencyMs: 0,
            usage: ExecFunctionUsage(inputTokens: 0, outputTokens: 0)
        )
    }

    private func detectChallenge(from text: String) -> ExecFunctionChallengeType {
        let lower = text.lowercased()

        let overwhelmKeywords = ["too much", "everything", "can't handle", "overwhelm", "drowning", "so many"]
        if overwhelmKeywords.contains(where: { lower.contains($0) }) {
            return .overwhelm
        }

        let initiationKeywords = ["can't start", "don't know where to begin", "procrastinat", "putting off", "stuck"]
        if initiationKeywords.contains(where: { lower.contains($0) }) {
            return .taskInitiation
        }

        let prioritizationKeywords = ["which first", "what order", "prioriti", "most important", "what should i do first"]
        if prioritizationKeywords.contains(where: { lower.contains($0) }) {
            return .prioritization
        }

        let decisionKeywords = ["can't decide", "back and forth", "either", "should i", "not sure if"]
        if decisionKeywords.contains(where: { lower.contains($0) }) {
            return .decisionParalysis
        }

        return .taskInitiation
    }

    private func strategiesForChallenge(_ challenge: ExecFunctionChallengeType) -> [ExecFunctionStrategy] {
        switch challenge {
        case .taskInitiation:
            return [
                ExecFunctionStrategy(
                    strategyId: "two_minute_rule",
                    challengeType: challenge.rawValue,
                    title: "The 2-Minute Rule",
                    description: "Commit to just 2 minutes. Starting is the hardest part.",
                    actionPrompt: "Set a timer for 2 minutes and begin the very first step."
                ),
                ExecFunctionStrategy(
                    strategyId: "environment_setup",
                    challengeType: challenge.rawValue,
                    title: "Set Up Your Space",
                    description: "Preparing your environment can trick your brain into starting.",
                    actionPrompt: "Open the app, file, or tool you need. Just get it on screen."
                ),
            ]
        case .prioritization:
            return [
                ExecFunctionStrategy(
                    strategyId: "energy_matching",
                    challengeType: challenge.rawValue,
                    title: "Match Your Energy",
                    description: "Pick the task that fits how you feel right now.",
                    actionPrompt: "Rate your energy 1-5 right now, then pick a task that matches."
                ),
                ExecFunctionStrategy(
                    strategyId: "pick_any_one",
                    challengeType: challenge.rawValue,
                    title: "Just Pick One",
                    description: "Any progress beats perfect ordering. The order matters less than starting.",
                    actionPrompt: "Close your eyes, point at one task, and start that one."
                ),
            ]
        case .overwhelm:
            return [
                ExecFunctionStrategy(
                    strategyId: "brain_dump_first",
                    challengeType: challenge.rawValue,
                    title: "Brain Dump First",
                    description: "Get everything out of your head. You can sort it later.",
                    actionPrompt: "Write down every single thing on your mind, no filtering."
                ),
                ExecFunctionStrategy(
                    strategyId: "smallest_step",
                    challengeType: challenge.rawValue,
                    title: "Smallest Possible Step",
                    description: "Find the tiniest action that moves you forward.",
                    actionPrompt: "What's one thing you could do in under 30 seconds?"
                ),
            ]
        case .decisionParalysis:
            return [
                ExecFunctionStrategy(
                    strategyId: "good_enough",
                    challengeType: challenge.rawValue,
                    title: "Good Enough Is Great",
                    description: "Most decisions are reversible. Pick the one that feels 60% right.",
                    actionPrompt: "Which option would you tell a friend to choose?"
                ),
                ExecFunctionStrategy(
                    strategyId: "coin_flip_check",
                    challengeType: challenge.rawValue,
                    title: "The Coin Flip Check",
                    description: "Your gut reaction to a random choice reveals your preference.",
                    actionPrompt: "Assign heads/tails to your options. Flip (or imagine). Notice how you feel."
                ),
            ]
        }
    }

    private func encouragementForChallenge(_ challenge: ExecFunctionChallengeType) -> String {
        switch challenge {
        case .taskInitiation:
            "Starting is the bravest part. You've already taken a step by asking for help."
        case .prioritization:
            "There's no perfect order. Any movement forward counts."
        case .overwhelm:
            "It's okay to feel this way. Let's make it smaller together."
        case .decisionParalysis:
            "Both options are probably fine. Trust yourself."
        }
    }
}

enum ExecFunctionExecutionSource: Equatable {
    case onDevice
    case cloud
}

struct ExecFunctionExecutionResult: Equatable {
    let detectedChallenge: String
    let strategies: [ExecFunctionStrategy]
    let encouragement: String
    let source: ExecFunctionExecutionSource
    let usage: ExecFunctionUsage?
}

protocol ExecFunctionService {
    /// Generates executive function scaffolding strategies.
    func promptExecFunction(
        inputText: String,
        contextHints: [String],
        strategyHistory: [ExecFunctionStrategyFeedback]
    ) async throws -> ExecFunctionExecutionResult

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}

final class DefaultExecFunctionService: ExecFunctionService {
    static let featureKey = "execfunction"

    private let backendClient: AIBackendClient
    private let consentStore: CloudAIConsentStore
    private let usageStore: UsageCounterStore
    private let onDeviceGenerator: OnDeviceExecFunctionGenerating
    private let installIDProvider: () -> String

    init(
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        onDeviceGenerator: OnDeviceExecFunctionGenerating = SimpleOnDeviceExecFunctionGenerator(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId }
    ) {
        self.backendClient = backendClient
        self.consentStore = consentStore
        self.usageStore = usageStore
        self.onDeviceGenerator = onDeviceGenerator
        self.installIDProvider = installIDProvider
    }

    func promptExecFunction(
        inputText: String,
        contextHints: [String],
        strategyHistory: [ExecFunctionStrategyFeedback]
    ) async throws -> ExecFunctionExecutionResult {
        guard consentStore.isCloudAIEnabled else {
            usageStore.increment(feature: Self.featureKey, by: 1)
            let response = try await onDeviceGenerator.promptExecFunction(
                inputText: inputText,
                contextHints: contextHints
            )
            return ExecFunctionExecutionResult(
                detectedChallenge: response.detectedChallenge,
                strategies: response.strategies,
                encouragement: response.encouragement,
                source: .onDevice,
                usage: nil
            )
        }

        if AIQuotaConfig.isQuotaExceeded(usageStore: usageStore) {
            throw AIBackendClientError.server(code: "quota_exceeded", status: 429)
        }

        usageStore.increment(feature: Self.featureKey, by: 1)

        do {
            let cloudResponse = try await backendClient.promptExecFunction(
                request: ExecFunctionPromptRequest(
                    inputText: inputText,
                    contextHints: contextHints,
                    strategyHistory: strategyHistory
                )
            )
            return ExecFunctionExecutionResult(
                detectedChallenge: cloudResponse.detectedChallenge,
                strategies: cloudResponse.strategies,
                encouragement: cloudResponse.encouragement,
                source: .cloud,
                usage: cloudResponse.usage
            )
        } catch let error as AIBackendClientError where error.shouldFallbackToOnDevice {
            let response = try await onDeviceGenerator.promptExecFunction(
                inputText: inputText,
                contextHints: contextHints
            )
            return ExecFunctionExecutionResult(
                detectedChallenge: response.detectedChallenge,
                strategies: response.strategies,
                encouragement: response.encouragement,
                source: .onDevice,
                usage: nil
            )
        }
    }

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse? {
        try await AIQuotaConfig.reconcileUsage(
            feature: feature,
            backendClient: backendClient,
            consentStore: consentStore,
            usageStore: usageStore,
            installIDProvider: installIDProvider
        )
    }
}
