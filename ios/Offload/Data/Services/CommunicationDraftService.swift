// Purpose: AI-assisted communication draft generation with cloud-optional fallback.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep cloud usage opt-in and fallback-safe.

import Foundation

enum CommunicationDraftSource: Equatable {
    case onDevice
    case cloud
}

struct CommunicationDraftResult: Equatable {
    let draftText: String
    let tone: String
    let source: CommunicationDraftSource
    let usage: CommunicationDraftUsage?
}

protocol OnDeviceDraftGenerating {
    /// Generates a simple draft message without cloud access.
    func draftCommunication(
        inputText: String,
        channel: String,
        contactName: String?
    ) async throws -> CommunicationDraftResult
}

/// On-device fallback using template-based draft generation.
final class SimpleOnDeviceDraftGenerator: OnDeviceDraftGenerating {
    func draftCommunication(
        inputText: String,
        channel: String,
        contactName: String?
    ) async throws -> CommunicationDraftResult {
        let greeting = contactName.map { "Hi \($0)" } ?? "Hi"
        let draft: String

        switch channel {
        case "call":
            draft = """
            Talking points:
            • \(greeting) — wanted to chat about: \(inputText)
            • Key points to cover
            • Any follow-up actions
            """
        case "email":
            draft = """
            \(greeting),

            I wanted to reach out about \(inputText).

            Let me know your thoughts when you get a chance.

            Thanks!
            """
        default:
            draft = "\(greeting)! Quick note about \(inputText)"
        }

        return CommunicationDraftResult(
            draftText: draft,
            tone: "friendly",
            source: .onDevice,
            usage: nil
        )
    }
}

protocol CommunicationDraftService {
    /// Generates a draft message for a communication item.
    func draftCommunication(
        inputText: String,
        channel: String,
        contactName: String?,
        contextHints: [String]
    ) async throws -> CommunicationDraftResult

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}

final class DefaultCommunicationDraftService: CommunicationDraftService {
    static let featureKey = "draft"

    private let backendClient: AIBackendClient
    private let consentStore: CloudAIConsentStore
    private let usageStore: UsageCounterStore
    private let onDeviceGenerator: OnDeviceDraftGenerating
    private let installIDProvider: () -> String

    init(
        backendClient: AIBackendClient,
        consentStore: CloudAIConsentStore,
        usageStore: UsageCounterStore,
        onDeviceGenerator: OnDeviceDraftGenerating = SimpleOnDeviceDraftGenerator(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId }
    ) {
        self.backendClient = backendClient
        self.consentStore = consentStore
        self.usageStore = usageStore
        self.onDeviceGenerator = onDeviceGenerator
        self.installIDProvider = installIDProvider
    }

    func draftCommunication(
        inputText: String,
        channel: String,
        contactName: String?,
        contextHints: [String]
    ) async throws -> CommunicationDraftResult {
        guard consentStore.isCloudAIEnabled else {
            usageStore.increment(feature: Self.featureKey, by: 1)
            return try await onDeviceGenerator.draftCommunication(
                inputText: inputText,
                channel: channel,
                contactName: contactName
            )
        }

        if AIQuotaConfig.isQuotaExceeded(usageStore: usageStore) {
            throw AIBackendClientError.server(code: "quota_exceeded", status: 429)
        }

        usageStore.increment(feature: Self.featureKey, by: 1)

        do {
            let cloudResponse = try await backendClient.draftCommunication(
                request: CommunicationDraftRequest(
                    inputText: inputText,
                    channel: channel,
                    contactName: contactName,
                    contextHints: contextHints
                )
            )
            return CommunicationDraftResult(
                draftText: cloudResponse.draftText,
                tone: cloudResponse.tone,
                source: .cloud,
                usage: cloudResponse.usage
            )
        } catch let error as AIBackendClientError where error.shouldFallbackToOnDevice {
            return try await onDeviceGenerator.draftCommunication(
                inputText: inputText,
                channel: channel,
                contactName: contactName
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
