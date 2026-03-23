// Purpose: Backend client abstractions for AI cloud integration.
// Authority: Code-level
// Governed by: CLAUDE.md
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
    /// Sum of mergedCount across all given features — used for total quota enforcement.
    func totalMergedCount(for features: [String]) -> Int
}

protocol AIBackendClient {
    func createAnonymousSession(request: AnonymousSessionRequest) async throws -> AnonymousSessionResponse
    func signInWithApple(request: AppleAuthRequest) async throws -> AppleAuthResponse
    func generateBreakdown(request: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse
    func compileBrainDump(request: BrainDumpCompileRequest) async throws -> BrainDumpCompileResponse
    func suggestDecisions(request: DecisionRecommendRequest) async throws -> DecisionRecommendResponse
    func promptExecFunction(request: ExecFunctionPromptRequest) async throws -> ExecFunctionPromptResponse
    func draftCommunication(request: CommunicationDraftRequest) async throws -> CommunicationDraftResponse
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
        tokenStore: SessionTokenStore = KeychainSessionTokenStore(),
        consentStore: CloudAIConsentStore = UserDefaultsCloudAIConsentStore(),
        installIDProvider: @escaping () -> String = { DeviceInfo.installId },
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

    func signInWithApple(request: AppleAuthRequest) async throws -> AppleAuthResponse {
        let response: AppleAuthResponse = try await performRequest(
            path: "/v1/auth/apple",
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
        try await performAuthorizedAIRequest(path: "/v1/ai/breakdown/generate", body: request)
    }

    func reconcileUsage(request: UsageReconcileRequest) async throws -> UsageReconcileResponse {
        try await performAuthorizedRequest(path: "/v1/usage/reconcile", body: request)
    }

    func compileBrainDump(request: BrainDumpCompileRequest) async throws -> BrainDumpCompileResponse {
        try await performAuthorizedAIRequest(path: "/v1/ai/braindump/compile", body: request)
    }

    func suggestDecisions(request: DecisionRecommendRequest) async throws -> DecisionRecommendResponse {
        try await performAuthorizedAIRequest(path: "/v1/ai/decide/recommend", body: request)
    }

    func promptExecFunction(request: ExecFunctionPromptRequest) async throws -> ExecFunctionPromptResponse {
        try await performAuthorizedAIRequest(path: "/v1/ai/executive-function/prompt", body: request)
    }

    func draftCommunication(request: CommunicationDraftRequest) async throws -> CommunicationDraftResponse {
        try await performAuthorizedAIRequest(path: "/v1/ai/communication/draft", body: request)
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

    /// Performs an authorized request with consent check and cloud opt-in header.
    private func performAuthorizedAIRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody
    ) async throws -> ResponseBody {
        guard consentStore.isCloudAIEnabled else {
            throw AIBackendClientError.consentRequired
        }
        return try await performAuthorizedRequest(
            path: path,
            body: body,
            extraHeaders: ["X-Offload-Cloud-Opt-In": "true"]
        )
    }

    /// Performs a session-authenticated request, retrying once on 401.
    private func performAuthorizedRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody,
        extraHeaders: [String: String] = [:]
    ) async throws -> ResponseBody {
        try await ensureActiveSession()
        guard let token = tokenStore.token else {
            throw AIBackendClientError.missingSession
        }

        var headers = extraHeaders
        headers["Authorization"] = "Bearer \(token)"

        do {
            return try await performRequest(
                path: path, method: "POST", body: body,
                headers: headers, retryUnauthorized: false
            )
        } catch AIBackendClientError.unauthorized {
            try await refreshSession()
            guard let refreshedToken = tokenStore.token else {
                throw AIBackendClientError.missingSession
            }
            headers["Authorization"] = "Bearer \(refreshedToken)"
            return try await performRequest(
                path: path, method: "POST", body: body,
                headers: headers, retryUnauthorized: false
            )
        }
    }

    private func performRequest<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        body: RequestBody,
        headers: [String: String],
        retryUnauthorized _: Bool = false
    ) async throws -> ResponseBody {
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
