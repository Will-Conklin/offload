// Purpose: Task breakdown service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep cloud usage opt-in and fallback-safe.

import Foundation
import UIKit

protocol OnDeviceBreakdownGenerating {
    func generateBreakdown(
        inputText: String,
        granularity: Int,
        contextHints: [String],
        templateIds: [String]
    ) async throws -> [BreakdownStep]
}

final class SimpleOnDeviceBreakdownGenerator: OnDeviceBreakdownGenerating {
    func generateBreakdown(
        inputText: String,
        granularity: Int,
        contextHints: [String],
        templateIds: [String]
    ) async throws -> [BreakdownStep] {
        _ = (contextHints, templateIds)
        let rawParts = inputText.split(separator: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let parts = rawParts.filter { !$0.isEmpty }
        let maxSteps = max(1, min(granularity + 1, 6))
        let selected = Array(parts.prefix(maxSteps))
        if selected.isEmpty {
            return [BreakdownStep(title: "Review the task and define the first step")]
        }
        return selected.enumerated().map { index, value in
            BreakdownStep(title: "Step \(index + 1): \(value)")
        }
    }
}

enum BreakdownExecutionSource: Equatable {
    case onDevice
    case cloud
}

struct BreakdownExecutionResult: Equatable {
    let steps: [BreakdownStep]
    let source: BreakdownExecutionSource
    let usage: BreakdownUsage?
}

protocol BreakdownService {
    func generateBreakdown(
        inputText: String,
        granularity: Int,
        contextHints: [String],
        templateIds: [String]
    ) async throws -> BreakdownExecutionResult

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}

final class DefaultBreakdownService: BreakdownService {
    static let featureKey = "breakdown"

    private let backendClient: AIBackendClient
    private let consentStore: CloudAIConsentStore
    private let usageStore: UsageCounterStore
    private let onDeviceGenerator: OnDeviceBreakdownGenerating
    private let installIDProvider: () -> String

    init(
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        onDeviceGenerator: OnDeviceBreakdownGenerating = SimpleOnDeviceBreakdownGenerator(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId }
    ) {
        self.backendClient = backendClient
        self.consentStore = consentStore
        self.usageStore = usageStore
        self.onDeviceGenerator = onDeviceGenerator
        self.installIDProvider = installIDProvider
    }

    func generateBreakdown(
        inputText: String,
        granularity: Int,
        contextHints: [String],
        templateIds: [String]
    ) async throws -> BreakdownExecutionResult {
        guard consentStore.isCloudAIEnabled else {
            usageStore.increment(feature: Self.featureKey, by: 1)
            let steps = try await onDeviceGenerator.generateBreakdown(
                inputText: inputText,
                granularity: granularity,
                contextHints: contextHints,
                templateIds: templateIds
            )
            return BreakdownExecutionResult(steps: steps, source: .onDevice, usage: nil)
        }

        if AIQuotaConfig.isQuotaExceeded(usageStore: usageStore) {
            throw AIBackendClientError.server(code: "quota_exceeded", status: 429)
        }

        usageStore.increment(feature: Self.featureKey, by: 1)

        do {
            let cloudResponse = try await backendClient.generateBreakdown(
                request: BreakdownGenerateRequest(
                    inputText: inputText,
                    granularity: granularity,
                    contextHints: contextHints,
                    templateIds: templateIds
                )
            )
            return BreakdownExecutionResult(
                steps: cloudResponse.steps,
                source: .cloud,
                usage: cloudResponse.usage
            )
        } catch let error as AIBackendClientError where error.shouldFallbackToOnDevice {
            let steps = try await onDeviceGenerator.generateBreakdown(
                inputText: inputText,
                granularity: granularity,
                contextHints: contextHints,
                templateIds: templateIds
            )
            return BreakdownExecutionResult(steps: steps, source: .onDevice, usage: nil)
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
