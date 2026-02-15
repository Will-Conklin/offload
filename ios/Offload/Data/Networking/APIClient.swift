// Purpose: Networking utilities.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep networking isolated from view code.

import Foundation

struct APIRequest {
    let path: String
    let method: String
    var headers: [String: String]
    var body: Data?

    init(path: String, method: String, headers: [String: String] = [:], body: Data? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}

protocol APITransporting {
    func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse)
}

enum APIClientError: Error {
    case invalidURL
    case invalidResponse
    case statusCode(Int, Data)
    case transport(Error)
}

/// Network client for API communication.
final class APIClient: APITransporting {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession? = nil, baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else if let configuredBaseURL = ProcessInfo.processInfo.environment["OFFLOAD_API_BASE_URL"],
                  let url = URL(string: configuredBaseURL)
        {
            self.baseURL = url
        } else if let url = URL(string: "https://api.offload.app") {
            self.baseURL = url
        } else {
            fatalError("Invalid base URL configuration - this is a programmer error")
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = session ?? URLSession(configuration: configuration)
    }

    func resolvedURL(for path: String) -> URL? {
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let pathAndQuery = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let requestPath = pathAndQuery.isEmpty ? "" : String(pathAndQuery[0])
        let requestQuery = pathAndQuery.count > 1 ? String(pathAndQuery[1]) : nil

        let baseSegments = components.percentEncodedPath.split(separator: "/").map(String.init)
        let requestSegments = requestPath.split(separator: "/").map(String.init)
        let mergedSegments = baseSegments + requestSegments
        components.percentEncodedPath = "/" + mergedSegments.joined(separator: "/")
        components.percentEncodedQuery = requestQuery
        return components.url
    }

    func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = resolvedURL(for: request.path) else {
            throw APIClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if request.body != nil, request.headers["Content-Type"] == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw APIClientError.statusCode(httpResponse.statusCode, data)
            }
            return (data, httpResponse)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.transport(error)
        }
    }
}
