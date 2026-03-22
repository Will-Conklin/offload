// Purpose: AI quota configuration, enforcement, and persistent store (UserDefaults + Keychain).
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keychain survives reinstall; UserDefaults is the fast path.

import Foundation
import Security

// MARK: - AIQuotaConfig

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

// MARK: - QuotaStore

/// Tracks AI usage counts using UserDefaults for fast local access and a Keychain mirror
/// for server counts that survive app reinstall (preventing quota circumvention).
///
/// - Local increments are stored in UserDefaults only.
/// - Server counts are written to both UserDefaults and Keychain on `updateServerCount`.
/// - `mergedCount(for:)` returns `max(localUD, serverUD, serverKeychain)`.
final class QuotaStore: UsageCounterStore {
    private let defaults: UserDefaults
    private let localPrefix = "offload.usage.local."
    private let serverPrefix = "offload.usage.server."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - UsageCounterStore

    func increment(feature: String, by amount: Int) {
        let key = localPrefix + feature
        defaults.set(localCount(for: feature) + amount, forKey: key)
    }

    func localCount(for feature: String) -> Int {
        defaults.integer(forKey: localPrefix + feature)
    }

    func mergedCount(for feature: String) -> Int {
        let local = localCount(for: feature)
        let serverUD = defaults.integer(forKey: serverPrefix + feature)
        let serverKeychain = keychainServerCount(for: feature)
        return max(local, serverUD, serverKeychain)
    }

    func updateServerCount(feature: String, serverCount: Int) {
        let existingUD = defaults.integer(forKey: serverPrefix + feature)
        let existingKeychain = keychainServerCount(for: feature)
        let effective = max(existingUD, existingKeychain, serverCount)
        defaults.set(effective, forKey: serverPrefix + feature)
        writeKeychainServerCount(effective, feature: feature)
    }

    func totalMergedCount(for features: [String]) -> Int {
        features.reduce(0) { $0 + mergedCount(for: $1) }
    }

    // MARK: - Keychain

    private func keychainServerCount(for feature: String) -> Int {
        let item = KeychainItem(account: "quota.\(feature).server")
        guard let data = item.read(),
              let string = String(data: data, encoding: .utf8),
              let count = Int(string) else { return 0 }
        return count
    }

    private func writeKeychainServerCount(_ count: Int, feature: String) {
        let item = KeychainItem(account: "quota.\(feature).server")
        guard let data = String(count).data(using: .utf8) else { return }
        item.write(data)
    }
}
