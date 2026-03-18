// Purpose: Decision fatigue reducer service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep cloud usage opt-in and fallback-safe.

import Foundation
import UIKit

protocol OnDeviceDecisionGenerating {
    /// Generates 2–3 good-enough options from the input text without cloud access.
    func suggestDecisions(
        inputText: String,
        contextHints: [String],
        clarifyingAnswers: [DecisionClarifyingAnswer]
    ) async throws -> [DecisionOption]
}

/// On-device fallback that surfaces simple generic options from item text.
final class SimpleOnDeviceDecisionGenerator: OnDeviceDecisionGenerating {
    func suggestDecisions(
        inputText: String,
        contextHints: [String],
        clarifyingAnswers: [DecisionClarifyingAnswer]
    ) async throws -> [DecisionOption] {
        _ = (contextHints, clarifyingAnswers)

        // Try to extract alternatives from "or"-style phrasing
        let lowerText = inputText.lowercased()
        let orSeparators = [" or ", " vs ", " versus ", " / "]
        for separator in orSeparators {
            if lowerText.contains(separator) {
                let parts = inputText
                    .components(separatedBy: separator)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if parts.count >= 2 {
                    return [
                        DecisionOption(
                            title: String(parts[0].prefix(80)),
                            description: "A direct path forward based on your capture.",
                            isRecommended: true
                        ),
                        DecisionOption(
                            title: String(parts[1].prefix(80)),
                            description: "An alternative worth considering.",
                            isRecommended: false
                        ),
                    ]
                }
            }
        }

        // Generic fallback options
        return [
            DecisionOption(
                title: "Do it now",
                description: "Act on this immediately while it's fresh.",
                isRecommended: true
            ),
            DecisionOption(
                title: "Schedule it",
                description: "Set a specific time to revisit and decide.",
                isRecommended: false
            ),
            DecisionOption(
                title: "Let it wait",
                description: "See if it still feels important in a day or two.",
                isRecommended: false
            ),
        ]
    }
}

enum DecisionFatigueExecutionSource: Equatable {
    case onDevice
    case cloud
}

struct DecisionFatigueExecutionResult: Equatable {
    let options: [DecisionOption]
    let clarifyingQuestions: [String]
    let source: DecisionFatigueExecutionSource
    let usage: DecisionUsage?
}

protocol DecisionFatigueService {
    /// Suggests 2–3 good-enough options for the input text.
    /// - Returns: Options plus optional clarifying questions for refinement.
    func suggestDecisions(
        inputText: String,
        contextHints: [String],
        clarifyingAnswers: [DecisionClarifyingAnswer]
    ) async throws -> DecisionFatigueExecutionResult

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}

final class DefaultDecisionFatigueService: DecisionFatigueService {
    static let featureKey = "decide"

    private let backendClient: AIBackendClient
    private let consentStore: CloudAIConsentStore
    private let usageStore: UsageCounterStore
    private let onDeviceGenerator: OnDeviceDecisionGenerating
    private let installIDProvider: () -> String

    init(
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        onDeviceGenerator: OnDeviceDecisionGenerating = SimpleOnDeviceDecisionGenerator(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId }
    ) {
        self.backendClient = backendClient
        self.consentStore = consentStore
        self.usageStore = usageStore
        self.onDeviceGenerator = onDeviceGenerator
        self.installIDProvider = installIDProvider
    }

    func suggestDecisions(
        inputText: String,
        contextHints: [String],
        clarifyingAnswers: [DecisionClarifyingAnswer]
    ) async throws -> DecisionFatigueExecutionResult {
        usageStore.increment(feature: DefaultDecisionFatigueService.featureKey, by: 1)

        guard consentStore.isCloudAIEnabled else {
            let options = try await onDeviceGenerator.suggestDecisions(
                inputText: inputText,
                contextHints: contextHints,
                clarifyingAnswers: clarifyingAnswers
            )
            return DecisionFatigueExecutionResult(
                options: options,
                clarifyingQuestions: [],
                source: .onDevice,
                usage: nil
            )
        }

        do {
            let cloudResponse = try await backendClient.suggestDecisions(
                request: DecisionRecommendRequest(
                    inputText: inputText,
                    contextHints: contextHints,
                    clarifyingAnswers: clarifyingAnswers
                )
            )
            return DecisionFatigueExecutionResult(
                options: cloudResponse.options,
                clarifyingQuestions: cloudResponse.clarifyingQuestions,
                source: .cloud,
                usage: cloudResponse.usage
            )
        } catch let error as AIBackendClientError where error.shouldFallbackToOnDevice {
            let options = try await onDeviceGenerator.suggestDecisions(
                inputText: inputText,
                contextHints: contextHints,
                clarifyingAnswers: clarifyingAnswers
            )
            return DecisionFatigueExecutionResult(
                options: options,
                clarifyingQuestions: [],
                source: .onDevice,
                usage: nil
            )
        } catch {
            throw error
        }
    }

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse? {
        guard consentStore.isCloudAIEnabled else {
            return nil
        }

        let response = try await backendClient.reconcileUsage(
            request: UsageReconcileRequest(
                installId: installIDProvider(),
                feature: feature,
                localCount: usageStore.mergedCount(for: feature)
            )
        )
        usageStore.updateServerCount(feature: feature, serverCount: response.serverCount)
        return response
    }
}
