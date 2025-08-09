//
//  HTTPClient.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import Foundation

// MARK: - HTTP Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]

    init(path: String, method: HTTPMethod, queryItems: [URLQueryItem] = [], headers: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
    }
}

// MARK: - Configuration

struct HTTPClientConfig {
    let baseURL: URL
    var timeout: TimeInterval = 30
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    var defaultHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    var additionalQueryItems: [URLQueryItem] = []
    var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    var encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    var isLoggingEnabled: Bool = false
}

// MARK: - Interceptors & Retry

protocol HTTPRequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest
    func willSend(_ request: URLRequest)
    func didReceive(data: Data, response: URLResponse)
}

extension HTTPRequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest { request }
    func willSend(_ request: URLRequest) {}
    func didReceive(data: Data, response: URLResponse) {}
}

protocol RetryPolicy {
    /// Return delay (seconds) to retry after, or nil to stop retrying.
    func retryDelay(for error: Error, attempt: Int) -> TimeInterval?
}

struct ExponentialBackoffRetryPolicy: RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryNetworkErrors: Bool
    let retryStatusCodes: Set<Int>

    init(maxRetries: Int = 2,
         baseDelay: TimeInterval = 0.5,
         maxDelay: TimeInterval = 5.0,
         retryNetworkErrors: Bool = true,
         retryStatusCodes: Set<Int> = [429, 500, 502, 503, 504]) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.retryNetworkErrors = retryNetworkErrors
        self.retryStatusCodes = retryStatusCodes
    }

    func retryDelay(for error: Error, attempt: Int) -> TimeInterval? {
        guard attempt <= maxRetries else { return nil }
        if let httpError = error as? HTTPError {
            if case let .requestFailed(statusCode, _) = httpError, retryStatusCodes.contains(statusCode) {
                return min(maxDelay, baseDelay * pow(2, Double(attempt - 1)))
            }
        }
        if retryNetworkErrors, error is URLError {
            return min(maxDelay, baseDelay * pow(2, Double(attempt - 1)))
        }
        return nil
    }
}

// MARK: - Errors

enum HTTPError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, data: Data)
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case network(underlying: Error)
    case cancelled

    static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.cancelled, .cancelled): return true
        case let (.requestFailed(a, _), .requestFailed(b, _)): return a == b
        case (.decodingFailed, .decodingFailed): return true
        case (.encodingFailed, .encodingFailed): return true
        case (.network, .network): return true
        default: return false
        }
    }
}

// MARK: - Protocol

protocol HTTPClient {
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response
    func send<Request: Encodable, Response: Decodable>(_ endpoint: Endpoint, body: Request) async throws -> Response
    func send(_ endpoint: Endpoint) async throws // no body, no response (e.g., 204)
}

// MARK: - Implementation

struct URLSessionHTTPClient: HTTPClient {
    private let config: HTTPClientConfig
    private let session: URLSession
    private let interceptors: [HTTPRequestInterceptor]
    private let retryPolicy: RetryPolicy?

    init(config: HTTPClientConfig,
         session: URLSession = .shared,
         interceptors: [HTTPRequestInterceptor] = [],
         retryPolicy: RetryPolicy? = ExponentialBackoffRetryPolicy()) {
        self.config = config
        self.session = session
        self.interceptors = interceptors
        self.retryPolicy = retryPolicy
    }

    // GET-like without body
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let request = try buildRequest(for: endpoint, bodyData: nil)
        let data = try await execute(request: request)
        do {
            return try config.decoder.decode(Response.self, from: data)
        } catch {
            throw HTTPError.decodingFailed(underlying: error)
        }
    }

    // With Encodable body (JSON)
    func send<Request: Encodable, Response: Decodable>(_ endpoint: Endpoint, body: Request) async throws -> Response {
        let bodyData: Data
        do {
            bodyData = try config.encoder.encode(body)
        } catch {
            throw HTTPError.encodingFailed(underlying: error)
        }
        var request = try buildRequest(for: endpoint, bodyData: bodyData)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let data = try await execute(request: request)
        do {
            return try config.decoder.decode(Response.self, from: data)
        } catch {
            throw HTTPError.decodingFailed(underlying: error)
        }
    }

    // No response body expected
    func send(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint, bodyData: nil)
        _ = try await execute(request: request)
    }

    // MARK: - Helpers

    private func buildRequest(for endpoint: Endpoint, bodyData: Data?) throws -> URLRequest {
        // Compose URL
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else { throw HTTPError.invalidURL }
        let path = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        components.path = (components.path) + "/" + path
        var query = config.additionalQueryItems
        if !endpoint.queryItems.isEmpty { query.append(contentsOf: endpoint.queryItems) }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw HTTPError.invalidURL }

        // Build request
        var request = URLRequest(url: url, cachePolicy: config.cachePolicy, timeoutInterval: config.timeout)
        request.httpMethod = endpoint.method.rawValue

        // Headers: defaults first, then endpoint overrides
        for (k, v) in config.defaultHeaders { request.setValue(v, forHTTPHeaderField: k) }
        for (k, v) in endpoint.headers { request.setValue(v, forHTTPHeaderField: k) }

        // Body
        request.httpBody = bodyData

        return request
    }

    private func execute(request initialRequest: URLRequest) async throws -> Data {
        var request = initialRequest
        // Interceptor adapt
        for interceptor in interceptors {
            request = try await interceptor.adapt(request)
        }

        var attempt = 1
        while true {
            if config.isLoggingEnabled {
                logRequest(request, attempt: attempt)
            }

            for interceptor in interceptors { interceptor.willSend(request) }

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw HTTPError.invalidResponse }
                for interceptor in interceptors { interceptor.didReceive(data: data, response: response) }

                guard 200..<300 ~= http.statusCode else {
                    let error = HTTPError.requestFailed(statusCode: http.statusCode, data: data)
                    if let delay = retryPolicy?.retryDelay(for: error, attempt: attempt) {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        attempt += 1
                        continue
                    }
                    throw error
                }

                if config.isLoggingEnabled {
                    logResponse(response: http, data: data)
                }
                return data
            } catch {
                if (error as? CancellationError) != nil || Task.isCancelled {
                    throw HTTPError.cancelled
                }
                // Map URLError to .network
                let mapped: Error = (error as? URLError) != nil ? HTTPError.network(underlying: error) : error
                if let delay = retryPolicy?.retryDelay(for: mapped, attempt: attempt) {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    continue
                }
                throw mapped
            }
        }
    }

    private func logRequest(_ request: URLRequest, attempt: Int) {
        var lines: [String] = []
        lines.append("[HTTP] Attempt \(attempt) \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyStr = String(data: body, encoding: .utf8) {
            lines.append("Body: \(bodyStr)")
        }
        print(lines.joined(separator: " | "))
    }

    private func logResponse(response: HTTPURLResponse, data: Data) {
        var lines: [String] = []
        lines.append("[HTTP] \(response.statusCode) \(response.url?.absoluteString ?? "")")
        if let bodyStr = String(data: data, encoding: .utf8), !bodyStr.isEmpty {
            lines.append("Body: \(bodyStr)")
        }
        print(lines.joined(separator: " | "))
    }
}

