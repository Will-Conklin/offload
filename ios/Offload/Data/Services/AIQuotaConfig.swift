// Purpose: Shared AI feature quota constants and usage reconciliation.
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation

/// Shared constants and utilities for AI quota enforcement across all AI services.
enum AIQuotaConfig {
    /// All AI feature keys subject to the shared cloud quota.
    static let allFeatures = ["breakdown", "braindump", "decide"]

    /// Maximum total cloud AI invocations across all features.
    static let cloudLimit = 100

    /// Checks whether the cloud quota has been exceeded.
    static func isQuotaExceeded(usageStore: UsageCounterStore) -> Bool {
        usageStore.totalMergedCount(for: allFeatures) >= cloudLimit
    }

    /// Reconciles local usage counts with the server for a given feature.
    /// - Returns: The server response, or `nil` if cloud AI is disabled.
    static func reconcileUsage(
        feature: String,
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        installIDProvider: () -> String
    ) async throws -> UsageReconcileResponse? {
        guard consentStore.isCloudAIEnabled else { return nil }

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
