//
//  PostRemoteDataSourceRetryableTests.swift
//  News FeedTests
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import XCTest
import Combine
@testable import News_Feed

final class PostRemoteDataSourceRetryableTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var remoteDataSource: PostRemoteDataSource!
    private var mockHTTPClient: MockHTTPClient!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
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
            return FeedAPIResponse(
                feed: [PostPreview.mock],
                paging: FeedAPIResponse.PaginationMetaData(next: nil)
            )
        }
        
        // When
        let result = try await remoteDataSource.fetchFeed(pageToken: nil)
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.feed.count, 1)
        }
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
        let result = try await remoteDataSource.fetchPostDetail(id: "p_18")
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.post.id, PostDetail.mock.id)
        }
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
        let result = try await remoteDataSource.fetchPostDetail(id: "p_19")
        
        // Then
        await MainActor.run {
            XCTAssertEqual(result.post.id, PostDetail.mock.id)
        }
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
            _ = try await remoteDataSource.fetchPostDetail(id: "p_20")
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
            return EmptyResponse()
        }
        
        let request = NewPostRequest(
            id: "p_21",
            content: "Test post",
            attachements: []
        )
        
        // When
        try await remoteDataSource.createPost(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testCreatePostWithRetry_NonRetryableError() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            throw NetworkError.unauthorized
        }
        
        let request = NewPostRequest(
            id: "p_22",
            content: "Test post",
            attachements: []
        )
        
        // When & Then
        do {
            try await remoteDataSource.createPost(request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(attemptCount, 1) // Should not retry
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Interact with Post with Retry Tests
    
    func testInteractWithPostWithRetry_SuccessAfterRetries() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            if attemptCount < 2 {
                throw NetworkError.serverError(500)
            }
            return EmptyResponse()
        }
        
        let request = PostInteractionRequest(postId: "p_23", action: "like")
        
        // When
        try await remoteDataSource.interact(request)
        
        // Then
        XCTAssertEqual(attemptCount, 2)
    }
    
    func testInteractWithPostWithRetry_NonRetryableError() async throws {
        // Given
        var attemptCount = 0
        mockHTTPClient.sendResult = { _ in
            attemptCount += 1
            throw NetworkError.unauthorized
        }
        
        let request = PostInteractionRequest(postId: "p_24", action: "unlike")
        
        // When & Then
        do {
            try await remoteDataSource.interact(request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(attemptCount, 1) // Should not retry
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - NetworkError Tests
    
    func testNetworkError_RetryableErrors() {
        XCTAssertTrue(NetworkError.serverError(500).isRetryable)
        XCTAssertTrue(NetworkError.serverError(502).isRetryable)
        XCTAssertTrue(NetworkError.serverError(503).isRetryable)
        XCTAssertTrue(NetworkError.serverError(504).isRetryable)
        XCTAssertTrue(NetworkError.timeout.isRetryable)
        XCTAssertTrue(NetworkError.connectionLost.isRetryable)
        XCTAssertTrue(NetworkError.rateLimited.isRetryable)
    }
    
    func testNetworkError_NonRetryableErrors() {
        XCTAssertFalse(NetworkError.serverError(400).isRetryable)
        XCTAssertFalse(NetworkError.serverError(401).isRetryable)
        XCTAssertFalse(NetworkError.serverError(403).isRetryable)
        XCTAssertFalse(NetworkError.serverError(404).isRetryable)
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
        XCTAssertFalse(NetworkError.forbidden.isRetryable)
        XCTAssertFalse(NetworkError.notFound.isRetryable)
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

private class MockHTTPClient: HTTPClient {
    var sendResult: ((Endpoint) async throws -> Any)?
    
    func send<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        guard let result = sendResult else {
            throw NetworkError.serverError(500)
        }
        
        let response = try await result(endpoint)
        guard let typedResponse = response as? T else {
            throw NetworkError.serverError(500)
        }
        
        return typedResponse
    }
    
    func send<Request: Encodable, Response: Decodable>(_ endpoint: Endpoint, body: Request) async throws -> Response {
        guard let result = sendResult else {
            throw NetworkError.serverError(500)
        }
        
        let response = try await result(endpoint)
        guard let typedResponse = response as? Response else {
            throw NetworkError.serverError(500)
        }
        
        return typedResponse
    }
    
    func send(_ endpoint: Endpoint) async throws {
        guard let result = sendResult else {
            throw NetworkError.serverError(500)
        }
        
        _ = try await result(endpoint)
    }
}


