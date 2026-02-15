// Purpose: Environment keys for backend AI scaffolding dependencies.
// Authority: Code-level
// Governed by: AGENTS.md
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
        backendClient: NetworkAIBackendClient(),
        consentStore: UserDefaultsCloudAIConsentStore(),
        usageStore: UserDefaultsUsageCounterStore()
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
}
