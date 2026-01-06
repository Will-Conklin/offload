//
//  APIClient.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation

/// Network client for API communication
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)

        // TODO: Move to configuration/environment
        guard let baseURL = URL(string: "https://api.offload.app") else {
            fatalError("Invalid base URL configuration - this is a programmer error")
        }
        self.baseURL = baseURL
    }

    // TODO: Implement request(_ endpoint: Endpoint) async throws -> Data
    // TODO: Implement upload(_ endpoint: Endpoint, data: Data) async throws -> Data
    // TODO: Implement download(_ endpoint: Endpoint) async throws -> URL
    // TODO: Add authentication/token management
    // TODO: Add retry logic with exponential backoff
    // TODO: Add request/response logging
    // TODO: Add error handling and mapping
}

// TODO: Define Endpoint protocol
// TODO: Define APIError enum
