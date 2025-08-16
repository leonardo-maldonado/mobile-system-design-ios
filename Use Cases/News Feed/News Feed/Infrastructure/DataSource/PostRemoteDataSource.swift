//
//  PostRemoteDataSource.swift
//  News Feed
//
//  Created by Leonardo Maldonado on 8/8/25.
//

import Foundation
import RetryableMacro

protocol PostRemoteDataFetching {
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse
    func createPost(_ request: NewPostRequest) async throws
    func interact(_ request: PostInteractionRequest) async throws
}

actor PostRemoteDataSource: PostRemoteDataFetching {
    
    var httpClient: URLSessionHTTPClient
    
    init(httpClient: URLSessionHTTPClient = .init(config: HTTPClientConfig())) {
        self.httpClient = httpClient
    }
    
    /// Fetch feed with automatic retry logic for network failures
    @Retryable(maxAttempts: 3, baseDelay: 1.0)
    func fetchFeed(pageToken: String?) async throws -> FeedAPIResponse {
        let endpoint = Endpoint(path: "/feed", method: .get)
        let response: FeedAPIResponse = try await httpClient.send(endpoint)
        return response
    }
    
    /// Fetch post detail with automatic retry logic
    @Retryable(maxAttempts: 2, baseDelay: 0.5)
    func fetchPostDetail(id: String) async throws -> PostDetailAPIResponse {
        let endpoint = Endpoint(path: "/posts/\(id)", method: .get)
        let response: PostDetailAPIResponse = try await httpClient.send(endpoint)
        return response
    }
    
    /// Create post with retry logic for network failures
    @RetryableWithCondition(
        maxAttempts: 2,
        baseDelay: 0.5,
        shouldRetry: { error, _ in
            // Only retry on server errors (5xx) or network timeouts
            if let networkError = error as? NetworkError {
                return networkError.statusCode >= 500
            }
            return error is URLError
        }
    )
    func createPost(_ request: NewPostRequest) async throws {
        let endpoint = Endpoint(path: "/posts", method: .post)
        let _: EmptyResponse = try await httpClient.send(endpoint, body: request)
    }
    
    /// Interact with post with retry logic for network failures
    @RetryableWithCondition(
        maxAttempts: 2,
        baseDelay: 0.5,
        shouldRetry: { error, _ in
            // Only retry on server errors (5xx) or network timeouts
            if let networkError = error as? NetworkError {
                return networkError.statusCode >= 500
            }
            return error is URLError
        }
    )
    func interact(_ request: PostInteractionRequest) async throws {
        let endpoint = Endpoint(path: "/posts/\(request.postId)/interact", method: .post)
        let _: EmptyResponse = try await httpClient.send(endpoint, body: request)
    }
}

// MARK: - Response Types

struct EmptyResponse: Codable {}

// MARK: - Network Error Types

/// Custom error types for better retry logic
enum NetworkError: Error {
    case serverError(Int)
    case timeout
    case connectionLost
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    
    var statusCode: Int {
        switch self {
        case .serverError(let code):
            return code
        case .timeout, .connectionLost:
            return 0
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .rateLimited:
            return 429
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .serverError(let code):
            return code >= 500
        case .timeout, .connectionLost:
            return true
        case .unauthorized, .forbidden, .notFound:
            return false
        case .rateLimited:
            return true
        }
    }
}
