// Purpose: Backend client abstractions for AI cloud integration.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep cloud calls consent-gated and testable.

import Foundation
import UIKit

enum AIBackendClientError: Error, Equatable {
    case consentRequired
    case missingSession
    case unauthorized
    case server(code: String, status: Int)
    case invalidResponse
    case transport
}

extension AIBackendClientError {
    var shouldFallbackToOnDevice: Bool {
        switch self {
        case .transport, .invalidResponse:
            return true
        case .server(let code, let status):
            let blockingCodes: Set<String> = [
                "quota_exceeded",
                "feature_disabled",
                "safety_blocked",
                "consent_required",
            ]

            if blockingCodes.contains(code) || status == 429 {
                return false
            }

            return status >= 500
        case .consentRequired, .missingSession, .unauthorized:
            return false
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    struct APIErrorBody: Decodable {
        let code: String
        let message: String
        let requestId: String

        enum CodingKeys: String, CodingKey {
            case code
            case message
            case requestId = "request_id"
        }
    }

    let error: APIErrorBody
}

protocol SessionTokenStore: AnyObject {
    var token: String? { get set }
    var expiresAt: Date? { get set }
    func clear()
}

final class InMemorySessionTokenStore: SessionTokenStore {
    var token: String?
    var expiresAt: Date?

    func clear() {
        token = nil
        expiresAt = nil
    }
}

protocol CloudAIConsentStore: AnyObject {
    var isCloudAIEnabled: Bool { get set }
}

final class UserDefaultsCloudAIConsentStore: CloudAIConsentStore {
    private enum Keys {
        static let cloudOptIn = "offload.cloud_ai_opt_in"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isCloudAIEnabled: Bool {
        get { defaults.bool(forKey: Keys.cloudOptIn) }
        set { defaults.set(newValue, forKey: Keys.cloudOptIn) }
    }
}

protocol UsageCounterStore: AnyObject {
    func increment(feature: String, by amount: Int)
    func localCount(for feature: String) -> Int
    func mergedCount(for feature: String) -> Int
    func updateServerCount(feature: String, serverCount: Int)
}

final class UserDefaultsUsageCounterStore: UsageCounterStore {
    private let defaults: UserDefaults
    private let localPrefix = "offload.usage.local."
    private let serverPrefix = "offload.usage.server."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func increment(feature: String, by amount: Int = 1) {
        let key = localPrefix + feature
        defaults.set(localCount(for: feature) + amount, forKey: key)
    }

    func localCount(for feature: String) -> Int {
        defaults.integer(forKey: localPrefix + feature)
    }

    func mergedCount(for feature: String) -> Int {
        max(localCount(for: feature), defaults.integer(forKey: serverPrefix + feature))
    }

    func updateServerCount(feature: String, serverCount: Int) {
        let key = serverPrefix + feature
        let existing = defaults.integer(forKey: key)
        defaults.set(max(existing, serverCount), forKey: key)
    }
}

protocol AIBackendClient {
    func createAnonymousSession(request: AnonymousSessionRequest) async throws -> AnonymousSessionResponse
    func generateBreakdown(request: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse
    func reconcileUsage(request: UsageReconcileRequest) async throws -> UsageReconcileResponse
}

final class NetworkAIBackendClient: AIBackendClient {
    private let transport: APITransporting
    private let tokenStore: SessionTokenStore
    private let consentStore: CloudAIConsentStore
    private let installIDProvider: () -> String
    private let appVersionProvider: () -> String
    private let platformProvider: () -> String

    init(
        transport: APITransporting = APIClient.shared,
        tokenStore: SessionTokenStore = InMemorySessionTokenStore(),
        consentStore: CloudAIConsentStore = UserDefaultsCloudAIConsentStore(),
        installIDProvider: @escaping () -> String = {
            UIDevice.current.identifierForVendor?.uuidString ?? "unknown-install"
        },
        appVersionProvider: @escaping () -> String = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        },
        platformProvider: @escaping () -> String = { "ios" }
    ) {
        self.transport = transport
        self.tokenStore = tokenStore
        self.consentStore = consentStore
        self.installIDProvider = installIDProvider
        self.appVersionProvider = appVersionProvider
        self.platformProvider = platformProvider
    }

    func createAnonymousSession(request: AnonymousSessionRequest) async throws -> AnonymousSessionResponse {
        let response: AnonymousSessionResponse = try await performRequest(
            path: "/v1/sessions/anonymous",
            method: "POST",
            body: request,
            headers: [:],
            retryUnauthorized: false
        )
        tokenStore.token = response.sessionToken
        tokenStore.expiresAt = response.expiresAt
        return response
    }

    func generateBreakdown(request: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse {
        guard consentStore.isCloudAIEnabled else {
            throw AIBackendClientError.consentRequired
        }

        try await ensureActiveSession()
        guard let token = tokenStore.token else {
            throw AIBackendClientError.missingSession
        }

        do {
            return try await performRequest(
                path: "/v1/ai/breakdown/generate",
                method: "POST",
                body: request,
                headers: [
                    "Authorization": "Bearer \(token)",
                    "X-Offload-Cloud-Opt-In": "true",
                ],
                retryUnauthorized: false
            )
        } catch AIBackendClientError.unauthorized {
            try await refreshSession()
            guard let refreshedToken = tokenStore.token else {
                throw AIBackendClientError.missingSession
            }
            return try await performRequest(
                path: "/v1/ai/breakdown/generate",
                method: "POST",
                body: request,
                headers: [
                    "Authorization": "Bearer \(refreshedToken)",
                    "X-Offload-Cloud-Opt-In": "true",
                ],
                retryUnauthorized: false
            )
        }
    }

    func reconcileUsage(request: UsageReconcileRequest) async throws -> UsageReconcileResponse {
        try await ensureActiveSession()
        guard let token = tokenStore.token else {
            throw AIBackendClientError.missingSession
        }

        do {
            return try await performRequest(
                path: "/v1/usage/reconcile",
                method: "POST",
                body: request,
                headers: ["Authorization": "Bearer \(token)"],
                retryUnauthorized: false
            )
        } catch AIBackendClientError.unauthorized {
            try await refreshSession()
            guard let refreshedToken = tokenStore.token else {
                throw AIBackendClientError.missingSession
            }
            return try await performRequest(
                path: "/v1/usage/reconcile",
                method: "POST",
                body: request,
                headers: ["Authorization": "Bearer \(refreshedToken)"],
                retryUnauthorized: false
            )
        }
    }

    private func ensureActiveSession() async throws {
        guard let expiry = tokenStore.expiresAt, let token = tokenStore.token else {
            try await refreshSession()
            return
        }

        let refreshThreshold = Date().addingTimeInterval(30)
        if token.isEmpty || expiry <= refreshThreshold {
            try await refreshSession()
        }
    }

    private func refreshSession() async throws {
        let request = AnonymousSessionRequest(
            installId: installIDProvider(),
            appVersion: appVersionProvider(),
            platform: platformProvider()
        )
        _ = try await createAnonymousSession(request: request)
    }

    private func performRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        body: RequestBody,
        headers: [String: String],
        retryUnauthorized: Bool
    ) async throws -> ResponseBody {
        _ = retryUnauthorized
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        return try await performRequest(path: path, method: method, bodyData: data, headers: headers)
    }

    private func performRequest<ResponseBody: Decodable>(
        path: String,
        method: String,
        bodyData: Data,
        headers: [String: String]
    ) async throws -> ResponseBody {
        do {
            let (data, _) = try await transport.send(APIRequest(path: path, method: method, headers: headers, body: bodyData))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let decoded = try? decoder.decode(ResponseBody.self, from: data) else {
                throw AIBackendClientError.invalidResponse
            }
            return decoded
        } catch let error as APIClientError {
            throw mapClientError(error)
        } catch {
            throw AIBackendClientError.transport
        }
    }

    private func mapClientError(_ error: APIClientError) -> AIBackendClientError {
        switch error {
        case .statusCode(let status, let data):
            if status == 401 {
                return .unauthorized
            }

            if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data), envelope.error.code == "consent_required" {
                return .consentRequired
            }

            if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                return .server(code: envelope.error.code, status: status)
            }

            return .server(code: "unknown_error", status: status)
        case .invalidResponse:
            return .invalidResponse
        case .invalidURL, .transport:
            return .transport
        }
    }
}
