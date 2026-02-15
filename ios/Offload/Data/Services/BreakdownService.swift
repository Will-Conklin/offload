// Purpose: Task breakdown service orchestration.
// Authority: Code-level
// Governed by: AGENTS.md
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
        installIDProvider: @escaping () -> String = {
            UIDevice.current.identifierForVendor?.uuidString ?? "unknown-install"
        }
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
        usageStore.increment(feature: "breakdown", by: 1)

        guard consentStore.isCloudAIEnabled else {
            let steps = try await onDeviceGenerator.generateBreakdown(
                inputText: inputText,
                granularity: granularity,
                contextHints: contextHints,
                templateIds: templateIds
            )
            return BreakdownExecutionResult(steps: steps, source: .onDevice, usage: nil)
        }

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
        } catch {
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
