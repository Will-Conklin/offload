// Purpose: Brain dump compiler service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep cloud usage opt-in and fallback-safe.

import Foundation
import UIKit

protocol OnDeviceBrainDumpGenerating {
    func compileBrainDump(
        inputText: String,
        contextHints: [String]
    ) async throws -> [BrainDumpItem]
}

final class SimpleOnDeviceBrainDumpGenerator: OnDeviceBrainDumpGenerating {
    func compileBrainDump(
        inputText: String,
        contextHints: [String]
    ) async throws -> [BrainDumpItem] {
        _ = contextHints
        let rawParts = inputText
            .components(separatedBy: CharacterSet(charactersIn: ".\n!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let parts = rawParts.filter { $0.split(separator: " ").count > 2 }
        if parts.isEmpty {
            let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            let truncated = trimmed.count > 200 ? String(trimmed.prefix(200)) + "…" : trimmed
            return [BrainDumpItem(title: truncated, type: "note")]
        }
        return parts.prefix(20).map { BrainDumpItem(title: String($0), type: "note") }
    }
}

enum BrainDumpExecutionSource: Equatable {
    case onDevice
    case cloud
}

struct BrainDumpExecutionResult: Equatable {
    let items: [BrainDumpItem]
    let source: BrainDumpExecutionSource
    let usage: BrainDumpUsage?
}

protocol BrainDumpService {
    func compileBrainDump(
        inputText: String,
        contextHints: [String]
    ) async throws -> BrainDumpExecutionResult

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}

final class DefaultBrainDumpService: BrainDumpService {
    static let featureKey = "braindump"

    private let backendClient: AIBackendClient
    private let consentStore: CloudAIConsentStore
    private let usageStore: UsageCounterStore
    private let onDeviceGenerator: OnDeviceBrainDumpGenerating
    private let installIDProvider: () -> String

    init(
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        onDeviceGenerator: OnDeviceBrainDumpGenerating = SimpleOnDeviceBrainDumpGenerator(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId }
    ) {
        self.backendClient = backendClient
        self.consentStore = consentStore
        self.usageStore = usageStore
        self.onDeviceGenerator = onDeviceGenerator
        self.installIDProvider = installIDProvider
    }

    func compileBrainDump(
        inputText: String,
        contextHints: [String]
    ) async throws -> BrainDumpExecutionResult {
        usageStore.increment(feature: DefaultBrainDumpService.featureKey, by: 1)

        guard consentStore.isCloudAIEnabled else {
            let items = try await onDeviceGenerator.compileBrainDump(
                inputText: inputText,
                contextHints: contextHints
            )
            return BrainDumpExecutionResult(items: items, source: .onDevice, usage: nil)
        }

        do {
            let cloudResponse = try await backendClient.compileBrainDump(
                request: BrainDumpCompileRequest(
                    inputText: inputText,
                    contextHints: contextHints
                )
            )
            return BrainDumpExecutionResult(
                items: cloudResponse.items,
                source: .cloud,
                usage: cloudResponse.usage
            )
        } catch let error as AIBackendClientError where error.shouldFallbackToOnDevice {
            let items = try await onDeviceGenerator.compileBrainDump(
                inputText: inputText,
                contextHints: contextHints
            )
            return BrainDumpExecutionResult(items: items, source: .onDevice, usage: nil)
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
