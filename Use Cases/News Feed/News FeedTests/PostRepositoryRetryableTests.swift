//
//  PostRepositoryRetryableTests.swift
//  News FeedTests
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import XCTest
import Combine
@testable import News_Feed

final class PostRepositoryRetryableTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var remoteDataSource: PostRemoteDataSource!
    private var mockHTTPClient: MockURLSessionHTTPClient!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = MockURLSessionHTTPClient()
        remoteDataSource = PostRemoteDataSource(httpClient: mockHTTPClient)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        remoteDataSource = nil
        mockHTTPClient = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Feed with Retry Tests
    
    func testFetchFeedWithRetry_SuccessAfterRetries() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount < 3 {
                throw NetworkError.serverError(500)
            }
            return FeedAPIResponse(feed: [PostPreview.mock])
        }
        
        // When
        let result = try await remoteDataSource.fetchFeed(pageToken: nil)
        
        // Then
        XCTAssertEqual(result.feed.count, 1)
        XCTAssertEqual(attemptCount, 3)
    }
    
    func testFetchFeedWithRetry_MaxAttemptsExceeded() async throws {
        // Given
        mockHTTPClient.sendResult = { _ in
            throw NetworkError.serverError(500)
        }
        
        // When & Then
        do {
            _ = try await remoteDataSource.fetchFeed(pageToken: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testFetchFeedWithRetry_NonRetryableError() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            throw NetworkError.unauthorized
        }
        
        // When & Then
        do {
            _ = try await remoteDataSource.fetchFeed(pageToken: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(attemptCount, 1) // Should not retry
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Fetch Post Detail with Retry Tests
    
    func testFetchPostDetailWithRetry_SuccessAfterRetries() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.timeout
            }
            return PostDetailAPIResponse(post: PostDetail.mock)
        }
        
        // When
        let result = try await remoteDataSource.fetchPostDetail(id: "test-id")
        
        // Then
        XCTAssertEqual(result.post.id, PostDetail.mock.id)
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testFetchPostDetailWithRetry_ServerErrorRetry() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount == 1 {
                throw NetworkError.serverError(503)
            }
            return PostDetailAPIResponse(post: PostDetail.mock)
        }
        
        // When
        let result = try await remoteDataSource.fetchPostDetail(id: "test-id")
        
        // Then
        XCTAssertEqual(result.post.id, PostDetail.mock.id)
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testFetchPostDetailWithRetry_ClientErrorNoRetry() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            throw NetworkError.notFound
        }
        
        // When & Then
        do {
            _ = try await remoteDataSource.fetchPostDetail(id: "test-id")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(attemptCount, 1) // Should not retry
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Create Post with Retry Tests
    
    func testCreatePostWithRetry_SuccessAfterRetries() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.serverError(500)
            }
        }
        
        let request = NewPostRequest(content: "Test post", attachments: [])
        
        // When
        try await remoteDataSource.createPost(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testCreatePostWithRetry_NetworkTimeoutRetry() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount == 1 {
                throw NetworkError.timeout
            }
        }
        
        let request = NewPostRequest(content: "Test post", attachments: [])
        
        // When
        try await remoteDataSource.createPost(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    // MARK: - Interact with Post with Retry Tests
    
    func testInteractWithPostWithRetry_SuccessAfterRetries() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.serverError(503)
            }
        }
        
        let request = PostInteractionRequest(postId: "test-id", action: .like)
        
        // When
        try await remoteDataSource.interact(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testInteractWithPostWithRetry_ConnectionLostRetry() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount == 1 {
                throw NetworkError.connectionLost
            }
        }
        
        let request = PostInteractionRequest(postId: "test-id", action: .unlike)
        
        // When
        try await remoteDataSource.interact(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkError_RetryableStatusCodes() {
        // Test server errors (5xx) are retryable
        XCTAssertTrue(NetworkError.serverError(500).isRetryable)
        XCTAssertTrue(NetworkError.serverError(502).isRetryable)
        XCTAssertTrue(NetworkError.serverError(503).isRetryable)
        XCTAssertTrue(NetworkError.serverError(504).isRetryable)
        
        // Test client errors (4xx) are not retryable
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
        XCTAssertFalse(NetworkError.forbidden.isRetryable)
        XCTAssertFalse(NetworkError.notFound.isRetryable)
        
        // Test network errors are retryable
        XCTAssertTrue(NetworkError.timeout.isRetryable)
        XCTAssertTrue(NetworkError.connectionLost.isRetryable)
        XCTAssertTrue(NetworkError.rateLimited.isRetryable)
    }
    
    func testNetworkError_StatusCodeMapping() {
        XCTAssertEqual(NetworkError.serverError(500).statusCode, 500)
        XCTAssertEqual(NetworkError.unauthorized.statusCode, 401)
        XCTAssertEqual(NetworkError.forbidden.statusCode, 403)
        XCTAssertEqual(NetworkError.notFound.statusCode, 404)
        XCTAssertEqual(NetworkError.rateLimited.statusCode, 429)
        XCTAssertEqual(NetworkError.timeout.statusCode, 0)
        XCTAssertEqual(NetworkError.connectionLost.statusCode, 0)
    }
}

// MARK: - Mock HTTP Client

private class MockURLSessionHTTPClient: URLSessionHTTPClient {
    var sendResult: ((Endpoint) async throws -> Any)?
    
    override func send<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        guard let result = sendResult else {
            throw NetworkError.serverError(500)
        }
        
        let response = try await result(endpoint)
        guard let typedResponse = response as? T else {
            throw NetworkError.serverError(500)
        }
        
        return typedResponse
    }
}

// MARK: - Mock Data Extensions

extension PostPreview {
    static let mock = PostPreview(
        postId: "test-id",
        author: AuthorPreview(name: "Test Author", avatarUrl: nil),
        content: "Test content",
        createdAt: Date(),
        liked: false,
        likeCount: 0,
        sharedCount: 0,
        attachmentCount: 0
    )
}

extension PostDetail {
    static let mock = PostDetail(
        id: "test-id",
        author: AuthorPreview(name: "Test Author", avatarUrl: nil),
        content: "Test content",
        createdAt: Date(),
        liked: false,
        likesCount: 0,
        sharedCount: 0,
        attachments: []
    )
}
