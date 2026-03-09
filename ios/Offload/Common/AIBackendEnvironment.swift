// Purpose: Environment keys for backend AI scaffolding dependencies.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep fallback defaults local and side-effect safe.

import SwiftUI

private struct AIBackendClientKey: EnvironmentKey {
    static let defaultValue: AIBackendClient = NetworkAIBackendClient()
}

private struct CloudAIConsentStoreKey: EnvironmentKey {
    static let defaultValue: CloudAIConsentStore = UserDefaultsCloudAIConsentStore()
}

private struct UsageCounterStoreKey: EnvironmentKey {
    static let defaultValue: UsageCounterStore = UserDefaultsUsageCounterStore()
}

private struct BreakdownServiceKey: EnvironmentKey {
    static let defaultValue: BreakdownService = DefaultBreakdownService(
        backendClient: AIBackendClientKey.defaultValue,
        consentStore: CloudAIConsentStoreKey.defaultValue,
        usageStore: UsageCounterStoreKey.defaultValue
    )
}

private struct BrainDumpServiceKey: EnvironmentKey {
    static let defaultValue: BrainDumpService = DefaultBrainDumpService(
        backendClient: AIBackendClientKey.defaultValue,
        consentStore: CloudAIConsentStoreKey.defaultValue,
        usageStore: UsageCounterStoreKey.defaultValue
    )
}

private struct DecisionFatigueServiceKey: EnvironmentKey {
    static let defaultValue: DecisionFatigueService = DefaultDecisionFatigueService(
        backendClient: AIBackendClientKey.defaultValue,
        consentStore: CloudAIConsentStoreKey.defaultValue,
        usageStore: UsageCounterStoreKey.defaultValue
    )
}

extension EnvironmentValues {
    var aiBackendClient: AIBackendClient {
        get { self[AIBackendClientKey.self] }
        set { self[AIBackendClientKey.self] = newValue }
    }

    var cloudAIConsentStore: CloudAIConsentStore {
        get { self[CloudAIConsentStoreKey.self] }
        set { self[CloudAIConsentStoreKey.self] = newValue }
    }

    var usageCounterStore: UsageCounterStore {
        get { self[UsageCounterStoreKey.self] }
        set { self[UsageCounterStoreKey.self] = newValue }
    }

    var breakdownService: BreakdownService {
        get { self[BreakdownServiceKey.self] }
        set { self[BreakdownServiceKey.self] = newValue }
    }

    var brainDumpService: BrainDumpService {
        get { self[BrainDumpServiceKey.self] }
        set { self[BrainDumpServiceKey.self] = newValue }
    }

    var decisionFatigueService: DecisionFatigueService {
        get { self[DecisionFatigueServiceKey.self] }
        set { self[DecisionFatigueServiceKey.self] = newValue }
    }
}
